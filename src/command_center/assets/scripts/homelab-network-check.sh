#!/usr/bin/env bash
#
# homelab-network-check.sh
# Comprehensive network health check for homelab infrastructure
#
# Usage: ./homelab-network-check.sh [--json] [--verbose]
#
# Exit codes:
#   0 = GREEN (all checks passed)
#   1 = YELLOW (warnings present)
#   2 = RED (critical failures)

set -euo pipefail

# Configuration
OPNSENSE_IP="${OPNSENSE_IP:-10.0.0.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# VLAN Configuration (adjust IPs to match your network)
declare -A VLANS=(
    ["VLAN10_MGMT"]="10.0.10.1"
    ["VLAN20_SERVERS"]="10.0.20.1"
    ["VLAN30_TRUSTED"]="10.0.30.1"
    ["VLAN40_STORAGE"]="10.0.40.1"
    ["VLAN50_IOT"]="10.0.50.1"
    ["VLAN60_GUEST"]="10.0.60.1"
)

# Critical endpoints to test
declare -A CRITICAL_ENDPOINTS=(
    ["OPNSense"]="$OPNSENSE_IP"
    ["Controller"]="10.0.20.10"
    ["NAS"]="10.0.40.3"
)

# External endpoints for internet connectivity
EXTERNAL_ENDPOINTS=(
    "1.1.1.1"           # Cloudflare DNS
    "8.8.8.8"           # Google DNS
    "google.com"        # DNS resolution test
)

# Thresholds
LATENCY_WARN_MS=50
LATENCY_CRIT_MS=100
PACKET_LOSS_WARN=1
PACKET_LOSS_CRIT=5

# Output formatting
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

JSON_OUTPUT=false
VERBOSE=false
OVERALL_STATUS="GREEN"
WARNINGS=()
ERRORS=()
RESULTS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) JSON_OUTPUT=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        *) shift ;;
    esac
done

log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "$@" >&2
    fi
}

add_result() {
    local check="$1"
    local status="$2"
    local message="$3"
    local latency="${4:-}"
    
    RESULTS+=("{\"check\": \"$check\", \"status\": \"$status\", \"message\": \"$message\", \"latency_ms\": \"$latency\"}")
    
    if [[ "$status" == "RED" ]]; then
        ERRORS+=("$check: $message")
        OVERALL_STATUS="RED"
    elif [[ "$status" == "YELLOW" && "$OVERALL_STATUS" != "RED" ]]; then
        WARNINGS+=("$check: $message")
        OVERALL_STATUS="YELLOW"
    fi
}

# Test ping connectivity and latency
ping_test() {
    local name="$1"
    local host="$2"
    local result
    
    log "Testing: $name ($host)"
    
    if result=$(ping -c 3 -W 2 "$host" 2>&1); then
        # Extract latency (avg)
        local latency=$(echo "$result" | grep -oP 'avg[^=]*=\s*\K[0-9.]+' | head -1)
        local packet_loss=$(echo "$result" | grep -oP '[0-9.]+(?=% packet loss)')
        
        latency=${latency:-0}
        packet_loss=${packet_loss:-0}
        
        if (( $(echo "$packet_loss > $PACKET_LOSS_CRIT" | bc -l) )); then
            add_result "$name" "RED" "Packet loss ${packet_loss}% exceeds critical threshold" "$latency"
        elif (( $(echo "$packet_loss > $PACKET_LOSS_WARN" | bc -l) )); then
            add_result "$name" "YELLOW" "Packet loss ${packet_loss}% exceeds warning threshold" "$latency"
        elif (( $(echo "$latency > $LATENCY_CRIT_MS" | bc -l) )); then
            add_result "$name" "RED" "Latency ${latency}ms exceeds critical threshold" "$latency"
        elif (( $(echo "$latency > $LATENCY_WARN_MS" | bc -l) )); then
            add_result "$name" "YELLOW" "Latency ${latency}ms exceeds warning threshold" "$latency"
        else
            add_result "$name" "GREEN" "OK (${latency}ms, ${packet_loss}% loss)" "$latency"
        fi
    else
        add_result "$name" "RED" "Unreachable" ""
    fi
}

# Test DNS resolution
dns_test() {
    local name="$1"
    local hostname="$2"
    
    log "Testing DNS: $hostname"
    
    if result=$(timeout 5 nslookup "$hostname" 2>&1); then
        local resolved_ip=$(echo "$result" | grep -A1 "Name:" | grep "Address" | head -1 | awk '{print $2}')
        add_result "DNS_$name" "GREEN" "Resolved to ${resolved_ip:-OK}"
    else
        add_result "DNS_$name" "RED" "DNS resolution failed"
    fi
}

# Test TCP port connectivity
port_test() {
    local name="$1"
    local host="$2"
    local port="$3"
    
    log "Testing port: $name ($host:$port)"
    
    if timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        add_result "${name}_PORT_${port}" "GREEN" "Port $port open"
    else
        add_result "${name}_PORT_${port}" "YELLOW" "Port $port closed or filtered"
    fi
}

# Main execution
main() {
    log "Starting network health check..."
    log "Timestamp: $(date -Iseconds)"
    
    echo "====================================" >&2
    echo "  Homelab Network Health Check" >&2
    echo "====================================" >&2
    echo "" >&2
    
    # Test critical endpoints
    echo ">> Testing Critical Endpoints..." >&2
    for name in "${!CRITICAL_ENDPOINTS[@]}"; do
        ping_test "$name" "${CRITICAL_ENDPOINTS[$name]}"
    done
    
    # Test VLANs
    echo "" >&2
    echo ">> Testing VLAN Gateways..." >&2
    for vlan in "${!VLANS[@]}"; do
        ping_test "$vlan" "${VLANS[$vlan]}"
    done
    
    # Test external connectivity (internet)
    echo "" >&2
    echo ">> Testing Internet Connectivity..." >&2
    for endpoint in "${EXTERNAL_ENDPOINTS[@]}"; do
        if [[ "$endpoint" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ping_test "INTERNET_$endpoint" "$endpoint"
        else
            dns_test "$endpoint" "$endpoint"
            ping_test "INTERNET_$endpoint" "$endpoint"
        fi
    done
    
    # Test OPNSense web interface
    echo "" >&2
    echo ">> Testing OPNSense Services..." >&2
    port_test "OPNSENSE" "$OPNSENSE_IP" "443"
    port_test "OPNSENSE" "$OPNSENSE_IP" "22"
    
    # Output results
    echo "" >&2
    echo "====================================" >&2
    
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"overall_status\": \"$OVERALL_STATUS\","
        echo "  \"warnings\": ${#WARNINGS[@]},"
        echo "  \"errors\": ${#ERRORS[@]},"
        echo "  \"checks\": ["
        local first=true
        for result in "${RESULTS[@]}"; do
            if [[ "$first" == "true" ]]; then
                echo "    $result"
                first=false
            else
                echo "    ,$result"
            fi
        done
        echo "  ]"
        echo "}"
    else
        if [[ "$OVERALL_STATUS" == "GREEN" ]]; then
            echo -e "${GREEN}✓ NETWORK STATUS: GREEN${NC}"
            echo "  All ${#RESULTS[@]} checks passed"
        elif [[ "$OVERALL_STATUS" == "YELLOW" ]]; then
            echo -e "${YELLOW}⚠ NETWORK STATUS: YELLOW${NC}"
            echo "  Warnings: ${#WARNINGS[@]}"
            for warn in "${WARNINGS[@]}"; do
                echo "    - $warn"
            done
        else
            echo -e "${RED}✗ NETWORK STATUS: RED${NC}"
            echo "  Errors: ${#ERRORS[@]}"
            for err in "${ERRORS[@]}"; do
                echo "    - $err"
            done
            if [[ ${#WARNINGS[@]} -gt 0 ]]; then
                echo "  Warnings: ${#WARNINGS[@]}"
                for warn in "${WARNINGS[@]}"; do
                    echo "    - $warn"
                done
            fi
        fi
    fi
    
    # Exit with appropriate code
    case "$OVERALL_STATUS" in
        GREEN) exit 0 ;;
        YELLOW) exit 1 ;;
        RED) exit 2 ;;
    esac
}

main "$@"
