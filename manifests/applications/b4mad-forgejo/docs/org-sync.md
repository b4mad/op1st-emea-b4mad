# Codeberg → Forgejo org sync

`../forge-org-sync.sh` backs up the Codeberg org structure to JSONL and
replays it onto `forgejo.b4mad.net`. Both run Forgejo, so one `/api/v1`
(Gitea-compatible) dialect covers read and write.

## What it covers

Org profile (full_name, description, website, location, visibility, **avatar
image embedded as base64**) · teams (permission + units) · team memberships ·
org-level labels · **empty** repo shells. No git content — mirror repos
separately with Forgejo's built-in migration if needed.

On restore the org profile is **upserted**: created if missing, otherwise
patched, and the avatar is uploaded from the embedded base64 either way.
(Org profile READMEs — the `.profile` repo — are out of scope; that's git
content.)

## Tokens (env)

- `CODEBERG_TOKEN` — read scope on codeberg.org (source)
- `FORGEJO_TOKEN` — org-admin write scope on the **target** instance
- `FORGEJO_TARGET_URL` — target base URL (default `https://forgejo.b4mad.net`)

> ⚠️ **Do not `source .envrc` for restore.** In this repo `.envrc` aliases
> `FORGEJO_URL` and `FORGEJO_ACCESS_TOKEN` to **Codeberg**, so sourcing it
> would point a restore back at the source. The script deliberately ignores
> those names, aborts if target host == source host, and verifies
> `GET /user` on the target before writing anything. Export a real
> forgejo.b4mad.net token as `FORGEJO_TOKEN` explicitly.

## Backup

Write the JSONL to `b4mad-erdgeschoss-systems/forgejo/`, not into this repo
— that is the one place it is kept:

```bash
S=~/Systems/forgejo                                       # b4mad-erdgeschoss-systems
./forge-org-sync.sh backup "$S/codeberg-orgs.jsonl"       # all 11 owned orgs
./forge-org-sync.sh backup "$S/out.jsonl" b4mad toolbxs   # explicit subset
```

One typed JSON record per line: `org`, `label`, `repo`, `team`,
`team_member`. ⚠️ **The JSONL holds private-org member lists. It is
`.gitignore`d in both repos — never commit it.** This repo is public;
a copy was committed here on 2026-07-24 and removed on 2026-07-28.

## Restore (idempotent)

```bash
DRY_RUN=1 ./forge-org-sync.sh restore codeberg-orgs.jsonl  # preview, no writes
./forge-org-sync.sh restore codeberg-orgs.jsonl            # apply
```

Existing objects are left untouched. Order: orgs → teams (auto-created
`Owners` skipped) → labels → repo shells → memberships.

⚠️ Memberships reference Codeberg usernames. Any user that does not yet
exist on forgejo.b4mad.net is logged and skipped — create the accounts
there first, then re-run to backfill memberships.
