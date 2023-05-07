## adding a cluster to ArgoCD

```bash
go install github.com/hairyhenderson/gomplate/v4/cmd/gomplate@latest
export OP1ST_B4MAD_AUTHENTICATION_TOKEN=$(oc get secret --namespace kube-system argocd-manager -o jsonpath='{.data.token}')
export OP1ST_B4MAD_CLUSTER_NAME=$(oc get nodes -o json | jq '.items[0].metadata.name' | tr -d \")
export OP1ST_B4MAD_URL=$(oc whoami --show-server)
cat manifests/applications/nostromo-openshift-gitops/clusters/cluster.tpl | gomplate | kubeseal --namespace openshift-gitops --controller-namespace=sealed-secrets -o yaml >manifests/applications/nostromo-openshift-gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml
git add manifests/applications/nostromo-openshift-gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml
git commit manifests/applications/nostromo-openshift-gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml -sS -m "add ${OP1ST_B4MAD_CLUSTER_NAME} cluster to ArgoCD"
```
