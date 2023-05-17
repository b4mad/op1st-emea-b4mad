## configuring pipelines

follow <https://docs.openshift.com/container-platform/4.12/cicd/pipelines/using-pipelines-as-code.html#configuring-github-app-for-pac>

### create the required secret

```bash
kubectl -n openshift-pipelines create secret generic --dry-run=client pipelines-as-code-secret --from-literal github-private-key="$(cat ....private-key.pem)" --from-literal github-application-id="<an integer>" --from-literal webhook.secret="<a string>" -o yaml | kubeseal --controller-namespace=sealed-secrets -o yaml
```
