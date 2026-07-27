# Forgejo custom templates (landing page & friends)

How to change what Forgejo renders — starting with the **home / landing page**
(`home.tmpl`), which is what anonymous and signed-out visitors see at
<https://forgejo.b4mad.net/>.

## How it works

Forgejo loads custom templates from `$GITEA_CUSTOM/templates/`. In this
deployment `GITEA_CUSTOM=/data/gitea`, so the override path is
`/data/gitea/templates/home.tmpl`.

We keep the template **in git**, not hand-edited on the PVC:

| Piece | Where |
|---|---|
| Template source | `forgejo-home-template.configmap.yaml` (ConfigMap `forgejo-custom-templates`, key `home.tmpl`) |
| Mount wiring | `extraVolumes` + `extraVolumeMounts` in `values-nostromo-test.yaml` |
| Mount point | `/data/gitea/templates/home.tmpl` via `subPath: home.tmpl`, read-only |

> ⚠️ Forgejo **replaces `home.tmpl` wholesale** — it does not merge with the
> built-in one. Our version is derived from Forgejo v16.0.1's default
> `templates/home.tmpl`, keeps `{{template "base/head" .}}` /
> `{{template "base/footer" .}}` so the nav and styling still render, and drops
> the default "Powered by Forgejo" feature grid (`{{template "home_forgejo" .}}`).

## Update procedure

1. Edit the `home.tmpl` block in
   `forgejo-home-template.configmap.yaml`. Editable spots are marked
   `{{/* ---- EDIT ---- */}}`. The `{{if not .IsSigned}}` block is shown
   **only to logged-out visitors**.

2. Apply the ConfigMap and restart — a **`subPath` ConfigMap mount does NOT
   hot-reload**, so a pod restart is required to pick up the new content:

   ```bash
   oc -n b4mad-forgejo apply -f forgejo-home-template.configmap.yaml
   oc -n b4mad-forgejo rollout restart deploy/forgejo
   oc -n b4mad-forgejo rollout status deploy/forgejo
   ```

3. Verify the live page:

   ```bash
   curl -s https://forgejo.b4mad.net/ | grep -oE '<h2>[^<]*</h2>'
   ```

> A `helm upgrade` with the current values also re-applies the mount, but it
> does **not** re-apply the ConfigMap — the ConfigMap is managed out-of-band
> (like the SOPS secrets). Always `oc apply` the ConfigMap after editing it.

## Template variables & helpers

Available in `home.tmpl` (Forgejo/Gitea template context):

| Var / helper | Meaning |
|---|---|
| `.IsSigned` | true if the viewer is logged in — branch anonymous vs member content |
| `{{AppDisplayName}}` | instance name (`[DEFAULT] APP_NAME`) |
| `{{AppSubUrl}}` | base path (`""` here; use for building internal links) |
| `{{AssetUrlPrefix}}` | static asset base, e.g. `{{AssetUrlPrefix}}/img/logo.svg` |
| `{{ctx.Locale.Tr "key"}}` | i18n string lookup |

Styling uses Forgejo's bundled Tailwind (`tw-*`) and Fomantic UI (`ui ...`)
classes — reuse those rather than inlining CSS, so light/dark themes keep
working.

## Adding more custom templates

Same pattern for any other overridable template (custom footer, `500.tmpl`,
mail templates, etc.):

1. Add another key under `data:` in the ConfigMap (e.g. `500.tmpl`).
2. Add a matching `extraVolumeMounts` entry in the values file pointing at
   `/data/gitea/templates/<path>` with the right `subPath`.
3. Apply + restart as above.

For the list of overridable templates and available variables, see the
Forgejo docs: <https://forgejo.org/docs/latest/admin/customization/>.
