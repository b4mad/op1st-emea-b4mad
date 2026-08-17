#!/usr/bin/env bash
#
# Keep gitea.podAnnotations["op1st.b4mad.net/restart-hash"] in
# values-nostromo.yaml in sync with the ConfigMaps the Forgejo pod only reads
# ONCE, at start.
#
# Why this exists (op1st-emea-b4mad-aid): Anubis reads POLICY_FNAME at startup
# and never again, and initPreScript copies the custom templates + robots.txt
# into /data on start. An Argo CD sync updates the mounted ConfigMap, the repo
# and `oc get cm` both agree the new content is in place — and the pod keeps
# serving the old one indefinitely. A policy change that silently does nothing
# is worse than one that fails loudly.
#
# The fix is the usual `checksum/config` trick, which Helm cannot do for us
# here because these ConfigMaps live in the kustomize source, not the chart.
# So: hash them ourselves, park the hash in a pod annotation, and let the
# pre-commit hook keep it honest. A changed annotation changes the pod
# template, which rolls the pod, which re-reads everything.
#
# Run by .pre-commit-config.yaml; safe to run by hand. Rewrites the values file
# and exits 1 when the hash was stale (pre-commit convention: the fixed file is
# left in the worktree for you to re-stage).
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
app_dir="${repo_root}/manifests/applications/b4mad-forgejo"
values="${app_dir}/values-nostromo.yaml"

# Everything the pod reads exactly once, at start. Add a file here and the
# annotation starts tracking it — that is the whole extension mechanism.
inputs=(
  "${app_dir}/anubis.yaml"                    # ConfigMap/anubis-policy -> sidecar, POLICY_FNAME
  "${app_dir}/home-template.configmap.yaml"   # ConfigMap/forgejo-custom-templates -> initPreScript copy
)

for f in "${inputs[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "update-pod-restart-hash: missing input ${f}" >&2
    exit 2
  fi
done

# 12 hex chars is plenty: this is a change detector, not a security boundary.
want="$(cat "${inputs[@]}" | sha256sum | cut -c1-12)"

marker='op1st.b4mad.net/restart-hash:'
have="$(sed -n "s|.*${marker} *||p" "${values}" | tr -d '"' | head -1)"

if [[ -z "${have}" ]]; then
  echo "update-pod-restart-hash: no '${marker}' line in ${values#"${repo_root}"/}" >&2
  echo "  the annotation was removed — restore it under gitea.podAnnotations" >&2
  exit 2
fi

if [[ "${have}" == "${want}" ]]; then
  exit 0
fi

# Portable in-place edit (BSD/GNU sed disagree about -i).
tmp="$(mktemp)"
sed "s|\(${marker}\) *.*|\1 ${want}|" "${values}" >"${tmp}"
cat "${tmp}" >"${values}"
rm -f "${tmp}"

echo "update-pod-restart-hash: ${have} -> ${want} in ${values#"${repo_root}"/}"
echo "  a start-time ConfigMap changed; re-stage the values file so the pod rolls."
exit 1
