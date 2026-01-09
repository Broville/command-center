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
| **Controller** | ash (`10.0.20.10`) - Raspberry Pi 4 |
| **Control Plane API** | `https://10.0.20.11:6443` |
| **Nodes** | 10 (3 control-plane + 7 workers) |
| **CNI** | Cilium |
| **Storage** | Rook-Ceph |

---

## Cluster Nodes

| Node | IP | Role | Hardware |
|------|-----|------|----------|
| ash | `10.0.20.10` | Controller | RPi 4 |
| charmander | `10.0.20.11` | Control Plane | M700 |
| squirtle | `10.0.20.12` | Control Plane | M700 |
| bulbasaur | `10.0.20.13` | Control Plane | M700 |
| pikachu | `10.0.20.14` | Worker | M700 |
| chikorita | `10.0.20.15` | Worker | M700 |
| cyndaquil | `10.0.20.16` | Worker | M700 |
| totodile | `10.0.20.17` | Worker | M700 |
| growlithe | `10.0.20.18` | Worker | M700 |
| arcanine | `10.0.20.19` | Worker (GPU) | M900 + RTX 3090 |
| sprigatito | `10.0.20.20` | Worker (GPU) | M700 + GTX 1650 |

### Raspberry Pi Nodes (VLAN 30)

| Node | IP | Purpose |
|------|----|---------|
| mario | `10.0.30.10` | Additional cluster capacity |
| flareon | `10.0.30.11` | Additional cluster capacity |
| jolteon | `10.0.30.12` | Additional cluster capacity |
| vaporeon | `10.0.30.13` | Additional cluster capacity |
| glaceon | `10.0.30.14` | Additional cluster capacity |

---

## Cluster Services

### Core Infrastructure
- **ArgoCD**: GitOps controller (`argocd` namespace)
- **Cert-Manager**: Certificate management (`cert-manager` namespace)
- **External-Secrets**: Secret management (`external-secrets` namespace)
- **Rook-Ceph**: Distributed storage (`rook-ceph` namespace)
- **Cilium**: CNI and network policies (`kube-system` namespace)
- **NGINX Ingress**: Ingress controller (`ingress-nginx` namespace)

### Platform Services
- **Gitea**: Git hosting (internal)
- **Grafana**: Visualization
- **Prometheus**: Metrics collection
- **Loki**: Log aggregation
- **Renovate**: Dependency updates
- **Cloudflared**: Cloudflare tunnel

### Application Services
- **Emby**: Media server
- **Radarr**: Movie management
- **Sonarr**: TV show management
- **SABnzbd**: Download client
- **Open WebUI**: AI chat interface
- **Ollama**: LLM inference server
- **Qdrant**: Vector database

---

## Storage Configuration

### Rook-Ceph
- **Storage Classes**: `standard-rwo` (block), `standard-rwx` (filesystem)
- **Namespace**: `rook-ceph`
- **Health Command**: `kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health`

### NFS (UNRAID NAS)
- **IP**: `10.0.40.3`
- **Ports**: 111, 2049, 20048

```bash
# Mount NFS share
mount -t nfs 10.0.40.3:/mnt/user/share /mnt/nas

# Mount SMB share
mount -t cifs //10.0.40.3/share /mnt/nas -o username=user
```
