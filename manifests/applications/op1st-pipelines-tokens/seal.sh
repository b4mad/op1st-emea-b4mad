#!/usr/bin/env bash
# seal.sh — regenerate SealedSecret(s) from SOPS-encrypted plaintext.
#
# Walks every *.enc.yaml in this directory. For each one:
#   1. sops -d        produce plaintext Secret
#   2. kubeseal       produce SealedSecret
#   3. yq merge       restore metadata.annotations from plaintext onto
#                     spec.template.metadata.annotations (kubeseal strips
#                     them by default)
#
# Prereqs: sops, kubeseal, yq (mikefarah/yq v4+).
# Cluster kubeconfig must point at the cluster running sealed-secrets.
set -euo pipefail

cd "$(dirname "$0")"

CONTROLLER_NS="${SEALED_SECRETS_CONTROLLER_NS:-sealed-secrets}"
CONTROLLER_NAME="${SEALED_SECRETS_CONTROLLER_NAME:-sealed-secrets-controller}"

for cmd in sops kubeseal yq; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done

shopt -s nullglob
plaintexts=( *.enc.yaml )
if (( ${#plaintexts[@]} == 0 )); then
  echo "no *.enc.yaml found" >&2; exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for plain in "${plaintexts[@]}"; do
  base="${plain%.enc.yaml}"
  sealed="${base}.yaml"

  if sops -d "$plain" 2>/dev/null | grep -q REPLACE_ME; then
    echo "skip $plain — plaintext still contains REPLACE_ME (edit with: sops $plain)" >&2
    continue
  fi

  echo "==> resealing $plain"

  sops -d "$plain" >"$TMP/plain.yaml"

  # Snapshot Secret-level annotations from plaintext before kubeseal strips
  # them off the template.
  yq -o=json '.metadata.annotations // {}' "$TMP/plain.yaml" >"$TMP/annotations.json"

  kubeseal \
    --controller-namespace="$CONTROLLER_NS" \
    --controller-name="$CONTROLLER_NAME" \
    --format=yaml \
    <"$TMP/plain.yaml" >"$TMP/sealed.yaml"

  # Merge annotations back onto spec.template.metadata.annotations.
  ANN_FILE="$TMP/annotations.json" yq -i '
    .spec.template.metadata.annotations =
      (.spec.template.metadata.annotations // {}) * load(strenv(ANN_FILE))
  ' "$TMP/sealed.yaml"

  mv "$TMP/sealed.yaml" "$sealed"
  echo "    wrote: $sealed"
done

echo
echo "review with: git diff -- *.yaml"
echo "commit:      git add *.yaml *.enc.yaml && git commit"
