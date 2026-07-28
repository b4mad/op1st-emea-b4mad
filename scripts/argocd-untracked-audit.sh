#!/bin/env bash
#
# argocd-untracked-audit.sh — find in-cluster objects ArgoCD does NOT own.
#
# Why this exists
# ---------------
# Git is only a description of the cluster if every object in the managed
# namespaces got there through git. Objects created imperatively (oc create,
# helm CLI, a human in a hurry) are invisible to `git grep` yet fully
# load-bearing at runtime.
#
# The instructive failure (2026-07-28, b4mad-renovate): a second, untracked
# ResourceQuota named `compute-quota` sat next to the git-managed `renovate`
# quota for 442 days. Kubernetes enforces the INTERSECTION of all quotas in a
# namespace, so raising the git-managed one to 6Gi changed nothing — the
# untracked one still bound at 3Gi and every scheduled renovate run failed
# silently. Verifying the object you edited is not the same as verifying the
# constraint that binds.
#
# What it checks
# --------------
# Ownership is decided AUTHORITATIVELY, from the union of
# .status.resources across every Argo Application in every Argo namespace.
# That set is what the application-controller actually believes it manages,
# and it is correct regardless of tracking method.
#
# The two cheap annotation/label indicators are reported alongside, because
# they are what a human reaches for first — but neither is reliable here, and
# the script exists partly to stop people trusting them:
#
#   argocd.argoproj.io/tracking-id   Both Argo instances are configured with
#                                    application.resourceTrackingMethod:
#                                    annotation. But objects last synced
#                                    before that switch never got the
#                                    annotation — e.g. every object in
#                                    b4mad-radicle is genuinely Argo-owned
#                                    and Synced, yet carries no tracking-id.
#                                    Absence is therefore NOT proof of drift.
#
#   app.kubernetes.io/instance       Argo's legacy tracking label, but also a
#                                    plain kustomize commonLabel in this repo:
#                                    the b4mad-renovate quotas carry
#                                    instance=erdgeschoss, which is not an
#                                    Application name at all. Presence is
#                                    therefore NOT proof of ownership.
#
#   kubectl.kubernetes.io/last-applied-configuration
#                                    absent => never client-side-applied,
#                                    i.e. likely `oc create`d or helm-CLI
#                                    installed. Weak, reported for triage.
#
# Namespaces are derived from the repo, not hardcoded: every Application /
# ApplicationSet manifest under manifests/ contributes its
# spec.destination.namespace when the destination is this (in-cluster) server.
#
# Read-only. It never mutates the cluster. Deletions are a human decision.
#
# Usage
#   scripts/argocd-untracked-audit.sh                 # audit all derived namespaces
#   scripts/argocd-untracked-audit.sh b4mad-renovate  # audit specific namespaces
#   NAMESPACES_ONLY=1 scripts/argocd-untracked-audit.sh   # print the derived list and exit
#   VERBOSE=1 scripts/argocd-untracked-audit.sh       # also list tracked objects
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Kinds worth auditing. Deliberately excludes controller-generated noise
# (Pod, ReplicaSet, Endpoints, EndpointSlice, ControllerRevision, Event) —
# anything with an ownerReference is skipped below anyway.
KINDS="${KINDS:-resourcequota,limitrange,configmap,secret,serviceaccount,service,route,deployment,statefulset,daemonset,cronjob,job,persistentvolumeclaim,networkpolicy,role,rolebinding,horizontalpodautoscaler,poddisruptionbudget,servicemonitor,prometheusrule,imagestream,buildconfig}"

log() { printf '%s\n' "$*" >&2; }

# ---------------------------------------------------------------- namespaces
derive_namespaces() {
    python3 - "$REPO_ROOT" <<'PY'
import os, sys, yaml
root = sys.argv[1]
# Destinations that are NOT this cluster. Anything naming phobos is remote.
REMOTE_HINTS = ("phobos",)
ns = set()
for dirpath, _, files in os.walk(os.path.join(root, "manifests")):
    for fn in files:
        if not fn.endswith((".yaml", ".yml")) or ".enc." in fn:
            continue
        p = os.path.join(dirpath, fn)
        try:
            with open(p) as fh:
                docs = list(yaml.safe_load_all(fh))
        except Exception:
            continue
        for d in docs:
            if not isinstance(d, dict):
                continue
            kind = d.get("kind")
            specs = []
            if kind == "Application":
                specs = [d.get("spec", {})]
            elif kind == "ApplicationSet":
                specs = [d.get("spec", {}).get("template", {}).get("spec", {})]
            else:
                continue
            for spec in specs:
                dest = (spec or {}).get("destination", {}) or {}
                target = "%s %s" % (dest.get("server", ""), dest.get("name", ""))
                if any(h in target for h in REMOTE_HINTS):
                    continue
                n = dest.get("namespace")
                if n and "{{" not in n:
                    ns.add(n)
for n in sorted(ns):
    print(n)
PY
}

# --------------------------------------------------------------- preflight
command -v oc >/dev/null || { log "FATAL: oc not on PATH"; exit 2; }
if ! oc whoami >/dev/null 2>&1; then
    log "FATAL: not logged in to a cluster (oc whoami failed)."
    exit 2
fi

TRACKING="$(oc get cm argocd-cm -n op1st-gitops -o jsonpath='{.data.application\.resourceTrackingMethod}' 2>/dev/null)"
TRACKING="${TRACKING:-label}"   # ArgoCD's own default when unset

# Authoritative ownership set: every (namespace/Kind/name) any Application
# claims in .status.resources. Written to a temp file, consumed per namespace.
OWNED_FILE="$(mktemp)"
trap 'rm -f "$OWNED_FILE"' EXIT
ARGO_NS="${ARGO_NS:-op1st-gitops openshift-gitops}"
for ans in $ARGO_NS; do
    oc get applications.argoproj.io -n "$ans" -o json 2>/dev/null |
        jq -r '.items[] | .metadata.name as $app | (.status.resources // [])[]
               | select(.namespace != null)
               | "\(.namespace)/\(.kind)/\(.name)"'
done | sort -u >"$OWNED_FILE"
log "argocd Applications claim $(wc -l <"$OWNED_FILE") namespaced objects"

if [ "$#" -gt 0 ]; then
    NAMESPACES="$*"
else
    NAMESPACES="$(derive_namespaces)"
fi

if [ -n "${NAMESPACES_ONLY:-}" ]; then
    printf '%s\n' $NAMESPACES
    exit 0
fi

log "argocd resourceTrackingMethod: ${TRACKING}"
log "namespaces derived from repo:  $(printf '%s ' $NAMESPACES)"
log ""

printf '%-26s %-24s %-52s %-9s %-7s %-9s\n' NAMESPACE KIND NAME ARGO-OWNS TRACK-ID LAST-APPL
printf '%-26s %-24s %-52s %-9s %-7s %-9s\n' --------- ---- ---- --------- -------- ---------

FOUND=0
for ns in $NAMESPACES; do
    oc get namespace "$ns" >/dev/null 2>&1 || { log "skip: namespace ${ns} does not exist"; continue; }

    out="$(oc get "$KINDS" -n "$ns" -o json 2>/dev/null |
        VERBOSE="${VERBOSE:-}" OWNED_FILE="$OWNED_FILE" python3 -c '
import json, os, sys
verbose = bool(os.environ.get("VERBOSE"))
with open(os.environ["OWNED_FILE"]) as fh:
    OWNED = {line.strip() for line in fh if line.strip()}

# Objects the platform creates in every namespace; not drift.
SKIP_NAMES = {
    "configmap": {
        "kube-root-ca.crt", "openshift-service-ca.crt",
        # service-ca / tekton CA bundle injection
        "config-service-cabundle", "config-trusted-cabundle",
        # CloudNativePG operator drops this into every namespace it watches
        "cnpg-default-monitoring",
    },
    "serviceaccount": {"default", "builder", "deployer"},
    "rolebinding": {
        # auto-managed by the OpenShift namespace controllers
        "system:deployers", "system:image-builders", "system:image-pullers",
    },
}
SKIP_SECRET_TYPES = {
    "kubernetes.io/service-account-token",
    "kubernetes.io/dockercfg",
}

# Annotations/labels that prove another controller owns the object. These are
# not "untracked drift" — they are the observable output of something that IS
# (or should be) in git, e.g. a cert-manager Certificate or a Reflector source.
CONTROLLER_ANNOTATIONS = (
    "openshift.io/owning-component",      # OpenShift platform components
    "openshift.io/description",           # auto-managed namespace RBAC
    "cert-manager.io/certificate-name",   # issued by a cert-manager Certificate
    "cnpg.io/operatorVersion",            # CloudNativePG operator
    "reflector.v1.k8s.emberstack.com/reflects",  # a Reflector mirror copy
)
CONTROLLER_LABELS = {
    # RBAC the openshift-gitops / argocd operator maintains per managed namespace
    "app.kubernetes.io/managed-by": {"argocd", "openshift-gitops"},
    "config.openshift.io/inject-trusted-cabundle": None,
    "service.beta.openshift.io/inject-cabundle": None,
    "cnpg.io/reload": None,
}

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

for item in data.get("items", []):
    kind = item.get("kind", "?")
    lkind = kind.lower()
    md = item.get("metadata", {})
    name = md.get("name", "?")
    ns = md.get("namespace", "?")

    # Controller-generated: owned by something else, audit the owner instead.
    if md.get("ownerReferences"):
        continue
    if name in SKIP_NAMES.get(lkind, ()):
        continue
    if lkind == "secret":
        if item.get("type") in SKIP_SECRET_TYPES:
            continue
        # Helm release ledger — an artifact of a Helm-sourced Application.
        if item.get("type") == "helm.sh/release.v1":
            continue

    ann = md.get("annotations", {}) or {}
    lab = md.get("labels", {}) or {}

    if not verbose:
        if any(a in ann for a in CONTROLLER_ANNOTATIONS):
            continue
        skip = False
        for k, vals in CONTROLLER_LABELS.items():
            if k in lab and (vals is None or lab[k] in vals):
                skip = True
                break
        if skip:
            continue

    owned = "%s/%s/%s" % (ns, kind, name) in OWNED
    trackid = "argocd.argoproj.io/tracking-id" in ann
    lastapp = "kubectl.kubernetes.io/last-applied-configuration" in ann

    if owned and not verbose:
        continue
    print("%s\t%s\t%s\t%s\t%s\t%s" % (
        ns, kind, name,
        "yes" if owned else "NO",
        "yes" if trackid else "no",
        "yes" if lastapp else "no",
    ))
')"

    if [ -n "$out" ]; then
        while IFS=$'\t' read -r a b c d e f; do
            printf '%-26s %-24s %-52s %-9s %-7s %-9s\n' "$a" "$b" "$c" "$d" "$e" "$f"
            [ "$d" = "NO" ] && FOUND=$((FOUND + 1))
        done <<<"$out"
    fi
done

log ""
log "untracked objects: ${FOUND}"
log ""
log "For each: adopt into git, or delete. PREFER DELETING duplicates —"
log "two overlapping ResourceQuotas is what caused the 2026-07-28 outage,"
log "and adopting both preserves the trap. This script changes nothing."
