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
    
    # Use temporary files to avoid "Argument list too long" errors
    TMP_NODES=$(mktemp)
    TMP_PODS=$(mktemp)
    TMP_APPS=$(mktemp)
    TMP_CEPH=$(mktemp)
    trap 'rm -f "$TMP_NODES" "$TMP_PODS" "$TMP_APPS" "$TMP_CEPH"' EXIT

    get_nodes > "$TMP_NODES"
    get_pods_unhealthy > "$TMP_PODS"
    get_argocd_apps > "$TMP_APPS"
    get_ceph_health > "$TMP_CEPH"

    jq -n \
      --arg timestamp "$TIMESTAMP" \
      --slurpfile nodes "$TMP_NODES" \
      --slurpfile unhappy_pods "$TMP_PODS" \
      --slurpfile apps "$TMP_APPS" \
      --slurpfile ceph "$TMP_CEPH" \
      '{
        timestamp: $timestamp,
        cluster: {
            nodes: $nodes[0].items | map({name: .metadata.name, status: .status.conditions[-1].type, capacity: .status.capacity}),
            unhealthy_pods: $unhappy_pods[0] | map({namespace: .metadata.namespace, name: .metadata.name, status: .status.phase, reason: .status.containerStatuses[0].state.waiting.reason}),
            apps: $apps[0].items | map({name: .metadata.name, health: .status.health.status, sync: .status.sync.status}),
            ceph: $ceph[0]
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
