# user-workload-monitoring (nostromo)

UWM Prometheus remote-writes a copy of user-project metrics to the in-cluster
OpenObserve (`manifests/applications/b4mad-openobserve`). Local UWM storage,
console metrics and alerting are unchanged.

| Namespaces | OpenObserve org | Org identifier (URL path) |
| --- | --- | --- |
| `b4mad-.*` | `b4mad` | `3JuQB0RU7PKv25fZyeABptKiT0P` |
| `machdenstaat-.*` | `machdenstaat` | `3JuQBpCQmQvsOfEfQyGDBJLZlG5` |
| `feeldata-.*` | `feeldata` | `3JuQDFXwWgZc5FDJxmwVyFkutll` |

⚠️ The API path takes the org **identifier**, not its name (only `default`
has both equal). Using the name gets `401 Unauthorized`.

Everything else stays local only. Series carry the external labels
`region=emea, org=b4mad, environment=nostromo`.

## Credentials

A dedicated OpenObserve ingest user (not root), member of all three orgs.
Stored as `openobserve-remote-write` (keys `username`, `password`) in
`openshift-user-workload-monitoring`.

1. In the OpenObserve UI, create the orgs and the ingest user, and add the user
   to each org.
2. Create the SOPS source and seal it (run on `nano`, where the GPG key is):

   ```bash
   cat > manifests/environments/nostromo/user-workload-monitoring/openobserve-remote-write.enc.yaml <<'YAML'
   apiVersion: v1
   kind: Secret
   metadata:
     name: openobserve-remote-write
     namespace: openshift-user-workload-monitoring
   type: Opaque
   stringData:
     username: <ingest-user-email>
     password: <ingest-user-password>
   YAML
   sops -e -i manifests/environments/nostromo/user-workload-monitoring/openobserve-remote-write.enc.yaml

   scripts/sops2sealedsecret --force \
     --context default/api-nostromo-erdgeschoss-b4mad-emea-operate-first-cloud:6443/goern \
     --namespace openshift-user-workload-monitoring \
     manifests/environments/nostromo/user-workload-monitoring/openobserve-remote-write.enc.yaml \
     manifests/environments/nostromo/user-workload-monitoring/openobserve-remote-write.yaml
   ```

## Verify

```promql
# in the console, openshift-user-workload-monitoring
rate(prometheus_remote_storage_samples_failed_total[5m])
prometheus_remote_storage_highest_timestamp_in_seconds - ignoring(remote_name, url) group_right prometheus_remote_storage_queue_highest_sent_timestamp_seconds
```
