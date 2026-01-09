---
description: Homelab infrastructure reference - Table of Contents for all homelab rules
type: reference
applies_to:
  - homelab-troubleshoot
  - homelab-recon
  - homelab-action
sync_locations:
  - ~/.gemini/SUB_RULES/HOMELAB_reference.md
  - ~/.gemini/antigravity/global_workflows/homelab-reference.md
  - ~/.config/opencode/command/homelab-reference.md
sync_note: Master index for homelab rules. References modular sub-rule files.
---

# Homelab Infrastructure Reference

This document serves as the **Table of Contents** for all homelab infrastructure rules and reference documentation.

> [!CAUTION]
> **Foundational Rules Apply**: You MUST follow the rules defined in the linked documents.
> - **ALL GREEN** status required across Metal, System, Platform, and Apps layers.
> - **Zero Tolerance** for issues of any severity.
> - **No Pause** until complete.

---

## 📋 Sub-Rules (Modular References)

| Document | Description |
|----------|-------------|
| [Foundational Rules](HOMELAB_foundational_rules.md) | **ABSOLUTE rules** governing all homelab workflows (Rules 1-7) |
| [Network Reference](HOMELAB_network.md) | Network architecture, VLANs, infrastructure devices |
| [Cluster Reference](HOMELAB_cluster.md) | Kubernetes cluster, nodes, services, storage |
| [Access Reference](HOMELAB_access.md) | SSH, kubectl, external access, troubleshooting |

---

## 🔧 Available Workflows

| Command | Purpose |
|---------|---------|
| `/homelab-recon` | Health check & maintenance report generation |
| `/homelab-action` | Execute maintenance items from recon |
| `/homelab-troubleshoot` | Diagnose and fix issues |
| `/build_charts` | Generate Helm charts for applications |

---

## Quick Validation Commands

```bash
# Quick validation check - ALL must pass for GREEN status
kubectl get nodes | grep -v "Ready"                           # Empty = GREEN
kubectl get pods -n kube-system | grep -v "Running\|Completed" # Empty = GREEN
kubectl get applications -n argocd | grep -v "Synced.*Healthy" # Empty = GREEN
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health # HEALTH_OK = GREEN
```

---

## Key References

| Resource | Location |
|----------|----------|
| **Documentation** | https://homelab.eaglepass.io |
| **Primary Repo** | https://git.eaglepass.io/ops/homelab |
| **GitHub Mirror** | https://github.com/brimdor/homelab |
| **Gitea API Docs** | https://git.eaglepass.io/api/swagger |
| **Gitea Token** | `~/.config/gitea/.env` |

---

*This is the master index. See linked sub-rules for detailed information.*
