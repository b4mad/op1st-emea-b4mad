# b4mad-keycloak

Keycloak for the #B4mad Network, instance `b4mad-erdgeschoss`, served at
<https://keycloak.erdgeschoss.b4mad.net>.

## How realms are managed — two mechanisms, on purpose

| Realm              | Managed by                         | Reconciles? |
| ------------------ | ---------------------------------- | ----------- |
| `erdgeschoss`      | `realms/erdgeschoss.b4mad.net.yaml` (`KeycloakRealmImport`) | **No** |
| `b4mad-forgejo`    | `realm-config/` + keycloak-config-cli | Yes |
| `b4mad.industries` | Nothing — hand-made                | No |

⚠️ **`KeycloakRealmImport` is create-only.** The operator runs
`kc.sh import --override=false`, and the CRD exposes no strategy field, so a
CR applies exactly once — when the realm does not yet exist — and is a silent
no-op forever after. It cannot mutate a live realm and never deletes one.

This is not theoretical. `realms/erdgeschoss.b4mad.net.yaml` is 11 lines
declaring no users, groups or clients, while the live realm has **6 users, 3
groups and 15 clients**. Git describes almost none of it. Two hand-written
kcadm Jobs in this directory exist purely to work around that limitation.

Realm `b4mad-forgejo` was therefore migrated to
[keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli), which
PUTs desired state on every Argo CD sync. For that realm, `realm-config/` is
authoritative: edits reach the server, and console hand-edits are corrected.

Bringing `erdgeschoss` under the same tool is worthwhile but needs a full
export of its existing users and clients first — do not simply add it to
`IMPORT_FILES_LOCATIONS`.

### Deletion semantics

`import.managed.*` defaults to `full`, but `import.remote-state.enabled`
defaults to `true`, which limits purging to resources keycloak-config-cli
itself created (tracked in realm attributes). Both defaults are left alone.
That is safe only because the tool owns `b4mad-forgejo` outright.

## Prerequisite Secrets

⚠️ **The `keycloak-config-cli` Job fails until all three exist.** They are not
created by this kustomization because their values originate outside the
cluster. `IMPORT_VARSUBSTITUTION_UNDEFINEDISERROR` defaults to `true`, so a
missing key fails the sync loudly rather than importing an empty secret.

One Secret per OAuth app, so each rotates independently.

| Secret                       | Keys                        | Status |
| ---------------------------- | --------------------------- | ------ |
| `codeberg-oauth2-app`        | `client-id`, `client-secret` | ✅ in repo |
| `b4mad-forgejo-realm-secrets`| `FORGEJO_CLIENT_SECRET`, `ERDGESCHOSS_BROKER_SECRET` | ✅ in repo |

A `github-oauth2-app` Secret will join these when the GitHub identity
provider is restored — deferred, tracked as **op1st-emea-b4mad-4w5**.

⚠️ A `secretKeyRef` to a Secret that does not exist is not a soft failure:
the pod never starts (`CreateContainerConfigError`) and the PostSync hook
fails the whole sync. Add the env references and the provider config in the
same change as the Secret, never ahead of it.

`FORGEJO_CLIENT_SECRET` is the existing `forgejo` client secret from realm
`b4mad.industries` — reuse it so the sealed `b4mad-forgejo/forgejo-oauth-secret`
needs no reseal. Read it with:

```bash
oc -n b4mad-keycloak exec deploy/b4mad-erdgeschoss -- /opt/keycloak/bin/kcadm.sh \
  get clients -r b4mad.industries -q clientId=forgejo --fields id,secret
```

`ERDGESCHOSS_BROKER_SECRET` is generated (`openssl rand -hex 32`) and shared:
`setup-erdgeschoss-broker-job.yaml` sets it on the client in realm
`erdgeschoss`, and config-cli substitutes the same value into the identity
provider config here.

### ⚠️ `.enc.yaml` does not mean encrypted

The convention in this repo is a **pair** of files:

- `foo.enc.yaml` — a plain `Secret`, encrypted with SOPS. Human source of truth.
- `foo.yaml` — the `SealedSecret`, listed in `kustomization.yaml`. What Argo applies.

The `.enc.yaml` suffix is only a name. `kubectl create secret --dry-run -o yaml`
produces base64, which is **encoding, not encryption** — anyone can reverse it.
A genuine SOPS file has a top-level `sops:` block with PGP fingerprints; if that
block is absent, the file is plaintext. The `sops-encrypted` pre-commit hook
(`scripts/check-sops-encrypted.sh`) enforces this.

If a plaintext secret ever reaches a commit, **rotate it**. Rewriting history
does not un-publish a value that has already been distributed.

Full round trip for one app:

```bash
kubectl create secret generic codeberg-oauth2-app \
  --namespace b4mad-keycloak --dry-run=client -o yaml \
  --from-literal=client-id='…' \
  --from-literal=client-secret='…' \
  > codeberg-oauth2-app.enc.yaml

sops -e -i codeberg-oauth2-app.enc.yaml          # <-- the step that matters
sops -d codeberg-oauth2-app.enc.yaml | kubeseal --format yaml \
  > codeberg-oauth2-app.yaml
```

Add the resulting `*.yaml` (the SealedSecret) to `resources:` in
`kustomization.yaml`.

## Registering the OAuth apps

Callback URLs follow Keycloak's broker endpoint pattern
`…/realms/<realm>/broker/<idp-alias>/endpoint`.

**Codeberg** — Settings → Applications → Manage OAuth2 Applications:

- Redirect URI:
  `https://keycloak.erdgeschoss.b4mad.net/realms/b4mad-forgejo/broker/codeberg/endpoint`
- Confidential client: yes

Codeberg runs Forgejo and is a full OIDC provider; the endpoints in
`realm-config/b4mad-forgejo.yaml` came from
<https://codeberg.org/.well-known/openid-configuration>.

**GitHub** — not registered yet, see **op1st-emea-b4mad-4w5**. When it is:
<https://github.com/settings/developers> → New OAuth App, homepage
`https://forgejo.b4mad.net`, callback
`https://keycloak.erdgeschoss.b4mad.net/realms/b4mad-forgejo/broker/github/endpoint`.

## ⚠️ Realm `b4mad-forgejo` is open to the public

Codeberg is enabled as an identity provider with `linkOnly: false`. Any
Codeberg user can authenticate, receive a brokered account, and — because
`b4mad-forgejo/values-nostromo.yaml` sets `ENABLE_AUTO_REGISTRATION: true` —
get an account on forgejo.b4mad.net. Restoring the GitHub provider
(op1st-emea-b4mad-4w5) widens this to GitHub's user base as well.

This is the intended posture for a Tier-2 forge and was chosen deliberately.
To close it again, set `linkOnly: true` on the provider; existing users can
still link and use that login, but no new accounts are created.

Privilege is **not** delegated to the public providers. Site-admin comes only
from the `erdgeschoss` group `/admins`, via a mapper scoped to that provider
alias. There is deliberately no group mapper on `codeberg` — nor should one
be added for `github`.

⚠️ `erdgeschoss` has both `/admin` and `/admins`, each containing only
`goern`. The mapper keys on `/admins`; editing `/admin` does nothing. One of
them is a typo that wants cleaning up.

## ⚠️ No SMTP

No realm on this instance has an SMTP server configured, so Keycloak cannot
send mail. Every identity provider therefore sets `trustEmail: true` — with
it false, a `VERIFY_EMAIL` required action would fire that can never be
satisfied, dead-ending every first login.

The stock *first broker login* flow still challenges an incoming identity
whose email collides with an existing account, so this does not by itself
permit account takeover: the user must re-authenticate as the existing
account to link. Configuring SMTP would let that be done by mail instead.

## Cutting Forgejo over

`b4mad-forgejo/values-nostromo.yaml` still points `autoDiscoverUrl` at
`/realms/b4mad.industries/…`. Repoint it at `/realms/b4mad-forgejo/…` when
this realm is verified. That is a deliberate separate change.
