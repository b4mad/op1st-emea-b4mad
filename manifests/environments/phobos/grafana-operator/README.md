https://grafana-operator.github.io/grafana-operator/docs/installation/kustomize/

```
mkdir grafana-operator
flux pull artifact oci://ghcr.io/grafana-operator/kustomize/grafana-operator:v5.3.0 --output ./grafana-operator/
```

oc create -k .
