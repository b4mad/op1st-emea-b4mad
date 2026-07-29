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

## Prerequisite: the `b4mad-forgejo-realm-secrets` Secret

⚠️ **The `keycloak-config-cli` Job will fail until this Secret exists.** It is
not created by this kustomization because four of its six values originate
outside the cluster. `IMPORT_VARSUBSTITUTION_UNDEFINEDISERROR` defaults to
`true`, so a missing key fails the sync loudly rather than silently importing
an empty secret.

| Key                         | Where it comes from |
| --------------------------- | ------------------- |
| `FORGEJO_CLIENT_SECRET`     | Existing `forgejo` client in realm `b4mad.industries` — reuse it so the sealed `b4mad-forgejo/forgejo-oauth-secret` needs no reseal |
| `ERDGESCHOSS_BROKER_SECRET` | Generate: `openssl rand -hex 32` |
| `GITHUB_CLIENT_ID`          | GitHub OAuth App (below) |
| `GITHUB_CLIENT_SECRET`      | GitHub OAuth App (below) |
| `CODEBERG_CLIENT_ID`        | Codeberg OAuth2 application (below) |
| `CODEBERG_CLIENT_SECRET`    | Codeberg OAuth2 application (below) |

Read the existing Forgejo client secret:

```bash
oc -n b4mad-keycloak exec deploy/b4mad-erdgeschoss -- /opt/keycloak/bin/kcadm.sh \
  get clients -r b4mad.industries -q clientId=forgejo --fields id,secret
```

Then seal it — never commit the plaintext:

```bash
kubectl create secret generic b4mad-forgejo-realm-secrets \
  --namespace b4mad-keycloak --dry-run=client -o yaml \
  --from-literal=FORGEJO_CLIENT_SECRET='…' \
  --from-literal=ERDGESCHOSS_BROKER_SECRET="$(openssl rand -hex 32)" \
  --from-literal=GITHUB_CLIENT_ID='…' \
  --from-literal=GITHUB_CLIENT_SECRET='…' \
  --from-literal=CODEBERG_CLIENT_ID='…' \
  --from-literal=CODEBERG_CLIENT_SECRET='…' \
| kubeseal --format yaml > b4mad-forgejo-realm-secrets.yaml
```

Add the result to `resources:` in `kustomization.yaml` once it exists.

## Registering the OAuth apps

Both callback URLs follow Keycloak's broker endpoint pattern
`…/realms/<realm>/broker/<idp-alias>/endpoint`.

**GitHub** — <https://github.com/settings/developers> → New OAuth App:

- Homepage URL: `https://forgejo.b4mad.net`
- Authorization callback URL:
  `https://keycloak.erdgeschoss.b4mad.net/realms/b4mad-forgejo/broker/github/endpoint`

**Codeberg** — Settings → Applications → Manage OAuth2 Applications:

- Redirect URI:
  `https://keycloak.erdgeschoss.b4mad.net/realms/b4mad-forgejo/broker/codeberg/endpoint`
- Confidential client: yes

Codeberg runs Forgejo and is a full OIDC provider; the endpoints in
`realm-config/b4mad-forgejo.yaml` came from
<https://codeberg.org/.well-known/openid-configuration>.

## ⚠️ Realm `b4mad-forgejo` is open to the public

GitHub and Codeberg are enabled as identity providers with `linkOnly: false`.
Any GitHub or Codeberg user can authenticate, receive a brokered account, and
— because `b4mad-forgejo/values-nostromo.yaml` sets
`ENABLE_AUTO_REGISTRATION: true` — get an account on forgejo.b4mad.net.

This is the intended posture for a Tier-2 forge and was chosen deliberately.
To close it again, set `linkOnly: true` on both providers; existing users can
still link and use those logins, but no new accounts are created.

Privilege is **not** delegated to the public providers. Site-admin comes only
from the `erdgeschoss` group `/admins`, via a mapper scoped to that provider
alias. There is deliberately no group mapper on `github` or `codeberg`.

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
