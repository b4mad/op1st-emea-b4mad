# CloudNative-PG Certificate Management

This document describes the certificate architecture used by CloudNative-PG (CNPG) and provides guidance on generating dual-purpose certificates when required.

## Overview

CNPG manages TLS certificates for PostgreSQL clusters automatically. By default, the operator generates separate certificates for different purposes, following the security principle of least privilege.

## Default Certificate Architecture

When using operator-managed certificates (the default), CNPG creates the following secrets for each cluster:

| Secret | Type | Extended Key Usage | Purpose |
|--------|------|-------------------|---------|
| `<cluster>-ca` | CA Certificate | N/A | Signs both server and client certificates |
| `<cluster>-server` | TLS Certificate | `serverAuth` only | PostgreSQL server identity for client connections |
| `<cluster>-replication` | TLS Certificate | `clientAuth` only | Streaming replica authentication |

### Verifying Certificate Key Usages

To inspect a certificate's extended key usage:

```bash
oc get secret <cluster>-server -n <namespace> \
  -o jsonpath="{.data['tls\.crt']}" \
  | base64 -d | openssl x509 -text -noout | grep -A1 "Extended Key Usage"
```

Example output for a server certificate:
```
X509v3 Extended Key Usage:
    TLS Web Server Authentication
```

Example output for a replication certificate:
```
X509v3 Extended Key Usage:
    TLS Web Client Authentication
```

## When Dual-Purpose Certificates Are Needed

Some scenarios require certificates with both `serverAuth` and `clientAuth` extended key usages:

- Mutual TLS (mTLS) configurations where the same entity acts as both client and server
- External integrations that expect dual-purpose certificates
- Certain backup or replication tools that require combined EKUs

## Solution: Using cert-manager for Dual-Purpose Certificates

CNPG does not provide a configuration option to generate dual-purpose certificates automatically. To obtain certificates with both EKUs, use cert-manager to manage certificates externally.

### Prerequisites

- cert-manager installed in the cluster (available in `cert-manager` namespace)
- Appropriate permissions to create Certificate and Issuer resources

### Step 1: Create Certificate Authority

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: postgres-selfsigned-issuer
  namespace: <namespace>
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: postgres-ca
  namespace: <namespace>
spec:
  isCA: true
  commonName: postgres-ca
  secretName: postgres-ca-key-pair
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: postgres-selfsigned-issuer
    kind: Issuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: postgres-ca-issuer
  namespace: <namespace>
spec:
  ca:
    secretName: postgres-ca-key-pair
```

### Step 2: Create Dual-Purpose Server Certificate

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-server-dual-cert
  namespace: <namespace>
  labels:
    cnpg.io/reload: ""
type: kubernetes.io/tls
data: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: postgres-server-dual
  namespace: <namespace>
spec:
  secretName: postgres-server-dual-cert
  usages:
    - server auth
    - client auth
    - digital signature
    - key encipherment
  dnsNames:
    - <cluster>-rw
    - <cluster>-rw.<namespace>
    - <cluster>-rw.<namespace>.svc
    - <cluster>-rw.<namespace>.svc.cluster.local
    - <cluster>-r
    - <cluster>-r.<namespace>
    - <cluster>-r.<namespace>.svc
    - <cluster>-r.<namespace>.svc.cluster.local
    - <cluster>-ro
    - <cluster>-ro.<namespace>
    - <cluster>-ro.<namespace>.svc
    - <cluster>-ro.<namespace>.svc.cluster.local
  issuerRef:
    name: postgres-ca-issuer
    kind: Issuer
    group: cert-manager.io
```

### Step 3: Create Client/Replication Certificate (if needed)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-client-cert
  namespace: <namespace>
  labels:
    cnpg.io/reload: ""
type: kubernetes.io/tls
data: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: postgres-client
  namespace: <namespace>
spec:
  secretName: postgres-client-cert
  usages:
    - client auth
    - digital signature
  commonName: streaming_replica
  issuerRef:
    name: postgres-ca-issuer
    kind: Issuer
    group: cert-manager.io
```

### Step 4: Configure CNPG Cluster to Use Custom Certificates

Update your Cluster resource to reference the cert-manager managed secrets:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster>
  namespace: <namespace>
spec:
  instances: 3
  certificates:
    serverTLSSecret: postgres-server-dual-cert
    serverCASecret: postgres-ca-key-pair
    clientCASecret: postgres-client-cert
    replicationTLSSecret: postgres-client-cert
  storage:
    size: 10Gi
```

## Important Considerations

### Automatic Certificate Reload

Add the `cnpg.io/reload: ""` label to certificate secrets to enable automatic reloading when certificates are renewed by cert-manager. Without this label, you must manually trigger a reload:

```bash
oc cnpg reload <cluster> -n <namespace>
```

### Certificate Expiration

Monitor certificate expiration dates. The cluster status includes expiration information:

```bash
oc get cluster <cluster> -n <namespace> -o jsonpath='{.status.certificates.expirations}' | jq
```

### Security Trade-offs

Using single-purpose certificates (the CNPG default) is more secure because:

- Limits the scope of a compromised certificate
- Follows the principle of least privilege
- Reduces attack surface

Only use dual-purpose certificates when specifically required by your use case.

## Troubleshooting

### Certificate Not Being Used

If the cluster is not using the new certificate:

1. Verify the secret exists and contains valid certificate data
2. Check that the secret has the `cnpg.io/reload` label
3. Verify the Cluster spec references the correct secret names
4. Check operator logs for certificate-related errors:

```bash
oc logs -n cnpg-system deployment/cnpg-controller-manager | grep -i cert
```

### Certificate Validation Errors

If PostgreSQL rejects connections due to certificate issues:

1. Verify the certificate's DNS SANs match the service names
2. Ensure the certificate is signed by the CA referenced in `serverCASecret`
3. Check that the certificate has not expired

## References

- [CNPG Certificates Documentation](https://cloudnative-pg.io/documentation/current/certificates/)
- [CNPG cert-manager Integration Example](https://cloudnative-pg.io/documentation/current/samples/cluster-example-cert-manager/)
- [cert-manager Certificate Resources](https://cert-manager.io/docs/usage/certificate/)
