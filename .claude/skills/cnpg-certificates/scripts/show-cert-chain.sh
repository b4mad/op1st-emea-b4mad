#!/bin/bash
#
# show-cert-chain.sh
#
# Display complete certificate chains for all TLS secrets in a namespace.
# Useful for support and debugging certificate issues.
#
# Usage:
#   ./show-cert-chain.sh <namespace> [context]
#
# Arguments:
#   namespace - Required. The Kubernetes namespace to inspect.
#   context   - Optional. Kubernetes context to use. Uses current context if not specified.
#
# Requirements:
#   - oc or kubectl CLI
#   - openssl
#   - jq
#
# Environment Variables:
#   VERBOSE=1  - Show full certificate text output
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Configuration
VERBOSE=${VERBOSE:-0}

# Detect available CLI (prefer oc over kubectl)
if command -v oc &> /dev/null; then
    CLI="oc"
elif command -v kubectl &> /dev/null; then
    CLI="kubectl"
else
    echo "Error: Neither 'oc' nor 'kubectl' found in PATH" >&2
    exit 1
fi

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <namespace> [context]"
    echo ""
    echo "Arguments:"
    echo "  namespace - Required. The Kubernetes namespace to inspect."
    echo "  context   - Optional. Kubernetes context to use."
    echo ""
    echo "Environment Variables:"
    echo "  VERBOSE=1 - Show full certificate text output"
    exit 1
fi

NAMESPACE="$1"
CONTEXT_ARG=""
if [[ -n "${2:-}" ]]; then
    CONTEXT_ARG="--context=$2"
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

# Function to extract and format certificate info
format_cert_info() {
    local cert_pem="$1"
    local indent="${2:-    }"

    # Extract key certificate fields
    local subject issuer serial not_before not_after is_ca key_usage ext_key_usage san

    subject=$(echo "$cert_pem" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
    issuer=$(echo "$cert_pem" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
    serial=$(echo "$cert_pem" | openssl x509 -noout -serial 2>/dev/null | sed 's/serial=//')
    not_before=$(echo "$cert_pem" | openssl x509 -noout -startdate 2>/dev/null | sed 's/notBefore=//')
    not_after=$(echo "$cert_pem" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')

    # Check if CA
    is_ca=$(echo "$cert_pem" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Basic Constraints" | grep -o "CA:TRUE" || echo "CA:FALSE")

    # Get key usage
    key_usage=$(echo "$cert_pem" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Key Usage:" | tail -1 | sed 's/^[[:space:]]*//' || echo "N/A")

    # Get extended key usage
    ext_key_usage=$(echo "$cert_pem" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Extended Key Usage:" | tail -1 | sed 's/^[[:space:]]*//' || echo "N/A")

    # Get Subject Alternative Names
    san=$(echo "$cert_pem" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name:" | tail -1 | sed 's/^[[:space:]]*//' || echo "N/A")

    # Calculate days remaining
    local expiry_epoch now_epoch days_remaining status_color status_text
    local not_after_raw
    not_after_raw=$(echo "$cert_pem" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    expiry_epoch=$(date -d "$not_after_raw" +%s 2>/dev/null || echo "0")
    now_epoch=$(date +%s)

    if [[ "$expiry_epoch" != "0" ]]; then
        days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))
        if [[ $days_remaining -lt 0 ]]; then
            status_color="$RED"
            status_text="EXPIRED"
        elif [[ $days_remaining -lt 7 ]]; then
            status_color="$RED"
            status_text="CRITICAL"
        elif [[ $days_remaining -lt 30 ]]; then
            status_color="$YELLOW"
            status_text="WARNING"
        else
            status_color="$GREEN"
            status_text="OK"
        fi
    else
        days_remaining="?"
        status_color="$YELLOW"
        status_text="UNKNOWN"
    fi

    # Output formatted info
    echo -e "${indent}${CYAN}Subject:${NC}     $subject"
    echo -e "${indent}${CYAN}Issuer:${NC}      $issuer"
    echo -e "${indent}${CYAN}Serial:${NC}      $serial"
    echo -e "${indent}${CYAN}Valid From:${NC}  $not_before"
    echo -e "${indent}${CYAN}Valid Until:${NC} $not_after ${status_color}[$status_text - ${days_remaining} days]${NC}"
    echo -e "${indent}${CYAN}Is CA:${NC}       $is_ca"

    if [[ "$key_usage" != "N/A" ]]; then
        echo -e "${indent}${CYAN}Key Usage:${NC}   $key_usage"
    fi

    if [[ "$ext_key_usage" != "N/A" ]]; then
        echo -e "${indent}${CYAN}Ext Key Usage:${NC} $ext_key_usage"
    fi

    if [[ "$san" != "N/A" && -n "$san" ]]; then
        echo -e "${indent}${CYAN}SANs:${NC}        $san"
    fi
}

# Function to verify certificate chain
verify_chain() {
    local namespace="$1"
    local cert_secret="$2"
    local ca_secret="$3"
    local indent="${4:-    }"

    # Get CA certificate
    local ca_cert
    ca_cert=$($CLI $CONTEXT_ARG get secret "$ca_secret" -n "$namespace" \
        -o jsonpath="{.data['tls\.crt']}" 2>/dev/null | base64 -d 2>/dev/null || \
        $CLI $CONTEXT_ARG get secret "$ca_secret" -n "$namespace" \
        -o jsonpath="{.data['ca\.crt']}" 2>/dev/null | base64 -d 2>/dev/null || echo "")

    if [[ -z "$ca_cert" ]]; then
        echo -e "${indent}${YELLOW}Cannot verify: CA secret '$ca_secret' not found${NC}"
        return 1
    fi

    # Get certificate to verify
    local cert
    cert=$($CLI $CONTEXT_ARG get secret "$cert_secret" -n "$namespace" \
        -o jsonpath="{.data['tls\.crt']}" 2>/dev/null | base64 -d 2>/dev/null || echo "")

    if [[ -z "$cert" ]]; then
        echo -e "${indent}${YELLOW}Cannot verify: Certificate secret '$cert_secret' not found${NC}"
        return 1
    fi

    # Create temp files for verification
    local ca_file cert_file
    ca_file=$(mktemp)
    cert_file=$(mktemp)
    echo "$ca_cert" > "$ca_file"
    echo "$cert" > "$cert_file"

    # Verify the chain
    local verify_result
    verify_result=$(openssl verify -CAfile "$ca_file" "$cert_file" 2>&1)
    local verify_status=$?

    # Cleanup
    rm -f "$ca_file" "$cert_file"

    if [[ $verify_status -eq 0 ]]; then
        echo -e "${indent}${GREEN}✓ Chain verification: OK${NC}"
        return 0
    else
        echo -e "${indent}${RED}✗ Chain verification: FAILED${NC}"
        echo -e "${indent}  ${DIM}$verify_result${NC}"
        return 1
    fi
}

# Function to display certificate chain from a secret
display_cert_chain() {
    local namespace="$1"
    local secret_name="$2"

    print_subheader "Secret: $secret_name"

    # Get secret type and labels
    local secret_info
    secret_info=$($CLI $CONTEXT_ARG get secret "$secret_name" -n "$namespace" -o json 2>/dev/null)

    if [[ -z "$secret_info" ]]; then
        echo -e "    ${RED}Secret not found${NC}"
        return
    fi

    local secret_type
    secret_type=$(echo "$secret_info" | jq -r '.type // "unknown"')
    echo -e "    ${DIM}Type: $secret_type${NC}"

    # Check for CNPG reload label
    local cnpg_reload
    cnpg_reload=$(echo "$secret_info" | jq -r '.metadata.labels["cnpg.io/reload"] // "not set"')
    if [[ "$cnpg_reload" != "not set" ]]; then
        echo -e "    ${DIM}CNPG Auto-Reload: enabled${NC}"
    fi

    # Get certificate data
    local cert_data
    cert_data=$(echo "$secret_info" | jq -r '.data["tls.crt"] // empty' | base64 -d 2>/dev/null || echo "")

    if [[ -z "$cert_data" ]]; then
        # Try ca.crt for CA secrets
        cert_data=$(echo "$secret_info" | jq -r '.data["ca.crt"] // empty' | base64 -d 2>/dev/null || echo "")
    fi

    if [[ -z "$cert_data" ]]; then
        echo -e "    ${YELLOW}No certificate data found (tls.crt or ca.crt)${NC}"
        return
    fi

    # Count certificates in chain
    local cert_count
    cert_count=$(echo "$cert_data" | grep -c "BEGIN CERTIFICATE" || echo "0")
    echo -e "    ${DIM}Certificates in chain: $cert_count${NC}"
    echo ""

    # Split and display each certificate in the chain
    local cert_index=0
    local current_cert=""
    local in_cert=false

    while IFS= read -r line; do
        if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
            in_cert=true
            current_cert="$line"$'\n'
        elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
            current_cert+="$line"$'\n'
            in_cert=false
            cert_index=$((cert_index + 1))

            # Determine certificate role
            local cert_role
            local is_ca
            is_ca=$(echo "$current_cert" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Basic Constraints" | grep -o "CA:TRUE" || echo "")

            if [[ $cert_index -eq 1 ]]; then
                if [[ -n "$is_ca" ]]; then
                    cert_role="Root/Intermediate CA"
                else
                    cert_role="End Entity (Leaf)"
                fi
            else
                if [[ -n "$is_ca" ]]; then
                    cert_role="Intermediate/Root CA"
                else
                    cert_role="Additional Certificate"
                fi
            fi

            echo -e "    ${BOLD}Certificate #$cert_index ($cert_role)${NC}"
            echo -e "    ─────────────────────────────────────"
            format_cert_info "$current_cert" "      "
            echo ""

            # Show full text if verbose
            if [[ "$VERBOSE" == "1" ]]; then
                echo -e "      ${DIM}--- Full Certificate Text ---${NC}"
                echo "$current_cert" | openssl x509 -noout -text 2>/dev/null | sed 's/^/      /'
                echo ""
            fi

            current_cert=""
        elif [[ "$in_cert" == true ]]; then
            current_cert+="$line"$'\n'
        fi
    done <<< "$cert_data"

    # Show chain relationship
    if [[ $cert_count -gt 1 ]]; then
        echo -e "    ${BOLD}Chain Relationship:${NC}"
        echo -e "    ─────────────────────────────────────"

        local prev_subject=""
        cert_index=0
        current_cert=""
        in_cert=false

        while IFS= read -r line; do
            if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
                in_cert=true
                current_cert="$line"$'\n'
            elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
                current_cert+="$line"$'\n'
                in_cert=false
                cert_index=$((cert_index + 1))

                local subject issuer
                subject=$(echo "$current_cert" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//' | sed 's/^[[:space:]]*//')
                issuer=$(echo "$current_cert" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//' | sed 's/^[[:space:]]*//')

                if [[ $cert_index -eq 1 ]]; then
                    echo -e "      [#$cert_index] $subject"
                else
                    echo -e "         ↑ signed by"
                    echo -e "      [#$cert_index] $subject"
                fi

                prev_subject="$subject"
                current_cert=""
            elif [[ "$in_cert" == true ]]; then
                current_cert+="$line"$'\n'
            fi
        done <<< "$cert_data"
        echo ""
    fi
}

# Function to find related CA secret for a certificate
find_ca_secret() {
    local namespace="$1"
    local secret_name="$2"

    # Common patterns for CA secrets
    local base_name
    base_name=$(echo "$secret_name" | sed -E 's/-(server|client|replication)(-cert)?$//')

    # Check for common CA secret patterns - prefer cert-manager patterns first
    local ca_patterns=(
        "${base_name}-ca-key-pair"
        "${base_name}-ca"
        "${base_name}-root-ca"
        "ca"
    )

    for pattern in "${ca_patterns[@]}"; do
        # Check if secret exists and has tls.crt or ca.crt
        local secret_data
        secret_data=$($CLI $CONTEXT_ARG get secret "$pattern" -n "$namespace" -o json 2>/dev/null || echo "")
        if [[ -n "$secret_data" ]]; then
            local has_cert
            has_cert=$(echo "$secret_data" | jq -r 'if .data["tls.crt"] != null or .data["ca.crt"] != null then "yes" else "no" end' 2>/dev/null)
            if [[ "$has_cert" == "yes" ]]; then
                echo "$pattern"
                return 0
            fi
        fi
    done

    return 1
}

# Main execution
main() {
    print_header "Certificate Chain Report"
    echo ""
    echo "Generated: $(date)"
    echo "Namespace: $NAMESPACE"
    echo "Context: $($CLI $CONTEXT_ARG config current-context 2>/dev/null || echo 'N/A')"

    # Check namespace exists
    if ! $CLI $CONTEXT_ARG get namespace "$NAMESPACE" &>/dev/null; then
        echo -e "${RED}Error: Namespace '$NAMESPACE' not found${NC}"
        exit 1
    fi

    # Get all TLS secrets in namespace
    print_header "TLS Secrets in Namespace"

    local secrets
    secrets=$($CLI $CONTEXT_ARG get secrets -n "$NAMESPACE" -o json 2>/dev/null | \
        jq -r '.items[] | select(.type == "kubernetes.io/tls" or (.data["tls.crt"] != null) or (.data["ca.crt"] != null)) | .metadata.name' 2>/dev/null | sort)

    if [[ -z "$secrets" ]]; then
        echo ""
        echo -e "${YELLOW}No TLS secrets found in namespace '$NAMESPACE'${NC}"
        exit 0
    fi

    local secret_count
    secret_count=$(echo "$secrets" | wc -l | xargs)
    echo ""
    echo "Found $secret_count TLS secret(s)"

    # Display each certificate chain
    print_header "Certificate Details"

    for secret in $secrets; do
        display_cert_chain "$NAMESPACE" "$secret"
    done

    # Chain verification section
    print_header "Chain Verification"
    echo ""

    for secret in $secrets; do
        # Skip CA secrets for verification (they verify themselves)
        if [[ "$secret" == *"-ca"* ]] || [[ "$secret" == *"root"* ]]; then
            continue
        fi

        local ca_secret
        ca_secret=$(find_ca_secret "$NAMESPACE" "$secret" || echo "")

        if [[ -n "$ca_secret" ]]; then
            echo -e "  ${BOLD}$secret${NC} → $ca_secret"
            verify_chain "$NAMESPACE" "$secret" "$ca_secret" "    " || true
        else
            echo -e "  ${BOLD}$secret${NC}"
            echo -e "    ${YELLOW}No CA secret found for verification${NC}"
        fi
        echo ""
    done || true

    # Summary
    print_header "Summary"
    echo ""
    echo "Secrets analyzed: $secret_count"
    echo ""
    echo "For detailed certificate text, run with VERBOSE=1:"
    echo "  VERBOSE=1 $0 $NAMESPACE"
    echo ""
}

# Run main function
main "$@"
