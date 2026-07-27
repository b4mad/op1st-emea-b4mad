#!/usr/bin/env bash
# Create a service-account ("bot") user + named personal access token on the
# nostromo Forgejo test instance (namespace b4mad-forgejo).
#
# WHY a script: the instance is a throwaway SQLite deployment (see README.md).
# Accounts/tokens created here are NOT captured in git and vanish if the volume
# is lost. This script IS the record of how to recreate them.
#
# Auth model: DISABLE_REGISTRATION + ALLOW_ONLY_EXTERNAL_REGISTRATION +
# ENABLE_INTERNAL_SIGNIN=false, so bots can neither self-register nor web-login.
# The ONLY supported path is admin-created local accounts driving the API/git
# via a PAT (basic auth over HTTPS or the token as an API bearer).
#
# Usage:  ./create-forge-bot.sh <username> <email> <token-scopes> [token-name]
# Example:./create-forge-bot.sh b4mad-renovate renovate@b4mad.net \
#            "write:repository,write:issue,read:user" renovate
#
# The generated token is printed ONCE on stdout — capture it immediately and
# store it in a SOPS-encrypted secret; it cannot be retrieved again.
#
# Profile picture: the bot's avatar is set from AVATAR_FILE (default:
# b4mad-renovate-avatar.png next to this script) on every run — for both newly
# created AND already-existing ("updated") bots. Override the source image with
# AVATAR_FILE=/path/to.png, or set AVATAR_FILE= (empty) to skip the avatar step.
#
#   ⚠️ HOW the avatar is set: Forgejo's POST /api/v1/user/avatar needs a
#   write:user-scoped token OR HTTP basic auth. To avoid forcing write:user onto
#   the bot's operational token, we authenticate this single call with basic
#   auth, rotating the account password to a throwaway random value first. This
#   is invisible in practice: per the auth model above, bots never sign in and
#   drive everything via their PAT — the password is unused. The throwaway value
#   is discarded, so no known credential lingers.
set -euo pipefail

NS=b4mad-forgejo
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# The public route of THIS instance (NS is hardcoded above, so the URL is too).
# Deliberately NOT ${FORGEJO_URL:-…}: the environment already exports
# FORGEJO_URL=https://codeberg.org (for the Codeberg CLI/MCP), which would
# silently redirect the bot's credentials to the wrong forge → 401.
FORGEJO_URL="https://forgejo.b4mad.net"
# AVATAR_FILE may be set empty to skip; only default when the var is UNSET.
AVATAR_FILE="${AVATAR_FILE-$SCRIPT_DIR/b4mad-renovate-avatar.png}"
USERNAME="${1:?username required}"
EMAIL="${2:?email required}"
SCOPES="${3:?comma-separated token scopes required}"
TOKEN_NAME="${4:-$USERNAME}"

POD="$(oc -n "$NS" get pod -l app.kubernetes.io/name=forgejo \
        -o jsonpath='{.items[0].metadata.name}')"
exec_forgejo() { oc -n "$NS" exec "pod/$POD" -c forgejo -- forgejo "$@"; }

# Set the bot's Forgejo avatar from AVATAR_FILE via the API (basic auth; see the
# header note on why we rotate the password). No-op if AVATAR_FILE is empty or
# missing. All diagnostics go to stderr — stdout is reserved for the token.
set_bot_avatar() {
  local user="$1" file="$AVATAR_FILE"
  [[ -n "$file" ]] || { echo "» AVATAR_FILE empty — skipping avatar" >&2; return 0; }
  if [[ ! -f "$file" ]]; then
    echo "⚠️ avatar file '$file' not found — skipping avatar" >&2
    return 0
  fi
  echo "» setting avatar for '$user' from $(basename "$file")" >&2
  local ephpw img tmpjson code
  ephpw="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"
  exec_forgejo admin user change-password --username "$user" \
    --password "$ephpw" --must-change-password=false >&2
  img="$(base64 -w0 "$file")"
  tmpjson="$(mktemp)"
  printf '{"image":"%s"}' "$img" >"$tmpjson"
  code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$FORGEJO_URL/api/v1/user/avatar" \
    -u "$user:$ephpw" -H 'Content-Type: application/json' \
    --data-binary @"$tmpjson")"
  rm -f "$tmpjson"
  if [[ "$code" == "204" ]]; then
    echo "» avatar set (HTTP 204)" >&2
  else
    echo "⚠️ avatar upload failed (HTTP $code)" >&2
    return 1
  fi
}

if exec_forgejo admin user list 2>/dev/null | awk '{print $2}' | grep -qx "$USERNAME"; then
  echo "» user '$USERNAME' already exists — skipping create" >&2
else
  echo "» creating local bot user '$USERNAME' <$EMAIL>" >&2
  exec_forgejo admin user create \
    --username "$USERNAME" \
    --email "$EMAIL" \
    --random-password \
    --must-change-password=false >&2
fi

set_bot_avatar "$USERNAME"

echo "» generating access token '$TOKEN_NAME' (scopes: $SCOPES)" >&2
echo -n "${USERNAME} token: "
exec_forgejo admin user generate-access-token \
  --username "$USERNAME" \
  --token-name "$TOKEN_NAME" \
  --scopes "$SCOPES" \
  --raw
