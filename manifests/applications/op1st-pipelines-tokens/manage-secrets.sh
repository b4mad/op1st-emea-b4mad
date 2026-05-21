#!/usr/bin/env bash
# manage-secrets.sh — create and (re)seal SealedSecrets in this directory.
#
# Subcommands:
#   new [name]
#       Generate an ed25519 SSH keypair, build a kubernetes.io/ssh-auth
#       Secret containing both ssh-privatekey and ssh-publickey, SOPS-encrypt
#       to <name>.enc.yaml, then run a reseal so <name>.yaml (SealedSecret)
#       is produced in the same step. Annotations and metadata.namespace can
#       be added afterwards with `sops <name>.enc.yaml` followed by another
#       `reseal`.
#
#   reseal
#       Walk every *.enc.yaml in the target directory, decrypt with SOPS,
#       run kubeseal, and merge metadata.annotations back onto
#       spec.template.metadata.annotations (kubeseal drops them).
#
# Options:
#   -C <dir>     Target directory (default: current working directory).
#   -h, --help   Show this help.
#
# Env:
#   SEALED_SECRETS_CONTROLLER_NS   (default: sealed-secrets)
#   SEALED_SECRETS_CONTROLLER_NAME (default: sealed-secrets-controller)
#   SECRET_NAMESPACE               (default: op1st-gitops)
#   REFLECT_BASE                   (default: op1st-pipelines) — always added to
#                                  reflector.../reflection-(allowed|auto)-namespaces;
#                                  the prompt asks for one additional namespace
#   HREF_DEFAULT                   (default: https://codeberg.org/op1st-gitops)
#                                  set to "" to skip the b4mad.net/href annotation
#
# Prereqs: sops, kubeseal, yq (mikefarah v4+), oc, ssh-keygen.
set -euo pipefail

CONTROLLER_NS="${SEALED_SECRETS_CONTROLLER_NS:-sealed-secrets}"
CONTROLLER_NAME="${SEALED_SECRETS_CONTROLLER_NAME:-sealed-secrets-controller}"
SECRET_NAMESPACE="${SECRET_NAMESPACE:-op1st-gitops}"
REFLECT_BASE="${REFLECT_BASE:-op1st-pipelines}"
HREF_DEFAULT="${HREF_DEFAULT-https://codeberg.org/op1st-gitops}"

TARGET_DIR="$PWD"
SUBCMD=""
NAME=""

usage() {
  sed -n '2,/^set -euo pipefail/p' "$0" | sed -e 's/^# \{0,1\}//' -e '/^set -euo pipefail/d'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -C) TARGET_DIR="$(cd "$2" && pwd)"; shift 2;;
    -h|--help) usage 0;;
    new|reseal) SUBCMD="$1"; shift;;
    *) NAME="$1"; shift;;
  esac
done

[[ -n "$SUBCMD" ]] || { echo "missing subcommand" >&2; usage 1 >&2; }

require() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }
  done
}

# seal_one <plaintext.enc.yaml> <output.yaml>
seal_one() {
  local plain="$1" sealed="$2"
  local tmp; tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN

  if sops -d "$plain" 2>/dev/null | grep -q REPLACE_ME; then
    echo "skip $plain — plaintext still contains REPLACE_ME (edit with: sops $plain)" >&2
    return 0
  fi

  sops -d "$plain" > "$tmp/plain.yaml"

  yq -o=json '.metadata.annotations // {}' "$tmp/plain.yaml" > "$tmp/annotations.json"

  kubeseal \
    --controller-namespace="$CONTROLLER_NS" \
    --controller-name="$CONTROLLER_NAME" \
    --format=yaml \
    < "$tmp/plain.yaml" > "$tmp/sealed.yaml"

  ANN_FILE="$tmp/annotations.json" yq -i '
    .spec.template.metadata.annotations =
      (.spec.template.metadata.annotations // {}) * load(strenv(ANN_FILE))
  ' "$tmp/sealed.yaml"

  mv "$tmp/sealed.yaml" "$sealed"
  echo "    wrote: $sealed"
}

cmd_new() {
  require ssh-keygen oc sops kubeseal yq

  if [[ -z "$NAME" ]]; then
    read -r -p "Secret name: " NAME
  fi
  [[ -n "$NAME" ]] || { echo "name required" >&2; exit 1; }
  [[ "$NAME" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] \
    || { echo "invalid name — must be lowercase RFC1123 (a-z, 0-9, '-')" >&2; exit 1; }

  local target reflect href
  read -r -p "Reflect Secret to which namespace (e.g. b4mad-hausmeister): " target
  [[ -n "$target" ]] || { echo "target namespace required" >&2; exit 1; }
  [[ "$target" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] \
    || { echo "invalid namespace — must be lowercase RFC1123" >&2; exit 1; }
  reflect="${REFLECT_BASE},${target}"
  read -r -p "b4mad.net/href [${HREF_DEFAULT:-<none>}]: " href
  href="${href-$HREF_DEFAULT}"

  local out_enc="${TARGET_DIR}/${NAME}.enc.yaml"
  local out_sealed="${TARGET_DIR}/${NAME}.yaml"

  if [[ -e "$out_enc" || -e "$out_sealed" ]]; then
    echo "refusing to overwrite ${out_enc} or ${out_sealed}" >&2
    exit 1
  fi

  local work; work="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" EXIT

  ssh-keygen -t ed25519 -N "" -C "$NAME" -f "$work/key" >/dev/null

  oc create secret generic "$NAME" \
    --type=kubernetes.io/ssh-auth \
    --from-file=ssh-privatekey="$work/key" \
    --from-file=ssh-publickey="$work/key.pub" \
    --dry-run=client --output=yaml > "$work/plain.yaml"

  NS="$SECRET_NAMESPACE" REFLECT="$reflect" yq -i '
    .metadata.namespace = strenv(NS) |
    .metadata.annotations = {
      "reflector.v1.k8s.emberstack.com/reflection-allowed": "true",
      "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces": strenv(REFLECT),
      "reflector.v1.k8s.emberstack.com/reflection-auto-enabled": "true",
      "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces": strenv(REFLECT)
    }
  ' "$work/plain.yaml"

  if [[ -n "$href" ]]; then
    HREF="$href" yq -i '.metadata.annotations.["b4mad.net/href"] = strenv(HREF)' "$work/plain.yaml"
  fi

  sops -e "$work/plain.yaml" > "$out_enc"
  echo "==> wrote: $out_enc"

  echo "==> sealing $out_enc"
  seal_one "$out_enc" "$out_sealed"

  echo
  echo "public key (add as deploy key on the git host):"
  cat "$work/key.pub"
  echo
  echo "to add reflector annotations or set metadata.namespace:"
  echo "  sops $out_enc"
  echo "  $0 reseal"
}

cmd_reseal() {
  require sops kubeseal yq

  shopt -s nullglob
  local plaintexts=( "$TARGET_DIR"/*.enc.yaml )
  if (( ${#plaintexts[@]} == 0 )); then
    echo "no *.enc.yaml in $TARGET_DIR" >&2
    exit 1
  fi

  local plain base
  for plain in "${plaintexts[@]}"; do
    base="${plain%.enc.yaml}"
    echo "==> resealing $plain"
    seal_one "$plain" "${base}.yaml"
  done

  echo
  echo "review: git diff -- '$TARGET_DIR'/*.yaml"
  echo "commit: git add '$TARGET_DIR'/*.yaml '$TARGET_DIR'/*.enc.yaml && git commit"
}

case "$SUBCMD" in
  new) cmd_new ;;
  reseal) cmd_reseal ;;
  *) usage 1 >&2 ;;
esac
