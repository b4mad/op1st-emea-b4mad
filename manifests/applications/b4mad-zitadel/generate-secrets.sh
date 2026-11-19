#!/usr/bin/env bash
# Generate the b4mad-zitadel Secrets: SOPS source of truth (*.enc.yaml) plus
# the SealedSecret Argo CD applies (*.yaml), the repo-wide pattern.
#
# Usage (from anywhere; needs sops + a PGP key from .sops.yaml, kubeseal,
# openssl):
#   manifests/applications/b4mad-zitadel/generate-secrets.sh [--cert sealed-secrets.pem] \
#     [--tunnel-credentials <tunnel-id>.json]
#
# --cert seals offline against the controller's public certificate, for hosts
# that hold the PGP key but have no cluster login. Fetch it where you do have
# one:
#   oc -n sealed-secrets get secret <newest sealed-secrets-key…> \
#     -o jsonpath='{.data.tls\.crt}' | base64 -d > sealed-secrets.pem
# Without --cert, kubeseal asks the controller in namespace sealed-secrets.
#
# --tunnel-credentials takes the credentials file `cloudflared tunnel create`
# wrote and turns it into zitadel-cloudflared (key credentials.json). It is
# only read when zitadel-cloudflared.enc.yaml does not exist yet.
#
# ⚠️ Idempotent by refusal: an existing *.enc.yaml is NEVER regenerated, only
# re-sealed. zitadel-masterkey must never change — Zitadel encrypts its
# secrets with it, and a new one makes the database unreadable. To rotate
# zitadel-login, delete its .enc.yaml deliberately and re-run.
#
# Plaintext only ever exists in a mode-0600 temp file on tmpfs that is removed
# on exit, and in pipes. Nothing is printed.
set -euo pipefail
umask 077

here=$(cd "$(dirname "$0")" && pwd)
repo=$(git -C "$here" rev-parse --show-toplevel)
ns=b4mad-zitadel

abspath() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
cert_args=(--controller-namespace sealed-secrets)
tunnel_creds=
while [[ $# -gt 0 ]]; do
  case $1 in
    --cert)
      [[ -r ${2:-} ]] || { echo "cannot read cert '${2:-}'" >&2; exit 2; }
      cert_args=(--cert "$(abspath "$2")"); shift 2 ;;
    --tunnel-credentials)
      [[ -r ${2:-} ]] || { echo "cannot read tunnel credentials '${2:-}'" >&2; exit 2; }
      tunnel_creds=$(abspath "$2"); shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

for t in sops kubeseal openssl base64; do
  command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 2; }
done

tmp=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/zitadel-secrets.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

b64() { base64 -w0; }

# Encrypt plaintext Secret YAML from stdin into $1.enc.yaml (repo .sops.yaml
# rules), unless it already exists.
encrypt() {
  local name=$1 out="$here/$1.enc.yaml"
  if [[ -e $out ]]; then
    echo "keep     $name.enc.yaml (exists, not regenerated)"
    cat >/dev/null
    return
  fi
  cat >"$tmp/$name.yaml"
  (cd "$repo" && sops --config .sops.yaml --encrypt \
    --input-type yaml --output-type yaml "$tmp/$name.yaml") >"$out.tmp"
  mv "$out.tmp" "$out"
  rm -f "$tmp/$name.yaml"
  echo "created  $name.enc.yaml"
}

seal() {
  local name=$1
  (cd "$repo" && sops --decrypt "$here/$name.enc.yaml") \
    | kubeseal "${cert_args[@]}" --format yaml >"$here/$name.yaml.tmp"
  mv "$here/$name.yaml.tmp" "$here/$name.yaml"
  echo "sealed   $name.yaml"
}

secret_header() {
  printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: %s\n  namespace: %s\ntype: Opaque\ndata:\n' "$1" "$ns"
}

# aws-creds — the same S3 credentials as b4mad-keycloak. Its source file
# carries no namespace (it was given to kubeseal at seal time), so set one;
# sops indents with 4 spaces, hence the indentation-agnostic patterns.
if [[ ! -e $here/aws-creds.enc.yaml ]]; then
  (cd "$repo" && sops --decrypt manifests/applications/b4mad-keycloak/aws-creds.enc.yaml) \
    | sed -E -e '/^ +(creationTimestamp|namespace):/d' \
        -e 's/^( +)name: aws-creds$/&\n\1namespace: '"$ns"'/' \
    | encrypt aws-creds
else
  encrypt aws-creds </dev/null
fi

# zitadel-masterkey — exactly 32 characters.
{
  secret_header zitadel-masterkey
  printf '  masterkey: %s\n' "$(openssl rand -hex 16 | tr -d '\n' | b64)"
} | encrypt zitadel-masterkey

# zitadel-login — RSA keypair for the Login v2 system user + cookie secret.
if [[ ! -e $here/zitadel-login.enc.yaml ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj /CN=login-service \
    -keyout "$tmp/tls.key" -out "$tmp/tls.crt" 2>/dev/null
fi
{
  secret_header zitadel-login
  if [[ -e $tmp/tls.key ]]; then
    printf '  tls.crt: %s\n' "$(b64 <"$tmp/tls.crt")"
    printf '  tls.key: %s\n' "$(b64 <"$tmp/tls.key")"
    printf '  ZITADEL_SESSION_COOKIE_SECRET: %s\n' "$(openssl rand -hex 32 | tr -d '\n' | b64)"
  fi
} | encrypt zitadel-login

# zitadel-cloudflared — the tunnel's credentials.json, as written by
# `cloudflared tunnel create`.
secrets=(aws-creds zitadel-masterkey zitadel-login)
if [[ -e $here/zitadel-cloudflared.enc.yaml || -n $tunnel_creds ]]; then
  {
    secret_header zitadel-cloudflared
    if [[ -n $tunnel_creds ]]; then
      printf '  credentials.json: %s\n' "$(b64 <"$tunnel_creds")"
    fi
  } | encrypt zitadel-cloudflared
  secrets+=(zitadel-cloudflared)
fi

for s in "${secrets[@]}"; do
  # metadata stays unencrypted under the repo's encrypted_regex, so the
  # namespace can be checked without decrypting.
  grep -Eq "^ +namespace: $ns\$" "$here/$s.enc.yaml" \
    || { echo "$s.enc.yaml is not in namespace $ns — refusing to seal" >&2; exit 1; }
  seal "$s"
done
