# b4mad-zitadel

Zitadel for the #B4mad Network, served at <https://id.b4mad.industries>.
Successor to `b4mad-keycloak`; tracked as bead **op1st-emea-b4mad-b1b**.

| Piece | Where |
| --- | --- |
| Zitadel + Login v2 | Helm chart `zitadel` from charts.zitadel.com, values in `values-nostromo.yaml` |
| Database | CNPG cluster `prod` (`postgresql.yaml`), backups to `s3://nostromo-cnpg/b4mad-zitadel/` |
| Argo CD | `op1st-gitops/applications/b4mad-zitadel.yaml` (multi-source: this dir + chart) |
| Public access | cloudflared tunnel — login + OIDC only (bead `-b1b.2`) |
| Admin Console / gRPC API | OpenShift Route on `id-admin.apps.nostromo…` (bead `-b1b.2`) |
| Orgs, projects, clients, branding | config-as-code, OpenTofu (bead `-b1b.3`) |

⚠️ `ExternalDomain` (`id.b4mad.industries`) is the OIDC issuer. Changing it
breaks every client.

## Argo CD and the chart's Helm hooks

The chart is written for `helm install`: it uses Helm hooks for ordering and
`lookup` to keep generated secrets stable. Neither survives Argo CD, which
renders with `helm template`:

- `lookup` returns nothing, so a chart-generated masterkey or login key would
  be **regenerated on every sync**. All three are our own SealedSecrets.
- Helm pre-install hooks become Argo PreSync, which runs before the CNPG
  cluster exists. `values-nostromo.yaml` replaces them with sync waves; read
  its "Argo CD ordering" section before bumping the chart version.

## Secrets

Same convention as the rest of the repo: `foo.enc.yaml` is a SOPS-encrypted
plain Secret (source of truth), `foo.yaml` is the SealedSecret Argo applies.
All three must exist before the first sync.

| Secret | Keys | Notes |
| --- | --- | --- |
| `aws-creds` | `ACCESS_KEY_ID`, `ACCESS_SECRET_KEY`, `url` | Same S3 credentials as `b4mad-keycloak/aws-creds` |
| `zitadel-masterkey` | `masterkey` | 32 chars. ⚠️ **Never changes.** Lose it and every encrypted value in the DB is gone; a DB backup is useless without it |
| `zitadel-login` | `tls.crt`, `tls.key`, `ZITADEL_SESSION_COOKIE_SECRET` | RSA keypair: Zitadel trusts `tls.crt` as system user `login-client`, Login v2 signs with `tls.key`. Cookie secret ≥ 32 chars, `new,old` to rotate |

Create them with `generate-secrets.sh` on a host that holds one of the PGP
keys in `.sops.yaml`. It never regenerates an existing `.enc.yaml` (the
masterkey must not change), only re-seals it, and never prints a value:

```zsh
# where you have an oc login: the controller's PUBLIC cert, newest key
oc -n sealed-secrets get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
  --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].data.tls\.crt}' \
  | base64 -d > sealed-secrets.pem

# where the PGP key is (sops, kubeseal, openssl)
manifests/applications/b4mad-zitadel/generate-secrets.sh --cert sealed-secrets.pem
```

The `sops-encrypted` pre-commit hook refuses an `.enc.yaml` without a `sops:`
block.

## The bootstrap machine user

`FirstInstance` creates org `b4mad` with only a machine user, `iam-admin`
(IAM owner). The setup Job writes its key to the Secret `iam-admin`, outside
git and outside Argo's tracking. There is deliberately no human admin in
`FirstInstance`: its first password would have to live in the ConfigMap.
Human administrators are created by config-as-code using `iam-admin`.

## First sync

Run and watched by hand on 2026-11-19, then automated sync was turned on.
Order observed: CNPG `prod` healthy → `zitadel-init` (6s) → `zitadel-setup`
(27s, created Secret `iam-admin`) → Deployments ready. The one failure on
the way was the chart's fixed UID/fsGroup 1000, which the restricted-v2 SCC
rejects; `podSecurityContext`/`securityContext` in values-nostromo.yaml null
them out.
