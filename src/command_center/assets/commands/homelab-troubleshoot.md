---
description: Troubleshoot issues across the Homelab Kubernetes cluster
sync_locations:
  - .agent/workflows/homelab-troubleshoot.md
  - .opencode/command/homelab-troubleshoot.md
  - .gemini/commands/homelab-troubleshoot.toml
sync_note: IMPORTANT - This file must be kept in sync across all locations. When making changes, update ALL files.
---

> [!CAUTION]
> ## ⚡ EXECUTION IMPERATIVE
> **DO NOT ASK FOR CONFIRMATION. DO NOT ASK IF YOU SHOULD START.**
>
> Receiving this command is the authorization. BEGIN STEP 1 IMMEDIATELY.
>
> The moment you receive `/homelab-troubleshoot`, you MUST:
> 1. **START** executing Step 1 pre-flight checklist
> 2. **CONTINUE** through all steps until all layers are GREEN
> 3. **ONLY STOP** when ALL completion criteria are satisfied
>
> There is no "Should I proceed?" - the answer is always YES. Proceed.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

The text the user typed after the command **is** their priority input - it may specify:
- The specific issue or symptom to troubleshoot
- A specific service, pod, or namespace having problems
- Error messages or symptoms observed
- Any special instructions or constraints

---

# Homelab Troubleshooting Workflow

## Overview

This workflow GUIDES you through troubleshooting issues across the Homelab Kubernetes infrastructure. EXECUTE all steps until ALL layers are GREEN.

> [!IMPORTANT]
> **Sync Requirement**: This workflow exists in multiple locations that must stay synchronized:
> - `.agent/workflows/homelab-troubleshoot.md`
> - `.opencode/command/homelab-troubleshoot.md`
> - `.gemini/commands/homelab-troubleshoot.toml`
> 
> When updating this file, **COPY changes to all locations**.

> [!CAUTION]
> **Acceptance Criteria**: Troubleshooting is NOT complete until **ALL layers are GREEN** with **ZERO issues**:
> - **Metal Layer**: All nodes `Ready`, no resource pressure
> - **System Layer**: Ceph `HEALTH_OK` (no warnings, no errors), all kube-system pods `Running`
> - **Platform Layer**: All ArgoCD applications `Synced` AND `Healthy`
> - **Apps Layer**: All application pods `Running`, no `CrashLoopBackOff`, no `Error` states
> - **Overall Status**: GREEN across all layers
>
> **ZERO tolerance for issues of ANY severity level:**
> - No CRITICAL issues
> - No HIGH priority issues
> - No MEDIUM priority issues
> - No LOW priority issues
>
> **Partial success is NOT acceptable.** A single warning (e.g., Ceph `HEALTH_WARN`), a single unhealthy app, or even a low-priority issue means troubleshooting must continue until fully resolved.

## References

- **Documentation**: https://homelab.eaglepass.io
- **Primary Repo**: https://git.eaglepass.io/ops/homelab
- **Fallback Repo**: https://github.com/brimdor/homelab (auto-synced from primary)

## Prerequisites

### 1. VERIFY Local Tools Are Up-to-Date

BEFORE STARTING, VERIFY all local tools are current and functional.

### 2. ESTABLISH Access Priority

EXECUTE access in this priority order:

1. **PRIMARY**: USE the local system for all work
2. **FALLBACK**: USE controller only when local access to Kubernetes cluster is unavailable
   - SSH: `ssh brimdor@10.0.20.10`
   - Homelab files: `~/homelab`

### 3. EXECUTE Controller Access (Fallback Only)

IF local access is unavailable, EXECUTE these commands:

```bash
# CONNECT to controller
ssh brimdor@10.0.20.10

# NAVIGATE to homelab directory
cd ~/homelab

# GET latest code (RUN every time you connect for the day)
git pull

# START the tools container
make tools
```

## Cluster Architecture

- **Kubernetes Distribution**: K3s
- **GitOps**: ArgoCD (manages application deployments)
- **CNI**: Cilium (network connectivity and policies)
- **Storage**: Rook Ceph (persistent volumes)
- **Ingress**: NGINX Ingress Controller (external access)
- **Monitoring**: Prometheus + Grafana + Loki (metrics and logs)
- **External DNS**: Manages DNS records for services
- **Cert Manager**: Manages TLS certificates
- **External Secrets**: Manages secrets from external sources

## Cluster Organization

The homelab is organized into several key directories:

### 1. system/ - Core Cluster Infrastructure
- `argocd/` - GitOps controller
- `cert-manager/` - Certificate management
- `cloudflared/` - Cloudflare tunnel
- `connect/` - Tailscale/connectivity services
- `external-dns/` - DNS management
- `gpu-operator/` - GPU support
- `ingress-nginx/` - Ingress controller
- `kured/` - Node reboot manager
- `loki/` - Log aggregation
- `monitoring-system/` - Prometheus/Grafana
- `rook-ceph/` - Storage provider
- `volsync-system/` - Volume synchronization

### 2. platform/ - Platform Services
- `dex/` - Identity provider
- `external-secrets/` - Secret management
- `gitea/` - Git hosting
- `global-secrets/` - Cluster-wide secrets
- `grafana/` - Visualization
- `kanidm/` - Identity management
- `renovate/` - Dependency updates
- `woodpecker/` - CI/CD
- `zot/` - Container registry

### 3. apps/ - User Applications

> [!NOTE]
> The apps directory is **dynamic** - applications are added and removed frequently.
> To discover current applications, EXECUTE: `ls ~/Documents/GitHub/homelab/apps/`

Applications include media services, AI/ML workloads, productivity tools, databases, and more.
Each app has its own directory containing Kubernetes manifests managed by ArgoCD.

### 4. metal/ - Bare Metal Provisioning
- Ansible playbooks for cluster setup (`cluster.yml`, `nodes.yml`, `boot.yml`)
- Node configuration (`group_vars/`, `inventories/`)
- K3s installation and management
- Roles for provisioning (`roles/`)

### 5. external/ - External Resources (Terraform)
- Cloudflare configuration
- External service setup
- Terraform modules (`modules/`)
- Namespace management (`namespaces.yml`)

## Available Helper Scripts

Located in `scripts/` directory:

| Script | Description |
|--------|-------------|
| `get-status` | GET overall cluster status |
| `argocd-admin-password` | RETRIEVE ArgoCD admin password |
| `get-dns-config` | CHECK DNS configuration |
| `get-wireguard-config` | GET VPN config |
| `kanidm-reset-password` | RESET identity management passwords |
| `helm-diff` | COMPARE Helm chart changes |
| `error_check` | CHECK for common errors |
| `configure` | CONFIGURE cluster components |
| `new-service` | SCAFFOLD new service |
| `onboard-user` | ADD new user |
| `spin_up` / `spin_down` | MANAGE cluster power state |
| `pxe-logs` | CHECK PXE boot logs |
| `take-screenshots` | CAPTURE service screenshots |

## Compatible Tools

| Tool | Purpose |
|------|---------|
| `kubectl` | Kubernetes CLI (required) |
| `helm` | Kubernetes package manager (required) |
| `kustomize` | Kubernetes configuration management |
| `k9s` | Terminal UI for Kubernetes |
| `argocd` | ArgoCD CLI (for GitOps management) |
| `cilium` | Cilium CLI (for network troubleshooting) |
| `ceph` | Ceph storage CLI (for storage issues) |
| `terraform` | Infrastructure as code (for external resources) |
| `ansible` | Configuration management (for bare metal) |

## Key Namespaces

| Namespace | Purpose |
|-----------|---------|
| `argocd` | GitOps controller |
| `cert-manager` | Certificate management |
| `rook-ceph` | Storage system |
| `ingress-nginx` | Ingress controller |
| `monitoring-system` | Monitoring stack |
| `external-secrets` | Secret management |
| `gitea` | Git hosting |
| `platform-*` | Platform services |

---

## Troubleshooting Steps

### Step 1: EXECUTE Pre-flight Checklist

BEFORE diving deep, EXECUTE these commands to verify basics:

```bash
# 1. VERIFY cluster is reachable
kubectl cluster-info

# 2. CHECK nodes are healthy
kubectl get nodes

# 3. VERIFY core system pods are running
kubectl get pods -n kube-system

# 4. CHECK ArgoCD is operational
kubectl get pods -n argocd

# 5. VERIFY storage is healthy
kubectl get cephcluster -n rook-ceph

# 6. CHECK network is functional (if available)
cilium status

# 7. CHECK for critical events
kubectl get events -A | grep -i error
```

**ALL checks MUST pass before proceeding to Step 2.**

### Step 2: IDENTIFY the Issue Category

DETERMINE the category of issue and EXECUTE the appropriate diagnostic commands:

#### Application Issues

EXECUTE these commands to diagnose application issues:

```bash
# CHECK ArgoCD application status
kubectl get applications -n argocd

# CHECK pod status
kubectl get pods -n <namespace>

# VIEW pod logs
kubectl logs -n <namespace> <pod-name>

# CHECK events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# VERIFY ingress
kubectl get ingress -n <namespace>

# CHECK secrets
kubectl get secrets -n <namespace>
```

#### Network Issues

EXECUTE these commands to diagnose network issues:

```bash
# CHECK Cilium status
cilium status

# RUN Network Health Check Script (Recommended) -- SELECT ONE:
~/.gemini/scripts/homelab-network-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --verbose  # Opencode

# TEST connectivity
cilium connectivity test

# CHECK network policies
kubectl get networkpolicies -A

# VERIFY DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# CHECK ingress controller
kubectl get pods -n ingress-nginx
```

#### Storage Issues

EXECUTE these commands to diagnose storage issues:

```bash
# CHECK Ceph cluster health
kubectl get cephcluster -n rook-ceph

# RUN NAS Health Check Script (Recommended) -- SELECT ONE:
~/.gemini/scripts/homelab-nas-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-nas-check.sh --verbose  # Opencode

# VIEW PVC status
kubectl get pvc -A

# CHECK storage classes
kubectl get storageclass
```

#### GitOps Issues

EXECUTE these commands to diagnose GitOps issues:

```bash
# CHECK ArgoCD sync status
argocd app list

# FORCE sync
argocd app sync <app-name>

# VIEW sync logs
argocd app logs <app-name>

# CHECK ArgoCD health
kubectl get pods -n argocd
```

#### Certificate Issues

EXECUTE these commands to diagnose certificate issues:

```bash
# CHECK cert-manager
kubectl get certificates -A

# VIEW certificate requests
kubectl get certificaterequests -A

# CHECK issuers
kubectl get clusterissuers

# REVIEW cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager
```

#### Monitoring & Logging

EXECUTE these commands to access monitoring:

```bash
# QUERY Prometheus
kubectl port-forward -n monitoring-system svc/prometheus 9090:9090

# CHECK monitoring pods
kubectl get pods -n monitoring-system
```

### Step 3: GATHER Debug Information

When troubleshooting, COLLECT the following evidence:

- **CAPTURE** pod status and descriptions
- **RETRIEVE** container logs (current and previous if crashed)
- **EXAMINE** events in relevant namespaces
- **CHECK** resource usage (CPU/Memory)
- **TEST** network connectivity
- **VERIFY** storage health and PVC bindings
- **INSPECT** ingress and service configurations
- **CONFIRM** certificate status
- **REVIEW** ArgoCD application sync status
- **EXAMINE** recent changes from git history

### Step 4: RESOLVE and DOCUMENT

EXECUTE these steps in order:

1. **APPLY** the fix
2. **VERIFY** the solution works
3. **DOCUMENT** findings if significant
4. **CREATE** an issue for recurring problems at https://git.eaglepass.io/ops/homelab/issues

### Step 5: VALIDATE ALL Layers Are GREEN

> [!CAUTION]
> **Do NOT consider troubleshooting complete until ALL checks pass.**

EXECUTE the following validation checks and ENSURE **every single one** returns GREEN status:

#### EXECUTE Metal Layer Validation

```bash
# All nodes must be Ready (no NotReady, no SchedulingDisabled)
kubectl get nodes
# Expected: All nodes show STATUS=Ready

# No resource pressure on any node
kubectl describe nodes | grep -E "Pressure|Taint"
# Expected: No MemoryPressure, DiskPressure, or PIDPressure
```

#### EXECUTE Network Layer Validation

```bash
# RUN Network Health Check Script -- SELECT ONE:
~/.gemini/scripts/homelab-network-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --verbose  # Opencode
# Expected: All VLANs reachable, Latency <50ms (Exit Code 0)
```

#### EXECUTE Storage (NAS) Layer Validation

```bash
# RUN NAS Health Check Script -- SELECT ONE:
~/.gemini/scripts/homelab-nas-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-nas-check.sh --verbose  # Opencode
# Expected: Unraid reachable, shares accessible (Exit Code 0)
```

#### EXECUTE System Layer Validation

```bash
# Ceph must be HEALTH_OK (not HEALTH_WARN, not HEALTH_ERR)
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph health
# Expected: HEALTH_OK (anything else = NOT GREEN)

# Detailed Ceph check - must have no warnings
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph health detail
# Expected: No output (empty = healthy)

# All kube-system pods Running
kubectl get pods -n kube-system | grep -v "Running\|Completed"
# Expected: No output (all pods Running or Completed)
```

#### EXECUTE Platform Layer Validation

```bash
# ALL ArgoCD applications must be Synced AND Healthy
kubectl get applications -n argocd | grep -v "Synced.*Healthy"
# Expected: Only the header line (all apps Synced/Healthy)

# Specific check for any OutOfSync or Degraded apps
kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.sync.status != "Synced" or .status.health.status != "Healthy") | .metadata.name'
# Expected: No output
```

#### EXECUTE Apps Layer Validation

```bash
# No pods in error states across all namespaces
kubectl get pods -A | grep -E "Error|CrashLoopBackOff|ImagePullBackOff|Pending|Failed"
# Expected: No output (or only expected transient states)

# Check for recent warning events
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' | tail -20
# Expected: No recent critical warnings
```

#### GREEN Status Criteria Summary

| Layer | Check | GREEN Criteria | RED Criteria |
|-------|-------|----------------|--------------|
| **Metal** | `kubectl get nodes` | All `Ready` | Any `NotReady` |
| **Network** | `homelab-network-check.sh` (see below) | All VLANs reachable, latency <50ms | Unreachable or >100ms |
| **Storage (NAS)** | `homelab-nas-check.sh` (see below) | Unraid reachable, shares accessible | Unreachable |
| **System** | `ceph health` | `HEALTH_OK` | `HEALTH_WARN` or `HEALTH_ERR` |
| **System** | kube-system pods | All `Running` | Any `CrashLoopBackOff`, `Error` |
| **Platform** | ArgoCD apps | All `Synced` + `Healthy` | Any `OutOfSync` or `Degraded` |
| **Apps** | All pods | All `Running` | Any `Error`, `CrashLoopBackOff` |

> [!WARNING]
> **Zero Issue Tolerance**: ALL issues must be resolved regardless of severity:
> | Severity | Action Required |
> |----------|-----------------|
> | CRITICAL | RESOLVE immediately |
> | HIGH | RESOLVE before completion |
> | MEDIUM | RESOLVE before completion |
> | LOW | RESOLVE before completion |
>
> There is no "acceptable" level of issues. Even LOW priority items block successful completion.

**IF ANY check fails or ANY issue remains (from LOW to CRITICAL), troubleshooting MUST continue.** Do NOT close issues or report success until all layers are GREEN and all issues are resolved.

### Step 6: GENERATE Completion Report

> [!IMPORTANT]
> **Reporting Requirement**: You MUST output a final summary report in the EXACT format defined in the template.
>
> **Template Location**:
> - Antigravity: `~/.gemini/templates/homelab-troubleshoot-report.md`
> - Opencode: `~/.config/opencode/templates/homelab-troubleshoot-report.md`

1. **READ** the template file from the appropriate location above.
2. **GENERATE** the Markdown report exactly matching the template structure.
3. **OUTPUT** the report at the very end of your response.

---

## Execution Checklist

COMPLETE all items before considering troubleshooting finished:

- [ ] COMPLETE Step 1: EXECUTE pre-flight checklist, ALL checks pass
- [ ] COMPLETE Step 2: IDENTIFY issue category, EXECUTE diagnostic commands
- [ ] COMPLETE Step 3: GATHER debug information, COLLECT all evidence
- [ ] COMPLETE Step 4: APPLY fix, VERIFY solution, DOCUMENT findings
- [ ] COMPLETE Step 5: VALIDATE all layers are GREEN
- [ ] CONFIRM Metal Layer: All nodes `Ready`, no resource pressure
- [ ] CONFIRM Network Layer: All VLANs reachable, latency <50ms
- [ ] CONFIRM Storage Layer: Unraid reachable, shares accessible
- [ ] CONFIRM System Layer: Ceph `HEALTH_OK`, all kube-system pods `Running`
- [ ] CONFIRM Platform Layer: All ArgoCD apps `Synced` AND `Healthy`
- [ ] CONFIRM Apps Layer: All pods `Running`, no error states
- [ ] CONFIRM Overall Status: **GREEN**
- [ ] COMPLETE Step 6: GENERATE completion report in the required format

---

## MCP Tool Integration (Primary Method)

USE the available **Gitea** and **GitHub** MCP tools for all repository interactions. These are safer, more robust, and preferred over direct API calls.

### Priority Order

1. **Gitea MCP**: USE for all operations on the primary repository (`ops/homelab`)
2. **GitHub MCP**: USE as a fallback for GitHub-hosted mirrors or if Gitea MCP is unavailable
3. **API Fallback**: USE raw `curl` commands (detailed below) **ONLY** if MCP tools are non-functional

### Common MCP Operations

- **List Issues**: USE `gitea_list_repo_issues` (Gitea) or `list_issues` (GitHub)
- **Create Issue**: USE `gitea_create_issue` (Gitea) or `create_issue` (GitHub)
- **Add Comment**: USE `gitea_create_issue_comment` (Gitea) or `add_issue_comment` (GitHub)
- **List PRs**: USE `gitea_list_repo_pull_requests` (Gitea) or `list_pull_requests` (GitHub)
- **Get Repo Info**: USE `gitea_search_repos` (Gitea) or `search_repositories` (GitHub)

---

## 1Password Secret Management

USE the 1Password CLI (`op`) to manage application secrets directly from the terminal.

### Vault Information
- **Vault Name**: `Server`
- **Item Naming Convention**: `<app-name> Secrets`
- **Category**: `Database`

### EXECUTE Check Existing Secrets
```bash
# CHECK if secrets exist for an app
op item get --vault "Server" "<app-name> Secrets"
```

### EXECUTE Create or Update Secrets

USE this command block to create or update secrets for an application. REPLACE `<app-name>` and DEFINE the secret variables before running.

```bash
# CONFIGURE the secret details
app_name="<app-name>"

# BUILD the payload (EDIT labels and values as needed)
payload=$(cat <<JSON
{
  "title": "${app_name} Secrets",
  "category": "DATABASE",
  "fields": [
    {"label": "api-key", "value": "secret-value-1", "type": "CONCEALED"},
    {"label": "another-secret", "value": "secret-value-2", "type": "CONCEALED"}
  ]
}
JSON
)

# CREATE or UPDATE in 'Server' vault
if op item get --vault "Server" "${app_name} Secrets" >/dev/null 2>&1; then
  echo "$payload" | op item edit --vault "Server" "${app_name} Secrets" -
else
  echo "$payload" | op item create --vault "Server" -
fi
```

---

## Gitea API Fallback (Emergency Only)

> [!WARNING]
> USE the following API commands ONLY if the MCP tools above are failing or unavailable.

For automated repo, issue, and PR operations without MCP, USE the Gitea API with the stored token.

### Token Location
```bash
# Token files are stored at:
~/.config/gitea/.env        # For bash/zsh
~/.config/gitea/gitea.fish  # For fish shell

# LOAD token in fish shell:
source ~/.config/gitea/gitea.fish

# LOAD token in bash/zsh:
source ~/.config/gitea/.env

# Environment variables available after sourcing:
# GITEA_TOKEN - API access token
# GITEA_URL   - Base URL (https://git.eaglepass.io)
```

### API Base URL
```
https://git.eaglepass.io/api/v1
```

### Common API Operations

#### EXECUTE List Issues
```bash
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues" \
  -H "Authorization: token $GITEA_TOKEN"
```

#### EXECUTE Create Issue
```bash
curl -s -X POST "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Issue Title", "body": "Issue description"}'
```

#### EXECUTE Add Comment to Issue
```bash
curl -s -X POST "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}/comments" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": "Comment text"}'
```

#### EXECUTE List Pull Requests
```bash
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls" \
  -H "Authorization: token $GITEA_TOKEN"
```

#### EXECUTE Get Repository Info
```bash
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab" \
  -H "Authorization: token $GITEA_TOKEN"
```

### API Documentation
Full API documentation: https://git.eaglepass.io/api/swagger

---

## Completion Criteria

**This workflow is COMPLETE when ALL of the following are TRUE:**

1. ✅ Pre-flight checklist passes (all systems reachable)
2. ✅ Issue category identified and diagnosed
3. ✅ Fix applied and verified
4. ✅ **Metal Layer**: GREEN - All nodes `Ready`, no resource pressure
5. ✅ **Network Layer**: GREEN - All VLANs reachable, latency <50ms, OPNSense up
6. ✅ **Storage (NAS) Layer**: GREEN - Unraid reachable, shares accessible
7. ✅ **System Layer**: GREEN - Ceph `HEALTH_OK`, all kube-system pods `Running`
8. ✅ **Platform Layer**: GREEN - All ArgoCD apps `Synced` AND `Healthy`
9. ✅ **Apps Layer**: GREEN - All pods `Running`, no error states
10. ✅ **Overall Status**: GREEN across all layers
11. ✅ **Final Report**: Generated and verified against the template
12. ✅ ZERO issues remaining (CRITICAL through LOW)

> [!CAUTION]
> **DO NOT STOP UNTIL ALL CRITERIA ARE MET.**

---

## Mandatory Rules

These rules are NON-NEGOTIABLE:

1. **EXECUTE one fix at a time, VERIFY before proceeding**
2. **ALWAYS validate ALL layers after each significant change**
3. **NEVER consider work complete until ALL layers are GREEN**
4. **ZERO tolerance for issues - resolve ALL severities (CRITICAL to LOW)**
5. **DOCUMENT findings for recurring problems**
6. **USE MCP tools as primary method, API as fallback only**
7. **IF in doubt, GATHER more evidence before applying fixes**
