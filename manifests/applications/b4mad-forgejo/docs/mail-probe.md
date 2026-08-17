# Forgejo mail probe

End-to-end check that **Forgejo itself** still originates notification mail,
in namespace `b4mad-forgejo`. Manifest: `../mail-probe-cronjob.yaml`; alerts:
`ForgejoMailProbeFailing` / `ForgejoMailProbeStale` in `../monitoring.yaml`.

## Why it exists

`forgejo-mailer-check` opens its own SMTP session to the relay. It proves the
relay accepts our credentials and nothing else — it never enters Forgejo.

On **2026-08-14** that gap produced a silent, total outage of user-facing mail:
the instance had always run with `[service] ENABLE_NOTIFY_MAIL` unset, which
defaults to `false`, so no mention, watch, or review-request mail had *ever*
been delivered to anyone. Both mailer alerts were green throughout. A user
reported it (`goern/skill#1`); nothing in the monitoring could have.

The two checks answer different questions and are both worth keeping:

| Probe | SMTP check | Reading |
|---|---|---|
| red | green | Forgejo stopped originating mail — config, queue, or template |
| red | red | relay or mailbox problem; start there, the probe is downstream |
| green | red | check the SMTP check itself — the product path works |

## How it works

Every 4h at `:37` (offset from the SMTP check at `:17`):

1. POST a comment on the probe issue as `gitea_admin`, mentioning
   `@mailer-probe` with a unique `mailprobe-<hex>` marker.
2. Poll the mailbox over IMAP (up to `WAIT_SECONDS`, default 300) for a message
   whose body carries that marker.
3. Delete the probe mail and the comment. A stale-marker sweep runs first, so a
   run killed mid-flight cannot leave litter behind.

Exit non-zero → `kube_job_status_failed` → `ForgejoMailProbeFailing`.

> ⚠️ The commenter and the mentioned user **must be different accounts**.
> Forgejo never mails an actor their own action, so a self-mention passes
> nothing through the mail path and the probe would test nothing.

## One-time Forgejo-side setup

The CronJob is GitOps-managed, but its counterparts live in Forgejo's database
and have to be created once. Recreate them after a restore-from-scratch.

```bash
# 1. Probe user. Its address is the instance's OWN mailbox — the same one
#    forgejo-mailer-creds authenticates to, which is what makes the delivered
#    mail readable over IMAP.
oc -n b4mad-forgejo exec deploy/forgejo -c forgejo -- \
  forgejo admin user create --username mailer-probe \
    --email b4mad-forge@b4mad-service.net \
    --password "$(openssl rand -base64 24)" --must-change-password=false

# Activate it and mark it restricted (it must never accrue visibility it
# doesn't need). SSO-only sign-in means the password is unusable anyway.
oc -n b4mad-forgejo exec prod-1 -- psql -U postgres -d forgejo -c \
  "update \"user\" set is_active=true, is_restricted=true where lower_name='mailer-probe';
   update email_address set is_activated=true where email='b4mad-forge@b4mad-service.net';"

# 2. Private probe repo + issue #1, owned by gitea_admin, with mailer-probe as
#    a READ collaborator. The mention only produces mail if the mentioned user
#    can actually see the repo.
PW=$(sops -d ../admin-secret.enc.yaml | yq '.stringData.password')
curl -u "gitea_admin:$PW" -X POST -H 'Content-Type: application/json' \
  -d '{"name":"mail-probe","private":true,"auto_init":true,"default_branch":"main",
       "description":"Synthetic end-to-end mail probe target. Do not use."}' \
  https://git.b4mad.industries/api/v1/user/repos

curl -u "gitea_admin:$PW" -X PUT -H 'Content-Type: application/json' \
  -d '{"permission":"read"}' \
  https://git.b4mad.industries/api/v1/repos/gitea_admin/mail-probe/collaborators/mailer-probe

curl -u "gitea_admin:$PW" -X POST -H 'Content-Type: application/json' \
  -d '{"title":"mail probe","body":"Target issue for the forgejo-mail-probe CronJob."}' \
  https://git.b4mad.industries/api/v1/repos/gitea_admin/mail-probe/issues

# 3. Scoped API token -> ../forgejo-mail-probe.enc.yaml (see its comment for
#    the rotation procedure), then re-seal:
#    ../../../../scripts/sops2sealedsecret --context <ctx> --namespace b4mad-forgejo \
#      ../forgejo-mail-probe.enc.yaml ../forgejo-mail-probe.yaml
```

## Running and testing it

```bash
# Run once now
oc -n b4mad-forgejo create job --from=cronjob/forgejo-mail-probe forgejo-mail-probe-manual
oc -n b4mad-forgejo logs job/forgejo-mail-probe-manual
```

**Fault injection** — a monitor that has never failed on purpose is just a
green light. Disable mail for the probe user only, which reproduces "Forgejo
does not originate the mail" without touching global config or restarting the
pod:

```bash
oc -n b4mad-forgejo exec prod-1 -- psql -U postgres -d forgejo -c \
  "update \"user\" set email_notifications_preference='disabled' where lower_name='mailer-probe';"
# run the job -> must FAIL with "no mail carrying mailprobe-… reached …"
oc -n b4mad-forgejo exec prod-1 -- psql -U postgres -d forgejo -c \
  "update \"user\" set email_notifications_preference='enabled' where lower_name='mailer-probe';"
# run the job again -> must pass
```

Verified this way on 2026-08-14: fails when mail is suppressed, passes when it
is not, and leaves no comment or mail behind in either case.
