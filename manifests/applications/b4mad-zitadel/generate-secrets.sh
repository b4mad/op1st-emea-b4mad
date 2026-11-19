#!/usr/bin/env bash
# Generate the b4mad-zitadel Secrets: SOPS source of truth (*.enc.yaml) plus
# the SealedSecret Argo CD applies (*.yaml), the repo-wide pattern.
#
# Usage (from anywhere; needs sops + a PGP key from .sops.yaml, kubeseal,
# openssl):
#   manifests/applications/b4mad-zitadel/generate-secrets.sh [--cert sealed-secrets.pem]
#
# --cert seals offline against the controller's public certificate, for hosts
# that hold the PGP key but have no cluster login. Fetch it where you do have
# one:
#   oc -n sealed-secrets get secret <newest sealed-secrets-key…> \
#     -o jsonpath='{.data.tls\.crt}' | base64 -d > sealed-secrets.pem
# Without --cert, kubeseal asks the controller in namespace sealed-secrets.
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

cert_args=(--controller-namespace sealed-secrets)
if [[ ${1:-} == --cert ]]; then
  [[ -r ${2:-} ]] || { echo "cannot read cert '${2:-}'" >&2; exit 2; }
  cert_args=(--cert "$(cd "$(dirname "$2")" && pwd)/$(basename "$2")")
fi

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

# aws-creds — the same S3 credentials as b4mad-keycloak, re-namespaced.
if [[ ! -e $here/aws-creds.enc.yaml ]]; then
  (cd "$repo" && sops --decrypt manifests/applications/b4mad-keycloak/aws-creds.enc.yaml) \
    | sed -e 's/^\(  namespace:\) b4mad-keycloak$/\1 '"$ns"'/' -e '/^  creationTimestamp:/d' \
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

for s in aws-creds zitadel-masterkey zitadel-login; do
  # metadata stays unencrypted under the repo's encrypted_regex, so the
  # namespace can be checked without decrypting.
  grep -q "^  namespace: $ns\$" "$here/$s.enc.yaml" \
    || { echo "$s.enc.yaml is not in namespace $ns — refusing to seal" >&2; exit 1; }
  seal "$s"
done
