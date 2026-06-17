---
description: Access methods - SSH, kubectl, external access, and troubleshooting
type: reference
applies_to:
  - homelab-troubleshoot
  - homelab-recon
  - homelab-action
sync_locations:
  - ~/.gemini/SUB_RULES/HOMELAB_access.md
  - ~/.gemini/antigravity/global_workflows/HOMELAB_access.md
  - ~/.config/opencode/command/HOMELAB_access.md
sync_note: Access procedures and troubleshooting reference.
---

# Agent Access Guide

> **Evidence**: This access guide reflects the current network and cluster state: ash (`10.0.20.10`) as the SSH jump host, Kubernetes API at `10.0.20.50:6443`, and external/internal application lists from `homelab/network/docs/access/external-access.md`.

## SSH Access

```bash
# Controller (primary entry point)
ssh brimdor@10.0.20.10

# From ash, access kubectl via Nix container
cd ~/homelab && git pull && make tools
# Wait 20-30 seconds for container to load
kubectl get nodes -o wide
```

> **Evidence**: ash is the only SSH jump host documented in the network device inventory (`homelab/network/docs/network/devices.md`) and is not registered as a Kubernetes node (`kubectl get nodes`).

## Direct SSH to Nodes

Direct SSH from workstation is **blocked**. Use Controller as jump host:

1. `ssh brimdor@10.0.20.10` (controller)
2. `cd homelab && make tools`
3. `ssh root@<nodeIP>` (from inside container)

---

## Common kubectl Commands

```bash
# Cluster status
kubectl get nodes -o wide
kubectl cluster-info

# Workload status
kubectl get pods -A
kubectl get deployments -A

# Service discovery
kubectl get svc -A
kubectl get ingress -A

# Logs
kubectl logs -n <namespace> <pod-name>

# Execute commands in pods
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Port forwarding
kubectl port-forward svc/<service> -n <namespace> <local-port>:<remote-port>
```

---

## External Access

### Cloudflare Tunnel

| Property | Value |
|----------|-------|
| Tunnel Name | `homelab` |
| Tunnel Domain | `homelab-tunnel.eaglepass.io` |
| Wildcard | `*.eaglepass.io` |
| Backend | `https://ingress-nginx-controller.ingress-nginx` |

> **Evidence**: Cloudflare Tunnel configuration is documented in `homelab/network/docs/access/external-access.md` and implemented via the `cloudflared` ArgoCD Application in the live cluster.

### External Applications

| App | URL |
|-----|-----|
| Open WebUI | `https://open.eaglepass.io` |
| Emby | `https://emby.eaglepass.io` |
| Emby Health | `https://emby-health.eaglepass.io` |
| HumbleAI | `https://humbleai.eaglepass.io` |
| HumbleAI Canary | `https://humbleai-canary.eaglepass.io` |

> **Evidence**: External app list matches `homelab/network/docs/access/external-access.md`, which is the canonical source for Cloudflare Tunnel-exposed applications. Emby Health and HumbleAI Canary were missing from the original rules list and have been added.

### Internal-Only Applications

| App | URL |
|-----|-----|
| ArgoCD | `https://argocd.eaglepass.io` |
| Radarr | `https://radarr.eaglepass.io` |
| Sonarr | `https://sonarr.eaglepass.io` |
| SABnzbd | `https://sabnzbd.eaglepass.io` |
| SearXNG | `https://searxng.eaglepass.io` |
| LocalAI | `https://localai.eaglepass.io` |

> **Evidence**: Internal app list matches `homelab/network/docs/access/external-access.md`. SearXNG and LocalAI were missing from the original rules list and have been added.

### Making an App Externally Accessible

Add Cloudflare annotations to the Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/target: "homelab-tunnel.eaglepass.io"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
spec:
  rules:
    - host: my-app.eaglepass.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### Remote Access Alternatives

- **Twingate**: NAS at `10.0.40.3` runs Twingate connectors for secure remote access
- **VPN**: OPNSense can be configured with WireGuard or OpenVPN

> **Evidence**: UNRAID NAS IP `10.0.40.3` is documented in `homelab/network/docs/network/devices.md` and `homelab/network/docs/network/vlans.md`; the Twingate service runs on the NAS per `homelab/network/docs/access/external-access.md`.

---

## Troubleshooting Access

### Cannot reach a device
1. Check IP assignment: `ip addr` or `ifconfig`
2. Check gateway: `ip route` - should point to VLAN gateway
3. Ping gateway: `ping 10.0.X.1`
4. Ping destination: `ping <target-ip>`
5. Check OPNSense firewall rules

### SSH connection refused
1. Verify SSH service: `systemctl status sshd`
2. Check firewall: `ufw status` or `iptables -L`
3. Verify correct username and key

### kubectl not working
1. Ensure you're in Nix container: `make tools` from `~/homelab`
2. Check kubeconfig: `ls -la ~/.kube/config` or `echo $KUBECONFIG`
3. Verify API server: `curl -k https://10.0.20.50:6443`
4. Check authentication: Ensure certificates/tokens are valid

> **Evidence**: The control-plane API endpoint is `10.0.20.50:6443` per `kubectl cluster-info`, `~/.kube/config`, and the Ansible inventory `control_plane_endpoint` variable in `homelab/metal/inventories/prod.yml`. The old endpoint `10.0.20.11:6443` is obsolete.

---

## Key References

| Resource | Location |
|----------|----------|
| **Documentation** | https://homelab.eaglepass.io |
| **Primary Repo** | https://git.eaglepass.io/ops/homelab |
| **GitHub Mirror** | https://github.com/brimdor/homelab |
| **Gitea API Docs** | https://git.eaglepass.io/api/swagger |
| **Gitea Token** | `~/.config/gitea/.env` |

> **Evidence**: Repository and documentation URLs are recorded in the canonical homelab access docs (`homelab/network/docs/access/external-access.md`) and the command-center rules index. The Gitea token path is the local convention used by homelab workflows.
