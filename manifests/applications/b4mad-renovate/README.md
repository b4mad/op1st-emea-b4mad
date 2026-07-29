# Renovate — b4mad-renovate

Two Renovate fleets, one namespace. Renovate binds exactly **one**
`platform` + `endpoint` per process, so covering two forges means two
CronJobs — not two entries in one config.

| | Codeberg fleet | Forgejo fleet |
|---|---|---|
| CronJob | `renovate` | `renovate-forgejo` |
| Schedule | `@hourly` | `30 * * * *` |
| Endpoint | `https://codeberg.org/api/v1` | `https://forgejo.b4mad.net/api/v1` |
| Config | `config.yaml` | `config-forgejo.yaml` |
| Secret | `environment.enc.yaml` → `environment.yaml` | `environment-forgejo.enc.yaml` → `environment-forgejo.yaml` |
| Cache PVC | `renovate-cache` | `renovate-forgejo-cache` |
| Repo selection | explicit `repositories` array | `autodiscover` + `autodiscoverFilter` |
| git identity | SSH key volume | none — HTTPS + `RENOVATE_TOKEN` |

## ⚠️ Migration hazard: don't renovate the same repo twice

Repos are moving off codeberg.org onto forgejo.b4mad.net. The Forgejo job
autodiscovers `b4mad/*`, which overlaps the Codeberg job's explicit list
(`hash-B4mad-op1st`, `hugo.containerimage`, `semantic-release`). Today the
Forgejo copies are empty shells and Renovate skips them.

**When you migrate a repo, delete it from `config.yaml` in the same commit**
— otherwise both fleets open PRs against the two forges. Conversely, where
Forgejo is upstream and Codeberg is a push-mirror (the `toolbxs/*` case),
renovating the mirror fights the mirror-push; only the upstream may be
enrolled.

## ⚠️ Two ResourceQuotas, enforced as an intersection

`resource_quota.yaml` (`renovate`) and `compute_quota.yaml` (`compute-quota`)
both bind this namespace. Kubernetes applies **every** quota, so the tightest
value wins no matter which object it sits on — raising one alone accomplishes
nothing. Keep the numbers identical in both files.

This bit on 2026-07-28: `compute-quota` had lived untracked in-cluster for 442
days at `limits.memory: 3Gi`, enough for exactly one renovate pod. Doubling
only the git-managed `renovate` quota looked correct (`oc get resourcequota
renovate` confirmed 6Gi) while `renovate-forgejo` failed every scheduled run
with `FailedCreate: exceeded quota: compute-quota` whenever the Codeberg job
held the memory. Diagnose with `oc get resourcequota` — plural, no name.

## Tokens

The Forgejo fleet authenticates as the `b4mad-renovate` service account on
forgejo.b4mad.net. Its PAT is minted by `create-forge-agent.py` in
`agentic-forges/forge-agents` and stored as `renovate-token` in
`../b4mad-forgejo/bot-tokens.enc.yaml` — that file is the source of
truth. `environment-forgejo.enc.yaml` here holds a **copy**, so a rotation
means editing both, then regenerating the sealed sibling:

```bash
scripts/sops2sealedsecret --context <nostromo-context> --namespace b4mad-renovate \
  environment-forgejo.enc.yaml environment-forgejo.yaml --force
```

## The SSH key is inert — and that is deliberate

The `renovate` CronJob mounts `codeberg-org-b4mad-renovate-ssh` at
`/home/ubuntu/.ssh`. **Nothing reads it.** Renovate clones over HTTPS with
`RENOVATE_TOKEN`; `gitUrl` is unset, so the endpoint-derived HTTPS path is
used and a successful run logs zero SSH activity.

It could not work as mounted even if something tried: secret volumes land as
`root:<fsGroup>` mode `0644`, the pod runs as an assigned UID from the
namespace range (`1000740000/10000`), and OpenSSH hard-refuses a private key
that is group- or world-readable. Making it functional needs an initContainer
that copies the key to an `emptyDir` and `chmod 600`s it — deliberately not
done, because nothing needs SSH. The Forgejo fleet mounts no key at all.

The secret is kept, in git, so the namespace is reproducible and the bot
identity (`christoph+renovate@goern.name`, 4096-bit RSA) has one recorded
home. Its keys are the literal filenames ssh expects — `b4mad-renovate`,
`b4mad-renovate.pub`, `config`, `known_hosts` — so the volume renders a
usable `.ssh` directory the moment permissions are solved.

### Resolved 2026-07-28

The CronJob used to mount `ssh-key-secret`: hand-created in-cluster 569 days
earlier, never in this repo, no owner references or labels — and it carried
an operator's **personal** 3072-bit key (`goern@x1-erdgeschoss-b4mad-net`),
not the bot's. Its `config` pointed `IdentityFile` at `~/.ssh/id_rsa`, while
the git-managed secret held a different 4096-bit key under keys
(`ssh-privatekey`/`ssh-publickey`) that ssh would never look for. The two
halves were never connected. Both defects are gone; `ssh-key-secret` is
unreferenced and can be deleted from the cluster.

> `dot-ssh/` holds the working copies used to build the secret.
> `.gitignore` excludes the private key, so **`codeberg-org-b4mad-renovate-ssh.enc.yaml`
> is the only durable copy** — do not lose the SOPS recipients.
