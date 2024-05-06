apiVersion: v1
kind: Secret
metadata:
  name: {{.Env.OP1ST_B4MAD_CLUSTER_NAME}}
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: {{.Env.OP1ST_B4MAD_CLUSTER_NAME}}
  server: {{.Env.OP1ST_B4MAD_URL}}
  config: |
    {
      "bearerToken": "{{.Env.OP1ST_B4MAD_AUTHENTICATION_TOKEN}}",
    }
