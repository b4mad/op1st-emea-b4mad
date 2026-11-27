# Agent notes: b4mad-zitadel

See README.md for how this instance is deployed. Zitadel config (orgs,
projects, apps, grants) is declared in `config/main.tf` and applied by the
`zitadel-config` Job on every Argo CD sync. Console changes are reverted.

## Pattern for a new OIDC app in org erdgeschoss

Copy the agentsview block in `config/main.tf`:

- `zitadel_project` with `org_id = local.erdgeschoss_org_id`,
  `project_role_assertion = true`, `project_role_check = true`.
  ⚠️ Without `project_role_check`, ANY user of the instance gets a token,
  including self-registered users of org git.
- `zitadel_project_role`, a `zitadel_application_oidc` (confidential WEB client,
  `OIDC_AUTH_METHOD_TYPE_BASIC`, auth code flow).
- `zitadel_project_grant` to org b4mad (`local.org_id`) plus a
  `zitadel_user_grant` for each user allowed in.
- A `kubernetes_secret_v1` holding client id/secret. Zitadel returns the
  secret only at creation. Add the Secret name to `resourceNames` in
  `config-job.yaml`, or the Job cannot write it.

## store-1 (Synology NAS), bead op1st-emea-b4mad-zkw

- Device: Synology DSM 7.4.1-90080 Update 2, client "SSO Client" (OIDC).
- Redirect URIs (exact match, trailing slash): `https://store-1.local:5001/`
  for the browser, `https://10.144.8.24:5001/` for clients that connect by
  LAN IP (added for the Synology Photos app). Each address DSM is opened by
  needs its own entry, in both `var.store1_urls` and DSM's redirect list.
- `.local` resolves only via mDNS on the LAN, which is fine for the browser
  redirect. ⚠️ store-1 is on the isolated NAS VLAN. DSM itself must reach
  `https://id.b4mad.industries` (discovery, token, JWKS) over the back-channel.
  Check that egress before blaming the config.
- DSM does not create users from OIDC. It maps one claim to an existing DSM
  user. Zitadel's `preferred_username` is the login name and may carry an
  `@domain` suffix, so choose the claim deliberately. Set
  `id_token_userinfo_assertion = true` so the claims are in the ID token.
- Access (user decision 2026-11-27): all users of org erdgeschoss plus goern
  from org b4mad, nobody else. `has_project_check` admits whole orgs, so it
  cannot express "only goern from b4mad". Instead, `project_role_check` plus
  role `user`: a project grant to b4mad with a user grant for goern, and one
  user grant per erdgeschoss user, read via data source
  `zitadel_human_users`. A new erdgeschoss user gets access on the next
  Argo CD sync of the config Job.
- DSM accounts on store-1: `goern`, `tina`, `fritz`, `elisabeth`. Map DSM's
  username claim to `preferred_username`; it must equal these names. If
  Zitadel adds an `@domain` suffix, fix that in Zitadel, not with DSM renames.
- `fritz` (org erdgeschoss) is declared in `config/main.tf`, an exception to
  "users are data". Initial password is in Secret `zitadel-fritz-initial`.
  He gets his store-1 grant on the second Job run, because the data source
  reads the user list at plan time.
- No in-cluster consumer: client id/secret, discovery URL and redirect URI
  are in Secret `store-1-oidc-zitadel` in this namespace and are pasted into
  DSM by hand. Do not add reflector annotations.

## nostromo-traffic (traffic-app), bead op1st-emea-b4mad-2pv.7

- Project and OIDC app `traffic-app` in org erdgeschoss, role `user`. Same
  access model as store-1 (erdgeschoss users plus goern, nobody else), reusing
  `data.zitadel_human_users.erdgeschoss`. A new erdgeschoss user gets access on
  the next Job run.
- Redirect URI is `var.traffic_url` + `/oauth2/callback`. It must equal the
  Route host of `manifests/applications/nostromo-traffic`.
- Secret `traffic-oidc-zitadel` (client id/secret plus a generated oauth2-proxy
  cookie secret) is reflected into namespace `nostromo-traffic`. nostromo-traffic
  is not in the Argo app-of-apps, so the pod cannot start until this Job has
  run once and reflector has copied the Secret.
