# CNPG Certificate Management Skill

Manage TLS certificates for CloudNative-PG (CNPG) PostgreSQL clusters.

## Capabilities

This skill helps you:
- Inspect certificate configurations for CNPG clusters
- Check certificate expiration dates across all namespaces (using included script)
- Display complete certificate chains for all TLS secrets in a namespace (for support)
- Analyze certificate key usages (serverAuth, clientAuth)
- Verify certificate chain relationships and trust
- Generate cert-manager resources for dual-purpose certificates
- Apply certificate configurations to clusters

## Usage

When the user asks to manage CNPG certificates, follow these workflows:

### Workflow 1: Inspect Cluster Certificates

1. List all CNPG clusters:
   ```bash
   oc get clusters.postgresql.cnpg.io -A
   ```

2. Get certificate status from cluster:
   ```bash
   oc get cluster <cluster-name> -n <namespace> -o jsonpath='{.status.certificates}' | jq
   ```

3. Inspect the actual certificate key usages:
   ```bash
   # Server certificate
   oc get secret <cluster>-server -n <namespace> \
     -o jsonpath="{.data['tls\.crt']}" \
     | base64 -d | openssl x509 -text -noout | grep -A2 "Extended Key Usage"

   # Replication certificate
   oc get secret <cluster>-replication -n <namespace> \
     -o jsonpath="{.data['tls\.crt']}" \
     | base64 -d | openssl x509 -text -noout | grep -A2 "Extended Key Usage"
   ```

4. Check certificate expiration:
   ```bash
   oc get cluster <cluster-name> -n <namespace> \
     -o jsonpath='{.status.certificates.expirations}' | jq
   ```

### Workflow 2: Check All Certificate Expirations Cluster-Wide

Use the included shell script to get a comprehensive report of all CNPG certificate expirations across all namespaces:

```bash
# Run from the repository root
.claude/skills/cnpg-certificates/scripts/check-cnpg-cert-expiry.sh

# Or specify a specific Kubernetes context
.claude/skills/cnpg-certificates/scripts/check-cnpg-cert-expiry.sh my-cluster-context
```

The script provides:
- **Cluster discovery**: Finds all CNPG clusters across all namespaces
- **Certificate details**: Shows CA, Server TLS, and Replication certificates for each cluster
- **Expiration status**: Color-coded status (OK/WARNING/CRITICAL/EXPIRED)
- **Days remaining**: Calculates days until expiration
- **Extended Key Usage**: Shows whether certificates are single or dual-purpose
- **cert-manager integration**: Detects and reports on cert-manager managed certificates
- **Summary**: Lists any certificates requiring attention

Environment variables:
- `WARN_DAYS`: Warning threshold in days (default: 30)
- `CRIT_DAYS`: Critical threshold in days (default: 7)

Example output:
```
═══════════════════════════════════════════════════════════════════
  CNPG Certificate Expiration Report
═══════════════════════════════════════════════════════════════════

Generated: Fri Dec 13 12:00:00 UTC 2025
Cluster: my-cluster
Warning threshold: 30 days
Critical threshold: 7 days

───────────────────────────────────────────────────────────────────
  Cluster: postgres-db (namespace: production)
───────────────────────────────────────────────────────────────────

    Certificate Secrets:
    CA:                  postgres-db-ca          ✓ OK (340 days)    Jan 15 2027
    Server TLS:          postgres-db-server      ✓ OK (85 days)     Mar 08 2026
    Replication:         postgres-db-replication ✓ OK (85 days)     Mar 08 2026
```

### Workflow 3: Display Certificate Chains (Support)

Use the included shell script to display complete certificate chains for all TLS secrets in a namespace. This is useful for support and debugging certificate issues.

```bash
# Show all certificate chains in a namespace
.claude/skills/cnpg-certificates/scripts/show-cert-chain.sh <namespace>

# With a specific Kubernetes context
.claude/skills/cnpg-certificates/scripts/show-cert-chain.sh <namespace> my-cluster-context

# With verbose output (full certificate text)
VERBOSE=1 .claude/skills/cnpg-certificates/scripts/show-cert-chain.sh <namespace>
```

The script provides:
- **Secret discovery**: Finds all TLS secrets in the namespace
- **Certificate chain display**: Shows all certificates in each secret's chain
- **Certificate details**: Subject, Issuer, Serial, Validity, Key Usage, Extended Key Usage, SANs
- **Chain relationship**: Visual representation of certificate chain hierarchy
- **Chain verification**: Verifies certificates against their CA
- **Expiration status**: Color-coded status (OK/WARNING/CRITICAL/EXPIRED)

Example output:
```
═══════════════════════════════════════════════════════════════════
  Certificate Chain Report
═══════════════════════════════════════════════════════════════════

Generated: Sat Dec 13 15:00:00 CET 2025
Namespace: b4mad-agent-registry-prod
Context: my-cluster

═══════════════════════════════════════════════════════════════════
  TLS Secrets in Namespace
═══════════════════════════════════════════════════════════════════

Found 4 TLS secret(s)

───────────────────────────────────────────────────────────────────
  Secret: b4rega2a-server-cert
───────────────────────────────────────────────────────────────────
    Type: kubernetes.io/tls
    CNPG Auto-Reload: enabled
    Certificates in chain: 1

    Certificate #1 (End Entity (Leaf))
    ─────────────────────────────────────
      Subject:
      Issuer:      CN=b4rega2a-ca
      Serial:      1234567890ABCDEF
      Valid From:  Dec 13 14:57:11 2025 GMT
      Valid Until: Dec 13 14:57:11 2026 GMT [OK - 364 days]
      Is CA:       CA:FALSE
      Ext Key Usage: TLS Web Server Authentication
      SANs:        DNS:b4rega2a-rw, DNS:b4rega2a-rw.b4mad-agent-registry-prod...

═══════════════════════════════════════════════════════════════════
  Chain Verification
═══════════════════════════════════════════════════════════════════

  b4rega2a-server-cert → b4rega2a-ca-key-pair
    ✓ Chain verification: OK
```

### Workflow 4: Generate Dual-Purpose Certificates with cert-manager

When the user needs dual-purpose certificates (both serverAuth and clientAuth), generate the following resources. Replace placeholders:
- `${CLUSTER_NAME}` - CNPG cluster name
- `${NAMESPACE}` - Target namespace

```yaml
---
# Self-signed issuer for CA
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${CLUSTER_NAME}-selfsigned-issuer
  namespace: ${NAMESPACE}
spec:
  selfSigned: {}
---
# CA Certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CLUSTER_NAME}-ca
  namespace: ${NAMESPACE}
spec:
  isCA: true
  commonName: ${CLUSTER_NAME}-ca
  secretName: ${CLUSTER_NAME}-ca-key-pair
  duration: 87600h # 10 years
  renewBefore: 720h # 30 days
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: ${CLUSTER_NAME}-selfsigned-issuer
    kind: Issuer
    group: cert-manager.io
---
# CA Issuer for signing end-entity certificates
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${CLUSTER_NAME}-ca-issuer
  namespace: ${NAMESPACE}
spec:
  ca:
    secretName: ${CLUSTER_NAME}-ca-key-pair
---
# Pre-create server secret with reload label
apiVersion: v1
kind: Secret
metadata:
  name: ${CLUSTER_NAME}-server-cert
  namespace: ${NAMESPACE}
  labels:
    cnpg.io/reload: ""
type: kubernetes.io/tls
stringData:
  tls.crt: ""
  tls.key: ""
---
# Dual-purpose server certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CLUSTER_NAME}-server
  namespace: ${NAMESPACE}
spec:
  secretName: ${CLUSTER_NAME}-server-cert
  duration: 8760h # 1 year
  renewBefore: 720h # 30 days
  usages:
    - server auth
    - client auth
    - digital signature
    - key encipherment
  dnsNames:
    - ${CLUSTER_NAME}-rw
    - ${CLUSTER_NAME}-rw.${NAMESPACE}
    - ${CLUSTER_NAME}-rw.${NAMESPACE}.svc
    - ${CLUSTER_NAME}-rw.${NAMESPACE}.svc.cluster.local
    - ${CLUSTER_NAME}-r
    - ${CLUSTER_NAME}-r.${NAMESPACE}
    - ${CLUSTER_NAME}-r.${NAMESPACE}.svc
    - ${CLUSTER_NAME}-r.${NAMESPACE}.svc.cluster.local
    - ${CLUSTER_NAME}-ro
    - ${CLUSTER_NAME}-ro.${NAMESPACE}
    - ${CLUSTER_NAME}-ro.${NAMESPACE}.svc
    - ${CLUSTER_NAME}-ro.${NAMESPACE}.svc.cluster.local
  issuerRef:
    name: ${CLUSTER_NAME}-ca-issuer
    kind: Issuer
    group: cert-manager.io
---
# Pre-create client secret with reload label
apiVersion: v1
kind: Secret
metadata:
  name: ${CLUSTER_NAME}-client-cert
  namespace: ${NAMESPACE}
  labels:
    cnpg.io/reload: ""
type: kubernetes.io/tls
stringData:
  tls.crt: ""
  tls.key: ""
---
# Client/Replication certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CLUSTER_NAME}-client
  namespace: ${NAMESPACE}
spec:
  secretName: ${CLUSTER_NAME}-client-cert
  duration: 8760h # 1 year
  renewBefore: 720h # 30 days
  usages:
    - client auth
    - digital signature
  commonName: streaming_replica
  issuerRef:
    name: ${CLUSTER_NAME}-ca-issuer
    kind: Issuer
    group: cert-manager.io
```

### Workflow 5: Update Cluster to Use Custom Certificates

After cert-manager creates the certificates, update the CNPG Cluster:

```yaml
spec:
  certificates:
    serverTLSSecret: ${CLUSTER_NAME}-server-cert
    serverCASecret: ${CLUSTER_NAME}-ca-key-pair
    clientCASecret: ${CLUSTER_NAME}-client-cert
    replicationTLSSecret: ${CLUSTER_NAME}-client-cert
```

### Workflow 6: Verify Certificate Configuration

After applying changes:

1. Wait for certificates to be ready:
   ```bash
   oc get certificates -n <namespace>
   ```

2. Verify the new certificate has dual-purpose EKU:
   ```bash
   oc get secret <cluster>-server-cert -n <namespace> \
     -o jsonpath="{.data['tls\.crt']}" \
     | base64 -d | openssl x509 -text -noout | grep -A2 "Extended Key Usage"
   ```

   Expected output:
   ```
   X509v3 Extended Key Usage:
       TLS Web Server Authentication, TLS Web Client Authentication
   ```

3. Check cluster health:
   ```bash
   oc get cluster <cluster-name> -n <namespace>
   ```

### Workflow 7: Troubleshoot Certificate Issues

1. Check cert-manager certificate status:
   ```bash
   oc describe certificate <cluster>-server -n <namespace>
   ```

2. Check CNPG operator logs:
   ```bash
   oc logs -n cnpg-system deployment/cnpg-controller-manager --tail=100 | grep -i cert
   ```

3. Force certificate reload:
   ```bash
   oc cnpg reload <cluster-name> -n <namespace>
   ```

4. Verify secret has the reload label:
   ```bash
   oc get secret <cluster>-server-cert -n <namespace> -o jsonpath='{.metadata.labels}' | jq
   ```

## Output Location

When generating certificate manifests, save them to:
```
manifests/applications/<application-name>/certificates/
```

## Important Notes

- Always use `cnpg.io/reload: ""` label on certificate secrets for automatic reload
- Default CNPG certificates use single-purpose EKUs (more secure)
- Only use dual-purpose certificates when specifically required
- Monitor certificate expiration via cluster status
- cert-manager handles automatic renewal based on `renewBefore` setting

## Scripts

This skill includes the following scripts in the `scripts/` directory:

### check-cnpg-cert-expiry.sh

A comprehensive shell script to check certificate expiration for all CNPG clusters.

**Location**: `.claude/skills/cnpg-certificates/scripts/check-cnpg-cert-expiry.sh`

**Usage**:
```bash
./check-cnpg-cert-expiry.sh [context]
```

**Features**:
- Discovers all CNPG clusters across all namespaces
- Checks CA, Server TLS, and Replication certificates
- Reports days until expiration with color-coded status
- Detects cert-manager managed certificates
- Shows Extended Key Usage (EKU) for each certificate
- Provides summary of certificates needing attention

**Requirements**:
- `oc` or `kubectl` CLI
- `openssl`
- `jq`

**Environment Variables**:
| Variable | Default | Description |
|----------|---------|-------------|
| `WARN_DAYS` | 30 | Warn if certificate expires within this many days |
| `CRIT_DAYS` | 7 | Critical if certificate expires within this many days |

### show-cert-chain.sh

A support-focused shell script to display complete certificate chains for all TLS secrets in a namespace.

**Location**: `.claude/skills/cnpg-certificates/scripts/show-cert-chain.sh`

**Usage**:
```bash
./show-cert-chain.sh <namespace> [context]
```

**Features**:
- Lists all TLS secrets in a namespace
- Displays complete certificate chain for each secret
- Shows detailed certificate information:
  - Subject and Issuer
  - Serial number
  - Validity period with days remaining
  - CA status (is certificate a CA)
  - Key Usage and Extended Key Usage
  - Subject Alternative Names (SANs)
- Visual chain relationship display
- Verifies certificate chains against CA certificates
- Color-coded expiration status (OK/WARNING/CRITICAL/EXPIRED)
- Detects CNPG auto-reload labels

**Requirements**:
- `oc` or `kubectl` CLI
- `openssl`
- `jq`

**Environment Variables**:
| Variable | Default | Description |
|----------|---------|-------------|
| `VERBOSE` | 0 | Set to 1 for full certificate text output |

**Example**:
```bash
# Basic usage
.claude/skills/cnpg-certificates/scripts/show-cert-chain.sh b4mad-agent-registry-prod

# With verbose output
VERBOSE=1 .claude/skills/cnpg-certificates/scripts/show-cert-chain.sh b4mad-agent-registry-prod

# With specific context
.claude/skills/cnpg-certificates/scripts/show-cert-chain.sh b4mad-agent-registry-prod my-context
```

## Reference Documentation

See `docs/cnpg-certificates.md` for detailed documentation on CNPG certificate management.
