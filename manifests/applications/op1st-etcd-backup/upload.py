#!/usr/bin/env python3
"""Encrypt etcd snapshot artefacts and send them to off-site object storage.

Three things here are load-bearing and none of them is obvious.

**Everything is encrypted before it leaves the node.** An etcd snapshot is not
"cluster metadata" — it is a plaintext copy of *every Secret in the cluster*:
Keycloak, Forgejo, CNPG, Matrix, all the ``b4mad-*`` workloads, TLS private
keys, service-account tokens, and the sealed-secrets controller's own master
key, which decrypts every SealedSecret in the GitOps repo. Uploading that
unencrypted to a third-party object store would make the bucket credential
equivalent to total compromise of this site. So it is encrypted client-side
with a key that has never been in that bucket. The ops doc says where the key
lives and how to recover it.

**boto3, not curl.** The node has no S3 client at all — no ``aws``, ``mc``,
``rclone``, ``s3cmd``, and no boto3 in the system Python — so the client has to
come from the container image. The one thing the node *does* have is curl
7.76.1, and it is a trap: its ``--aws-sigv4`` was the first release of that
feature and does not sign S3 requests reliably. It omits the mandatory
``x-amz-content-sha256``, and once that is supplied by hand it still fails on
multi-parameter query strings and on PUTs above a few kilobytes. Some requests
succeed, which is worse than none, because the smoke test passes.

**No multipart.** See ``_transfer_config``. This is the single most important
reliability decision in the file.

The ciphertext is written to a temp file next to the snapshot rather than
streamed, because a single ``PutObject`` needs a known Content-Length. The temp
file is always removed, including on failure.

**Retention is the bucket's job, and this script re-asserts it every run.**
Nothing here ever deletes a snapshot; objects age out under the bucket
lifecycle policy in ``lifecycle.json``, which is mounted from the same
ConfigMap as this file and pushed with ``PutBucketLifecycleConfiguration``
after a successful upload. See ``apply_lifecycle`` — the ordering, the
non-fatality and the prefix check are each there for a reason.
"""

from __future__ import annotations

import contextlib
import hashlib
import json
import os
import subprocess
import sys
import time

import boto3
import boto3.s3.transfer
import botocore.config

BUCKET = os.environ["S3_BUCKET"]
PREFIX = os.environ["S3_PREFIX"].strip("/")
HOST = os.environ["S3_HOST"]
#: Hetzner ignores the region but botocore insists on one.
REGION = os.environ.get("S3_REGION", "us-east-1")
#: Passphrase for openssl. Never logged, never sent to the bucket.
ENC_KEY_VAR = "ETCD_BACKUP_ENC_KEY"
#: Bucket retention policy, mounted from the same ConfigMap as this script.
#: Empty or missing means "do not touch the bucket's lifecycle configuration",
#: which is the correct behaviour for a run that has no opinion about it.
LIFECYCLE_FILE = os.environ.get("S3_LIFECYCLE_FILE", "/opt/etcd-backup/lifecycle.json")

CHUNK = 4 * 1024 * 1024
MB = 1024 * 1024
GB = 1024 * MB

#: S3 caps a single PutObject at 5 GiB. Stay clear of the edge.
SINGLE_PUT_LIMIT = 4 * GB

#: Deliberately conservative and deliberately ubiquitous. AES-256-CBC with a
#: salted PBKDF2-SHA512 derivation is what `openssl enc` offers, and `openssl
#: enc` is the one decryption tool guaranteed to exist wherever a restore might
#: have to happen — a RHCOS node with nothing installed, a rescue image, a
#: laptop. age and gpg would give authenticated encryption, but neither is on
#: RHCOS, and a backup you cannot decrypt during an outage is not a backup.
#: Integrity is covered instead by the plaintext SHA-256 recorded in object
#: metadata and re-checked after decryption.
OPENSSL_ARGS = [
    "openssl", "enc", "-aes-256-cbc",
    "-pbkdf2", "-iter", "600000", "-md", "sha512",
    "-salt", "-pass", f"env:{ENC_KEY_VAR}",
]

#: Retries exist for network blips, not for multipart flakiness — that is dealt
#: with by not using multipart. Each attempt re-encrypts from the plaintext on
#: disk, so retrying is always safe and always produces a complete object.
ATTEMPTS = 3
BACKOFF_S = (10, 30)


def _transfer_config(size: int) -> boto3.s3.transfer.TransferConfig:
    """Force a single PutObject for anything that fits in one.

    ⚠️ Do not "optimise" this back to multipart. Hetzner Object Storage rejects
    multipart uploads of this size with a bare ``AccessDenied: None``, and it
    does so as a function of part count: measured 2026-08-20 against the real
    788 MiB snapshot, 8 MiB parts failed, 64 MiB parts failed, 128 MiB parts
    (6 parts) succeeded, and a single PutObject succeeded twice at ~135 s.
    Small files always work, so any test with a sample file will tell you
    multipart is fine. It is not.

    Above the single-PUT ceiling there is no choice, so use the largest parts
    practical and no concurrency, which is the configuration that survived
    longest in testing.
    """
    if size <= SINGLE_PUT_LIMIT:
        return boto3.s3.transfer.TransferConfig(
            multipart_threshold=5 * GB, multipart_chunksize=5 * GB, use_threads=False
        )
    return boto3.s3.transfer.TransferConfig(
        multipart_threshold=512 * MB, multipart_chunksize=512 * MB,
        max_concurrency=1, use_threads=False,
    )


def sha256_of(path: str) -> str:
    """Hash in chunks — these files are ~750 MiB and must not be slurped."""
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(CHUNK), b""):
            digest.update(block)
    return digest.hexdigest()


def encrypt_to(path: str, dest: str) -> None:
    with open(path, "rb") as source, open(dest, "wb") as sink:
        subprocess.run(OPENSSL_ARGS, stdin=source, stdout=sink, check=True, env=os.environ)


def upload(client, path: str) -> None:
    name = os.path.basename(path)
    key = f"{PREFIX}/{name}.enc"
    plain_size = os.path.getsize(path)
    plain_sum = sha256_of(path)
    # Alongside the snapshot, so it is on the same filesystem the free-space
    # check in backup.sh already validated. backup.sh also sweeps up stray
    # *.enc.tmp from a killed run.
    tmp = f"{path}.enc.tmp"

    print(f"  {name}: {plain_size} bytes plaintext, sha256={plain_sum}", flush=True)

    try:
        encrypt_to(path, tmp)
        cipher_size = os.path.getsize(tmp)
        print(f"  {name}: {cipher_size} bytes encrypted", flush=True)

        for attempt in range(1, ATTEMPTS + 1):
            try:
                client.upload_file(
                    tmp, BUCKET, key,
                    # The recorded hash is of the *plaintext*, so it is what
                    # proves a restore produced the right bytes. It leaks
                    # nothing — a one-way digest of a 750 MiB file.
                    ExtraArgs={"Metadata": {
                        "plaintext-sha256": plain_sum,
                        "plaintext-bytes": str(plain_size),
                        "cipher": "aes-256-cbc/pbkdf2-sha512-600000",
                    }},
                    Config=_transfer_config(cipher_size),
                )
                remote = client.head_object(Bucket=BUCKET, Key=key)["ContentLength"]
                if remote != cipher_size:
                    raise RuntimeError(
                        f"{key} is {remote} bytes in the bucket but {cipher_size} on disk"
                    )
                print(f"  {name}: verified at s3://{BUCKET}/{key}", flush=True)
                return
            except Exception as exc:
                print(f"  {name}: attempt {attempt}/{ATTEMPTS} failed: "
                      f"{type(exc).__name__}: {exc}", flush=True)
                with contextlib.suppress(Exception):
                    client.delete_object(Bucket=BUCKET, Key=key)
                if attempt == ATTEMPTS:
                    raise SystemExit(
                        f"FATAL: {name} did not upload after {ATTEMPTS} attempts"
                    ) from exc
                time.sleep(BACKOFF_S[attempt - 1])
    finally:
        # Never leave ~790 MiB of ciphertext on the disk we are protecting.
        with contextlib.suppress(FileNotFoundError):
            os.remove(tmp)


def apply_lifecycle(client, path: str) -> None:
    """Re-assert the bucket retention policy from ``lifecycle.json``.

    Retention lives in the bucket, not in this script, because a pruner that
    runs inside the job needs ``DeleteObject`` on every run — and this job
    handles a plaintext copy of every Secret in the cluster. A lifecycle rule
    lets the normal path be strictly ``PutObject``.

    Four decisions worth keeping:

    **It runs after the uploads, not before.** A run that fails to upload must
    not install an expiry policy. The whole point of the sequencing is that the
    rule only ever lands on a bucket that is actively receiving backups; the
    failure mode it avoids is an expiry quietly deleting the last off-site copy
    of a cluster whose backup job stopped working a fortnight ago.

    **It is never fatal.** The backup is the critical path and retention is
    housekeeping. If the credential loses ``PutLifecycleConfiguration``, or
    Hetzner has a bad day, the snapshot is still off-site and that is what
    matters. It logs loudly instead. ⚠️ Note what that costs: bucket lifecycle
    state is not a Prometheus series, so nothing alerts on retention silently
    not being enforced. The job log is the only signal. If this starts failing,
    the bucket grows unbounded and the first symptom is a storage bill.

    **It only writes when the policy differs.** Otherwise the log line is noise
    on 364 days out of 365, and a real change is invisible among them.

    **It checks the prefix couples to S3_PREFIX.** This is the trap: the rule
    matches on a literal key prefix, so changing ``S3_PREFIX`` in the CronJob
    without changing ``lifecycle.json`` leaves a policy that matches nothing.
    Nothing breaks, nothing alerts, and the bucket simply grows forever. Warn
    on that explicitly rather than trusting whoever edits one to remember the
    other.
    """
    if not path or not os.path.exists(path):
        print(f"  lifecycle: no policy file at {path}, leaving the bucket's "
              "configuration untouched", flush=True)
        return

    try:
        with open(path) as handle:
            desired = json.load(handle)

        rules = desired.get("Rules", [])
        if not any(PREFIX.startswith(r.get("Filter", {}).get("Prefix", "").strip("/"))
                   for r in rules
                   if r.get("Filter", {}).get("Prefix", "").strip("/")):
            print(f"  lifecycle: ⚠️  no rule in {os.path.basename(path)} matches "
                  f"S3_PREFIX={PREFIX!r} — nothing under this prefix will ever "
                  "expire and the bucket will grow without bound", flush=True)

        try:
            current = client.get_bucket_lifecycle_configuration(Bucket=BUCKET)
            live = current.get("Rules", [])
        except Exception:
            # NoSuchLifecycleConfiguration on a bucket that has never had one.
            live = []

        if live == rules:
            print(f"  lifecycle: already matches {os.path.basename(path)} "
                  f"({len(rules)} rule(s))", flush=True)
            return

        client.put_bucket_lifecycle_configuration(
            Bucket=BUCKET, LifecycleConfiguration=desired
        )
        print(f"  lifecycle: applied {len(rules)} rule(s) from "
              f"{os.path.basename(path)} to {BUCKET}", flush=True)
        for rule in rules:
            days = rule.get("Expiration", {}).get("Days")
            where = rule.get("Filter", {}).get("Prefix", "")
            print(f"    {rule.get('ID')}: {rule.get('Status')}"
                  + (f", expire {where!r} after {days}d" if days else ""), flush=True)
    except Exception as exc:
        # Deliberately swallowed. See the docstring.
        print(f"  lifecycle: ⚠️  could not apply retention policy: "
              f"{type(exc).__name__}: {exc}", flush=True)
        print("  lifecycle: the backup itself is unaffected; retention is not "
              "being enforced until this succeeds", flush=True)


def main(paths: list[str]) -> None:
    if not paths:
        raise SystemExit("usage: upload.py <file> [<file>...]")
    if not os.environ.get(ENC_KEY_VAR):
        raise SystemExit(f"FATAL: {ENC_KEY_VAR} is empty — refusing to upload etcd in the clear")
    client = boto3.client(
        "s3",
        endpoint_url=f"https://{HOST}",
        region_name=REGION,
        config=botocore.config.Config(
            # Path-style addressing. Virtual-hosted style also works against
            # Hetzner today; path-style does not depend on a wildcard TLS
            # certificate per bucket name, so it is the safer default.
            s3={"addressing_style": "path"},
            # ⚠️ Do not remove. boto3 1.36 changed the default to
            # "when_supported", which adds a CRC32 header to every UploadPart;
            # Hetzner rejects those with `AccessDenied: None`.
            request_checksum_calculation="when_required",
            response_checksum_validation="when_required",
        ),
    )
    for path in paths:
        upload(client, path)
    # Last, and only once every artefact is safely in the bucket. See
    # apply_lifecycle: a run that failed to upload must not install an expiry.
    apply_lifecycle(client, LIFECYCLE_FILE)


if __name__ == "__main__":
    main(sys.argv[1:])
