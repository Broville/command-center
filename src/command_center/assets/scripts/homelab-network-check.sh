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
    ["VLAN20_CLUSTER_PROD"]="10.0.20.1"
    ["VLAN30_CLUSTER_EXTRA"]="10.0.30.1"
    ["VLAN40_STORAGE"]="10.0.40.1"
    ["VLAN50_IOT"]="10.0.50.1"
)

# Critical endpoints and external checks are defined inline in main()

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
        # Extract latency (avg) and packet loss.
        local latency
        latency=$(echo "$result" | awk -F'/' '/(rtt|round-trip)/ {print $5; exit}')
        local packet_loss
        packet_loss=$(echo "$result" | awk -F',' '/packet loss/ {print $3; exit}' | sed -E 's/[^0-9.]+//g')

        latency=${latency:-0}
        packet_loss=${packet_loss:-0}

        # Numeric comparisons via awk (avoid requiring bc).
        if awk -v v="$packet_loss" -v t="$PACKET_LOSS_CRIT" 'BEGIN {exit !(v > t)}'; then
            add_result "$name" "RED" "Packet loss ${packet_loss}% exceeds critical threshold" "$latency"
        elif awk -v v="$packet_loss" -v t="$PACKET_LOSS_WARN" 'BEGIN {exit !(v > t)}'; then
            add_result "$name" "YELLOW" "Packet loss ${packet_loss}% exceeds warning threshold" "$latency"
        elif awk -v v="$latency" -v t="$LATENCY_CRIT_MS" 'BEGIN {exit !(v > t)}'; then
            add_result "$name" "RED" "Latency ${latency}ms exceeds critical threshold" "$latency"
        elif awk -v v="$latency" -v t="$LATENCY_WARN_MS" 'BEGIN {exit !(v > t)}'; then
            add_result "$name" "YELLOW" "Latency ${latency}ms exceeds warning threshold" "$latency"
        else
            add_result "$name" "GREEN" "OK (${latency}ms, ${packet_loss}% loss)" "$latency"
        fi
        return 0
    fi

    return 1
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

dns_server_test() {
    local label="$1"
    local hostname="$2"
    local server="$3"

    log "Testing DNS via $server: $hostname"

    if timeout 5 nslookup "$hostname" "$server" >/dev/null 2>&1; then
        add_result "DNS_${label}" "GREEN" "Resolved $hostname via $server"
    else
        add_result "DNS_${label}" "RED" "Cannot resolve $hostname via $server"
    fi
}

# Test TCP port connectivity
port_test() {
    local name="$1"
    local host="$2"
    local port="$3"
    local required="${4:-false}"
    
    log "Testing port: $name ($host:$port)"
    
    if timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        add_result "${name}_PORT_${port}" "GREEN" "Port $port open"
        return 0
    fi

    if [[ "$required" == "true" ]]; then
        add_result "${name}_PORT_${port}" "RED" "Port $port closed or filtered"
        return 1
    fi

    add_result "${name}_PORT_${port}" "GREEN" "Port $port closed (optional)"
    return 0
}

tcp_any_port_open() {
    local host="$1"; shift
    local port
    for port in "$@"; do
        if timeout 3 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            echo "$port"
            return 0
        fi
    done
    return 1
}

reachability_test() {
    local name="$1"
    local host="$2"
    local icmp_allowed="${3:-true}"
    shift 3 || true
    local ports=("$@")

    if [[ "$icmp_allowed" == "true" ]]; then
        if ping_test "$name" "$host"; then
            return 0
        fi
    fi

    if [[ ${#ports[@]} -gt 0 ]]; then
        local open_port
        if open_port=$(tcp_any_port_open "$host" "${ports[@]}"); then
            add_result "$name" "GREEN" "Reachable (ICMP blocked/disabled; TCP port $open_port open)" ""
            return 0
        fi
    fi

    add_result "$name" "RED" "Unreachable (ICMP blocked/disabled and no TCP reachability)" ""
    return 1
}

http_test() {
    local name="$1"
    local url="$2"

    if ! command -v curl >/dev/null 2>&1; then
        add_result "$name" "YELLOW" "curl not installed; skipping HTTP test" ""
        return 1
    fi

    local out
    out=$(curl -s -o /dev/null -w "%{http_code} %{time_connect}" --connect-timeout 5 --max-time 8 "$url" 2>/dev/null || true)
    local code
    code=$(echo "$out" | awk '{print $1}')
    local time_connect
    time_connect=$(echo "$out" | awk '{print $2}')

    # Convert seconds to ms (best effort).
    local latency_ms=""
    if [[ -n "$time_connect" && "$time_connect" != "0" ]]; then
        latency_ms=$(awk -v t="$time_connect" 'BEGIN {printf "%.0f", (t * 1000)}')
    fi

    if [[ "$code" =~ ^[0-9]+$ ]] && (( code >= 200 && code < 400 )); then
        add_result "$name" "GREEN" "HTTP OK ($code)" "$latency_ms"
        return 0
    fi

    add_result "$name" "RED" "HTTP failed ($code)" "$latency_ms"
    return 1
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
    reachability_test "OPNSense" "$OPNSENSE_IP" true 443
    reachability_test "Controller" "10.0.20.10" true 22
    reachability_test "NAS" "10.0.40.3" false 445 2049 80 443

    # Service-level checks (avoid relying on ICMP alone)
    port_test "OPNSENSE" "$OPNSENSE_IP" 443 true
    port_test "CONTROLLER" "10.0.20.10" 22 true
    
    # Test VLANs
    echo "" >&2
    echo ">> Testing VLAN Gateways..." >&2
    local vlan_unreachable=0
    for vlan in "${!VLANS[@]}"; do
        if ping_test "$vlan" "${VLANS[$vlan]}"; then
            continue
        fi
        add_result "$vlan" "YELLOW" "Unreachable (ICMP)" ""
        vlan_unreachable=$((vlan_unreachable + 1))
    done

    if (( vlan_unreachable >= 3 )); then
        add_result "VLAN_GATEWAYS" "RED" "${vlan_unreachable} VLAN gateways unreachable" ""
    elif (( vlan_unreachable > 0 )); then
        add_result "VLAN_GATEWAYS" "YELLOW" "${vlan_unreachable} VLAN gateways unreachable" ""
    else
        add_result "VLAN_GATEWAYS" "GREEN" "All VLAN gateways reachable" ""
    fi
    
    # Test external connectivity (internet)
    echo "" >&2
    echo ">> Testing Internet Connectivity..." >&2
    # DNS server reachability (ICMP optional; TCP:53 fallback)
    reachability_test "INTERNET_1.1.1.1" "1.1.1.1" true 53
    reachability_test "INTERNET_8.8.8.8" "8.8.8.8" true 53

    # Validate DNS resolution via specific servers (more meaningful than ICMP)
    dns_server_test "CLOUDFLARE" "google.com" "1.1.1.1"
    dns_server_test "GOOGLE" "google.com" "8.8.8.8"

    # Validate general outbound HTTPS
    http_test "INTERNET_HTTPS" "https://google.com"
    
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
