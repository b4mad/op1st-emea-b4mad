# Alertmanager Receivers

we use a [github-receiver](https://github.com/m-lab/alertmanager-github-receiver/tree/main)  to receive alerts from the prometheus instances, it is accessible in-cluster via
`github-receiver.op1st-alertmanager.svc.cluster.local:9393/v1/receiver`.

## getting the current configuration

```bash
oc get secret alertmanager-main --context nostromo --namespace openshift-monitoring -o template --template='{{.data}}' \
 | cut -d ':' -f 2 \
 | base64 -d - > alertmanager.yaml
```

## updating the configuration

This is done in multiple phases:

1. update the raw configuration in the `alertmanager.yaml`
2. create a secret from it
3. sops-encrypt the secret
4. commit the changes to the repository

### update the raw configuration

After getting the current configuration, change it as needed and save the file

### create a secret from it

`oc --context nostromo --namespace openshift-monitoring create secret generic alertmanager-main --dry-run=client --output=yaml --from-file=alertmanager.yaml > secrets/nostromo/alertmanager-main.yaml`

### sops-encrypt the secret

`sops --encrypt --in-place secrets/nostromo/alertmanager-main.yaml` so that we dont keep unencrypted data in the
repository. Next we need to create a sealed secret from it:

`./scripts/sops2sealedsecret --context nostromo --namespace openshift-monitoring secrets/nostromo/alertmanager-main.yaml manifests/environments/nostromo/alertmanager-receivers/alertmanager-main.yaml  --force`
