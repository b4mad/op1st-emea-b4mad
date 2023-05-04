## Secret Operations (sops, sealed-secrets)

Install `sops` from <https://github.com/mozilla/sops/releases>

Have a look at `.sops.yaml`.

### sealed secrets

The cluster will be configured with [sealed secrets](https://github.com/redhat-cop/gitops-catalog/sealed-secrets-operator/overlays/default/README.md).

To create a backup of the private keys, run: `kubectl get secret --namespace sealed-secrets --selector sealedsecrets.bitnami.com/sealed-secrets-key --output yaml >sealed-secrets-main.key`.

Install the `kubeseal` command line tool via `go install github.com/bitnami-labs/sealed-secrets/cmd/kubeseal@v0.20.5`
or download it from <https://github.com/bitnami-labs/sealed-secrets/releases/tag/v0.20.5>

General usage information for [sealed secrets](https://github.com/bitnami-labs/sealed-secrets#usage). Keep in mind that
we deploy it to a different namespace, so you need to use `--controller-namespace sealed-secrets` for all commands.

#### Sealed Secrets used on Nostromo

1. create a service account, follow <https://cert-manager.io/docs/configuration/acme/dns01/google/#set-up-a-service-account>
2. create the sealed secret containing the service account to access gcdns: `kubectl create secret --namespace openshift-cert-manager generic google-clouddns-nostromo-dns01-solver --dry-run=client --from-file=<service_account_filename> -o json | kubeseal --controller-namespace sealed-secrets -o yaml >bootstrap/google-clouddns-nostromo-dns01-solver_sealed-secret.yaml`
3. creae a sealed secret containing the api token for Cloudflare DNS: `kubectl create secret generic cloudflare-b4mad-racing-nostromo-dns01-solver --namespace=openshift-cert-manager --dry-run=client  --from-literal api-token=<token_string>  -o yaml | kubeseal --controller-namespace=sealed-secrets -o yaml >bootstrap/cloudflare-b4mad-racing-nostromo-dns01-solver.yaml`.
