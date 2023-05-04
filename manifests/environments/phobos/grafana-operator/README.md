https://grafana-operator.github.io/grafana-operator/docs/installation/kustomize/

```
mkdir grafana-operator
flux pull artifact oci://ghcr.io/grafana-operator/kustomize/grafana-operator:v5.0.0-rc1 --output ./grafana-operator/
```

oc create -k .
