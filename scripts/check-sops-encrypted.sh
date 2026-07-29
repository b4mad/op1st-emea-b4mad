#!/usr/bin/env bash
# Refuse to commit a *.enc.yaml that is not actually SOPS-encrypted.
#
# The .enc.yaml suffix is a promise, not a mechanism: `kubectl create secret
# --dry-run -o yaml > foo.enc.yaml` produces a file that looks encrypted at a
# glance but holds plain base64, which is reversible by anyone. This hook
# makes the promise enforceable.
#
# A genuine SOPS file carries a top-level `sops:` metadata block (mac, pgp
# fingerprints, encrypted_regex). Absence of that block is the check — it
# cannot be faked by accident the way base64 can be mistaken for ciphertext.
set -euo pipefail

rc=0
for f in "$@"; do
  [ -f "$f" ] || continue
  if ! grep -qE '^sops:' "$f"; then
    echo "ERROR: $f has an .enc.yaml name but no top-level 'sops:' block." >&2
    echo "       It is NOT encrypted. base64 is encoding, not encryption." >&2
    echo "       Encrypt in place with:  sops -e -i $f" >&2
    rc=1
  fi
done

if [ "$rc" -ne 0 ]; then
  echo >&2
  echo "Refusing the commit. If a plaintext secret already reached a commit," >&2
  echo "rotate it — rewriting history does not un-publish it." >&2
fi
exit "$rc"
