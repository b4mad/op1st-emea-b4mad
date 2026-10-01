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

The installer admin kubeconfig was committed in plaintext on 2024-10-03 (commit `2f309f3`) and is still in git history on `origin` and the Radicle remote. Its client certificate was issued by `admin.kubeconfig-signer@1726699878` and was valid until 2034, so the key must be treated as exposed. Removing the file from the tree does not revoke it, and Kubernetes cannot revoke a client certificate without removing its signer from the trusted CA bundle.

On 2026-10-01 that signer was removed from the bundle (see below). The leaked kubeconfig now fails with `Unauthorized`. Two older signers are still trusted: `admin-kubeconfig-signer` (until 2033-04-25) and `admin.kubeconfig-signer@1726648210` (until 2034-09-16). No certificate issued by them is known to exist. Tracked in bead `op1st-emea-b4mad-wy1`.

The credential documented here uses a different private key and a different signer (`node-system-admin-signer`), so the leaked key never applied to it. All node-local kubeconfigs (`lb-ext`, `lb-int`, `localhost`, `localhost-recovery` in `openshift-kube-apiserver/node-kubeconfigs`) are issued by `node-system-admin-signer` too.

### Revoking an admin signer

Trusted admin signers live in the ConfigMap `openshift-config/admin-kubeconfig-client-ca`. It is not owned by an operator (field managers: `cluster-bootstrap`, `oc`). The kube-apiserver operator merges it into `openshift-kube-apiserver/client-ca`, which the API server reloads live. Removing a signer needed no kube-apiserver rollout, and the operator did not restore it. This was done once, on nostromo running OpenShift 4.21.35.

1. Take the break-glass kubeconfig as described above and keep it until the end. Check `oc whoami` returns `system:admin`.
2. Save the ConfigMap: `oc get cm -n openshift-config admin-kubeconfig-client-ca -o yaml`, and strip `resourceVersion`, `uid`, `creationTimestamp` and `managedFields`. The certificates are public, but the file is the rollback.
3. Find the signer to drop by listing the subjects in `data."ca-bundle.crt"` with `openssl x509 -noout -subject`. Match it against the issuer of the certificate you want to revoke. Never drop `node-system-admin-signer`: it is not in this ConfigMap, the operator adds it to `client-ca`.
4. Rebuild the bundle without that certificate and apply it with `oc patch cm -n openshift-config admin-kubeconfig-client-ca --type merge -p ...`. Remove one signer at a time.
5. Verify: the old kubeconfig returns `Unauthorized`, the break-glass kubeconfig still returns `system:admin`, and `oc get co kube-apiserver authentication` stays Available and not Degraded.

Rollback is re-applying the saved ConfigMap. That trusts the removed signer again, so a leaked credential becomes valid again. If the API is down, use `localhost-recovery.kubeconfig` on a control-plane node. It is issued by `node-system-admin-signer` and does not depend on this ConfigMap.
