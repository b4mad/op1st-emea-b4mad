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
| Canonical URL | <https://git.b4mad.industries/> |
| Alt URL | <https://forgejo.b4mad.net/> (redirects to canonical) |
| Database | PostgreSQL — CNPG cluster `prod` via `pooler-prod` |
| Auth | Keycloak OIDC, SSO-only |
| git-SSH | `ssh://git@git.b4mad.industries:2222/…` (old host still works) |

## Files

| File | Purpose |
|---|---|
| `kustomization.yaml` | Everything Argo CD applies besides the chart (namespace, secrets, backups, borg build) |
| `values-nostromo.yaml` | Helm values overlay, consumed by the Application's chart source via `$values` |
| `admin-secret.enc.yaml` | SOPS-encrypted pinned `gitea_admin` break-glass credentials (`gitea.admin.existingSecret` — chart would otherwise render a fresh random password every sync) |
| `oauth-secret.enc.yaml` | SOPS-encrypted OIDC client id/secret → k8s Secret `forgejo-oauth-secret` (`data.key` = client-id, `data.secret` = client-secret) |
| `gpg-signing-secret.enc.yaml` | SOPS-encrypted GPG private key → k8s Secret `forgejo-gpg-signing-key` (`stringData.privateKey`) |
| `offsite-borg-secret.enc.yaml` | SOPS-encrypted borg credentials (ssh key, known_hosts, passphrase) |
| `forgejo-mailer.enc.yaml` | SOPS-encrypted `b4mad-forge@b4mad-service.net` mailbox credentials → k8s Secret `forgejo-mailer`, a single `mailer` key holding the app.ini `[mailer]` block (`gitea.additionalConfigSources` in `values-nostromo.yaml`) |
| `forgejo-mailer-creds.enc.yaml` | Same mailbox, as discrete `host`/`user`/`passwd` keys → k8s Secret `forgejo-mailer-creds`, used only by `mailer-check-cronjob.yaml`. **Deliberately a separate Secret from `forgejo-mailer`** — `additionalConfigSources` treats every key of the referenced Secret as its own app.ini section, so mixing discrete fields into that Secret crashes Forgejo's `init-app-ini` (hit this in production 2026-07-30) |
| `mailer-check-cronjob.yaml` | Synthetic SMTP send test standing in for the mail-delivery metric Forgejo doesn't expose — alerts in `monitoring.yaml` |
| `bot-tokens.enc.yaml` | SOPS-only bot tokens — source of truth for the four pre-2026-07-29 bots. Not applied to the cluster from here; `renovate-token` is copied into `../b4mad-renovate/environment-forgejo.enc.yaml`, so rotating it means updating both files |
| `forgejo-agent-<name>.enc.yaml` | SOPS-encrypted full agent credentials (token + SSH + GPG private keys) written by `create-forge-agent.py`; the only copy — the plaintext is shredded at generation |
| `forgejo-agent-<name>.yaml` | Its SealedSecret sibling, applied by Argo CD |

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
re-created with `create-forge-agent.py` from the
[`agentic-forges/forge-agents`](https://git.b4mad.industries/agentic-forges/forge-agents)
project, which keeps this repo pure GitOps.

| Account | Email | Token scopes | Credentials | Keys |
|---|---|---|---|---|
| `b4mad-renovate` | `renovate@b4mad.net` | `write:repository,write:issue,read:user,read:organization` | `bot-tokens.enc.yaml` → `renovate-token` | none |
| `b4mad-gitops` | `gitops@b4mad.net` | — | `bot-tokens.enc.yaml` → `gitops-token` | none |
| `b4mad-castra` | `castra@b4mad.net` | `write:repository,write:issue,read:user` | `bot-tokens.enc.yaml` → `castra-token` | none |
| `b4mad-release-agent` | `release-bot@b4mad.net` | `write:repository,write:package,write:issue,read:organization,read:user` | `forgejo-agent-b4mad-release-agent.enc.yaml` | ssh+gpg |
| `op1st-site-operator` | `site-operator@b4mad.net` | `write:repository,read:organization,read:user` | `forgejo-agent-op1st-site-operator.enc.yaml` | ssh+gpg |

⚠️ `b4mad-release-agent` was renamed from `b4mad-release-bot` on 2026-07-30 and
backfilled with keys on 2026-07-31, so it no longer belongs to the unsigned set
below. Its `bot-tokens.enc.yaml` → `release-bot-token` entry is **superseded**
by the `forgejo-agent-` Secret and no longer valid — that token was revoked when
the agent was backfilled. `read:organization` was added at the same time: it is
required for anything that walks org repos.

⚠️ The remaining three predate `create-forge-agent.py` and have **neither an SSH
nor a GPG key** (validated 2026-07-29). Their commits are therefore unsigned and
unverifiable — anything holding the token is indistinguishable from the agent
itself. Backfilling is tracked as `Systems-3ywf`; it is not a re-run, because
re-running adds credentials rather than rotating them.

Agents created from 2026-07-29 onward get one `forgejo-agent-<name>.enc.yaml`
holding token + SSH + GPG private keys, plus a `forgejo-agent-<name>.yaml`
SealedSecret sibling, and are listed with `Keys: ssh+gpg`.

### Org memberships (not captured by `forge-org-sync.sh`)

That script replays **Codeberg's** structure, where these bots do not exist —
so bot memberships have no declarative source and must be recorded here.

| Bot | Org | Team |
|---|---|---|
| `b4mad-release-agent` | `toolbxs` | `DevSecOps` (added 2026-07-28 as `b4mad-release-bot`) |
| `b4mad-release-agent` | `feeldata` | team not recorded — enumerated from the API 2026-07-31 |
| `b4mad-release-agent` | `agentic-forges` | team not recorded — enumerated from the API 2026-07-31 |

| `op1st-site-operator` | `operate-first` | team not recorded — membership confirmed via `/api/v1/user/orgs` as the agent, 2026-08-06 |

⚠️ `op1st-site-operator` holds **admin** on
`operate-first/op1st-emea-b4mad-nostromo-site-state` (verified 2026-08-06), but
only needs `push` — it commits triage state and nothing else. Admin also lets it
rewrite protections and delete the repo. Downgrade to write unless something
here actually requires more. It has `pull` only on the org's other two repos,
which is right.

⚠️ The last two were found by querying `/api/v1/user/orgs` as the agent, not from
any record — this table had only the `toolbxs` row. Treat it as a floor, not an
inventory, until someone reconciles it against the forge.

⚠️ Org membership and repo permission are **separate** gates. As of 2026-07-31
the agent is a member of `agentic-forges` but has no push on
`agentic-forges/forgejo-mcp`; it can push to every repo in `toolbxs` and
`feeldata`. A scope is the ceiling, membership gets you into the namespace, and
the per-repo permission is what finally decides.

⚠️ A token scoped `write:package` is **not** sufficient to push to an *org*
package namespace — the account must also be a member of that org. Without it
the registry rejects the push as a bare `authentication required`, with nothing
pointing at membership as the cause. This cost real time on 2026-07-28; if a
push starts failing that way, check membership before re-minting tokens.

⚠️ `read:organization` is not optional for Renovate: it resolves each repo's
owning org before processing it, so without that scope **every** repository
fails with `403 … token does not have at least one of required scope(s):
[read:organization]`. Added 2026-07-28 after the Forgejo fleet's first run.

⚠️ Re-running the script mints an **additional** token and uploads **additional**
keys — it does not rotate. Revoke the old ones first, or names collide and stale
credentials accumulate. The `/admin/users/{u}/tokens` endpoints take the
`gitea_admin` break-glass credentials, so no password rotation on the agent is
needed to clean up:

```bash
ADMIN=$(oc -n b4mad-forgejo get secret forgejo-admin \
          -o jsonpath='{.data.username}' | base64 -d)
PW=$(oc -n b4mad-forgejo get secret forgejo-admin \
          -o jsonpath='{.data.password}' | base64 -d)
curl -s -u "$ADMIN:$PW" https://git.b4mad.industries/api/v1/admin/users/<bot>/tokens
curl -s -u "$ADMIN:$PW" -X DELETE \
     https://git.b4mad.industries/api/v1/admin/users/<bot>/tokens/<id-or-name>
# SSH keys: DELETE /api/v1/admin/users/<bot>/keys/<id>
# GPG keys are user-scoped only — DELETE /api/v1/user/gpg_keys/<id> as the agent
```

```bash
# from an agentic-forges/forge-agents checkout (~/Source/forge-agents):
./create-forge-agent.py <username> <email> --scopes <comma,separated>

# re-assert the shared avatar on an existing agent, touching nothing else:
./create-forge-agent.py <username> <email> --avatar-only
```

**Every agent/bot wears the same avatar** (`forgejo/bot-avatar.png` in the ops
repo) so service accounts are distinguishable from humans at a glance. The
script re-applies it on every run, which is what keeps them uniform; `AVATAR_FILE`
overrides it, but doing so is deliberate divergence from the convention.

The token prints once on stdout; put it straight into
`bot-tokens.enc.yaml` with `sops`. That file is SOPS-only and has no
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
  ssh -p 2222 git@git.b4mad.industries
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

## Mailer

`[mailer]` is wired via `gitea.additionalConfigSources` (`values-nostromo.yaml`)
pointing at the `forgejo-mailer` Secret's `mailer` key — there is no
`mailer.existingSecret` in this chart (verified against
`values.yaml`/`values.schema.json` 2026-07-30), so `additionalConfigSources` is
the generic escape hatch instead.

⚠️ `SMTP_ADDR` is pinned to `www49.your-server.de`, not the vanity name
`mail.b4mad-service.net` — Hetzner's shared-hosting cert on that host doesn't
cover the vanity name. See `forgejo-mailer.enc.yaml` and `Systems-mcz8` in the
ops repo for the full story; the pin is load-bearing and breaks silently if
Hetzner migrates the account.

Forgejo/Gitea expose no mail-delivery metric (checked against a live pod's
`/metrics` 2026-07-30), and this cluster has no log-aggregation stack to catch
mailer error lines either. `mailer-check-cronjob.yaml` stands in for both: a
CronJob every 4h that authenticates and sends a real test email over the same
host/credentials Forgejo uses, so it fails exactly when Forgejo's own send
path would. `ForgejoMailerCheckFailing` / `ForgejoMailerCheckStale` in
`monitoring.yaml` alert on it via `kube_job_status_failed` /
`kube_cronjob_status_last_successful_time` (kube-state-metrics).

## OpenShift-specific fixes

- `global.compatibility.openshift.adaptSecurityContext: force` — strips the
  chart's hardcoded `runAsUser`/`fsGroup` so the restricted-v2 SCC assigns
  UIDs from the namespace range.
- `SSH_USER: git` + `BUILTIN_SSH_SERVER_USER: git` — under the random-UID SCC,
  `RUN_USER` defaults to the numeric UID, which made the built-in SSH server
  reject every `git@host` login. Pin the SSH login user to `git`.
  **Do not set `RUN_USER`** — Forgejo asserts it equals the real OS user at
  startup and refuses to boot otherwise.

## Hardening

- **`DISABLE_DOWNLOAD_SOURCE_ARCHIVES: true`** (`[repository]` in
  `values-nostromo.yaml`). Turns off on-the-fly source-archive downloads: the
  `…/archive/<ref>.tar.gz|.zip` route returns `404` and the download
  links/buttons disappear from the repo and release UIs.

  *Why:* the archive route is an unauthenticated asymmetric-amplification DoS
  vector. A byte-cheap `GET` makes the server spawn `git archive` + gzip and
  write a tarball to disk — expensive work, and per-unique-ref so the archive
  cache doesn't absorb a flood. On this instance the blast radius is sharp:
  a **single** Forgejo pod (`replicaCount: 1`, no HA) with a **hard 768Mi
  memory limit** (OOMKill boundary — our own values comment names
  archive/clone bursts as the spiky consumer) and **no CPU limit** (so it can
  starve node co-tenants), all writing into **one 32Gi PVC** shared with the
  bleve code index. One flood can OOMKill the pod (full forge outage) or fill
  the PVC, cascading to op1st-pipelines CI, Renovate, and the release agents
  that read from the forge.

  *What it does NOT break:* `git clone`/fetch, raw single-file download
  (`/raw/…`), and release **attachments** (`/releases/download/…`) are
  separate routes and keep working. ⚠️ It *does* break anything fetching
  tarballs by URL (Renovate `fetchzip`-style sources, Go module proxy for
  non-vanity paths, `curl …/archive/…` in builds) — none in this fleet rely on
  it today; re-check before assuming so.

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
