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
  redirect_uris             = ["${var.partitur_public_url}/auth/callback"]
  post_logout_redirect_uris = ["${var.partitur_public_url}/auth/signed-out"]

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
    org-id-erdgeschoss       = zitadel_org.migrated["erdgeschoss"].id
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
