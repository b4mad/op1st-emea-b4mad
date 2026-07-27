# Forgejo backup & restore

For the nostromo test instance (namespace `b4mad-forgejo`).

## What is state, and where it lives

| State | Location | Backed up by |
|---|---|---|
| SQLite DB (`forgejo.db` + WAL) | PVC `gitea-shared-storage` `/data/forgejo.db` | dump / snapshot |
| Git repositories | `/data/git/gitea-repositories` | dump / snapshot |
| LFS, attachments, packages, avatars | `/data/gitea/…` | dump / snapshot |
| `app.ini` | `/data/gitea/conf/app.ini` (rendered by the chart) | dump; also reproducible from helm values |
| Helm values | `values-nostromo-test.yaml` | **git** |
| Secrets (oauth, GPG signing) | SOPS `*.enc.yaml` → k8s Secrets | **git** (SOPS) |
| Landing-page template | `forgejo-home-template.configmap.yaml` | **git** |
| Keycloak realm (SSO) | external Keycloak | **its own backup** — out of scope here |

> So a full recovery = **git** (values + SOPS secrets + ConfigMap) **plus** the
> PVC data (DB + repos). Everything declarative is already "backed up" by
> pushing the repo.

## Backup

### Scheduled logical dump (implemented)

`forgejo-backup-cronjob.yaml` defines a daily CronJob (**03:00 UTC**,
= 05:00 Europe/Berlin CEST; UTC is mandatory — a named `timeZone` crashes
cluster-wide kube-state-metrics, whose image lacks tzdata) that runs
`forgejo dump` into a dedicated PVC `forgejo-backup`,
keeping the **last 7** archives (`forgejo-<UTC-timestamp>.tar.zst`). The
off-site push (below) runs 04:40, after this dump completes.

```bash
oc -n b4mad-forgejo apply -f forgejo-backup-cronjob.yaml   # install
oc -n b4mad-forgejo create job --from=cronjob/forgejo-backup forgejo-backup-manual  # run now
oc -n b4mad-forgejo get pods -l job-name=forgejo-backup-manual     # watch
```

Each archive contains `app.ini`, the database (`forgejo-db.sql`), the
repositories, and the data dir (LFS/attachments/packages). The bleve code
index is skipped (`--skip-index`) — it is rebuildable.

> ⚠️ **Scope: same-node only.** Dumps land on `lvms-vg1`, the same disk as the
> data PVC. This protects against accidental deletion, a bad upgrade, or app
> corruption — **not** node/disk loss. For that, add off-site (below).
>
> ⚠️ **Live SQLite dump.** The dump copies the DB while Forgejo runs. SQLite
> recovers its WAL on open, but always run `forgejo doctor` after a restore.
> For a guaranteed-consistent dump, scale `deploy/forgejo` to 0 first.

### Ad-hoc manual dump

```bash
POD=$(oc -n b4mad-forgejo get pod -l app.kubernetes.io/name=forgejo -o jsonpath='{.items[0].metadata.name}')
oc -n b4mad-forgejo exec "$POD" -c forgejo -- \
  forgejo dump -c /data/gitea/conf/app.ini --type tar.zst --skip-index -f /tmp/forgejo-dump.tar.zst
oc -n b4mad-forgejo cp "$POD:/tmp/forgejo-dump.tar.zst" ./forgejo-dump.tar.zst -c forgejo
```

### Block snapshot alternative (fast local rollback)

`lvms-vg1` (topolvm) has a `VolumeSnapshotClass`, so a crash-consistent
snapshot of the data PVC is possible:

```bash
oc -n b4mad-forgejo scale deploy/forgejo --replicas=0   # quiesce for SQLite consistency
# create a VolumeSnapshot of PVC gitea-shared-storage (snapshotClassName: lvms-vg1)
oc -n b4mad-forgejo scale deploy/forgejo --replicas=1
```

Restore = provision a new PVC with `spec.dataSource` referencing the snapshot,
then point the deployment at it. Same cluster / same storage backend only.

## Restore (from a logical dump)

Forgejo has **no one-shot restore command** — it is a manual unpack. See the
authoritative procedure: <https://forgejo.org/docs/latest/admin/backup-and-restore/>.

1. **Rebuild the declarative layer** (fresh cluster / namespace):
   ```bash
   oc -n b4mad-forgejo apply -f forgejo-home-template.configmap.yaml
   sops -d forgejo-oauth-secret.enc.yaml        | oc -n b4mad-forgejo apply -f -
   sops -d forgejo-gpg-signing-secret.enc.yaml  | oc -n b4mad-forgejo apply -f -
   helm upgrade --install forgejo /var/home/goern/Source/forgejo-helm \
     -n b4mad-forgejo -f values-nostromo-test.yaml
   ```
2. **Quiesce**: `oc -n b4mad-forgejo scale deploy/forgejo --replicas=0`.
3. **Unpack the archive into the PVC** (via a maintenance pod mounting
   `gitea-shared-storage`, as in the queue-fix pattern):
   - repositories → `/data/git/gitea-repositories/`
   - `data/` → `/data/gitea/` (attachments, avatars, lfs, packages)
   - database: `sqlite3 /data/forgejo.db < forgejo-db.sql` (or drop in the
     dumped DB file). `app.ini` is already provided by the chart — no need to
     restore it.
4. **Fix ownership** to the pod's runtime UID/fsGroup (files must be group-
   readable/writable by the SCC-assigned range).
5. **Scale up** and heal:
   ```bash
   oc -n b4mad-forgejo scale deploy/forgejo --replicas=1
   POD=$(oc -n b4mad-forgejo get pod -l app.kubernetes.io/name=forgejo -o jsonpath='{.items[0].metadata.name}')
   oc -n b4mad-forgejo exec "$POD" -c forgejo -- forgejo doctor --run all --fix
   ```

## Off-site (implemented — Path A: in-cluster borg push to store-1)

A second daily CronJob, **`forgejo-offsite`** (`forgejo-offsite-cronjob.yaml`,
**04:40 UTC** = 06:40 Europe/Berlin CEST, ~100 min after the dump), pushes the newest local dump
into an **encrypted borg repo on the `store-1` NAS**, then prunes to
**keep-daily 7 / keep-weekly 4**. This is the off-node/off-disk copy the local
dump alone cannot provide.

```
forgejo-backup (03:00) ── forgejo dump ──▶ PVC forgejo-backup (7 tar.zst, lvms)
                                                     │  (mounted read-only)
forgejo-offsite (04:40) ── borg create/prune ──▶ ssh://borg@store-1/volume1/BorgBackup/forgejo.erdgeschoss
```

Moving parts (all in git):

| Piece | File | Notes |
|---|---|---|
| borg image | `forgejo-borg-image.yaml` (ImageStream) + `forgejo-borg-pipeline.yaml` (Tekton build) | Tekton pipeline `git-clone` → `buildah` builds `borg/Containerfile` → ImageStream `borg:latest`. Fedora base + `borgbackup` (borg 1.4.1). |
| off-site job | `forgejo-offsite-cronjob.yaml` | mounts `forgejo-backup` PVC read-only + the credential secret; `hostAliases` `store-1`→`10.144.8.24`. |
| credentials | `forgejo-offsite-borg-secret.enc.yaml` | SOPS/PGP → Secret `forgejo-offsite-borg`: `id_ed25519`, `known_hosts` (pinned store-1 host keys), `borg-passphrase`. |

Why a **custom** borg image: public borg images (e.g.
`ghcr.io/borgmatic-collective/borgmatic`) are Alpine-based and ship binaries
that are **not** world-executable, so under OpenShift's **restricted-v2** SCC
(arbitrary injected non-root UID) even `borg --version` fails with *Permission
denied*. The Fedora-built image runs as any UID. (UBI9+EPEL was a dead end:
`borgbackup` needs `libxxhash.so.0`, which lives only in the full RHEL CRB repo,
absent from UBI's CRB subset.)

restricted-v2 handling in the job: no `securityContext` (UID/fsGroup injected,
matching the app pod so the PVC is readable); `HOME`/`BORG_BASE_DIR` point at a
writable emptyDir; the ssh key is copied out of the read-only secret mount into
that emptyDir and `chmod 0600` so ssh's StrictModes is satisfied. Host identity
is pinned (`StrictHostKeyChecking=yes` + `known_hosts` from the secret;
`CheckHostIP=no` because the `hostAliases` IP is a NAT/route target, not the
address the host key was recorded against).

Install: the ImageStream, Pipeline + RBAC, credential SealedSecret and the
off-site CronJob are all applied by Argo CD (this directory's kustomization).
Manual steps are only the build trigger and an optional test run:

```bash
# --- build the borg image (Tekton, OpenShift Pipelines) ---
oc -n b4mad-forgejo create -f forgejo-borg-pipelinerun.yaml      # start a PipelineRun (generateName)
tkn -n b4mad-forgejo pipelinerun logs -f --last                  # watch the build
# --- off-site job: test now ---
oc -n b4mad-forgejo create job --from=cronjob/forgejo-offsite forgejo-offsite-manual
oc -n b4mad-forgejo logs -f -l job-name=forgejo-offsite-manual
```

> The borg image is built by a **Tekton pipeline** (`borg-build`:
> `git-clone` → `buildah` build+push of `borg/Containerfile`), which
> replaced the deprecated OpenShift `BuildConfig`. The pipeline clones this
> repo (github.com/b4mad/op1st-emea-b4mad — public, anonymous https; the old
> private-Codeberg deploy key is gone) and pushes to the same
> internal ImageStream tag, so `forgejo-offsite-cronjob.yaml` is unchanged.
> buildah runs under the operator's `pipelines-scc` (SETFCAP, `STORAGE_DRIVER=vfs`
> — no privileged) as the namespace `pipeline` ServiceAccount, which is granted
> `system:image-builder` for the registry push.

> ⚠️ **Synology / Path A caveats.** The `store-1` NAS sits on an isolated VLAN
> reached via a NAT/route from the cluster (`10.144.8.24`). Server-side
> `--append-only` was **dropped** from the forced command (a Synology SSH
> quirk), so the repo is **not** append-only — client-side `borg prune` frees
> disk, but a compromised job *could* delete archives. The passphrase +
> `known_hosts` pinning are the guardrails. Do not widen the retention prune
> beyond keep-daily 7 / keep-weekly 4 without intent.

### Restore from the borg repo (off-site)

Use this when the cluster/PVC is gone and you only have the store-1 repo. It
produces a `forgejo-<ts>.tar.zst` identical to a local dump, which then feeds
the logical-restore steps above.

```bash
# From any host that can reach store-1 (e.g. the workstation) with borg
# installed and the repo passphrase to hand:
export BORG_REPO=ssh://borg@store-1/volume1/BorgBackup/forgejo.erdgeschoss
export BORG_PASSPHRASE=…                     # from the SOPS secret
borg list                                    # pick the archive to restore
borg extract --list "::forgejo-<UTC-timestamp>"   # writes forgejo-<ts>.tar.zst to CWD
```

The extracted `forgejo-<ts>.tar.zst` is exactly the artifact the **"Restore
(from a logical dump)"** section consumes — unpack it into the data PVC per
steps 1–5 there (rebuild declarative layer → quiesce → unpack repos/`data/`/DB
→ fix ownership → scale up + `forgejo doctor --run all --fix`).

> In-cluster alternative: run a throwaway pod from the `borg` ImageStream with
> the `forgejo-offsite-borg` secret + `hostAliases` (as the CronJob does) and
> `borg extract` straight onto a mounted PVC — avoids pulling the archive
> through a laptop.

## ⚠️ Bigger picture

This instance is on **SQLite** — fine for a throwaway test, wrong for anything
you'd actually restore. If Forgejo graduates to real use, switch to the
Postgres subcharts and the backup story becomes `pg_dump` / CNPG PITR (the same
pattern as `docs/superpowers/plans/2026-07-07-zendrite-migration.md`), which is
far stronger than dumping a live SQLite file.
