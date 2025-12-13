#!/bin/bash
#
# check-cnpg-cert-expiry.sh
#
# Check expiration information for all CloudNative-PG related certificates
# across all namespaces on a Kubernetes/OpenShift cluster.
#
# Usage:
#   ./check-cnpg-cert-expiry.sh [context]
#
# Arguments:
#   context  - Optional Kubernetes context to use. Uses current context if not specified.
#
# Requirements:
#   - oc or kubectl CLI
#   - openssl
#   - jq
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
WARN_DAYS=${WARN_DAYS:-30}  # Warn if certificate expires within this many days
CRIT_DAYS=${CRIT_DAYS:-7}   # Critical if certificate expires within this many days

# Detect available CLI (prefer oc over kubectl)
if command -v oc &> /dev/null; then
    CLI="oc"
elif command -v kubectl &> /dev/null; then
    CLI="kubectl"
else
    echo "Error: Neither 'oc' nor 'kubectl' found in PATH" >&2
    exit 1
fi

# Set context if provided
CONTEXT_ARG=""
if [[ -n "${1:-}" ]]; then
    CONTEXT_ARG="--context=$1"
    echo -e "${BLUE}Using context: $1${NC}"
fi

# Function to print section header
print_header() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
}

# Function to print subsection header
print_subheader() {
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
}

# Function to check certificate expiration from secret
check_secret_cert() {
    local namespace="$1"
    local secret_name="$2"
    local cert_type="$3"

    # Get the certificate data
    local cert_data
    cert_data=$($CLI $CONTEXT_ARG get secret "$secret_name" -n "$namespace" \
        -o jsonpath="{.data['tls\.crt']}" 2>/dev/null || echo "")

    if [[ -z "$cert_data" ]]; then
        echo -e "    ${YELLOW}⚠  $cert_type: Secret '$secret_name' not found or has no tls.crt${NC}"
        return
    fi

    # Decode and parse the certificate
    local cert_info
    cert_info=$(echo "$cert_data" | base64 -d 2>/dev/null | openssl x509 -noout \
        -subject -issuer -dates -ext extendedKeyUsage 2>/dev/null || echo "PARSE_ERROR")

    if [[ "$cert_info" == "PARSE_ERROR" ]]; then
        echo -e "    ${RED}✗  $cert_type: Failed to parse certificate in '$secret_name'${NC}"
        return
    fi

    # Extract expiration date
    local not_after
    not_after=$(echo "$cert_info" | grep "notAfter=" | cut -d= -f2)

    # Calculate days until expiration
    local expiry_epoch
    local now_epoch
    local days_remaining

    expiry_epoch=$(date -d "$not_after" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$not_after" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))

    # Extract subject CN
    local subject_cn
    subject_cn=$(echo "$cert_info" | grep "subject=" | sed 's/.*CN = //' | cut -d',' -f1)

    # Extract Extended Key Usage
    local eku
    eku=$(echo "$cert_info" | grep -A1 "Extended Key Usage" | tail -1 | xargs || echo "N/A")

    # Determine status color
    local status_color
    local status_icon
    if [[ $days_remaining -lt 0 ]]; then
        status_color="$RED"
        status_icon="✗ EXPIRED"
    elif [[ $days_remaining -lt $CRIT_DAYS ]]; then
        status_color="$RED"
        status_icon="⚠ CRITICAL"
    elif [[ $days_remaining -lt $WARN_DAYS ]]; then
        status_color="$YELLOW"
        status_icon="⚠ WARNING"
    else
        status_color="$GREEN"
        status_icon="✓ OK"
    fi

    printf "    %-20s %-30s %b%-12s%b %s\n" \
        "$cert_type:" \
        "$secret_name" \
        "$status_color" "$status_icon ($days_remaining days)" "$NC" \
        "$not_after"
    printf "                       Subject: %s\n" "$subject_cn"
    printf "                       EKU: %s\n" "$eku"
}

# Function to check cert-manager Certificate resources
check_certmanager_certs() {
    local namespace="$1"
    local cluster_name="$2"

    # List cert-manager Certificate resources that might be related to this cluster
    local certs
    certs=$($CLI $CONTEXT_ARG get certificates -n "$namespace" -o json 2>/dev/null | \
        jq -r ".items[] | select(.metadata.name | contains(\"$cluster_name\") or contains(\"postgres\")) | .metadata.name" 2>/dev/null || echo "")

    if [[ -z "$certs" ]]; then
        return
    fi

    echo ""
    echo "    cert-manager Certificates:"

    for cert in $certs; do
        local cert_status
        cert_status=$($CLI $CONTEXT_ARG get certificate "$cert" -n "$namespace" -o json 2>/dev/null)

        local ready
        ready=$(echo "$cert_status" | jq -r '.status.conditions[] | select(.type=="Ready") | .status' 2>/dev/null || echo "Unknown")

        local not_after
        not_after=$(echo "$cert_status" | jq -r '.status.notAfter // "N/A"' 2>/dev/null)

        local renew_before
        renew_before=$(echo "$cert_status" | jq -r '.spec.renewBefore // "720h"' 2>/dev/null)

        local secret_name
        secret_name=$(echo "$cert_status" | jq -r '.spec.secretName // "N/A"' 2>/dev/null)

        # Calculate days remaining if we have a valid date
        local days_info=""
        if [[ "$not_after" != "N/A" && "$not_after" != "null" ]]; then
            local expiry_epoch
            local now_epoch
            expiry_epoch=$(date -d "$not_after" +%s 2>/dev/null || echo "0")
            now_epoch=$(date +%s)
            if [[ "$expiry_epoch" != "0" ]]; then
                local days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))
                days_info=" ($days_remaining days)"
            fi
        fi

        local status_color="$GREEN"
        if [[ "$ready" != "True" ]]; then
            status_color="$YELLOW"
        fi

        printf "      - %-40s Ready: %b%s%b  Expires: %s%s\n" \
            "$cert" "$status_color" "$ready" "$NC" "$not_after" "$days_info"
        printf "        Secret: %s, RenewBefore: %s\n" "$secret_name" "$renew_before"
    done
}

# Function to process a CNPG cluster
process_cluster() {
    local namespace="$1"
    local cluster_name="$2"

    print_subheader "Cluster: $cluster_name (namespace: $namespace)"

    # Get cluster certificate status
    local cluster_cert_status
    cluster_cert_status=$($CLI $CONTEXT_ARG get cluster "$cluster_name" -n "$namespace" \
        -o jsonpath='{.status.certificates.expirations}' 2>/dev/null || echo "{}")

    if [[ -n "$cluster_cert_status" && "$cluster_cert_status" != "{}" ]]; then
        echo ""
        echo "    CNPG Reported Expirations:"
        echo "$cluster_cert_status" | jq -r 'to_entries[] | "      \(.key): \(.value)"' 2>/dev/null || echo "      (unable to parse)"
    fi

    # Get certificate configuration from cluster spec
    local cert_config
    cert_config=$($CLI $CONTEXT_ARG get cluster "$cluster_name" -n "$namespace" \
        -o jsonpath='{.spec.certificates}' 2>/dev/null || echo "{}")

    # Determine secret names (use custom if specified, otherwise defaults)
    local server_tls_secret
    local server_ca_secret
    local client_ca_secret
    local replication_tls_secret

    server_tls_secret=$(echo "$cert_config" | jq -r '.serverTLSSecret // empty' 2>/dev/null)
    server_ca_secret=$(echo "$cert_config" | jq -r '.serverCASecret // empty' 2>/dev/null)
    replication_tls_secret=$(echo "$cert_config" | jq -r '.replicationTLSSecret // empty' 2>/dev/null)

    # Use defaults if not specified
    [[ -z "$server_tls_secret" ]] && server_tls_secret="${cluster_name}-server"
    [[ -z "$server_ca_secret" ]] && server_ca_secret="${cluster_name}-ca"
    [[ -z "$replication_tls_secret" ]] && replication_tls_secret="${cluster_name}-replication"

    echo ""
    echo "    Certificate Secrets:"

    # Check each certificate secret
    check_secret_cert "$namespace" "$server_ca_secret" "CA"
    check_secret_cert "$namespace" "$server_tls_secret" "Server TLS"
    check_secret_cert "$namespace" "$replication_tls_secret" "Replication"

    # Check for any additional client certificates
    local client_ca_secret_val
    client_ca_secret_val=$(echo "$cert_config" | jq -r '.clientCASecret // empty' 2>/dev/null)
    if [[ -n "$client_ca_secret_val" && "$client_ca_secret_val" != "$replication_tls_secret" ]]; then
        check_secret_cert "$namespace" "$client_ca_secret_val" "Client CA"
    fi

    # Check for cert-manager managed certificates
    check_certmanager_certs "$namespace" "$cluster_name"
}

# Main execution
main() {
    print_header "CNPG Certificate Expiration Report"
    echo ""
    echo "Generated: $(date)"
    echo "Cluster: $($CLI $CONTEXT_ARG config current-context 2>/dev/null || echo 'N/A')"
    echo "Warning threshold: ${WARN_DAYS} days"
    echo "Critical threshold: ${CRIT_DAYS} days"

    # Get all CNPG clusters across all namespaces
    print_header "Discovering CNPG Clusters"

    local clusters
    clusters=$($CLI $CONTEXT_ARG get clusters.postgresql.cnpg.io -A -o json 2>/dev/null || echo '{"items":[]}')

    local cluster_count
    cluster_count=$(echo "$clusters" | jq '.items | length' 2>/dev/null || echo "0")

    if [[ "$cluster_count" == "0" ]]; then
        echo ""
        echo -e "${YELLOW}No CNPG clusters found in any namespace.${NC}"
        echo ""
        exit 0
    fi

    echo ""
    echo "Found $cluster_count CNPG cluster(s)"

    # Process each cluster
    print_header "Certificate Details by Cluster"

    echo "$clusters" | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' 2>/dev/null | \
    while read -r namespace cluster_name; do
        process_cluster "$namespace" "$cluster_name"
    done

    # Summary section - scan for problems
    print_header "Summary"
    echo ""

    local problems_found=false

    echo "$clusters" | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' 2>/dev/null | \
    while read -r namespace cluster_name; do
        # Check cluster-reported expirations
        local expirations
        expirations=$($CLI $CONTEXT_ARG get cluster "$cluster_name" -n "$namespace" \
            -o jsonpath='{.status.certificates.expirations}' 2>/dev/null || echo "{}")

        if [[ -n "$expirations" && "$expirations" != "{}" ]]; then
            echo "$expirations" | jq -r 'to_entries[] | "\(.key) \(.value)"' 2>/dev/null | \
            while read -r cert_name exp_date; do
                if [[ -n "$exp_date" ]]; then
                    local expiry_epoch
                    local now_epoch
                    expiry_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
                    now_epoch=$(date +%s)
                    if [[ "$expiry_epoch" != "0" ]]; then
                        local days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))
                        if [[ $days_remaining -lt $CRIT_DAYS ]]; then
                            echo -e "${RED}CRITICAL: $namespace/$cluster_name - $cert_name expires in $days_remaining days ($exp_date)${NC}"
                            problems_found=true
                        elif [[ $days_remaining -lt $WARN_DAYS ]]; then
                            echo -e "${YELLOW}WARNING: $namespace/$cluster_name - $cert_name expires in $days_remaining days ($exp_date)${NC}"
                            problems_found=true
                        fi
                    fi
                fi
            done
        fi
    done

    if [[ "$problems_found" == "false" ]]; then
        echo -e "${GREEN}All certificates are healthy (expiring in more than $WARN_DAYS days)${NC}"
    fi

    echo ""
}

# Run main function
main "$@"
