# Forgejo — nostromo instance

A deployment of [Forgejo](https://forgejo.org/) via the
[forgejo-helm](https://code.forgejo.org/forgejo-helm/forgejo-helm) chart,
running on the **nostromo** OpenShift cluster in namespace
`b4mad-forgejo`. SSO via Keycloak, PostgreSQL storage.

> Storage is durable as of 2026-07-27: the DB is the CloudNativePG cluster
> `prod` (see `postgresql.yaml`), reached through the `pooler-prod` PgBouncer
> pooler, with WAL + base backups to `s3://nostromo-cnpg/b4mad-forgejo/` and a
> daily `ScheduledBackup` at 05:00. Accounts and repos here can be relied upon
> by automation.
>
> ⚠️ nostromo is a single node, so the cluster runs `instances: 1` — there is
> no HA standby. Durability comes from the S3 backups, not from replication.

## At a glance

| | |
|---|---|
| Cluster | nostromo (OpenShift) |
| Namespace | `b4mad-forgejo` |
| Chart | `forgejo-helm` |
| Canonical URL | <https://forgejo.b4mad.net/> |
| Alt URL | <https://forgejo.b4mad.industries/> (redirects to canonical) |
| Database | PostgreSQL — CNPG cluster `prod` via `pooler-prod` |
| Auth | Keycloak OIDC, SSO-only |
| git-SSH | `ssh://git@forgejo.b4mad.net:2222/…` |

## Files

| File | Purpose |
|---|---|
| `kustomization.yaml` | Everything Argo CD applies besides the chart (namespace, secrets, backups, borg build) |
| `values-nostromo.yaml` | Helm values overlay, consumed by the Application's chart source via `$values` |
| `forgejo-admin-secret.enc.yaml` | SOPS-encrypted pinned `gitea_admin` break-glass credentials (`gitea.admin.existingSecret` — chart would otherwise render a fresh random password every sync) |
| `forgejo-oauth-secret.enc.yaml` | SOPS-encrypted OIDC client id/secret → k8s Secret `forgejo-oauth-secret` (`data.key` = client-id, `data.secret` = client-secret) |
| `forgejo-gpg-signing-secret.enc.yaml` | SOPS-encrypted GPG private key → k8s Secret `forgejo-gpg-signing-key` (`stringData.privateKey`) |
| `forgejo-offsite-borg-secret.enc.yaml` | SOPS-encrypted borg credentials (ssh key, known_hosts, passphrase) |
| `forgejo-bot-tokens.enc.yaml` | SOPS-only bot tokens — source of truth. Not applied to the cluster from here; `renovate-token` is copied into `../b4mad-renovate/environment-forgejo.enc.yaml`, so rotating it means updating both files |

> Secret flow (repo convention): each `*.enc.yaml` (SOPS, recipients in the
> repo's `.sops.yaml`) is the **source of truth**; its sibling `*.yaml` is the
> **SealedSecret** Argo CD applies, generated with:
> ```bash
> scripts/sops2sealedsecret --context <nostromo-context> --namespace b4mad-forgejo \
>   <name>.enc.yaml <name>.yaml --force
> ```
> After rotating a value: edit the `.enc.yaml` with `sops`, regenerate the
> sealed sibling, commit both.

## Service accounts (bots)

Local (non-SSO) accounts driving the API and git over PAT. They live in
Forgejo's datastore, **not** in git — re-applying these manifests does not
recreate them. The 2026-07-27 move to CNPG wiped all of them and each was
re-created with `forgejo/create-forge-bot.sh` in the ops repo
(`b4mad-erdgeschoss-systems`), which keeps this repo pure GitOps.

| Account | Email | Token scopes | Token key in `forgejo-bot-tokens.enc.yaml` |
|---|---|---|---|
| `b4mad-renovate` | `renovate@b4mad.net` | `write:repository,write:issue,read:user,read:organization` | `renovate-token` |
| `b4mad-gitops` | `gitops@b4mad.net` | — | `gitops-token` |
| `b4mad-castra` | `castra@b4mad.net` | `write:repository,write:issue,read:user` | `castra-token` |
| `b4mad-release-bot` | `release-bot@b4mad.net` | `write:repository,write:package,write:issue,read:user` | `release-bot-token` |

### Org memberships (not captured by `forge-org-sync.sh`)

That script replays **Codeberg's** structure, where these bots do not exist —
so bot memberships have no declarative source and must be recorded here.

| Bot | Org | Team |
|---|---|---|
| `b4mad-release-bot` | `toolbxs` | `DevSecOps` (added 2026-07-28) |

⚠️ A token scoped `write:package` is **not** sufficient to push to an *org*
package namespace — the account must also be a member of that org. Without it
the registry rejects the push as a bare `authentication required`, with nothing
pointing at membership as the cause. This cost real time on 2026-07-28; if a
push starts failing that way, check membership before re-minting tokens.

⚠️ `read:organization` is not optional for Renovate: it resolves each repo's
owning org before processing it, so without that scope **every** repository
fails with `403 … token does not have at least one of required scope(s):
[read:organization]`. Added 2026-07-28 after the Forgejo fleet's first run.

⚠️ Re-running the script mints an **additional** token — it does not rotate.
Revoke the old one first, or names collide and stale credentials accumulate.
Token endpoints need basic auth (a PAT will not do), so:

```bash
POD=$(oc -n b4mad-forgejo get pod -l app.kubernetes.io/name=forgejo \
        -o jsonpath='{.items[0].metadata.name}')
TMPPW="tmp-$(openssl rand -hex 16)"
oc -n b4mad-forgejo exec pod/$POD -c forgejo -- forgejo admin user change-password \
  --username <bot> --password "$TMPPW" --must-change-password=false
curl -s -u "<bot>:$TMPPW" https://forgejo.b4mad.net/api/v1/users/<bot>/tokens   # list
curl -X DELETE -u "<bot>:$TMPPW" https://forgejo.b4mad.net/api/v1/users/<bot>/tokens/<id>
```

The script's avatar step then resets the password to its own random throwaway,
so no known credential is left behind once you re-mint.

```bash
# from a b4mad-erdgeschoss-systems checkout:
./forgejo/create-forge-bot.sh <username> <email> <scopes> [token-name]

# re-assert the shared avatar on an existing bot, minting no token:
AVATAR_ONLY=1 ./forgejo/create-forge-bot.sh <username> <email> -
```

**Every agent/bot wears the same avatar** (`forgejo/bot-avatar.png` in the ops
repo) so service accounts are distinguishable from humans at a glance. The
script re-applies it on every run, which is what keeps them uniform; `AVATAR_FILE`
overrides it, but doing so is deliberate divergence from the convention.

The token prints once on stdout; put it straight into
`forgejo-bot-tokens.enc.yaml` with `sops`. That file is SOPS-only and has no
SealedSecret sibling — it is local tooling credential, never applied to the
cluster.

## Networking

- **HTTP/HTTPS** — chart `Ingress` (`className: openshift-default`) on both
  hostnames; OpenShift's ingress-to-route controller turns each into a Route,
  cert-manager (`letsencrypt` ClusterIssuer) issues per-host TLS certs.
- **git-SSH** — no LoadBalancer on this single-node cluster, so the pod's
  built-in SSH server (`:2222`) is exposed via a fixed **NodePort 32222**.
  The erdgeschoss gateway forwards the external path:
  ```
  ssh -p 2222 git@forgejo.b4mad.net
    → gateway 88.153.142.188:2222
    → node 192.168.0.148:32222 (nodePort)
    → svc forgejo-ssh:22 → pod :2222
  ```

## Auth (SSO-only)

- OIDC login source `b4mad` against Keycloak realm **b4mad-forgejo**
  (`https://keycloak.erdgeschoss.b4mad.net/realms/b4mad-forgejo`). Cut over
  from realm `b4mad.industries` on 2026-07-29.
- That realm holds **no local identities**. It brokers to erd/G/eschoss (which
  grants site-admin, via `/admins` → `forgejo-admins`) and to Codeberg (which
  does not). See `b4mad-keycloak/README.md`.
- First SSO login **auto-provisions** an account
  (`ENABLE_AUTO_REGISTRATION`, username from `preferred_username`, linked by
  email).

### ⚠️ The realm cutover re-links accounts by email

Forgejo keys an OAuth account by login source + `login_name`, which stores the
`sub` claim. `sub` is **realm-scoped**, so changing realm invalidates the
stored value for every pre-existing SSO account — at the time of the cutover,
just `goern` (sub `81527376-…`).

Nothing breaks only because `ACCOUNT_LINKING = auto` re-links an incoming
identity to an existing account with the same email, rewriting `login_name`.
Setting `ACCOUNT_LINKING: disabled` would instead strand every existing SSO
account behind a login that can never match.

⚠️ The same mechanism is a takeover path now that a **public** provider
(Codeberg) is enabled with `trustEmail: true`: anyone who can present a
verified address matching an existing Forgejo user's email auto-links to that
account. Today every such address is `@b4mad.net`, a domain we control, which
is what keeps this bounded — it stops being bounded the moment a user with an
address on a third-party domain exists.
- Local username/password sign-in is **disabled** (`ENABLE_INTERNAL_SIGNIN:
  false`). Only the Keycloak button appears.
- ⚠️ This also disables web login for the built-in `gitea_admin` account —
  **break-glass is `oc exec … -- gitea admin …`**, not the web UI.

## Commit signing

Server-side signing is enabled (`signing.enabled`, `gpgHome:
/data/git/.gnupg`). Forgejo signs the commits **it** creates (initial commit,
CRUD actions, wiki, merges) — not users' pushed commits.

- Key: **ed25519** (EDDSA + cv25519), passphrase-less, non-expiring.
- UID: `Forgejo (#B4mad Forgejo commit signing) <forgejo@b4mad.net>` (see `AGENTS.md`)
- Fingerprint: `E8ACD36B3345ED1AC6450604720A29C30D58B935`
- Delivered via `existingSecret: forgejo-gpg-signing-key` (see Files above);
  `[repository.signing]` uses `SIGNING_KEY: default` (the single key in the
  pod's gpgHome).

## OpenShift-specific fixes

- `global.compatibility.openshift.adaptSecurityContext: force` — strips the
  chart's hardcoded `runAsUser`/`fsGroup` so the restricted-v2 SCC assigns
  UIDs from the namespace range.
- `SSH_USER: git` + `BUILTIN_SSH_SERVER_USER: git` — under the random-UID SCC,
  `RUN_USER` defaults to the numeric UID, which made the built-in SSH server
  reject every `git@host` login. Pin the SSH login user to `git`.
  **Do not set `RUN_USER`** — Forgejo asserts it equals the real OS user at
  startup and refuses to boot otherwise.

## Deploy

GitOps via Argo CD — the `b4mad-forgejo` Application
(`manifests/applications/op1st-gitops/applications/b4mad-forgejo.yaml`) has two
sources:

1. the `forgejo` chart (pinned version) from the `code.forgejo.org/forgejo-helm`
   OCI registry, rendered with `values-nostromo.yaml` (`$values` ref),
2. this directory's kustomization (namespace, SealedSecrets, backup CronJobs,
   borg ImageStream + Tekton pipeline).

Sync is `automated: {prune: true, selfHeal: true}` (the adoption of the
previously helm-CLI-installed release was reviewed and synced manually on
2026-07-24). There is no `helm upgrade` step anymore — change values/manifests
here, push, and Argo CD syncs.
