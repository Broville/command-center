#!/bin/bash
# homelab-recon.sh - Comprehensive Homelab Reconnaissance
# Gathers evidence from all layers: Metal, System, Platform, Apps

set -e

JSON_OUTPUT=false
VERBOSE=false

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --json) JSON_OUTPUT=true ;;
        --verbose) VERBOSE=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1" >&2
    fi
}

error() {
    echo "[ERROR] $1" >&2
}

# Data collection functions
get_nodes() {
    kubectl get nodes -o json
}

get_pods_unhealthy() {
    kubectl get pods -A -o json | jq '[.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded")]'
}

get_argocd_apps() {
    kubectl get applications -n argocd -o json
}

get_ceph_health() {
    if kubectl -n rook-ceph get deploy/rook-ceph-tools &>/dev/null; then
        kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status -f json
    else
        echo '{"status":"unknown", "reason":"rook-ceph-tools not found"}'
    fi
}

# Execution
if [ "$JSON_OUTPUT" = true ]; then
    log "Generating JSON output..."
    NODES=$(get_nodes)
    UNHEALTHY_PODS=$(get_pods_unhealthy)
    APPS=$(get_argocd_apps)
    CEPH=$(get_ceph_health)

    jq -n \
      --arg timestamp "$TIMESTAMP" \
      --argjson nodes "$NODES" \
      --argjson unhappy_pods "$UNHEALTHY_PODS" \
      --argjson apps "$APPS" \
      --argjson ceph "$CEPH" \
      '{
        timestamp: $timestamp,
        cluster: {
            nodes: $nodes.items | map({name: .metadata.name, status: .status.conditions[-1].type, capacity: .status.capacity}),
            unhealthy_pods: $unhappy_pods | map({namespace: .metadata.namespace, name: .metadata.name, status: .status.phase, reason: .status.containerStatuses[0].state.waiting.reason}),
            apps: $apps.items | map({name: .metadata.name, health: .status.health.status, sync: .status.sync.status}),
            ceph: $ceph
        }
      }'
else
    echo "=== HOMELAB RECON SNAPSHOT [$TIMESTAMP] ==="
    echo ""
    echo "--- Metal Layer (Nodes) ---"
    kubectl get nodes -o wide
    echo ""
    echo "--- System Layer (Unhealthy Pods) ---"
    kubectl get pods -A --no-headers | grep -v "Running\|Completed" || echo "ALL GREEN"
    echo ""
    echo "--- Platform Layer (ArgoCD Apps) ---"
    kubectl get applications -n argocd | grep -v "Synced.*Healthy" || echo "ALL GREEN"
    echo ""
    echo "--- Storage Layer (Ceph) ---"
    if kubectl -n rook-ceph get deploy/rook-ceph-tools &>/dev/null; then
        kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status
    else
        echo "Rook-Ceph tools not available."
    fi
fi
