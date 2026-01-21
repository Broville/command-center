#!/usr/bin/env bash
#
# homelab-nas-check.sh
# Comprehensive NAS/Unraid health check for homelab infrastructure
#
# Usage: ./homelab-nas-check.sh [--json] [--verbose]
#
# Exit codes:
#   0 = GREEN (all checks passed)
#   1 = YELLOW (warnings present)
#   2 = RED (critical failures)

set -euo pipefail

# Configuration
UNRAID_IP="${UNRAID_IP:-10.0.40.3}"
UNRAID_API_PORT="${UNRAID_API_PORT:-80}"

# SMB shares to test (adjust to match your shares)
SMB_SHARES=(
    "media"
    "backups"
    "appdata"
    "isos"
)

# NFS exports to test (if applicable)
NFS_EXPORTS=(
    "/mnt/user/media"
    "/mnt/user/backups"
)

# Thresholds
READ_LATENCY_WARN_MS=50
READ_LATENCY_CRIT_MS=100
WRITE_LATENCY_WARN_MS=100
WRITE_LATENCY_CRIT_MS=200
DISK_USAGE_WARN_PCT=80
DISK_USAGE_CRIT_PCT=90

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
    local value="${4:-}"
    
    RESULTS+=("{\"check\": \"$check\", \"status\": \"$status\", \"message\": \"$message\", \"value\": \"$value\"}")
    
    if [[ "$status" == "RED" ]]; then
        ERRORS+=("$check: $message")
        OVERALL_STATUS="RED"
    elif [[ "$status" == "YELLOW" && "$OVERALL_STATUS" != "RED" ]]; then
        WARNINGS+=("$check: $message")
        OVERALL_STATUS="YELLOW"
    fi
}

# Test NAS reachability
test_reachability() {
    log "Testing NAS reachability..."
    
    if ping -c 3 -W 2 "$UNRAID_IP" &>/dev/null; then
        local latency=$(ping -c 3 -W 2 "$UNRAID_IP" | grep -oP 'avg[^=]*=\s*\K[0-9.]+' | head -1)
        add_result "NAS_PING" "GREEN" "Reachable (${latency}ms)" "$latency"
    else
        add_result "NAS_PING" "RED" "NAS unreachable at $UNRAID_IP"
        return 1
    fi
}

# Test web interface
test_web_interface() {
    log "Testing Unraid web interface..."
    
    if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" "http://$UNRAID_IP:$UNRAID_API_PORT" | grep -q "200\|302\|301"; then
        add_result "UNRAID_WEB" "GREEN" "Web interface accessible"
    else
        add_result "UNRAID_WEB" "YELLOW" "Web interface not responding (may require auth)"
    fi
}

# Test SMB connectivity
test_smb_shares() {
    log "Testing SMB shares..."
    
    # Check if smbclient is available
    if ! command -v smbclient &>/dev/null; then
        add_result "SMB_CLIENT" "YELLOW" "smbclient not installed, skipping SMB tests"
        return
    fi
    
    for share in "${SMB_SHARES[@]}"; do
        log "  Testing share: $share"
        
        # Try anonymous listing first, then with credentials if available
        if timeout 10 smbclient -N -L "//$UNRAID_IP" 2>&1 | grep -qi "$share"; then
            add_result "SMB_$share" "GREEN" "Share visible"
        else
            add_result "SMB_$share" "YELLOW" "Share not visible (may require auth)"
        fi
    done
}

# Test NFS exports
test_nfs_exports() {
    log "Testing NFS exports..."
    
    # Check if showmount is available
    if ! command -v showmount &>/dev/null; then
        add_result "NFS_CLIENT" "YELLOW" "showmount not installed, skipping NFS tests"
        return
    fi
    
    local exports
    if exports=$(timeout 10 showmount -e "$UNRAID_IP" 2>&1); then
        for export in "${NFS_EXPORTS[@]}"; do
            if echo "$exports" | grep -q "$export"; then
                add_result "NFS_$(basename $export)" "GREEN" "Export available"
            else
                add_result "NFS_$(basename $export)" "YELLOW" "Export not found"
            fi
        done
    else
        add_result "NFS_EXPORTS" "YELLOW" "Cannot query NFS exports"
    fi
}

# Test disk I/O performance (if a mount point is available)
test_io_performance() {
    local mount_point="${1:-}"
    
    if [[ -z "$mount_point" || ! -d "$mount_point" ]]; then
        log "No mount point specified or not mounted, skipping I/O tests"
        return
    fi
    
    log "Testing I/O performance on $mount_point..."
    
    local test_file="$mount_point/.nas_health_check_$$"
    local test_size="1M"
    
    # Write test
    local write_start=$(date +%s%N)
    if dd if=/dev/zero of="$test_file" bs="$test_size" count=1 conv=fsync 2>/dev/null; then
        local write_end=$(date +%s%N)
        local write_ms=$(( (write_end - write_start) / 1000000 ))
        
        if (( write_ms > WRITE_LATENCY_CRIT_MS )); then
            add_result "IO_WRITE" "RED" "Write latency ${write_ms}ms exceeds critical threshold" "$write_ms"
        elif (( write_ms > WRITE_LATENCY_WARN_MS )); then
            add_result "IO_WRITE" "YELLOW" "Write latency ${write_ms}ms exceeds warning threshold" "$write_ms"
        else
            add_result "IO_WRITE" "GREEN" "Write latency ${write_ms}ms" "$write_ms"
        fi
        
        # Read test
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        
        local read_start=$(date +%s%N)
        if dd if="$test_file" of=/dev/null bs="$test_size" 2>/dev/null; then
            local read_end=$(date +%s%N)
            local read_ms=$(( (read_end - read_start) / 1000000 ))
            
            if (( read_ms > READ_LATENCY_CRIT_MS )); then
                add_result "IO_READ" "RED" "Read latency ${read_ms}ms exceeds critical threshold" "$read_ms"
            elif (( read_ms > READ_LATENCY_WARN_MS )); then
                add_result "IO_READ" "YELLOW" "Read latency ${read_ms}ms exceeds warning threshold" "$read_ms"
            else
                add_result "IO_READ" "GREEN" "Read latency ${read_ms}ms" "$read_ms"
            fi
        fi
        
        # Cleanup
        rm -f "$test_file" 2>/dev/null || true
    else
        add_result "IO_WRITE" "RED" "Write test failed"
    fi
}

# Test essential ports
test_ports() {
    log "Testing NAS ports..."
    
    local ports=(
        "80:HTTP"
        "443:HTTPS"
        "445:SMB"
        "111:NFS-RPC"
        "2049:NFS"
    )
    
    for port_info in "${ports[@]}"; do
        local port="${port_info%%:*}"
        local service="${port_info##*:}"
        
        if timeout 5 bash -c "echo >/dev/tcp/$UNRAID_IP/$port" 2>/dev/null; then
            add_result "PORT_$service" "GREEN" "Port $port open"
        else
            # SMB and NFS are expected, HTTP is optional
            if [[ "$service" == "SMB" || "$service" == "NFS" ]]; then
                add_result "PORT_$service" "YELLOW" "Port $port closed"
            else
                log "  Port $port ($service) closed (optional)"
            fi
        fi
    done
}

# Main execution
main() {
    log "Starting NAS health check..."
    log "Timestamp: $(date -Iseconds)"
    log "Target: $UNRAID_IP"
    
    echo "====================================" >&2
    echo "  Homelab NAS (Unraid) Health Check" >&2
    echo "====================================" >&2
    echo "" >&2
    
    # Test reachability first
    echo ">> Testing NAS Reachability..." >&2
    if ! test_reachability; then
        echo -e "${RED}✗ NAS unreachable - aborting further tests${NC}" >&2
        OVERALL_STATUS="RED"
    else
        # Continue with other tests
        echo "" >&2
        echo ">> Testing Web Interface..." >&2
        test_web_interface
        
        echo "" >&2
        echo ">> Testing Network Ports..." >&2
        test_ports
        
        echo "" >&2
        echo ">> Testing SMB Shares..." >&2
        test_smb_shares
        
        echo "" >&2
        echo ">> Testing NFS Exports..." >&2
        test_nfs_exports
        
        # I/O test if mount point provided via environment
        if [[ -n "${NAS_MOUNT_POINT:-}" ]]; then
            echo "" >&2
            echo ">> Testing I/O Performance..." >&2
            test_io_performance "$NAS_MOUNT_POINT"
        fi
    fi
    
    # Output results
    echo "" >&2
    echo "====================================" >&2
    
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"target\": \"$UNRAID_IP\","
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
            echo -e "${GREEN}✓ NAS STATUS: GREEN${NC}"
            echo "  All ${#RESULTS[@]} checks passed"
        elif [[ "$OVERALL_STATUS" == "YELLOW" ]]; then
            echo -e "${YELLOW}⚠ NAS STATUS: YELLOW${NC}"
            echo "  Warnings: ${#WARNINGS[@]}"
            for warn in "${WARNINGS[@]}"; do
                echo "    - $warn"
            done
        else
            echo -e "${RED}✗ NAS STATUS: RED${NC}"
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
