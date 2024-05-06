## adding a cluster to ArgoCD

```bash
go install github.com/hairyhenderson/gomplate/v4/cmd/gomplate@latest
export OP1ST_B4MAD_SECRET_NAME=argocd-manager # this is default for op1st
export OP1ST_B4MAD_AUTHENTICATION_TOKEN=$(oc get secret --namespace kube-system ${OP1ST_B4MAD_SECRET_NAME} -o jsonpath='{.data.token}' | base64 --decode)
export OP1ST_B4MAD_CLUSTER_NAME=$(oc get nodes -o json | jq '.items[0].metadata.name' | tr -d \")
export OP1ST_B4MAD_URL=$(oc whoami --show-server)

# at this point: make sure, you are running kubeseal on nostromo, as that cluster needs to be able to unseal the secrets!
cat manifests/applications/gitops/clusters/cluster.tpl | gomplate | kubeseal --namespace openshift-gitops --controller-namespace=sealed-secrets -o yaml >manifests/applications/gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml
pre-commit run --all-files
git add manifests/applications/gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml
git commit manifests/applications/gitops/clusters/${OP1ST_B4MAD_CLUSTER_NAME}.yaml -sS -m "🔐 add ${OP1ST_B4MAD_CLUSTER_NAME} cluster to ArgoCD"
```

### References

<https://inlets.dev/blog/2021/06/02/argocd-private-clusters.html>
