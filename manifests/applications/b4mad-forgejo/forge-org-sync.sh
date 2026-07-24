#!/usr/bin/env bash
#
# forge-org-sync.sh — back up Codeberg org structure to JSONL, replay onto Forgejo.
#
# Both codeberg.org and forgejo.b4mad.net run Forgejo, so one API dialect
# (/api/v1, Gitea-compatible) covers read and write.
#
# Structure captured/recreated: orgs, teams (+ units/permission), team
# memberships, org-level labels, and empty repo shells. NO git content.
#
# Usage:
#   CODEBERG_TOKEN=xxx ./forge-org-sync.sh backup  [orgs.jsonl] [org ...]
#   FORGEJO_TOKEN=xxx  ./forge-org-sync.sh restore [orgs.jsonl]
#
#   backup   reads from $CODEBERG_URL (default https://codeberg.org),
#            writes one typed JSON record per line to the JSONL file.
#            With no org args, defaults to the 11 orgs goern owns.
#   restore  reads the JSONL and creates anything missing on $FORGEJO_URL
#            (default https://forgejo.b4mad.net). Idempotent: existing
#            objects are left untouched. Set DRY_RUN=1 to preview.
#
set -euo pipefail

CODEBERG_URL=${CODEBERG_URL:-https://codeberg.org}
# NB: this repo's .envrc aliases FORGEJO_URL/FORGEJO_ACCESS_TOKEN to *Codeberg*.
# We deliberately IGNORE those for the restore target and require an explicit
# FORGEJO_TARGET_URL + FORGEJO_TOKEN, so `source .envrc` can't silently point a
# restore back at the source instance. Do NOT fall back to FORGEJO_ACCESS_TOKEN.
FORGEJO_URL=${FORGEJO_TARGET_URL:-https://forgejo.b4mad.net}
DRY_RUN=${DRY_RUN:-0}
PAGE=50

DEFAULT_ORGS=(
  agentic-forges b4mad feeldata kunsttherapie-bonn machdenstaat
  open-by-default operate-first sportverein-vilich-mueldorf
  sustainablesupplychain tinytalesshop toolbxs
)

# --- HTTP -------------------------------------------------------------------
# Populates RESP_CODE / RESP_BODY. Does not exit on HTTP errors so callers can
# treat "already exists" (422/409) as a non-fatal skip.
RESP_CODE=0
RESP_BODY=''
req() { # method base token path [json-data]
  local method=$1 base=$2 token=$3 path=$4 data=${5:-} tmp dtmp=''
  tmp=$(mktemp)
  local -a a=(-sS -o "$tmp" -w '%{http_code}' -X "$method"
              -H "Authorization: token $token")
  # Send the body from a file (--data-binary @file), never as an argv string:
  # base64 avatars exceed Linux MAX_ARG_STRLEN (128 KiB) and would E2BIG.
  if [[ -n $data ]]; then
    dtmp=$(mktemp); printf '%s' "$data" >"$dtmp"
    a+=(-H 'Content-Type: application/json' --data-binary @"$dtmp")
  fi
  RESP_CODE=$(curl "${a[@]}" "$base/api/v1$path")
  RESP_BODY=$(cat "$tmp"); rm -f "$tmp"
  [[ -n $dtmp ]] && rm -f "$dtmp"
  return 0   # never let the cleanup test's exit status trip `set -e`
}

# Download a URL and echo its bytes as single-line base64 (empty on failure).
download_b64() { # url token
  local url=$1 token=$2 tmp code
  [[ -z $url ]] && return 0
  tmp=$(mktemp)
  code=$(curl -sS -o "$tmp" -w '%{http_code}' -H "Authorization: token $token" "$url" || echo 000)
  [[ $code == 200 && -s $tmp ]] && base64 -w0 "$tmp"
  rm -f "$tmp"
}

# GET every page of a list endpoint, echo one concatenated JSON array.
get_all() { # base token path
  local base=$1 token=$2 path=$3 page=1 out='[]' n
  while :; do
    req GET "$base" "$token" "${path}?limit=${PAGE}&page=${page}"
    [[ $RESP_CODE == 200 ]] || { echo "  ! GET $path -> $RESP_CODE" >&2; break; }
    n=$(jq 'length' <<<"$RESP_BODY")
    out=$(jq -s '.[0]+.[1]' <<<"$out"$'\n'"$RESP_BODY")
    (( n < PAGE )) && break
    (( page++ ))
  done
  printf '%s' "$out"
}

# --- BACKUP -----------------------------------------------------------------
backup() {
  local out=$1; shift
  local orgs=("$@")
  [[ ${#orgs[@]} -eq 0 ]] && orgs=("${DEFAULT_ORGS[@]}")
  : "${CODEBERG_TOKEN:?set CODEBERG_TOKEN}"
  : >"$out"

  local org teams labels repos tid
  for org in "${orgs[@]}"; do
    echo "backup org: $org" >&2
    req GET "$CODEBERG_URL" "$CODEBERG_TOKEN" "/orgs/$org"
    if [[ $RESP_CODE != 200 ]]; then
      echo "  ! skip $org (GET org -> $RESP_CODE)" >&2; continue
    fi
    local avatar_url avatar_b64 abfile
    avatar_url=$(jq -r '.avatar_url // ""' <<<"$RESP_BODY")
    avatar_b64=$(download_b64 "$avatar_url" "$CODEBERG_TOKEN")
    [[ -n $avatar_b64 ]] && echo "  avatar embedded (${#avatar_b64} b64 chars)" >&2
    abfile=$(mktemp); printf '%s' "$avatar_b64" >"$abfile"   # --rawfile: avoids argv limit
    jq -c --rawfile avatar "$abfile" '{type:"org", username, full_name, description,
            website, location, visibility, avatar_url, avatar:$avatar}' \
            <<<"$RESP_BODY" >>"$out"
    rm -f "$abfile"

    # org labels
    labels=$(get_all "$CODEBERG_URL" "$CODEBERG_TOKEN" "/orgs/$org/labels")
    jq -c --arg org "$org" '.[] | {type:"label", org:$org,
            name, color, description, exclusive}' <<<"$labels" >>"$out"

    # empty repo shells (metadata only)
    repos=$(get_all "$CODEBERG_URL" "$CODEBERG_TOKEN" "/orgs/$org/repos")
    jq -c --arg org "$org" '.[] | {type:"repo", org:$org,
            name, description, private, default_branch}' <<<"$repos" >>"$out"

    # teams, then each team's members
    teams=$(get_all "$CODEBERG_URL" "$CODEBERG_TOKEN" "/orgs/$org/teams")
    jq -c --arg org "$org" '.[] | {type:"team", org:$org, name, description,
            permission, units, includes_all_repositories,
            can_create_org_repo}' <<<"$teams" >>"$out"

    while read -r tid tname; do
      [[ -z $tid ]] && continue
      local members
      members=$(get_all "$CODEBERG_URL" "$CODEBERG_TOKEN" "/teams/$tid/members")
      jq -c --arg org "$org" --arg team "$tname" '.[] |
            {type:"team_member", org:$org, team:$team, username:.login}' \
            <<<"$members" >>"$out"
    done < <(jq -r '.[] | "\(.id)\t\(.name)"' <<<"$teams")
  done
  echo "wrote $(wc -l <"$out") records to $out" >&2
}

# --- RESTORE ----------------------------------------------------------------
say() { echo "$@" >&2; }
would() { [[ $DRY_RUN == 1 ]] && { say "  [dry-run] $*"; return 0; }; return 1; }

# find a team id by name on the target org; echoes id or empty
target_team_id() { # org name
  local teams; teams=$(get_all "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$1/teams")
  jq -r --arg n "$2" '.[] | select(.name==$n) | .id' <<<"$teams" | head -n1
}

restore() {
  local in=$1
  : "${FORGEJO_TOKEN:?set FORGEJO_TOKEN (a forgejo.b4mad.net token, NOT the Codeberg one)}"
  [[ -f $in ]] || { say "no such file: $in"; exit 1; }

  # Safety: never let the restore target resolve to the source host.
  local shost thost
  shost=$(sed -E 's#https?://([^/]+).*#\1#' <<<"$CODEBERG_URL")
  thost=$(sed -E 's#https?://([^/]+).*#\1#' <<<"$FORGEJO_URL")
  [[ $shost == "$thost" ]] && {
    say "ABORT: restore target ($thost) equals source ($shost)."
    say "  Set FORGEJO_TARGET_URL to forgejo.b4mad.net; do not inherit FORGEJO_URL from .envrc."
    exit 1
  }
  # Verify the token actually authenticates on the target before mutating.
  req GET "$FORGEJO_URL" "$FORGEJO_TOKEN" "/user"
  [[ $RESP_CODE == 200 ]] || {
    say "ABORT: FORGEJO_TOKEN does not authenticate on $thost (GET /user -> $RESP_CODE)."
    exit 1
  }
  say "restore target: $thost as $(jq -r '.login' <<<"$RESP_BODY")"

  # 1) orgs — create if missing, else update profile; then upload avatar
  jq -c 'select(.type=="org")' "$in" | while read -r r; do
    local name img; name=$(jq -r '.username' <<<"$r")
    req GET "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$name"
    if [[ $RESP_CODE == 200 ]]; then
      if ! would "update profile of org $name"; then
        req PATCH "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$name" \
          "$(jq -c '{full_name, description, website, location, visibility}' <<<"$r")"
        [[ $RESP_CODE =~ ^20 ]] && say "org profile updated: $name" \
          || say "  ! org patch $name -> $RESP_CODE $RESP_BODY"
      fi
    else
      if ! would "create org $name"; then
        req POST "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs" \
          "$(jq -c '{username, full_name, description, website, location, visibility}' <<<"$r")"
        [[ $RESP_CODE =~ ^20 ]] && say "org created: $name" \
          || say "  ! org $name -> $RESP_CODE $RESP_BODY"
      fi
    fi
    # embedded avatar (base64)
    img=$(jq -r '.avatar // ""' <<<"$r")
    if [[ -n $img ]] && ! would "upload avatar for $name (${#img} b64 chars)"; then
      local ifile body; ifile=$(mktemp); printf '%s' "$img" >"$ifile"
      body=$(jq -nc --rawfile image "$ifile" '{image:$image}'); rm -f "$ifile"
      req POST "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$name/avatar" "$body"
      [[ $RESP_CODE =~ ^20 ]] && say "avatar set: $name" \
        || say "  ! avatar $name -> $RESP_CODE $RESP_BODY"
    fi
  done

  # 2) teams (skip auto-created Owners)
  jq -c 'select(.type=="team")' "$in" | while read -r r; do
    local org name; org=$(jq -r '.org' <<<"$r"); name=$(jq -r '.name' <<<"$r")
    [[ $name == Owners ]] && continue
    [[ -n $(target_team_id "$org" "$name") ]] && { say "team exists: $org/$name"; continue; }
    would "create team $org/$name" && continue
    req POST "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$org/teams" \
      "$(jq -c '{name, description, permission, units,
                 includes_all_repositories, can_create_org_repo}' <<<"$r")"
    [[ $RESP_CODE =~ ^20 ]] && say "team created: $org/$name" \
      || say "  ! team $org/$name -> $RESP_CODE $RESP_BODY"
  done

  # 3) org labels
  jq -c 'select(.type=="label")' "$in" | while read -r r; do
    local org name existing; org=$(jq -r '.org' <<<"$r"); name=$(jq -r '.name' <<<"$r")
    existing=$(get_all "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$org/labels")
    if jq -e --arg n "$name" 'any(.[]; .name==$n)' <<<"$existing" >/dev/null; then
      say "label exists: $org/$name"; continue
    fi
    would "create label $org/$name" && continue
    req POST "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$org/labels" \
      "$(jq -c '{name, color, description, exclusive}' <<<"$r")"
    [[ $RESP_CODE =~ ^20 ]] && say "label created: $org/$name" \
      || say "  ! label $org/$name -> $RESP_CODE $RESP_BODY"
  done

  # 4) repo shells (empty, no auto_init)
  jq -c 'select(.type=="repo")' "$in" | while read -r r; do
    local org name; org=$(jq -r '.org' <<<"$r"); name=$(jq -r '.name' <<<"$r")
    req GET "$FORGEJO_URL" "$FORGEJO_TOKEN" "/repos/$org/$name"
    if [[ $RESP_CODE == 200 ]]; then say "repo exists: $org/$name"; continue; fi
    would "create repo $org/$name" && continue
    req POST "$FORGEJO_URL" "$FORGEJO_TOKEN" "/orgs/$org/repos" \
      "$(jq -c '{name, description, private, default_branch, auto_init:false}' <<<"$r")"
    [[ $RESP_CODE =~ ^20 ]] && say "repo created: $org/$name" \
      || say "  ! repo $org/$name -> $RESP_CODE $RESP_BODY"
  done

  # 5) team memberships (last: teams must exist; users must exist on target)
  jq -c 'select(.type=="team_member")' "$in" | while read -r r; do
    local org team user tid
    org=$(jq -r '.org' <<<"$r"); team=$(jq -r '.team' <<<"$r"); user=$(jq -r '.username' <<<"$r")
    tid=$(target_team_id "$org" "$team")
    [[ -z $tid ]] && { say "  ! no target team $org/$team, skip member $user"; continue; }
    would "add $user to $org/$team (team $tid)" && continue
    req PUT "$FORGEJO_URL" "$FORGEJO_TOKEN" "/teams/$tid/members/$user"
    if [[ $RESP_CODE =~ ^20 ]]; then
      say "member added: $org/$team += $user"
    else
      local why="see body"
      [[ $RESP_CODE == 404 ]] && why="user '$user' not registered on target"
      [[ $RESP_CODE == 403 ]] && why="token lacks org-admin scope"
      say "  ! member $org/$team += $user -> $RESP_CODE ($why)"
    fi
  done
}

# --- main -------------------------------------------------------------------
cmd=${1:-}; shift || true
case "$cmd" in
  backup)  backup "${1:-codeberg-orgs.jsonl}" "${@:2}" ;;
  restore) restore "${1:-codeberg-orgs.jsonl}" ;;
  *) echo "usage: $0 {backup [file] [org...] | restore [file]}" >&2; exit 2 ;;
esac
