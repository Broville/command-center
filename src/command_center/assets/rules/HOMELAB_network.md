---
description: Nelson Network architecture - VLANs, devices, and network topology
type: reference
applies_to:
  - homelab-troubleshoot
  - homelab-recon
  - homelab-action
sync_locations:
  - ~/.gemini/SUB_RULES/HOMELAB_network.md
  - ~/.gemini/antigravity/global_workflows/HOMELAB_network.md
  - ~/.config/opencode/command/HOMELAB_network.md
sync_note: Network infrastructure reference. Update when topology changes.
---

# Network Architecture

The Nelson Network is a segmented VLAN network running a Kubernetes cluster, NAS storage, and various infrastructure services.

```
                    ┌─────────────────┐
                    │    Internet     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   AT&T Modem    │
                    └────────┬────────┘
                             │ WAN
                    ┌────────▼────────┐
                    │    OPNSense     │
                    │    10.0.0.1     │
                    │ (Firewall/Router)│
                    └────────┬────────┘
                             │ LAG (eth1+eth2)
                    ┌────────▼────────┐
                    │  TPLink Switch  │
                    │    10.0.10.2    │
                    │ (24-Port Managed)│
                    └────────┬────────┘
                             │
        ┌──────────┬─────────┼─────────┬──────────┐
        │          │         │         │          │
   ┌────▼────┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
   │ K8s     │ │ Extra │ │  NAS  │ │  IoT  │ │  AP   │
   │ Cluster │ │ (RPi) │ │       │ │       │ │       │
   │ VLAN 20 │ │VLAN 30│ │VLAN 40│ │VLAN 50│ │Trunk  │
   └─────────┘ └───────┘ └───────┘ └───────┘ └───────┘
```

---

## VLAN Configuration

| VLAN | Name | Network | Gateway | Purpose |
|------|------|---------|---------|---------|
| 1 | Native | `10.0.0.0/24` | `10.0.0.1` | Infrastructure only |
| 10 | Management | `10.0.10.0/24` | `10.0.10.1` | Network equipment |
| 20 | Cluster-Prod | `10.0.20.0/24` | `10.0.20.1` | Kubernetes cluster |
| 30 | Cluster-Extra | `10.0.30.0/24` | `10.0.30.1` | Raspberry Pis |

> **Evidence**: VLAN summary and device inventory in `homelab/network/docs/network/vlans.md` and `homelab/network/docs/network/devices.md` confirm these networks, gateways, and purposes.

| 40 | Storage | `10.0.40.0/24` | `10.0.40.1` | NAS traffic |
| 50 | IoT/Wireless | `10.0.50.0/24` | `10.0.50.1` | Wireless/IoT |

> **Evidence**: VLAN summary and device inventory in `homelab/network/docs/network/vlans.md` and `homelab/network/docs/network/devices.md` confirm VLAN 40 (storage/NAS), VLAN 50 (IoT/wireless), and their gateways.

**Inter-VLAN Routing**: Full "God Mode" - all VLANs can communicate with all other VLANs.

---

## Infrastructure Devices

| Device | IP | Type | Notes |
|--------|-----|------|-------|
| OPNSense | `10.0.0.1` | Router/Firewall | Gateway for all VLANs |
| TPLink Switch | `10.0.10.2` | Managed Switch | 24-Port Gigabit |
| TPLink AX5400 | `10.0.10.3` | Access Point | Broadcasts VLAN 50 |
| UNRAID NAS | `10.0.40.3` | NAS Server | Storage + Twingate |

> **Evidence**: Device inventory in `homelab/network/docs/network/devices.md` confirms these infrastructure device IPs, types, and roles.

### Web UIs

| Service | URL | Access |
|---------|-----|--------|
| OPNSense | `https://10.0.0.1` | Any VLAN |
| TPLink Switch | `http://10.0.10.2` | Any VLAN |
| UNRAID NAS | `http://10.0.40.3` | Any VLAN |

> **Evidence**: Management URLs and access scope are documented in `homelab/network/docs/network/devices.md` and the VLAN reference (`homelab/network/docs/network/vlans.md`).
