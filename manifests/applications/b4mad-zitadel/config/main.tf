# Declarative Zitadel configuration for id.b4mad.industries, applied by the
# `zitadel-config` Job (../config-job.yaml) with OpenTofu on every Argo CD
# sync, so drift made in the Console is reverted. Environment values come in
# as TF_VAR_* from the ConfigMap `zitadel-config-vars` (../kustomization.yaml).
#
# Adapted from goern/socializer manifests/zitadel/config/main.tf, the config
# of the single-app Zitadel in b4mad-socializer this instance replaces
# (bead op1st-emea-b4mad-b1b).

terraform {
  required_version = ">= 1.8"

  required_providers {
    zitadel = {
      source  = "zitadel/zitadel"
      version = "3.8.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }

  # State lives in the Secret `tfstate-default-zitadel-config` of this
  # namespace. KUBE_IN_CLUSTER_CONFIG and KUBE_NAMESPACE come from the Job.
  backend "kubernetes" {
    secret_suffix = "zitadel-config"
  }
}

variable "zitadel_domain" {
  type        = string
  description = "ExternalDomain of the instance (OIDC issuer host)."
}

variable "instance_id" {
  type        = string
  description = "Id of the Zitadel instance. Generated at first setup; read once from projections.instances."
}

variable "admin_domain" {
  type        = string
  description = "Host of the admin Route (Console, APIs). Must be a trusted domain, or Zitadel rejects it as X-Zitadel-Public-Host."
}

variable "org_name" {
  type        = string
  description = "Org FirstInstance created (values-nostromo.yaml FirstInstance.Org.Name)."
}

variable "namespace" {
  type        = string
  description = "Namespace of the Zitadel Service and of the Secrets this config writes."
}

variable "partitur_public_url" {
  type        = string
  description = "PARTITUR_PUBLIC_URL of the socializer webui, no trailing slash."
}

variable "partitur_extra_urls" {
  type        = list(string)
  default     = []
  description = "Further origins the partitur webui is served on (no trailing slash); each gets /auth/callback and /auth/signed-out registered."
}

variable "admin_user" {
  type = object({
    user_name  = string
    email      = string
    first_name = string
    last_name  = string
    nick_name  = optional(string)
    gender     = optional(string, "GENDER_UNSPECIFIED")
  })
  description = "Human administrator: IAM owner of the instance (Console) and partitur staff. Initial password is generated once and written to Secret zitadel-admin-initial."
}

variable "smtp" {
  type = object({
    host           = string
    user           = string
    sender_address = string
    sender_name    = string
  })
  description = "SMTP mailbox Zitadel sends from (verification, password reset, OTP). Host must include the port."
}

variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "Password of the SMTP mailbox (Secret zitadel-smtp). Write-only on the provider resource: never stored in state."
}

variable "bootstrap_pat" {
  type        = string
  sensitive   = true
  description = "PAT of the FirstInstance machine user iam-admin (Secret iam-admin-pat)."
}

# Through the in-cluster Service: the provider speaks gRPC, which is not
# exposed through Cloudflare. The instance is selected by header, as the
# Login UI does; the service-CA serving cert names the Service, so TLS is
# verified (SSL_CERT_FILE in the Job). A PAT rather than the machine key: a
# JWT profile's audience would be derived from the Service host, not the
# issuer (socializer's finding).
provider "zitadel" {
  domain = "zitadel.${var.namespace}.svc"
  port   = "8080"
  # trimspace: the Secret value may end in a newline, which gRPC rejects in a header.
  access_token = trimspace(var.bootstrap_pat)
  transport_headers = {
    "x-zitadel-instance-host" = var.zitadel_domain
    "x-zitadel-public-host"   = var.zitadel_domain
  }
}

data "zitadel_orgs" "this" {
  name        = var.org_name
  name_method = "TEXT_QUERY_METHOD_EQUALS"
  state       = "ORG_STATE_ACTIVE"
}

locals {
  org_id = one(data.zitadel_orgs.this.ids)
}

# --- Instance ---------------------------------------------------------------

# The admin Route (admin-route.yaml) presents this host as
# X-Zitadel-Public-Host; without the trusted domain Zitadel answers
# "Instance not found".
resource "zitadel_instance_trusted_domain" "admin" {
  instance_id = var.instance_id
  domain      = var.admin_domain
}

# Dedicated mailbox on the Hetzner account (user decision 2026-11-19, bead
# b1b.9), not the forge's or partitur's. Host is the Hetzner server name, not
# a vanity name: the shared-hosting cert covers only that (see b4mad-forgejo
# README). Port 465 with tls = true is implicit TLS.
resource "zitadel_email_provider_smtp" "default" {
  sender_address = var.smtp.sender_address
  sender_name    = var.smtp.sender_name
  host           = var.smtp.host
  user           = var.smtp.user
  password       = trimspace(var.smtp_password)
  tls            = true
  description    = "id@b4mad-service.net (Hetzner)"
  set_active     = true
}

# --- Orgs: one per former Keycloak realm (bead b1b.10) ----------------------
#
#   Keycloak realm      -> Zitadel org
#   feeldata            -> feeldata
#   b4mad.industries    -> b4mad        (exists: FirstInstance org)
#   b4mad-forgejo       -> git
#   erdgeschoss         -> erdgeschoss
#
# Users are data, not config: they were imported once from Keycloak (see
# README "Migration from Keycloak"), not declared here.
resource "zitadel_org" "migrated" {
  for_each = toset(["feeldata", "git", "erdgeschoss"])
  name     = each.key

  lifecycle {
    prevent_destroy = true
  }
}

# --- Human administrator -----------------------------------------------------

# Initial password: random, generated once (kept in state, so re-runs do not
# rotate it), handed over through a Secret; Zitadel forces a change at first
# login. There is no SMTP, so no e-mail flow; the address is marked verified.
resource "random_password" "admin_initial" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%*-_+"
}

resource "zitadel_human_user" "admin" {
  org_id     = local.org_id
  user_name  = var.admin_user.user_name
  email      = var.admin_user.email
  first_name = var.admin_user.first_name
  last_name  = var.admin_user.last_name
  nick_name  = var.admin_user.nick_name
  gender     = var.admin_user.gender

  is_email_verified            = true
  initial_password             = random_password.admin_initial.result
  initial_skip_password_change = false
}

resource "zitadel_instance_member" "admin" {
  user_id = zitadel_human_user.admin.id
  roles   = ["IAM_OWNER"]
}

# --- partitur.social (pilot, bead op1st-emea-b4mad-b1b.4) -------------------

resource "zitadel_project" "partitur" {
  org_id = local.org_id
  name   = "partitur"
  # Put the project's roles into the tokens, and refuse sign-in for users
  # without any role of this project (the webui checks too).
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

# The webui gates staff features on this role (PARTITUR_OIDC_STAFF_ROLE).
resource "zitadel_project_role" "partitur_staff" {
  project_id   = zitadel_project.partitur.id
  org_id       = local.org_id
  role_key     = "staff"
  display_name = "Staff"
}

resource "zitadel_application_oidc" "partitur_webui" {
  project_id = zitadel_project.partitur.id
  org_id     = local.org_id
  name       = "socializer-webui"

  app_type = "OIDC_APP_TYPE_WEB"
  # PUBLIC client with PKCE, as on the socializer instance: no client secret
  # exists, so none lands in state. Switching to BASIC would make Zitadel
  # issue one.
  auth_method_type = "OIDC_AUTH_METHOD_TYPE_NONE"
  response_types   = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types      = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]

  # goern/socializer webui/src/lib/server/auth.ts
  # Pinned to the legacy host: this old client (org b4mad) is kept unchanged
  # until R2 on 2027-02-18 (bead b1b.12, socializer-kbyy); partitur_public_url
  # moved to partitur.social in R1 and must not drag this client along.
  redirect_uris             = ["https://socializer.b4mad.industries/auth/callback"]
  post_logout_redirect_uris = ["https://socializer.b4mad.industries/auth/signed-out"]

  # Roles in the ID token (urn:zitadel:iam:org:project:roles), read at
  # callback time. No refresh token is kept.
  id_token_role_assertion     = true
  access_token_role_assertion = false
  id_token_userinfo_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_user_grant" "admin_partitur_staff" {
  org_id     = local.org_id
  project_id = zitadel_project.partitur.id
  user_id    = zitadel_human_user.admin.id
  role_keys  = [zitadel_project_role.partitur_staff.role_key]
}

# --- Kubernetes hand-over ----------------------------------------------------

provider "kubernetes" {}

# Created once; later runs never rewrite it, so a password the user changed
# or a Secret deleted after hand-over stays as is.
resource "kubernetes_secret_v1" "admin_initial" {
  metadata {
    name      = "zitadel-admin-initial"
    namespace = var.namespace
  }
  data = {
    user_name = var.admin_user.user_name
    password  = random_password.admin_initial.result
  }

  lifecycle {
    ignore_changes = [data]
  }
}

# Client ids are public identifiers, not secrets: one place to read them.
resource "kubernetes_config_map_v1" "clients" {
  metadata {
    name      = "zitadel-clients"
    namespace = var.namespace
  }
  data = {
    issuer                   = "https://${var.zitadel_domain}"
    partitur-webui-client-id = zitadel_application_oidc.partitur_webui.client_id
    # New client in org erdgeschoss; the webui switches to it (bead b1b.4).
    partitur-webui-client-id-erdgeschoss = zitadel_application_oidc.partitur_eg_webui.client_id
    org-id-b4mad             = local.org_id
    org-id-feeldata          = zitadel_org.migrated["feeldata"].id
    org-id-git               = zitadel_org.migrated["git"].id
    forgejo-client-id        = zitadel_application_oidc.forgejo.client_id
    org-id-erdgeschoss       = zitadel_org.migrated["erdgeschoss"].id
    agentsview-client-id     = zitadel_application_oidc.agentsview_eg.client_id
  }
}

# --- UAT accounts for socializer's Playwright login test (bead b1b.8) ------
#
# Two human users with FINAL generated passwords (no forced change: the test
# cannot answer one), so the UAT in goern/socializer (`mise run uat`,
# UAT_USER/UAT_PASSWORD) can sign in unattended:
#   uat-staff   — has partitur/staff: the sign-in must succeed.
#   uat-nostaff — no partitur role: with project_role_check Zitadel itself
#                 refuses the sign-in to partitur.
# Usernames/addresses use the reserved .invalid TLD: no real mailbox, and
# there is no SMTP anyway. Credentials: Secret zitadel-uat-initial.
locals {
  uat_users = {
    staff   = { user_name = "uat-staff@partitur.invalid", first_name = "UAT", last_name = "Staff" }
    nostaff = { user_name = "uat-nostaff@partitur.invalid", first_name = "UAT", last_name = "No-Staff" }
  }
}

resource "random_password" "uat" {
  for_each         = local.uat_users
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%*-_+"
}

resource "zitadel_human_user" "uat" {
  for_each   = local.uat_users
  org_id     = local.org_id
  user_name  = each.value.user_name
  email      = each.value.user_name
  first_name = each.value.first_name
  last_name  = each.value.last_name

  is_email_verified            = true
  initial_password             = random_password.uat[each.key].result
  initial_skip_password_change = true
}

resource "zitadel_user_grant" "uat_staff" {
  org_id     = local.org_id
  project_id = zitadel_project.partitur.id
  user_id    = zitadel_human_user.uat["staff"].id
  role_keys  = [zitadel_project_role.partitur_staff.role_key]
}

resource "kubernetes_secret_v1" "uat" {
  metadata {
    name      = "zitadel-uat-initial"
    namespace = var.namespace
    # Mirrored by reflector into b4mad-socializer under the same name: the
    # socializer agents running the UAT may read only that namespace
    # (requested via uac:socializer, 2026-11-20). Rotations follow.
    annotations = {
      "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
      "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = "b4mad-socializer"
      "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
      "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces"    = "b4mad-socializer"
    }
  }
  data = {
    staff_user       = local.uat_users.staff.user_name
    staff_password   = random_password.uat["staff"].result
    nostaff_user     = local.uat_users.nostaff.user_name
    nostaff_password = random_password.uat["nostaff"].result
  }

  lifecycle {
    ignore_changes = [data]
  }
}

# --- Branding (bead b1b.11) --------------------------------------------------
#
# The look of https://b4mad.industries: phosphor-green CRT terminal on black.
#   #000000 background, #9bcd9b phosphor green (text, primary), #ffa500
#   orange (the site's hover/accent, used for warnings), Josefin Sans 300.
# Assets were taken from the site itself (2026-11-19): branding-logo.png is
# the "#B4MAD" logo cropped from /images/og-b4mad.png (600 px wide),
# branding-icon.png is /apple-touch-icon.png, branding-font.ttf is
# /fonts/josefin-sans-300-latin.woff2 converted to TTF (OFL). They sit flat
# next to this file because they are mounted from a ConfigMap, which cannot
# hold directories.
#
# The site is dark-only, so is the login: THEME_MODE_DARK; the light values
# repeat the dark ones in case a client forces light mode.
# Instance default: applies to every org without its own label policy.
locals {
  brand = {
    background = "#000000"
    font       = "#9bcd9b"
    primary    = "#9bcd9b"
    warn       = "#ffa500"
  }
}

resource "zitadel_default_label_policy" "b4mad" {
  primary_color         = local.brand.primary
  background_color      = local.brand.background
  font_color            = local.brand.font
  warn_color            = local.brand.warn
  primary_color_dark    = local.brand.primary
  background_color_dark = local.brand.background
  font_color_dark       = local.brand.font
  warn_color_dark       = local.brand.warn
  theme_mode            = "THEME_MODE_DARK"

  # Users of several orgs log in here; the org suffix only confuses.
  hide_login_name_suffix = true
  disable_watermark      = true

  logo_path      = "${path.module}/branding-logo.png"
  logo_hash      = filemd5("${path.module}/branding-logo.png")
  logo_dark_path = "${path.module}/branding-logo.png"
  logo_dark_hash = filemd5("${path.module}/branding-logo.png")
  icon_path      = "${path.module}/branding-icon.png"
  icon_hash      = filemd5("${path.module}/branding-icon.png")
  icon_dark_path = "${path.module}/branding-icon.png"
  icon_dark_hash = filemd5("${path.module}/branding-icon.png")
  font_path      = "${path.module}/branding-font.ttf"
  font_hash      = filemd5("${path.module}/branding-font.ttf")

  set_active = true
}

# --- Login policy (instance default) ----------------------------------------
#
# Mirrors the Zitadel defaults read from projections.login_policies5 on
# 2026-11-19, with ONE change: no self-registration. With allow_register the
# public login offered "Register new user" and anyone could create an
# account in org b4mad.
resource "zitadel_default_login_policy" "default" {
  user_login                    = true
  allow_register                = false
  allow_external_idp            = true
  force_mfa                     = false
  force_mfa_local_only          = false
  passwordless_type             = "PASSWORDLESS_TYPE_ALLOWED"
  hide_password_reset           = false
  ignore_unknown_usernames      = false
  allow_domain_discovery        = true
  disable_login_with_email      = false
  disable_login_with_phone      = false
  default_redirect_uri          = ""
  password_check_lifetime       = "240h0m0s"
  external_login_check_lifetime = "240h0m0s"
  mfa_init_skip_lifetime        = "720h0m0s"
  second_factor_check_lifetime  = "18h0m0s"
  multi_factor_check_lifetime   = "12h0m0s"
  second_factors                = ["SECOND_FACTOR_TYPE_OTP", "SECOND_FACTOR_TYPE_U2F"]
  multi_factors                 = ["MULTI_FACTOR_TYPE_U2F_WITH_VERIFICATION"]
}

# --- Projects owned by org erdgeschoss (user decision 2026-11-19) -----------
#
# partitur and openshift belong to org erdgeschoss. Users of other orgs (goern
# is in b4mad) get roles through a project grant to their org plus a user
# grant on that project grant. Zitadel cannot move projects between orgs, so
# partitur was recreated here; the old project in org b4mad stays until the
# webui is switched to the new client id (then removed, bead b1b.4 notes).

locals {
  erdgeschoss_org_id = zitadel_org.migrated["erdgeschoss"].id
}

# partitur.social ------------------------------------------------------------

resource "zitadel_project" "partitur_eg" {
  org_id                 = local.erdgeschoss_org_id
  name                   = "partitur"
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "partitur_eg_staff" {
  project_id   = zitadel_project.partitur_eg.id
  org_id       = local.erdgeschoss_org_id
  role_key     = "staff"
  display_name = "Staff"
}

resource "zitadel_application_oidc" "partitur_eg_webui" {
  project_id = zitadel_project.partitur_eg.id
  org_id     = local.erdgeschoss_org_id
  name       = "socializer-webui"

  # Public PKCE client, same shape as before (goern/socializer
  # webui/src/lib/server/auth.ts).
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_NONE"
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  redirect_uris               = [for u in concat([var.partitur_public_url], var.partitur_extra_urls) : "${u}/auth/callback"]
  post_logout_redirect_uris   = [for u in concat([var.partitur_public_url], var.partitur_extra_urls) : "${u}/auth/signed-out"]
  id_token_role_assertion     = true
  access_token_role_assertion = false
  id_token_userinfo_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_grant" "partitur_eg_to_b4mad" {
  org_id         = local.erdgeschoss_org_id
  project_id     = zitadel_project.partitur_eg.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.partitur_eg_staff.role_key]
}

resource "zitadel_user_grant" "admin_partitur_eg_staff" {
  org_id           = local.org_id
  project_id       = zitadel_project.partitur_eg.id
  project_grant_id = zitadel_project_grant.partitur_eg_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.partitur_eg_staff.role_key]
}

resource "zitadel_user_grant" "uat_partitur_eg_staff" {
  org_id           = local.org_id
  project_id       = zitadel_project.partitur_eg.id
  project_grant_id = zitadel_project_grant.partitur_eg_to_b4mad.id
  user_id          = zitadel_human_user.uat["staff"].id
  role_keys        = [zitadel_project_role.partitur_eg_staff.role_key]
}

# OpenShift nostromo (cluster login, not yet wired into the OAuth CR) --------
#
# The cluster would add an OpenID identity provider named `b4mad-id` pointing
# here; that switch is a separate change in
# environments/nostromo/identity-providers.yaml and needs the client secret
# copied to openshift-config. project_role_check: only users with
# cluster-user may log in to the cluster at all.

variable "openshift_oauth_host" {
  type        = string
  description = "Host of the cluster's oauth-openshift route."
}

resource "zitadel_project" "openshift_eg" {
  org_id                 = local.erdgeschoss_org_id
  name                   = "openshift"
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "openshift_eg_cluster_user" {
  project_id   = zitadel_project.openshift_eg.id
  org_id       = local.erdgeschoss_org_id
  role_key     = "cluster-user"
  display_name = "Cluster user (may log in to OpenShift)"
}

resource "zitadel_application_oidc" "openshift_eg_nostromo" {
  project_id = zitadel_project.openshift_eg.id
  org_id     = local.erdgeschoss_org_id
  name       = "nostromo"

  # Confidential client: the OpenShift OAuth server holds a client secret.
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  redirect_uris               = ["https://${var.openshift_oauth_host}/oauth2callback/b4mad-id"]
  id_token_userinfo_assertion = true
  id_token_role_assertion     = true
  access_token_role_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_grant" "openshift_eg_to_b4mad" {
  org_id         = local.erdgeschoss_org_id
  project_id     = zitadel_project.openshift_eg.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.openshift_eg_cluster_user.role_key]
}

resource "zitadel_user_grant" "admin_openshift_eg" {
  org_id           = local.org_id
  project_id       = zitadel_project.openshift_eg.id
  project_grant_id = zitadel_project_grant.openshift_eg_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.openshift_eg_cluster_user.role_key]
}

# Client id + secret for the cluster's OAuth CR. Zitadel returns the secret
# only at creation, so it lives in tofu state and here.
resource "kubernetes_secret_v1" "openshift_nostromo" {
  metadata {
    name      = "zitadel-openshift-nostromo"
    namespace = var.namespace
  }
  data = {
    clientID     = zitadel_application_oidc.openshift_eg_nostromo.client_id
    clientSecret = zitadel_application_oidc.openshift_eg_nostromo.client_secret
  }
}

# AgentsView (agentsview.b4mad.industries), bead b1b.6.1 ---------------------
#
# oauth2-proxy in b4mad-agentsview is the only gate in front of the whole
# session archive. ⚠️ project_role_check is what keeps this closed: without
# it ANY user of this instance gets a token, including everyone who
# self-registers in org git via GitHub/Codeberg. Only holders of `viewer`
# may sign in (user decision 2026-11-23: goern only; add others by grant).

variable "agentsview_url" {
  type    = string
  default = "https://agentsview.b4mad.industries"
}

resource "zitadel_project" "agentsview_eg" {
  org_id                 = local.erdgeschoss_org_id
  name                   = "agentsview"
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "agentsview_eg_viewer" {
  project_id   = zitadel_project.agentsview_eg.id
  org_id       = local.erdgeschoss_org_id
  role_key     = "viewer"
  display_name = "Viewer (may open the AgentsView dashboard)"
}

resource "zitadel_application_oidc" "agentsview_eg" {
  project_id = zitadel_project.agentsview_eg.id
  org_id     = local.erdgeschoss_org_id
  name       = "agentsview"

  # Confidential client: oauth2-proxy holds the secret.
  app_type                  = "OIDC_APP_TYPE_WEB"
  auth_method_type          = "OIDC_AUTH_METHOD_TYPE_BASIC"
  response_types            = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types               = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  redirect_uris             = ["${var.agentsview_url}/oauth2/callback"]
  post_logout_redirect_uris = ["${var.agentsview_url}/"]
  # oauth2-proxy reads email/email_verified from the ID token.
  id_token_userinfo_assertion = true
  id_token_role_assertion     = true
  access_token_role_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_grant" "agentsview_eg_to_b4mad" {
  org_id         = local.erdgeschoss_org_id
  project_id     = zitadel_project.agentsview_eg.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.agentsview_eg_viewer.role_key]
}

resource "zitadel_user_grant" "admin_agentsview_eg" {
  org_id           = local.org_id
  project_id       = zitadel_project.agentsview_eg.id
  project_grant_id = zitadel_project_grant.agentsview_eg_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.agentsview_eg_viewer.role_key]
}

# Keys named for oauth2-proxy's env vars; reflector mirrors the Secret into
# b4mad-agentsview. Zitadel returns the secret only at creation.
resource "kubernetes_secret_v1" "agentsview_oidc" {
  metadata {
    name      = "agentsview-oidc-zitadel"
    namespace = var.namespace
    annotations = {
      "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
      "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = "b4mad-agentsview"
      "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
      "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces"    = "b4mad-agentsview"
    }
  }
  data = {
    OAUTH2_PROXY_CLIENT_ID     = zitadel_application_oidc.agentsview_eg.client_id
    OAUTH2_PROXY_CLIENT_SECRET = zitadel_application_oidc.agentsview_eg.client_secret
  }
}

# Human user fritz in org erdgeschoss (user decision 2026-11-27) ------------
#
# Exception to "users are data": fritz is new, not imported from Keycloak, so
# he is declared here. Same hand-over as the admin: random initial password
# in Secret zitadel-fritz-initial, change forced at first login. user_name
# matches his DSM account on store-1.

resource "random_password" "fritz_initial" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!#$%*-_+"
}

resource "zitadel_human_user" "fritz" {
  org_id     = local.erdgeschoss_org_id
  user_name  = "fritz"
  email      = "fritz@goern.name"
  first_name = "Fritz"
  last_name  = "Görn"

  is_email_verified            = true
  initial_password             = random_password.fritz_initial.result
  initial_skip_password_change = false
}

resource "kubernetes_secret_v1" "fritz_initial" {
  metadata {
    name      = "zitadel-fritz-initial"
    namespace = var.namespace
  }
  data = {
    user_name = zitadel_human_user.fritz.user_name
    password  = random_password.fritz_initial.result
  }

  lifecycle {
    ignore_changes = [data]
  }
}

# store-1: Synology NAS, DSM 7.4.1-90080 Update 2, bead op1st-emea-b4mad-zkw --
#
# DSM "SSO Client" (OIDC). Access (user decision 2026-11-27): every user of
# org erdgeschoss plus goern from org b4mad. hasProjectCheck cannot express
# "one user of another org" (it admits whole orgs), so this uses
# project_role_check with a `user` role granted per user. ⚠️ The erdgeschoss
# users are data (imported from Keycloak), so they are read at plan time; a
# new erdgeschoss user gets access on the next Argo CD sync of this Job
# (fritz, created above, therefore gets his grant on the second run).
# DSM is a second gate: it maps a claim to an EXISTING DSM account and does
# not create users. See AGENTS.md.

# Every address DSM is opened by needs its own redirect URI: the browser
# uses store-1.local (mDNS); clients by IP (Synology Photos) use the LAN IP.
variable "store1_urls" {
  type    = list(string)
  default = ["https://store-1.local:5001", "https://10.144.8.24:5001"]
}

resource "zitadel_project" "store1_eg" {
  org_id                 = local.erdgeschoss_org_id
  name                   = "store-1"
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "store1_eg_user" {
  project_id   = zitadel_project.store1_eg.id
  org_id       = local.erdgeschoss_org_id
  role_key     = "user"
  display_name = "User (may sign in to DSM on store-1)"
}

resource "zitadel_application_oidc" "store1_eg_dsm" {
  project_id = zitadel_project.store1_eg.id
  org_id     = local.erdgeschoss_org_id
  name       = "store-1-dsm"

  # Confidential client: DSM holds the secret (pasted in by hand).
  app_type                  = "OIDC_APP_TYPE_WEB"
  auth_method_type          = "OIDC_AUTH_METHOD_TYPE_BASIC"
  response_types            = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types               = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  redirect_uris             = [for u in var.store1_urls : "${u}/"]
  post_logout_redirect_uris = [for u in var.store1_urls : "${u}/"]
  # DSM reads the username claim from the ID token.
  id_token_userinfo_assertion = true
  id_token_role_assertion     = true
  access_token_role_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

# Users of the owning org: direct user grants, no project grant needed.
data "zitadel_human_users" "erdgeschoss" {
  org_id = local.erdgeschoss_org_id
}

resource "zitadel_user_grant" "store1_eg_erdgeschoss" {
  for_each   = toset(data.zitadel_human_users.erdgeschoss.user_ids)
  org_id     = local.erdgeschoss_org_id
  project_id = zitadel_project.store1_eg.id
  user_id    = each.value
  role_keys  = [zitadel_project_role.store1_eg_user.role_key]
}

# goern (org b4mad): project grant to b4mad, then a grant for goern only.
resource "zitadel_project_grant" "store1_eg_to_b4mad" {
  org_id         = local.erdgeschoss_org_id
  project_id     = zitadel_project.store1_eg.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.store1_eg_user.role_key]
}

resource "zitadel_user_grant" "admin_store1_eg" {
  org_id           = local.org_id
  project_id       = zitadel_project.store1_eg.id
  project_grant_id = zitadel_project_grant.store1_eg_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.store1_eg_user.role_key]
}

# No in-cluster consumer, so no reflector: read it once and paste it into
# DSM (Control Panel > Domain/LDAP > SSO Client). Zitadel returns the
# secret only at creation.
resource "kubernetes_secret_v1" "store1_oidc" {
  metadata {
    name      = "store-1-oidc-zitadel"
    namespace = var.namespace
  }
  data = {
    client_id     = zitadel_application_oidc.store1_eg_dsm.client_id
    client_secret = zitadel_application_oidc.store1_eg_dsm.client_secret
    well_known    = "https://${var.zitadel_domain}/.well-known/openid-configuration"
    redirect_uris = join(" ", [for u in var.store1_urls : "${u}/"])
  }
}

# nostromo-traffic (Route on the nostromo apps domain), bead op1st-emea-b4mad-2pv.7
#
# oauth2-proxy sidecar in namespace nostromo-traffic is the only way in.
# Access (user decision 2026-11-27) is the same model as store-1: every user
# of org erdgeschoss plus goern from org b4mad, nobody else. ⚠️
# project_role_check is what keeps it closed (org git self-registrations and
# the uat users in b4mad get no token). The erdgeschoss users are read at plan
# time (data.zitadel_human_users.erdgeschoss, declared with store-1), so a new
# one gets access on the next run of this Job.

variable "traffic_url" {
  type    = string
  default = "https://nostromo-traffic-nostromo-traffic.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud"
}

resource "zitadel_project" "traffic_eg" {
  org_id                 = local.erdgeschoss_org_id
  name                   = "traffic-app"
  project_role_assertion = true
  project_role_check     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "traffic_eg_user" {
  project_id   = zitadel_project.traffic_eg.id
  org_id       = local.erdgeschoss_org_id
  role_key     = "user"
  display_name = "User (may open nostromo-traffic)"
}

resource "zitadel_application_oidc" "traffic_eg" {
  project_id = zitadel_project.traffic_eg.id
  org_id     = local.erdgeschoss_org_id
  name       = "traffic-app"

  # Confidential client: oauth2-proxy holds the secret.
  app_type                  = "OIDC_APP_TYPE_WEB"
  auth_method_type          = "OIDC_AUTH_METHOD_TYPE_BASIC"
  response_types            = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types               = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  redirect_uris             = ["${var.traffic_url}/oauth2/callback"]
  post_logout_redirect_uris = ["${var.traffic_url}/"]
  # oauth2-proxy reads email/email_verified from the ID token.
  id_token_userinfo_assertion = true
  id_token_role_assertion     = true
  access_token_role_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_user_grant" "traffic_eg_erdgeschoss" {
  for_each   = toset(data.zitadel_human_users.erdgeschoss.user_ids)
  org_id     = local.erdgeschoss_org_id
  project_id = zitadel_project.traffic_eg.id
  user_id    = each.value
  role_keys  = [zitadel_project_role.traffic_eg_user.role_key]
}

# goern (org b4mad): project grant to b4mad, then a grant for goern only.
resource "zitadel_project_grant" "traffic_eg_to_b4mad" {
  org_id         = local.erdgeschoss_org_id
  project_id     = zitadel_project.traffic_eg.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.traffic_eg_user.role_key]
}

resource "zitadel_user_grant" "admin_traffic_eg" {
  org_id           = local.org_id
  project_id       = zitadel_project.traffic_eg.id
  project_grant_id = zitadel_project_grant.traffic_eg_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.traffic_eg_user.role_key]
}

# Cookie signing only (Zitadel never sees it). Generated here so it is never
# in git; lives in tfstate and the Secret below. 32 alphanumerics = 32 bytes,
# a valid oauth2-proxy AES key length.
resource "random_password" "traffic_cookie" {
  length  = 32
  special = false
}

# Keys named for oauth2-proxy's env vars; reflector mirrors the Secret into
# nostromo-traffic. Zitadel returns the secret only at creation.
resource "kubernetes_secret_v1" "traffic_oidc" {
  metadata {
    name      = "traffic-oidc-zitadel"
    namespace = var.namespace
    annotations = {
      "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
      "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = "nostromo-traffic"
      "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
      "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces"    = "nostromo-traffic"
    }
  }
  data = {
    OAUTH2_PROXY_CLIENT_ID     = zitadel_application_oidc.traffic_eg.client_id
    OAUTH2_PROXY_CLIENT_SECRET = zitadel_application_oidc.traffic_eg.client_secret
    OAUTH2_PROXY_COOKIE_SECRET = random_password.traffic_cookie.result
  }
}

# --- Org git: the #B4mad forge (git.b4mad.industries), bead b1b.6 ----------
#
# User decisions 2026-11-20:
#  - Codeberg (generic OIDC) and GitHub are the IdPs of org git; anyone with
#    such an account may get a forge account (the public posture realm
#    b4mad-forgejo has today). New users are created in org git.
#  - Forgejo asks for scope urn:zitadel:iam:org:id:<git>, so its login runs
#    in org git's context (these IdPs, this branding) and ONLY users of org
#    git can log in to the forge. Admins (goern, durandom) therefore use their
#    Codeberg/GitHub identity, i.e. a git-org account, holding forge-admin.
#  - Privilege is not delegated to the IdPs: admin comes only from the
#    project role forge-admin, granted here.

variable "codeberg_client_id" {
  type      = string
  sensitive = true
}

variable "codeberg_client_secret" {
  type      = string
  sensitive = true
}

variable "github_client_id" {
  type      = string
  sensitive = true
}

variable "github_client_secret" {
  type      = string
  sensitive = true
}

variable "forgejo_url" {
  type        = string
  description = "ROOT_URL of Forgejo, no trailing slash."
}

locals {
  git_org_id = zitadel_org.migrated["git"].id
}

# Codeberg runs Forgejo, a full OIDC provider. OAuth app registered by goern
# on codeberg.org with redirect https://id.b4mad.industries/idps/callback.
resource "zitadel_org_idp_oidc" "codeberg" {
  org_id              = local.git_org_id
  name                = "Codeberg"
  issuer              = "https://codeberg.org"
  client_id           = trimspace(var.codeberg_client_id)
  client_secret       = trimspace(var.codeberg_client_secret)
  scopes              = ["openid", "profile", "email"]
  is_id_token_mapping = false
  use_pkce            = true
  is_creation_allowed = true
  is_auto_creation    = true
  is_auto_update      = true
  is_linking_allowed  = true
  # Existing users (the 45 Codeberg users of Keycloak realm b4mad-forgejo
  # are not imported; they are created on first login) are matched by e-mail.
  auto_linking = "AUTO_LINKING_OPTION_EMAIL"
}

resource "zitadel_org_idp_github" "github" {
  org_id              = local.git_org_id
  name                = "GitHub"
  client_id           = trimspace(var.github_client_id)
  client_secret       = trimspace(var.github_client_secret)
  scopes              = ["read:user", "user:email"]
  is_creation_allowed = true
  is_auto_creation    = true
  is_auto_update      = true
  is_linking_allowed  = true
  auto_linking        = "AUTO_LINKING_OPTION_EMAIL"
}

# Org git: external IdPs only — no local passwords, no registration form;
# accounts come into existence through Codeberg/GitHub. Other values mirror
# the instance default.
resource "zitadel_login_policy" "git" {
  org_id                        = local.git_org_id
  user_login                    = false
  allow_register                = true
  allow_external_idp            = true
  idps                          = [zitadel_org_idp_oidc.codeberg.id, zitadel_org_idp_github.github.id]
  force_mfa                     = false
  force_mfa_local_only          = false
  passwordless_type             = "PASSWORDLESS_TYPE_ALLOWED"
  hide_password_reset           = true
  ignore_unknown_usernames      = false
  allow_domain_discovery        = true
  disable_login_with_email      = false
  disable_login_with_phone      = false
  default_redirect_uri          = ""
  password_check_lifetime       = "240h0m0s"
  external_login_check_lifetime = "240h0m0s"
  mfa_init_skip_lifetime        = "720h0m0s"
  second_factor_check_lifetime  = "18h0m0s"
  multi_factor_check_lifetime   = "12h0m0s"
  second_factors                = ["SECOND_FACTOR_TYPE_OTP", "SECOND_FACTOR_TYPE_U2F"]
  multi_factors                 = ["MULTI_FACTOR_TYPE_U2F_WITH_VERIFICATION"]
}

resource "zitadel_project" "forge" {
  org_id = local.git_org_id
  name   = "forge"
  # Public forge: every git-org user may log in; no role required.
  project_role_assertion = true
  project_role_check     = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "zitadel_project_role" "forge_admin" {
  project_id   = zitadel_project.forge.id
  org_id       = local.git_org_id
  role_key     = "forge-admin"
  display_name = "Forgejo site admin"
}

resource "zitadel_application_oidc" "forgejo" {
  project_id = zitadel_project.forge.id
  org_id     = local.git_org_id
  name       = "forgejo"

  # Confidential client; Forgejo OAuth source `b4mad-id` (callback path
  # /user/oauth2/<source name>/callback).
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  # Two Forgejo sources share this client: b4mad-id (org git scope: public
  # Codeberg/GitHub users) and b4mad-staff (no org scope: existing users of
  # orgs b4mad/erdgeschoss, e.g. goern), user decision 2026-11-20.
  redirect_uris = [
    "${var.forgejo_url}/user/oauth2/b4mad-id/callback",
    "${var.forgejo_url}/user/oauth2/b4mad-staff/callback",
  ]
  post_logout_redirect_uris   = ["${var.forgejo_url}/"]
  id_token_userinfo_assertion = true
  id_token_role_assertion     = true
  access_token_role_assertion = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  version                     = "OIDC_VERSION_1_0"
  dev_mode                    = false

  lifecycle {
    prevent_destroy = true
  }
}

# Forgejo's admin mapping reads a `groups` claim (groupClaimName: groups,
# adminGroup: forgejo-admins in b4mad-forgejo/values-nostromo.yaml). Zitadel
# has roles, not groups: this action turns forge-admin on project forge into
# groups = ["forgejo-admins"], for the ID token and userinfo. The action name
# must equal the function name.
resource "zitadel_action" "forgejo_groups" {
  org_id          = local.git_org_id
  name            = "forgejoGroups"
  timeout         = "10s"
  allowed_to_fail = true
  script          = <<-EOT
    function forgejoGroups(ctx, api) {
      var grants = ctx.v1.user.grants;
      if (grants == undefined || grants.count == 0) { return; }
      var admin = false;
      grants.grants.forEach(function (g) {
        if (g.projectId == "${zitadel_project.forge.id}" && g.roles.indexOf("forge-admin") >= 0) { admin = true; }
      });
      if (admin) { api.v1.claims.setClaim("groups", ["forgejo-admins"]); }
    }
  EOT
}

resource "zitadel_trigger_actions" "forgejo_groups_userinfo" {
  org_id       = local.git_org_id
  flow_type    = "FLOW_TYPE_CUSTOMISE_TOKEN"
  trigger_type = "TRIGGER_TYPE_PRE_USERINFO_CREATION"
  action_ids   = [zitadel_action.forgejo_groups.id]
}

resource "zitadel_trigger_actions" "forgejo_groups_access_token" {
  org_id       = local.git_org_id
  flow_type    = "FLOW_TYPE_CUSTOMISE_TOKEN"
  trigger_type = "TRIGGER_TYPE_PRE_ACCESS_TOKEN_CREATION"
  action_ids   = [zitadel_action.forgejo_groups.id]
}

# Credentials of the forgejo client in the shape the Forgejo chart expects
# for an OAuth source (keys `key`, `secret`); reflector mirrors it into
# b4mad-forgejo, where values-nostromo.yaml references it.
resource "kubernetes_secret_v1" "forgejo_oauth" {
  metadata {
    name      = "forgejo-oauth-zitadel"
    namespace = var.namespace
    annotations = {
      "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
      "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = "b4mad-forgejo"
      "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
      "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces"    = "b4mad-forgejo"
    }
  }
  data = {
    key    = zitadel_application_oidc.forgejo.client_id
    secret = zitadel_application_oidc.forgejo.client_secret
  }
}

# Site admins of the forge: their git-org users (created on first Codeberg/
# GitHub login, so referenced by id, not declared). The forgejoGroups action
# turns this role into groups=["forgejo-admins"], which Forgejo's b4mad-id
# source maps to site-admin on every login.
variable "forge_admin_user_ids" {
  type        = list(string)
  default     = []
  description = "Zitadel user ids (org git) holding forge-admin."
}

resource "zitadel_user_grant" "forge_admin" {
  for_each   = toset(var.forge_admin_user_ids)
  org_id     = local.git_org_id
  project_id = zitadel_project.forge.id
  user_id    = each.value
  role_keys  = [zitadel_project_role.forge_admin.role_key]
}

# Staff of org b4mad on the forge: project grant forge -> b4mad, and goern's
# single identity (b4mad) holds forge-admin through it (user decision
# 2026-11-20: no separate git-org account for goern).
resource "zitadel_project_grant" "forge_to_b4mad" {
  org_id         = local.git_org_id
  project_id     = zitadel_project.forge.id
  granted_org_id = local.org_id
  role_keys      = [zitadel_project_role.forge_admin.role_key]
}

resource "zitadel_user_grant" "admin_forge_admin" {
  org_id           = local.org_id
  project_id       = zitadel_project.forge.id
  project_grant_id = zitadel_project_grant.forge_to_b4mad.id
  user_id          = zitadel_human_user.admin.id
  role_keys        = [zitadel_project_role.forge_admin.role_key]
}

# Token actions run in the flow of the USER's org, so b4mad users need the
# same groups mapping as git users.
resource "zitadel_action" "forgejo_groups_b4mad" {
  org_id          = local.org_id
  name            = "forgejoGroups"
  timeout         = "10s"
  allowed_to_fail = true
  script          = zitadel_action.forgejo_groups.script
}

resource "zitadel_trigger_actions" "forgejo_groups_b4mad_userinfo" {
  org_id       = local.org_id
  flow_type    = "FLOW_TYPE_CUSTOMISE_TOKEN"
  trigger_type = "TRIGGER_TYPE_PRE_USERINFO_CREATION"
  action_ids   = [zitadel_action.forgejo_groups_b4mad.id]
}

resource "zitadel_trigger_actions" "forgejo_groups_b4mad_access_token" {
  org_id       = local.org_id
  flow_type    = "FLOW_TYPE_CUSTOMISE_TOKEN"
  trigger_type = "TRIGGER_TYPE_PRE_ACCESS_TOKEN_CREATION"
  action_ids   = [zitadel_action.forgejo_groups_b4mad.id]
}
