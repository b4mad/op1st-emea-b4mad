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

## Tokens

The Forgejo fleet authenticates as the `b4mad-renovate` service account on
forgejo.b4mad.net. Its PAT is minted by `create-forge-bot.sh` in the ops repo
and stored as `renovate-token` in
`../b4mad-forgejo/forgejo-bot-tokens.enc.yaml` — that file is the source of
truth. `environment-forgejo.enc.yaml` here holds a **copy**, so a rotation
means editing both, then regenerating the sealed sibling:

```bash
scripts/sops2sealedsecret --context <nostromo-context> --namespace b4mad-renovate \
  environment-forgejo.enc.yaml environment-forgejo.yaml --force
```

## Known drift

The `renovate` CronJob mounts a Secret named `ssh-key-secret`, which exists
in-cluster but is **not** in this repo. The git-managed
`codeberg-org-b4mad-renovate-ssh` SealedSecret is mounted by nothing. Deleting
the namespace would lose the SSH identity. Unresolved; the Forgejo fleet
deliberately avoids SSH so it does not inherit the problem.
