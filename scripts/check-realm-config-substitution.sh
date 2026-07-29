#!/usr/bin/env bash
# Refuse to commit a keycloak-config-cli realm file that names a substitution
# variable inside a comment.
#
# keycloak-config-cli runs its StringSubstitutor over the RAW FILE TEXT before
# the YAML is parsed, so it has no concept of a comment. A reference written
# as documentation — even an obviously illustrative one with an ellipsis — is
# resolved exactly like a real value, and an unresolvable name aborts the
# whole import with "Cannot resolve variable" (because
# IMPORT_VARSUBSTITUTION_UNDEFINEDISERROR defaults to true).
#
# That is a nasty failure mode: the file is valid YAML, it renders fine under
# `kustomize build`, and nothing catches it until the PostSync hook fails
# against the live server. It happened on the first sync of realm
# b4mad-forgejo, from a comment reading "$" "(env:…)".
#
# Real references belong on value lines only. This hook enforces that.
set -euo pipefail

rc=0
for f in "$@"; do
  [ -f "$f" ] || continue
  # Comment lines only: optional leading whitespace, then '#'.
  while IFS=: read -r lineno text; do
    [ -n "${lineno:-}" ] || continue
    echo "ERROR: $f:$lineno names a substitution variable in a comment." >&2
    echo "       ${text#"${text%%[![:space:]]*}"}" >&2
    rc=1
  done < <(grep -nE '^[[:space:]]*#.*\$\(' "$f" || true)
done

if [ "$rc" -ne 0 ]; then
  echo >&2
  echo "keycloak-config-cli substitutes over raw file text, before YAML is" >&2
  echo "parsed — it cannot tell a comment from a value. A prose mention is" >&2
  echo "resolved like a real reference and fails the import." >&2
  echo "Describe the variable by name, without the substitution sigil." >&2
fi
exit "$rc"
