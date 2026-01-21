# Maintenance Issue Template

> [!IMPORTANT]
> This template defines the **exact structure** for all maintenance issues.
> The AI Model MUST follow this template precisely when creating or updating maintenance issues.

---

## Template Usage Rules

1. **CHECK FIRST**: Before creating a new issue, QUERY for open issues with label `maintenance`
2. **UPDATE IF EXISTS**: If an open maintenance issue exists, EDIT its body (do NOT add comments)
3. **CREATE IF NONE**: Only create a new issue if no open maintenance issue exists
4. **FOLLOW EXACTLY**: Use this exact structure - do not deviate

---

## Issue Title Format

```
[Maintenance] YYYY-MM-DD - Homelab
```

When resolved, prepend `[RESOLVED]`:
```
[RESOLVED] [Maintenance] YYYY-MM-DD - Homelab
```

---

## Issue Body Template

```markdown
# [Maintenance] YYYY-MM-DD - Homelab

## Status

| Field | Value |
|-------|-------|
| **Overall Status** | 🔴 RED / 🟡 YELLOW / 🟢 GREEN |
| **Last Updated** | YYYY-MM-DD HH:MM TZ |
| **Source Report** | `reports/status-report-YYYY-MM-DD.md` |
| **Assigned To** | gitea_admin |

---

## Context Pack

### Cluster Identity
| Component | Value |
|-----------|-------|
| K3s Version | vX.Y.Z |
| Node Count | X |
| ArgoCD Apps | X total |
| Ceph Status | HEALTH_OK / HEALTH_WARN / HEALTH_ERR |

### Current Health Evidence (Snapshot)
| Layer | Status | Summary |
|-------|:------:|---------|
| **Metal** | 🟢/🟡/🔴 | X/Y nodes Ready |
| **Network** | 🟢/🟡/🔴 | VLANs reachable, latency Xms, OPNSense up |
| **Storage (NAS)** | 🟢/🟡/🔴 | Unraid reachable, shares accessible, R/W OK |
| **System** | 🟢/🟡/🔴 | Ceph: [status], kube-system: X pods |
| **Platform** | 🟢/🟡/🔴 | ArgoCD: X/Y Synced+Healthy |
| **Apps** | 🟢/🟡/🔴 | X non-running pods |

### Non-Running Pods (if any)
| Namespace | Pod | Status | Age |
|-----------|-----|--------|-----|
| ... | ... | ... | ... |

### Repo Inventory (Actionable)
| Category | Count | Details |
|----------|:-----:|---------|
| Open Renovate PRs | X | List PR numbers |
| Open User PRs | X | List PR numbers |
| Open Non-Maintenance Issues | X | List issue numbers |

---

## Proposed Changes (Spec)

> All changes identified from evidence, with reasoning and risk assessment.

| ID | Type | Layer | Priority | Impact | Downtime | Summary | Dependencies |
|:--:|------|:-----:|:--------:|:------:|:--------:|---------|:------------:|
| C1 | Fix | System | P0 | HIGH | None | Archive Ceph crashes | None |
| C2 | PR | Apps | P2 | LOW | None | Merge PR #X | None |
| C3 | Upgrade | Platform | P1 | MEDIUM | 2min | Upgrade ArgoCD | C1 |

### Priority Legend
- **P0**: CRITICAL - Do immediately
- **P1**: HIGH - Do before completion
- **P2**: MEDIUM - Schedule appropriately
- **P3**: LOW - Nice to have

### Impact Legend
- **HIGH**: Core functionality, data risk, security
- **MEDIUM**: Degraded performance, warnings
- **LOW**: Cosmetic, minor improvements

### Downtime Legend
- **None**: No service interruption
- **Xmin**: Expected disruption duration
- **Window**: Requires maintenance window

---

## Execution Plan

### Ordering Rules Applied
1. Priority: P0 → P1 → P2 → P3
2. Layer: Metal → Network → Storage → System → Platform → Apps
3. Dependencies: Complete prerequisites before dependent items
4. Databases: Always last within a priority level

### Validation Gate (Run After EVERY Change)
```bash
# Metal
kubectl get nodes | grep -v "Ready" || true

# Network (run health check script)
homelab-network-check.sh --json || true

# Storage/NAS (run health check script)
homelab-nas-check.sh --json || true

# System
kubectl get pods -n kube-system | grep -v "Running\|Completed" || true
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health

# Platform
kubectl get applications -n argocd | grep -v "Synced.*Healthy" || true

# Apps
kubectl get pods -A --no-headers | grep -v "Running\|Completed" || true
```

### Stop Conditions
- ❌ Any validation check fails
- ❌ Unknown rollback procedure
- ❌ Human escalation required

---

## Action Items (Tasks)

> **RULES**:
> - ALL executable steps are top-level `- [ ]` checkboxes
> - Each checkbox is ATOMIC (one action + one verification)
> - Ordered by: Priority → Layer → Dependencies
> - Each includes: Goal, Commands, Expected, If-fails, Rollback

### Phase A: Preflight
- [ ] **A1 P0** Preflight: Verify access (kubectl/controller/gitea)
  - **Goal**: Confirm all access methods work
  - **Commands**: `kubectl cluster-info`, `ssh brimdor@10.0.20.10 "echo ok"`, Gitea API test
  - **Expected**: All commands succeed
  - **If fails**: Document which access failed, troubleshoot before proceeding
  - **Rollback**: N/A

- [ ] **A2 P0** Preflight: Capture baseline snapshot
  - **Goal**: Record current state before changes
  - **Commands**: `kubectl get nodes`, `ceph status`, `kubectl get applications -n argocd`
  - **Expected**: Output captured to report
  - **If fails**: Re-run failed commands
  - **Rollback**: N/A

### Phase B: Remediate Critical Findings (P0)
- [ ] **B1 P0 System**: [Specific remediation task]
  - **Goal**: [What this achieves]
  - **Commands**: [Exact commands to run]
  - **Expected**: [Success criteria]
  - **If fails**: [Next diagnostic steps]
  - **Rollback**: [Exact rollback commands or "N/A"]

### Phase C: High Priority Items (P1)
- [ ] **C1 P1 [Layer]**: [Task description]
  - **Goal**: ...
  - **Commands**: ...
  - **Expected**: ...
  - **If fails**: ...
  - **Rollback**: ...

### Phase D: Medium Priority Items (P2)
- [ ] **D1 P2 [Layer]**: [Task description]
  - **Goal**: ...
  - **Commands**: ...
  - **Expected**: ...
  - **If fails**: ...
  - **Rollback**: ...

### Phase E: Low Priority Items (P3)
- [ ] **E1 P3 [Layer]**: [Task description]
  - **Goal**: ...
  - **Commands**: ...
  - **Expected**: ...
  - **If fails**: ...
  - **Rollback**: ...

### Phase F: Final Validation
- [ ] **F1 P0** Run `/homelab-recon` for final validation
  - **Goal**: Confirm all layers GREEN
  - **Commands**: Execute homelab-recon workflow
  - **Expected**: All layers GREEN, no new findings
  - **If fails**: Return to appropriate phase
  - **Rollback**: N/A

---

## Change Log

| Timestamp | Phase | Item | Action | Result | Status After |
|-----------|:-----:|------|--------|--------|:------------:|
| YYYY-MM-DD HH:MM | A | A1 | Verified access | All passed | 🟢 |
| ... | ... | ... | ... | ... | ... |

---

## Closure (Filled by homelab-action on completion)

### Resolution Summary
| Field | Value |
|-------|-------|
| **Status** | RESOLVED |
| **Started** | YYYY-MM-DD HH:MM |
| **Completed** | YYYY-MM-DD HH:MM |
| **Duration** | X hours Y minutes |
| **Resolved By** | homelab-action workflow |

### Final Infrastructure State
| Layer | Status | Verification |
|-------|:------:|--------------|
| **Metal** | 🟢 GREEN | All X nodes Ready |
| **Network** | 🟢 GREEN | All VLANs reachable, latency <50ms |
| **Storage (NAS)** | 🟢 GREEN | Unraid reachable, shares accessible |
| **System** | 🟢 GREEN | Ceph HEALTH_OK |
| **Platform** | 🟢 GREEN | All apps Synced/Healthy |
| **Apps** | 🟢 GREEN | All pods Running |

### Actions Completed Summary
- X items resolved
- Y PRs merged
- Z issues closed

### Lessons Learned (if any)
1. [Observation]
2. [Recommendation]

---

*Created/Updated by homelab-recon workflow*
*Last modified: YYYY-MM-DD HH:MM*
```

---

## Labels

Always apply these labels:
- `maintenance` (ID: 10)

## Assignees

Always assign to:
- `gitea_admin`
