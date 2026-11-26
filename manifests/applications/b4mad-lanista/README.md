# b4mad-lanista

lanista-web at <https://lanista.b4mad.industries> (Route, edge TLS, HTTP→HTTPS redirect).
Brings the previously `oc apply`-ed app under Argo CD (bead op1st-emea-b4mad-rpl).
Stateless: emptyDir volumes only, **no node pinning** (op1st-emea-b4mad-770).

⚠️ These manifests were rebuilt from the bead, not exported (`oc` was logged out).
Port, probes, extra env and the image tag are unverified. Diff before syncing.

## The lanista secret (OPENROUTER_API_KEY)

Not in `kustomization.yaml`: the live Secret `lanista` already exists and Argo must
not overwrite it with a placeholder. To bring it under git (the user does this; no
agent ever sees the value):

```bash
cd manifests/applications/b4mad-lanista
cp lanista.example.yaml lanista.enc.yaml
$EDITOR lanista.enc.yaml                     # put the real key in, locally only
sops --encrypt --in-place lanista.enc.yaml   # .sops.yaml encrypts stringData
git add lanista.enc.yaml                     # confirm values read ENC[...] first
```

Same layout as `b4mad-umami/umami-secrets.enc.yaml`. Note this repo's Argo has no SOPS
plugin: umami/agentsview pair each `*.enc.yaml` with a SealedSecret `*.yaml` that is
what Argo applies. Either seal it too (`kubeseal --controller-namespace sealed-secrets`,
see docs/secret-operations.md, then add it to `resources`) or keep the live Secret
unmanaged.

## Safe adoption

The Application (`op1st-gitops/applications/b4mad-lanista.yaml`) has **no automated sync**.

1. Merge; Argo shows the app OutOfSync. Nothing is changed.
2. Review the diff against live. Fix port, tag, probes etc. in git until only intended
   drift remains (the removed `nodeSelector` is the expected one).
3. Manual sync, **without prune** (the live Secret is not in git and would be a prune candidate).
4. Once green, enable `automated` with `selfHeal: true`.
