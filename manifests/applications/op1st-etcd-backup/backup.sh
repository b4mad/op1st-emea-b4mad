#!/bin/bash
# Take an etcd snapshot on the control-plane node and ship it off the box.
#
# Runs inside a privileged pod with the node's root filesystem bind-mounted at
# /host. The snapshot itself is taken by the host's own
# /usr/local/bin/cluster-backup.sh via chroot — that script is shipped and
# maintained by the cluster-etcd-operator, and re-implementing it here would be
# a way to get it subtly wrong. Everything this script adds is the safety rail
# around it: free-space checks, freshness checks and the off-node copy.
#
# Ordering is deliberate and is the whole design:
#
#   prune local  ->  check space  ->  snapshot  ->  validate  ->  upload
#
# Pruning happens BEFORE the snapshot so a full disk cannot block the backup,
# and the upload happens LAST so a failed upload always leaves the local copy
# behind. There is no "clean up after ourselves on failure" path, on purpose:
# on this cluster a stale local snapshot is worth vastly more than the disk it
# occupies.
#
# S3 retention is NOT handled here — it is an S3 lifecycle rule on the bucket.
# See the ops doc for why (short version: this job holds credentials that can
# delete backups, and the fewer destructive paths it contains, the better).

set -euo pipefail

# --- configuration (all overridable from the CronJob env) --------------------

# Where cluster-backup.sh writes, as the path looks *inside* the chroot.
BACKUP_DIR="${BACKUP_DIR:-/home/core/assets/backup}"
# The same directory as this container sees it. /host/home is a symlink to
# var/home on RHCOS and resolves correctly through the bind mount.
HOST_DIR="/host${BACKUP_DIR}"

# How many snapshot pairs to keep on the node, counting the one we are about to
# take. 3 = today plus two days of history, ~2.4 GiB at the current DB size.
KEEP_LOCAL="${KEEP_LOCAL:-3}"

# Refuse to start unless this much is free on the backup filesystem. The
# snapshot is a full copy of the etcd DB, so budget several times its size:
# bridge is a single-node control plane and filling its root disk is an outage,
# not an inconvenience.
MIN_FREE_KIB="${MIN_FREE_KIB:-16777216}"   # 16 GiB

# A snapshot smaller than this is treated as corrupt rather than uploaded. The
# real DB is ~750 MiB; anything under 32 MiB means something went wrong.
MIN_SNAPSHOT_BYTES="${MIN_SNAPSHOT_BYTES:-33554432}"

# A snapshot older than this was not produced by *this* run.
MAX_SNAPSHOT_AGE_S="${MAX_SNAPSHOT_AGE_S:-3600}"

log() { printf '%s  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
fatal() { log "FATAL: $*"; exit 1; }

# --- 0. sanity --------------------------------------------------------------

[ -d "$HOST_DIR" ] || fatal "$HOST_DIR does not exist — is the host root mounted at /host?"
[ -x /host/usr/local/bin/cluster-backup.sh ] \
  || fatal "cluster-backup.sh not found on the node; is this really a control-plane node?"

# --- 1. clear out crash debris and old snapshots ----------------------------
#
# cluster-backup.sh writes snapshot_<ts>.db.part and renames it on success, so
# a leftover .part is the fingerprint of a run that died mid-write. It is never
# useful and it occupies the same space a real snapshot would.

shopt -s nullglob
for part in "$HOST_DIR"/*.part "$HOST_DIR"/*.enc.tmp; do
  log "removing stale partial from an earlier run: ${part##*/}"
  rm -f "$part"
done

# Keep KEEP_LOCAL-1 pairs now; the snapshot we are about to take makes KEEP_LOCAL.
# Snapshots and their kuberesources tarball share a timestamp and are pruned as
# a unit — half a backup is not a backup.
keep_before=$(( KEEP_LOCAL - 1 ))
[ "$keep_before" -ge 0 ] || keep_before=0
mapfile -t existing < <(ls -1t "$HOST_DIR"/snapshot_*.db 2>/dev/null || true)
if [ "${#existing[@]}" -gt "$keep_before" ]; then
  for old in "${existing[@]:$keep_before}"; do
    ts="${old##*/snapshot_}"; ts="${ts%.db}"
    log "pruning local backup $ts"
    rm -f "$HOST_DIR/snapshot_${ts}.db" "$HOST_DIR/static_kuberesources_${ts}.tar.gz"
  done
fi
shopt -u nullglob

# --- 2. refuse to run on a nearly-full disk ---------------------------------

free_kib="$(df -Pk "$HOST_DIR" | awk 'NR==2 {print $4}')"
log "free space on the backup filesystem: $((free_kib / 1024)) MiB"
[ "$free_kib" -ge "$MIN_FREE_KIB" ] \
  || fatal "only $((free_kib / 1024)) MiB free, need $((MIN_FREE_KIB / 1024)) MiB. \
Not taking a snapshot — filling bridge's root disk would take the cluster down. \
Free space first (crictl rmi --prune is usually the biggest win)."

# --- 3. take the snapshot ---------------------------------------------------

log "running cluster-backup.sh on the node"
chroot /host /usr/local/bin/cluster-backup.sh "$BACKUP_DIR"

# --- 4. validate what we actually got ---------------------------------------
#
# cluster-backup.sh exiting 0 is necessary but not sufficient. The specific
# trap being guarded against: if it were ever to fail to write a new file while
# still exiting 0, the "newest snapshot" would be an OLD one, and we would
# cheerfully upload a stale snapshot every night and call the backup healthy.
# That is exactly the failure this whole bead exists to correct, so it gets an
# explicit check rather than a comment.

# shellcheck disable=SC2012  # names are snapshot_YYYY-MM-DD_HHMMSS.db, no spaces or newlines possible
snapshot="$(ls -1t "$HOST_DIR"/snapshot_*.db 2>/dev/null | head -1 || true)"
[ -n "$snapshot" ] || fatal "cluster-backup.sh exited 0 but produced no snapshot file"

stamp="${snapshot##*/snapshot_}"; stamp="${stamp%.db}"
kuberesources="$HOST_DIR/static_kuberesources_${stamp}.tar.gz"
[ -f "$kuberesources" ] \
  || fatal "snapshot $stamp has no matching static_kuberesources tarball; refusing to upload half a backup"

age=$(( $(date +%s) - $(stat -c %Y "$snapshot") ))
[ "$age" -le "$MAX_SNAPSHOT_AGE_S" ] \
  || fatal "newest snapshot is ${age}s old — cluster-backup.sh did not produce a fresh one this run"

size="$(stat -c %s "$snapshot")"
[ "$size" -ge "$MIN_SNAPSHOT_BYTES" ] \
  || fatal "snapshot is only ${size} bytes, below the ${MIN_SNAPSHOT_BYTES} sanity floor — treating as corrupt"

log "snapshot $stamp validated: $((size / 1024 / 1024)) MiB"

# --- 5. ship it off the node ------------------------------------------------
#
# A backup that only exists on the disk it protects is not a backup. If this
# fails the job fails and the local copy stays put; the next run's step 1 is
# what eventually reclaims it.
#
# upload.py encrypts before sending. The local copies on the node stay
# PLAINTEXT and that is deliberate: they are inside the cluster's own security
# boundary on a root-only path, and requiring a key to use the fast local
# recovery path would be a bad trade during an outage. Only what leaves the
# node is encrypted.
#
# It writes the ciphertext to <snapshot>.enc.tmp in this same directory before
# uploading, because a single-request PutObject needs a known Content-Length
# and Hetzner will not take this file as multipart. That is roughly one extra
# snapshot-sized file during the upload, which is why MIN_FREE_KIB above is set
# well above one snapshot's worth. It is removed in all cases, and step 1 sweeps
# up any left by a killed run.

log "encrypting and uploading $stamp to ${S3_BUCKET}/${S3_PREFIX} at ${S3_HOST}"
python3 /opt/etcd-backup/upload.py "$snapshot" "$kuberesources"

log "backup $stamp complete and verified off-node"
