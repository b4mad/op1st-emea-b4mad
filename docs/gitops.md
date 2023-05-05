## adding a cluster to ArgoCD

1. copy the cluster template to a temporary file
2. edit the tmp file and add your credentials
3. encrypt them and add a sealed secret to this repo

```bash
cp manifests/applications/nostromo/openshift-gitops/clusters/cluster-template.yaml cluster-phohos.yaml
vi cluster-phohos.yaml # add your credentials: kube-admin bearer token and url....
kubeseal --namespace openshift-gitops \
  --controller-namespace=sealed-secrets \
  --output yaml \
  --secret-file phobos.yaml >manifests/applications/nostromo/openshift-gitops/clusters/phobos.yaml
git add manifests/applications/nostromo/openshift-gitops/clusters/phobos.yaml
git commit -asSm "add phobos cluster to ArgoCD"
```
