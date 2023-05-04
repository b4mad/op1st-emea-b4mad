# Nostromo

## Configuration

### cert-manager

As of now, we do not delegate DNS zones per cluster, so we cannot use the default `letsencrypt-via-http01` issuer.
Instead, we use the `letsencrypt-via-google-clouddns` issuer. This issuer uses the [Google Cloud DNS01 solver](https://cert-manager.io/docs/configuration/acme/dns01/google/), and has the authority to create TXT records in the `b4mad-emea-operate-first-cloud` zone. Nevertheless
the Google Cloud DNS service account created is specific to this cluster, and [CloudFlare DNS01 solver](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/) is used to create TXT records in the `b4mad.racing` zone.

### Replacing the default ingress certificate

seeAlso <https://docs.openshift.com/container-platform/4.12/security/certificates/replacing-default-ingress-certificate.html>

check with `oc get certificate --namespace openshift-ingress nostromo-default-ingress-certificate -o jsonpath='{.status.conditions}'`

The defaul ingress controller will be patched by the bootstrap process to use the `nostromo-default-ingress-certificate` certificate.

### Integrated OpenShift image registry

The [Integrated OpenShift image registry](https://docs.openshift.com/container-platform/4.12/registry/index.html#registry-integrated-openshift-registry_registry-overview) is configured with persistent storage.

To enable the integrated OpenShift image registry, you must have a persistent volume claim (PVC) available in the `openshift-image-registry` namespace. The PVC must be named `image-registry-storage`. The state of the image registry operator will be `Degraded` until the PVC is available.

Apply the configuration by `kustomize build --enable-alpha-plugins capabilities/persistent-image-registry/ | oc apply -f -`

Check by using `oc get clusteroperator image-registry` and look for `True` in the `Available` column.
