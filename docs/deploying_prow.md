## Creating secrets

`kubectl create secret generic github-oauth --from-file=secret=github-oauth-app.txt --dry-run=client --namespace op1st-prow -o yaml | kubeseal --controller-namespace=sealed-secrets -o yaml > manifests/applications/prow/secrets/github-oauth.yaml` is our implementation of <https://docs.prow.k8s.io/docs/components/core/deck/github-oauth-setup/#set-up-secrets>
