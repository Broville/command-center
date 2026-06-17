---
description: Kubernetes cluster configuration - nodes, services, and storage
type: reference
applies_to:
  - homelab-troubleshoot
  - homelab-recon
  - homelab-action
sync_locations:
  - ~/.gemini/SUB_RULES/HOMELAB_cluster.md
  - ~/.gemini/antigravity/global_workflows/HOMELAB_cluster.md
  - ~/.config/opencode/command/HOMELAB_cluster.md
sync_note: Cluster infrastructure reference. Update when nodes or services change.
---

# Kubernetes Cluster

| Property | Value |
|----------|-------|
| **Distribution** | K3s |
| **Controller** | ash (`10.0.20.10`) - Raspberry Pi 4; management/jump host (not a K8s node) |
| **Control Plane API** | `https://10.0.20.50:6443` |
| **Nodes** | 9 (3 control-plane + 6 workers) |
| **CNI** | Cilium |
| **Storage** | Rook-Ceph |

> **Evidence**: Live cluster inventory (`kubectl get nodes -o wide`) and Ansible inventory `homelab/metal/inventories/prod.yml` list 9 active Kubernetes nodes; `kubectl cluster-info` and `~/.kube/config` confirm the control-plane API endpoint is `10.0.20.50:6443`. ash is the SSH jump host and is not registered as a Kubernetes node.

---

## Cluster Nodes

| Node | IP | Role | Hardware |
|------|-----|------|----------|
| charmander | `10.0.20.11` | Control Plane | M700 |
| squirtle | `10.0.20.12` | Control Plane | M700 |
| bulbasaur | `10.0.20.13` | Control Plane | M700 |
| pikachu | `10.0.20.14` | Worker | M700 |
| cyndaquil | `10.0.20.16` | Worker | M700 |
| totodile | `10.0.20.17` | Worker | M700 |
| growlithe | `10.0.20.18` | Worker | M700 |
| arcanine | `10.0.20.19` | Worker (GPU) | M900 + RTX 3090 |
| sprigatito | `10.0.20.20` | Worker (GPU) | M700 + GTX 1650 |

> **Evidence**: `kubectl get nodes -o wide` returns 9 Ready nodes; `homelab/metal/inventories/prod.yml` defines the same 9 nodes with no `chikorita` entry. chikorita (`10.0.20.15`) was decommissioned on 2026-06-06 per Ansible inventory commit `36b293587d2c04b631be4bc64894367f07ad93fb` and is absent from live `kubectl get nodes` output. A ghost entry remains in the Rook-Ceph CRUSH map (`ceph osd tree` shows host `chikorita` with `osd.0` down and weight 0) and should not be treated as an active cluster node.

### Raspberry Pi Nodes (VLAN 30)

| Node | IP | Purpose |
|------|----|---------|
| mario | `10.0.30.10` | Additional cluster capacity |
| luigi | `10.0.30.11` | Additional cluster capacity |
| toad | `10.0.30.12` | Additional cluster capacity |
| yoshi | `10.0.30.13` | Additional cluster capacity |
| peach | `10.0.30.14` | Additional cluster capacity |
| star | `10.0.30.15` | Additional cluster capacity |

> **Evidence**: Canonical homelab network docs (`homelab/network/docs/network/devices.md`) list six VLAN-30 Raspberry Pi nodes as mario/luigi/toad/yoshi/peach/star on `10.0.30.10-15`. Earlier names (flareon/jolteon/vaporeon/glaceon) were out of date and have been replaced.

---

## Cluster Services

### Core Infrastructure
- **ArgoCD**: GitOps controller (`argocd` namespace)
- **Cert-Manager**: Certificate management (`cert-manager` namespace)
- **External-Secrets**: Secret management (`external-secrets` namespace)
- **Rook-Ceph**: Distributed storage (`rook-ceph` namespace)
- **Cilium**: CNI and network policies (`kube-system` namespace)
- **NGINX Ingress**: Ingress controller (`ingress-nginx` namespace)

> **Evidence**: `kubectl get applications -n argocd` returns 60 ArgoCD Applications spanning these infrastructure components. No standalone `ollama`, `prometheus`, or `cilium` Application exists at the top level; Cilium is part of the kube-system/system stack, Prometheus is part of the observability stack, and Ollama is not deployed as a named Application.

### Platform Services
- **Gitea**: Git hosting (internal)
- **Grafana**: Visualization
- **Prometheus**: Metrics collection
- **Loki**: Log aggregation
- **Renovate**: Dependency updates
- **Cloudflared**: Cloudflare tunnel

> **Evidence**: These platform services are exposed as ArgoCD Applications in the live cluster (`kubectl get applications -n argocd`) and are documented in the canonical access docs (`homelab/network/docs/access/external-access.md`).

### Application Services
- **Emby**: Media server
- **Radarr**: Movie management
- **Sonarr**: TV show management
- **SABnzbd**: Download client
- **Open WebUI**: AI chat interface
- **HumbleAI**: AI application
- **HumbleAI Canary**: AI application (canary)
- **Llama**: LLM service
- **Qdrant**: Vector database
- **SearXNG**: Metasearch engine
- **LocalAI**: Local AI inference

> **Evidence**: `kubectl get applications -n argocd` lists 60 Applications including emby, radarr, sonarr, sabnzbd, open-webui, humbleai, humbleai-canary, llama, qdrant, searxng, and localai. No `ollama` ArgoCD Application exists, so the historical Ollama bullet has been removed; the HumbleAI/Llama apps now provide LLM/AI inference.

---

## Storage Configuration

### Rook-Ceph
- **Storage Classes**: `standard-rwo` (block), `standard-rwx` (filesystem)
- **Namespace**: `rook-ceph`
- **Health Command**: `kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health`

> **Evidence**: `kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health` reports `HEALTH_OK` (cluster is functional with 5 of 6 OSDs up). The decommissioned node chikorita still appears as a ghost CRUSH host with `osd.0` down/weight 0; this is expected post-decommission state and does not affect overall Ceph health.

### NFS (UNRAID NAS)
- **IP**: `10.0.40.3`
- **Ports**: 111, 2049, 20048

> **Evidence**: Network device inventory (`homelab/network/docs/network/devices.md`) and VLAN docs (`homelab/network/docs/network/vlans.md`) identify the UNRAID NAS at `10.0.40.3` on VLAN 40.

```bash
# Mount NFS share
mount -t nfs 10.0.40.3:/mnt/user/share /mnt/nas

# Mount SMB share
mount -t cifs //10.0.40.3/share /mnt/nas -o username=user
```
