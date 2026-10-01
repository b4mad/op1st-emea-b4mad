## Break-glass access to nostromo

A `system:admin` kubeconfig that does not depend on the OAuth server, an identity provider or the console route, so it still works when `*.apps` is down.

It lives in this repo as `secrets/nostromo/admin-kubeconfig-breakglass.enc.yaml`, encrypted with sops (PGP keys from `.sops.yaml`). Never commit it, or any kubeconfig, in plaintext. `.gitignore` and a gitleaks rule (`kubeconfig-file` in `.gitleaks.toml`) block anything named `*kubeconfig*` except `*.enc.yaml`.

### Use it

Decrypt to a private temporary file, drop the embedded CA, test, then shred:

```bash
umask 077
T=$(mktemp -d)
sops --decrypt --input-type yaml --output-type yaml \
  secrets/nostromo/admin-kubeconfig-breakglass.enc.yaml \
  | grep -v certificate-authority-data > "$T/kubeconfig"
KUBECONFIG="$T/kubeconfig" oc whoami        # system:admin
shred -u "$T/kubeconfig" && rmdir "$T"
```

Why the CA is removed: the file embeds the `kube-apiserver-lb-signer` CA, but the API server presents a Let's Encrypt certificate on `api.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud`. With the embedded CA, `oc` fails with `x509: certificate signed by unknown authority`. Without it, `oc` uses the system trust store.

If the Let's Encrypt certificate itself is broken, keep the embedded CA and talk to the API through a name or address the internal serving certificate covers.

### Expiry and refreshing it

The client certificate is issued by `node-system-admin-signer` and expires on **2028-09-18**. Check the date any time:

```bash
sops --decrypt --input-type yaml --output-type yaml \
  secrets/nostromo/admin-kubeconfig-breakglass.enc.yaml \
  | yq -r '.users[0].user."client-certificate-data"' | base64 -d \
  | openssl x509 -noout -enddate
```

To replace it, copy the node-local kubeconfig from a control-plane node and re-encrypt. `.sops.yaml` only encrypts `data`, `stringData` and `tls`, so the regex must be overridden to encrypt every value:

```bash
umask 077
T=$(mktemp -d)
oc debug node/<control-plane-node> -q -- chroot /host cat \
  /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig \
  > "$T/new.yaml"
sops --encrypt --input-type yaml --output-type yaml --encrypted-regex '.*' \
  --config .sops.yaml --filename-override secrets/nostromo/admin-kubeconfig-breakglass.enc.yaml \
  "$T/new.yaml" > secrets/nostromo/admin-kubeconfig-breakglass.enc.yaml
shred -u "$T/new.yaml" && rmdir "$T"
```

`oc debug` needs a working API. If the API is down, read the same file on the node itself (console or SSH, `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig`).

### History

The installer admin kubeconfig was committed in plaintext on 2024-10-03 (commit `2f309f3`) and is still in git history on `origin` and the Radicle remote. Its client key is valid until 2034, so treat it as exposed. Removing the file from the tree does not revoke it, and Kubernetes cannot revoke a client certificate without rotating its signer (`admin-kubeconfig-signer`). No supported rotation procedure has been confirmed yet; the Red Hat article found covers only the 2023 FIPS case. Tracked in bead `op1st-emea-b4mad-wy1`.

The credential documented here uses a different private key and a different signer (`node-system-admin-signer`), so the leaked key does not apply to it.
