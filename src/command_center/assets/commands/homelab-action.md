---
description: Execute all action items from maintenance issues until all infrastructure layers are GREEN
sync_locations:
  - .agent/workflows/homelab-action.md
  - .opencode/command/homelab-action.md
  - .gemini/commands/homelab-action.toml
sync_note: IMPORTANT - This file must be kept in sync across all locations. When making changes, update ALL files.
---

> [!CAUTION]
> ## ⚡ EXECUTION IMPERATIVE
> **DO NOT ASK FOR CONFIRMATION. DO NOT ASK IF YOU SHOULD START.**
>
> Receiving this command is the authorization. BEGIN PHASE 1 IMMEDIATELY.
>
> The moment you receive `/homelab-action`, you MUST:
> 1. **START** executing Phase 1 prerequisites
> 2. **CONTINUE** through all phases until all layers are GREEN
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
- A specific issue number to work on
- Specific action items to prioritize
- Components to focus on first
- Any special instructions or constraints

---

# Homelab Action Workflow

## Overview

This workflow iterates on all action items in the latest maintenance-labeled Gitea issue, executing remediation steps until all infrastructure layers achieve GREEN status. It operates in a continuous loop: execute actions, validate via recon, iterate on findings until success.

> [!IMPORTANT]
> **Sync Requirement**: This workflow exists in multiple locations that must stay synchronized:
> - `.agent/workflows/homelab-action.md`
> - `.opencode/command/homelab-action.md`
> - `.gemini/commands/homelab-action.toml`
>
> When updating this file, **COPY changes to all locations**.

> [!CAUTION]
> **FOUNDATIONAL RULES APPLY** - See `_foundational-rules.md`
>
> This workflow follows the **Homelab Foundational Rules**. These rules are NON-NEGOTIABLE:
> - **Rule 1**: Work is NOT complete until ALL layers are GREEN
> - **Rule 2**: Zero tolerance for issues of ANY severity (CRITICAL through LOW)
> - **Rule 3**: NO pause, NO stop, NO quit until complete
> - **Rule 4**: Continuous validation after every action
> - **Rule 5**: All action items must be executed and verified
>
> **The ONLY exit condition is ALL GREEN status across all layers with ZERO remaining issues.**

> [!IMPORTANT]
> **Do NOT add comments to issues.** Comments are reserved for humans only.
> Always **EDIT the original issue body** to mark items as completed and update status.

> [!CAUTION]
> **Acceptance Criteria**: This workflow is NOT complete until:
> - All action items are resolved (checked off)
> - All infrastructure layers are **GREEN**
> - Overall status is **GREEN**
> - Final recon validation confirms GREEN status

## References

- **Documentation**: https://homelab.eaglepass.io
- **Primary Repo**: https://git.eaglepass.io/ops/homelab
- **Fallback Repo**: https://github.com/brimdor/homelab (auto-synced from primary)
- **Related Workflow**: `homelab-recon.md` (for validation)

---

## Phase 1: Prerequisites & Issue Discovery

### 1.1 VERIFY Access

BEFORE STARTING, EXECUTE these commands to confirm access to all required systems:

```bash
# VERIFY kubectl access
kubectl cluster-info

# VERIFY controller access
ssh -o ConnectTimeout=5 brimdor@10.0.20.10 "echo 'Controller accessible'"

# VERIFY Gitea API access
source ~/.config/gitea/.env
curl -s "https://git.eaglepass.io/api/v1/user" -H "Authorization: token $GITEA_TOKEN" | jq -r '.login'
```

**ALL commands MUST succeed before proceeding to Phase 1.2.**

### 1.2 LOCATE Maintenance Issue

EXECUTE this command to find the latest open issue with the `maintenance` label:

```bash
source ~/.config/gitea/.env
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues?state=open&labels=maintenance" \
  -H "Authorization: token $GITEA_TOKEN" | jq -r '.[0] | "Issue #\(.number): \(.title)"'
```

**IF no maintenance issue is found**: RUN `/homelab-recon` first to generate one.

### 1.3 PARSE Action Items

EXECUTE these steps to extract all unchecked action items (`- [ ]`) from the issue body:

1. **FETCH** the issue body
2. **PARSE** markdown checkboxes
3. **CATEGORIZE** by phase/priority
4. **CREATE** execution plan

**Action Item Categories**:
| Priority | Description | Examples |
|----------|-------------|----------|
| **CRITICAL** | Immediate action required | Ceph crashes, nodes down, data at risk |
| **HIGH** | Should be addressed soon | Version upgrades, security patches |
| **MEDIUM** | Can be scheduled | Dependency updates, optimizations |
| **LOW** | Nice to have | Cleanup, documentation |

---

## Phase 2: Action Execution Loop

### 2.1 EXECUTE Strategy

For EACH action item, EXECUTE this pattern:

```
1. READ    - Understand the action and its context
2. PLAN    - Determine the safest approach
3. BACKUP  - Ensure rollback is possible (if applicable)
4. EXECUTE - Perform the action
5. VERIFY  - Confirm the action succeeded
6. UPDATE  - Mark checkbox complete in issue
7. NEXT    - Move to next action item
```

### 2.2 Common Action Patterns

#### Ceph Storage Actions

**EXECUTE Archive Crash History**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph crash archive-all
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health detail
```

**EXECUTE Check OSD Status**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd tree
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd df
```

**EXECUTE Reweight OSD**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd reweight <osd_id> 1.0
```

**EXECUTE Remove Dead OSD**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd out <osd_id>
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd purge <osd_id> --yes-i-really-mean-it
```

**EXECUTE Clear noout Flag**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd unset noout
```

**EXECUTE Check Ceph Health**:
```bash
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph status
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health detail
```

#### Kubernetes Actions

**EXECUTE Check Node Status**:
```bash
kubectl get nodes -o wide
kubectl top nodes
kubectl describe node <node_name> | grep -A5 Conditions
```

**EXECUTE Restart Deployment**:
```bash
kubectl rollout restart deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

**EXECUTE Check Pod Logs**:
```bash
kubectl logs -n <namespace> <pod_name> --tail=100
kubectl logs -n <namespace> <pod_name> --previous  # If crashed
```

**EXECUTE Force Pod Recreation**:
```bash
kubectl delete pod <pod_name> -n <namespace>
# Pod will be recreated by controller
```

#### Node Access Actions

**EXECUTE SSH to Node** (via Controller):
```bash
# Step 1: SSH to Controller
ssh brimdor@10.0.20.10

# Step 2: Start tools container
cd ~/homelab && make tools

# Step 3: Wait for container, then SSH to node
ssh root@<node_ip>
```

**EXECUTE Check Disk Space on Node**:
```bash
# From inside tools container
ssh root@<node_ip> "df -h"
ssh root@<node_ip> "du -sh /var/lib/rook/* 2>/dev/null | sort -hr | head -10"
```

#### ArgoCD Actions

**EXECUTE Sync Application**:
```bash
argocd app sync <app_name>
argocd app wait <app_name>
```

**EXECUTE Check Application Status**:
```bash
kubectl get applications -n argocd
argocd app get <app_name>
```

**EXECUTE Refresh Application**:
```bash
argocd app refresh <app_name>
```

#### Gitea PR & Issue Actions

When the maintenance issue includes Gitea action items (PRs to merge, issues to close), USE these patterns:

**EXECUTE Merge a Pull Request**:
```bash
source ~/.config/gitea/.env

# CHECK PR status first
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/{pr_number}" \
  -H "Authorization: token $GITEA_TOKEN" | jq '{mergeable, merged, state}'

# MERGE the PR (if mergeable)
curl -s -X POST "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/{pr_number}/merge" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Do": "merge", "delete_branch_after_merge": true}'
```

Or USE MCP tools:
- USE `gitea_get_pull_request_by_index` to check PR status
- MERGE via API if tools don't support direct merge

**EXECUTE Close an Issue**:
```bash
source ~/.config/gitea/.env

curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "closed"}'
```

Or USE MCP tools:
- USE `gitea_edit_issue` with `state: closed`

**EXECUTE Close a PR Without Merging**:
```bash
source ~/.config/gitea/.env

curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/{pr_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "closed"}'
```

**EXECUTE Add Resolution Note Before Closing**:
ALWAYS update the issue/PR body with a resolution note before closing:

```bash
# GET current body
CURRENT_BODY=$(curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" | jq -r '.body')

# PREPEND resolution note
NEW_BODY="## Resolution\nResolved as part of maintenance issue #X on YYYY-MM-DD.\n\n---\n\n${CURRENT_BODY}"

# UPDATE the issue
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$NEW_BODY\"}"
```

**VERIFY Post-Merge/Close**:
After merging PRs or closing issues, VERIFY:
1. ArgoCD detects and syncs changes (for merged PRs)
2. Cluster state reflects expected changes
3. No new issues introduced by the merge

### 2.3 Safety Guidelines

> [!WARNING]
> **BEFORE executing destructive actions:**
> 1. VERIFY the target is correct
> 2. ENSURE backups exist
> 3. DOCUMENT a rollback plan
> 4. CONSIDER scheduling a maintenance window

**NEVER do without confirmation**:
- Delete PVCs with data
- Remove OSDs without understanding why they're down
- Upgrade multiple components simultaneously
- Make changes during active incidents

**ALWAYS do**:
- One action at a time
- Verify after each action
- Update issue with progress
- Pause if unexpected behavior occurs

### 2.4 Renovate PR Processing Protocol

> [!CAUTION]
> **Renovate PRs MUST be processed one at a time.**
> Each merge requires GREEN status validation before proceeding to the next.
> If any layer goes YELLOW or RED, TROUBLESHOOT until GREEN before continuing.

#### 2.4.1 APPLY Merge Order (Safest to Riskiest)

PROCESS Renovate PRs in this order to minimize risk:

| Order | Category | Examples | Risk Level |
|:-----:|----------|----------|:----------:|
| 1 | Non-major bundles | "update all non-major dependencies" | LOW |
| 2 | Platform services | kured, cloudflared, renovate | LOW |
| 3 | Monitoring | grafana, prometheus, loki | MEDIUM |
| 4 | Core infrastructure | argocd, external-secrets, cert-manager | HIGH |
| 5 | App templates | app-template, common libraries | MEDIUM |
| 6 | Databases | postgres, mariadb, mongodb, redis | CRITICAL |

#### 2.4.2 EXECUTE One-at-a-Time Merge Loop

```
┌─────────────────────────────────────────────────────────────┐
│            RENOVATE PR PROCESSING LOOP                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────────┐                                          │
│   │ SELECT next  │                                          │
│   │ PR (by order)│                                          │
│   └──────┬───────┘                                          │
│          ↓                                                  │
│   ┌──────────────┐                                          │
│   │  MERGE PR    │                                          │
│   └──────┬───────┘                                          │
│          ↓                                                  │
│   ┌──────────────┐                                          │
│   │ WAIT for     │                                          │
│   │ ArgoCD sync  │  (max 5 min)                             │
│   └──────┬───────┘                                          │
│          ↓                                                  │
│   ┌──────────────┐     ┌──────────────┐                     │
│   │ CHECK ALL    │ NO  │ TROUBLESHOOT │                     │
│   │ layers GREEN?├────►│ until GREEN  │                     │
│   └──────┬───────┘     └──────┬───────┘                     │
│          │ YES                │                             │
│          ↓                    │                             │
│   ┌──────────────┐           │                              │
│   │ UPDATE issue │◄──────────┘                              │
│   │ (mark done)  │                                          │
│   └──────┬───────┘                                          │
│          ↓                                                  │
│   ┌──────────────┐                                          │
│   │ More PRs?    │ YES ──► [Loop back to SELECT next PR]    │
│   └──────┬───────┘                                          │
│          │ NO                                               │
│          ↓                                                  │
│   ┌──────────────┐                                          │
│   │ ALL DONE     │                                          │
│   └──────────────┘                                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 2.4.3 EXECUTE Per-Merge Validation

After EACH Renovate PR merge, EXECUTE validation for ALL layers:

```bash
# Quick validation - ALL must pass before next merge
kubectl get nodes | grep -v "Ready"                           # Empty = GREEN
kubectl get pods -n kube-system | grep -v "Running\|Completed" # Empty = GREEN
kubectl get applications -n argocd | grep -v "Synced.*Healthy" # Empty = GREEN
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health # HEALTH_OK = GREEN
kubectl get pods -A --no-headers | grep -v "Running\|Completed" # Empty = GREEN
```

**IF any check fails**:
1. **STOP** - Do NOT merge next PR
2. **INVESTIGATE** - Check logs, events, describe resources
3. **FIX** - Apply remediation
4. **VALIDATE** - Re-run all checks
5. **ONLY PROCEED** when ALL GREEN

#### 2.4.4 EXECUTE Merge Command

```bash
source ~/.config/gitea/.env

# For each Renovate PR (one at a time):
PR_NUM=XX  # SET to current PR number

# 1. MERGE the PR
curl -s -X POST "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/${PR_NUM}/merge" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Do": "merge", "delete_branch_after_merge": true}'

# 2. WAIT for ArgoCD to detect and sync (30-60 seconds)
sleep 60

# 3. RUN validation checks (see 2.4.3)

# 4. ONLY after GREEN, PROCEED to next PR
```

#### 2.4.5 TROUBLESHOOT Between Merges

IF status is YELLOW or RED after a merge:

| Status | Action |
|:------:|--------|
| **Pod CrashLoopBackOff** | CHECK logs, may need config fix or rollback |
| **ArgoCD OutOfSync** | FORCE refresh and sync, check for conflicts |
| **Ceph HEALTH_WARN** | CHECK `ceph health detail`, may self-resolve |
| **Node NotReady** | CHECK kubelet logs, may need pod eviction |

**EXECUTE Rollback if needed:**
```bash
# REVERT the last merge commit
git revert HEAD --no-edit
git push

# WAIT for ArgoCD to sync back to previous state
sleep 60
```

---

## Phase 3: Validation Loop

### 3.1 EXECUTE Quick Health Check

After each significant action, EXECUTE this quick validation:

```bash
# Nodes healthy?
kubectl get nodes | grep -v "Ready"

# Core pods healthy?
kubectl get pods -n kube-system | grep -v "Running\|Completed"

# ArgoCD apps healthy?
kubectl get applications -n argocd | grep -v "Synced.*Healthy"

# Ceph healthy?
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health
```

### 3.2 CHECK Layer Status

| Layer | Quick Check Command | GREEN Criteria |
|-------|---------------------|----------------|
| Metal | `kubectl get nodes` | All nodes Ready |
| System | `ceph health` + `kubectl get pods -n kube-system` | HEALTH_OK, all pods Running |
| Platform | `kubectl get applications -n argocd` | All Synced & Healthy |
| Apps | `kubectl get pods --all-namespaces \| grep -v Running` | No failed pods |

### 3.3 TRIGGER Full Recon

When all action items are complete, EXECUTE the full recon workflow:

```
EXECUTE: homelab-recon workflow
```

**EXPECTED Outcome**:
- All layers: GREEN
- Overall status: GREEN
- No new action items generated

### 3.4 EVALUATE Iteration Decision

After recon, EVALUATE and EXECUTE appropriate action:

| Recon Result | Action |
|--------------|--------|
| All GREEN | Workflow complete! PROCEED to Phase 4 to close issue. |
| New YELLOW items | ADD to action list, CONTINUE Phase 2 |
| New RED items | PRIORITIZE immediately, CONTINUE Phase 2 |
| Same issues persist | INVESTIGATE root cause, ESCALATE if needed |

---

## Phase 4: Issue Update & Completion

### 4.1 UPDATE Issue During Execution

As each action completes, EXECUTE these updates:

1. **CHANGE** `- [ ]` to `- [x]` for completed items
2. **ADD** outcome notes if relevant
3. **UPDATE** timestamps
4. **KEEP** running tally of progress

**Example Update**:
```markdown
- [x] Archive Ceph crashes *(completed 2025-12-09 14:30)*
- [x] Investigate osd.5 status *(disk failed, OSD removed)*
- [ ] Reweight osd.6 *(in progress)*
```

### 4.2 IDENTIFY Related Issues and PRs

Before closing, EXECUTE this search for related issues and PRs:

```bash
# LIST all open issues
source ~/.config/gitea/.env
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues?state=open" \
  -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | "#\(.number): \(.title)"'

# LIST all open PRs
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls?state=open" \
  -H "Authorization: token $GITEA_TOKEN" | jq -r '.[] | "PR #\(.number): \(.title)"'
```

**Related items may include**:
- **PRs merged during maintenance**: Dependency updates, configuration changes, feature PRs
- **PRs closed without merge**: Superseded, invalid, or no-longer-needed PRs
- **Issues resolved by fixes**: Bug reports fixed by merged changes
- **Issues closed as completed**: Feature requests implemented
- **Issues closed as won't fix**: Items determined to be invalid or out of scope
- Dependency update PRs that were merged (PR #2, PR #3, etc.)
- Issues referencing the same components (Ceph, K3s, specific apps)
- Issues created as a result of the same root cause
- Child tasks spawned from the main maintenance issue

### 4.3 TRACK PR/Issue Actions Taken

MAINTAIN a log of all PRs and Issues actioned during the maintenance window:

| Type | Number | Title | Action | Timestamp | Notes |
|------|--------|-------|--------|-----------|-------|
| PR | #X | [Title] | Merged | YYYY-MM-DD HH:MM | ArgoCD synced successfully |
| PR | #Y | [Title] | Closed | YYYY-MM-DD HH:MM | Superseded by PR #Z |
| Issue | #A | [Title] | Closed | YYYY-MM-DD HH:MM | Fixed by PR #X |
| Issue | #B | [Title] | Closed | YYYY-MM-DD HH:MM | Resolved during Ceph recovery |

### 4.4 CREATE Final Issue Update with Exhaustive Closure Notes

When all layers are GREEN, EXECUTE these steps to prepare comprehensive closure documentation:

1. **UPDATE issue title** to include `[RESOLVED]`
2. **ADD exhaustive resolution summary** at top of body
3. **DOCUMENT every action taken** with timestamps and outcomes
4. **DOCUMENT all PRs merged/closed** during maintenance
5. **DOCUMENT all Issues closed** during maintenance
6. **INCLUDE final verification data** from recon
7. **LIST related issues** being closed
8. **ADD lessons learned** if applicable

**Exhaustive Closure Template**:
```markdown
# RESOLVED - All Layers GREEN

## Resolution Summary

| Field | Value |
|-------|-------|
| **Status** | RESOLVED |
| **Started** | YYYY-MM-DD HH:MM |
| **Completed** | YYYY-MM-DD HH:MM |
| **Duration** | X hours Y minutes |
| **Resolved By** | homelab-action workflow |

---

## Final Infrastructure State

| Layer | Status | Verification |
|-------|:------:|--------------|
| **Metal** | GREEN | All 10 nodes Ready, CPU <50%, Memory <80% |
| **System** | GREEN | Ceph HEALTH_OK, all kube-system pods Running |
| **Platform** | GREEN | All ArgoCD apps Synced/Healthy, certs valid |
| **Apps** | GREEN | All application pods Running |

**Overall Status**: GREEN

---

## Actions Completed

### Phase 1: Ceph Storage Recovery
| Action | Timestamp | Result |
|--------|-----------|--------|
| Archive crash history | YYYY-MM-DD HH:MM | 629 crashes archived, warning cleared |
| Investigate mon g disk | YYYY-MM-DD HH:MM | Cleaned X GB, now at Y% available |
| Assess osd.1 | YYYY-MM-DD HH:MM | Disk failed, OSD removed from cluster |
| Assess osd.5 | YYYY-MM-DD HH:MM | Transient issue, OSD restarted successfully |
| Reweight osd.6 | YYYY-MM-DD HH:MM | Reweighted to 1.0, now participating |
| Reweight osd.7 | YYYY-MM-DD HH:MM | Reweighted to 1.0, now participating |
| Clear noout flag | YYYY-MM-DD HH:MM | Flag cleared, rebalancing complete |

### Phase 2: Dependency Updates
| Action | Timestamp | Result |
|--------|-----------|--------|
| Merge PR #2 | YYYY-MM-DD HH:MM | Non-major updates applied successfully |
| Merge PR #3 | YYYY-MM-DD HH:MM | Kong v3 upgrade complete |

### Phase 3: System Upgrades
| Action | Timestamp | Result |
|--------|-----------|--------|
| K3s upgrade to v1.29 | YYYY-MM-DD HH:MM | All nodes upgraded |
| K3s upgrade to v1.30 | YYYY-MM-DD HH:MM | All nodes upgraded |
| ... | ... | ... |

---

## Pull Requests & Issues Actioned

### PRs Merged
| PR | Title | Merged At | Verification |
|----|-------|-----------|--------------| 
| #X | [Title] | YYYY-MM-DD HH:MM | ArgoCD synced, services healthy |
| #Y | [Title] | YYYY-MM-DD HH:MM | Deployment rolled out successfully |

### PRs Closed (Not Merged)
| PR | Title | Closed At | Reason |
|----|-------|-----------|--------|
| #Z | [Title] | YYYY-MM-DD HH:MM | Superseded by #Y |

### Issues Closed
| Issue | Title | Closed At | Resolution |
|-------|-------|-----------|------------|
| #A | [Title] | YYYY-MM-DD HH:MM | Fixed by PR #X |
| #B | [Title] | YYYY-MM-DD HH:MM | Resolved during maintenance actions |

---

## Verification Data (Final Recon)

### Cluster Status
- **Nodes**: 10/10 Ready
- **Pods**: XXX Running, 0 Failed
- **ArgoCD Apps**: 32/32 Synced & Healthy
- **Certificates**: 17/17 Valid

### Ceph Status
- **Health**: HEALTH_OK
- **OSDs**: X up, X in
- **Storage**: X% used (X TiB available)
- **PGs**: All active+clean

### Resource Utilization
| Node | CPU | Memory |
|------|-----|--------|
| node1 | X% | X% |
| ... | ... | ... |

---

## Related Issues & PRs Closed

### Issues Closed
| Issue | Title | Reason |
|-------|-------|--------|
| #X | [Title] | Resolved by [action] |
| #Y | [Title] | Resolved by [action] |

### PRs Merged
| PR | Title | Merged At |
|----|-------|-----------|
| #X | [Title] | YYYY-MM-DD HH:MM |

### PRs Closed (Not Merged)
| PR | Title | Reason |
|----|-------|--------|
| #X | [Title] | Superseded by #Y |

---

## Lessons Learned

1. [Observation about what caused the issue]
2. [Recommendation for preventing recurrence]
3. [Process improvement suggestion]

---

## References

- **Final Report**: `reports/status-report-YYYY-MM-DD.md`
- **Workflow Used**: `homelab-action.md`
- **Validation**: `homelab-recon.md`

---

*Closed by homelab-action workflow*
*Completion time: YYYY-MM-DD HH:MM*
```

### 4.6 EXECUTE Close Main Issue

```bash
source ~/.config/gitea/.env

# UPDATE title to [RESOLVED]
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "[RESOLVED] Original Title Here"}'

# UPDATE body with exhaustive closure notes
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/closure_notes.json

# CLOSE the issue
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "closed"}'
```

### 4.7 EXECUTE Close Related Issues and PRs

For each related issue and PR identified in 4.2:

#### EXECUTE Close Related Issues
```bash
source ~/.config/gitea/.env

# For each related issue, ADD closure reference and CLOSE
for issue_num in 2 3 4; do  # Example issue numbers
  # UPDATE body with reference to main resolution
  curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/${issue_num}" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"body\": \"Resolved as part of maintenance issue #1. See #1 for full resolution details.\"}"
  
  # CLOSE the issue
  curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/${issue_num}" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"state": "closed"}'
done
```

#### EXECUTE Merge Approved PRs
```bash
source ~/.config/gitea/.env

# For each PR ready to merge
for pr_num in 5 6 7; do  # Example PR numbers
  # CHECK if mergeable
  MERGEABLE=$(curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/${pr_num}" \
    -H "Authorization: token $GITEA_TOKEN" | jq -r '.mergeable')
  
  if [ "$MERGEABLE" = "true" ]; then
    # MERGE the PR
    curl -s -X POST "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/${pr_num}/merge" \
      -H "Authorization: token $GITEA_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"Do": "merge", "delete_branch_after_merge": true, "merge_message_field": "Merged as part of maintenance workflow"}'
    
    echo "Merged PR #${pr_num}"
  else
    echo "PR #${pr_num} is not mergeable, skipping"
  fi
done
```

#### EXECUTE Close PRs Without Merging (if applicable)
```bash
source ~/.config/gitea/.env

# For PRs that should be closed without merge (superseded, invalid, etc.)
for pr_num in 8 9; do  # Example PR numbers
  curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls/${pr_num}" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"state": "closed"}'
  
  echo "Closed PR #${pr_num} without merging"
done
```

#### VERIFY ArgoCD Sync After PR Merges
After merging PRs, EXECUTE verification that ArgoCD detects and applies the changes:

```bash
# WAIT for ArgoCD to detect changes
sleep 30

# CHECK sync status
kubectl get applications -n argocd | grep -v "Synced.*Healthy"

# FORCE refresh if needed
argocd app list --refresh
```

**Criteria for closing related issues**:
- Issue was explicitly listed as a task in the maintenance issue
- Issue references components that were fixed (e.g., "Ceph crashes" issue closed after crash resolution)
- Dependency update PRs that were merged as part of the workflow
- Issues that become irrelevant after the fix (e.g., version skew warning after K3s upgrade)

**Criteria for merging PRs**:
- PR was listed in the maintenance issue as an action item
- PR has passed all required checks
- PR is mergeable (no conflicts)
- Changes have been verified post-merge via ArgoCD sync
- Dependency update PRs from Renovate that are ready

**Criteria for closing PRs without merge**:
- PR has been superseded by another PR
- PR is no longer relevant due to other changes
- PR has been open too long and is now stale
- Changes are no longer needed or desired

> [!WARNING]
> **Do NOT close issues or PRs that**:
> - Were not addressed by the actions taken
> - Represent separate ongoing work
> - Are feature requests unrelated to maintenance
> - Require additional verification beyond this workflow
> - Have failing checks or merge conflicts (PRs)

---

## Phase 5: Major Version Upgrade Safety Procedures

> [!CAUTION]
> **Major version upgrades** (e.g., v1 → v2, v8 → v9) often contain breaking changes.
> These require additional safety measures beyond standard action execution.

### 5.1 EXECUTE Pre-Upgrade Assessment

BEFORE ANY major version upgrade, EXECUTE these steps:

**1. REVIEW Release Notes & Breaking Changes**
```bash
# CHECK the upstream release notes for breaking changes
# DOCUMENT all breaking changes in the maintenance issue
# IDENTIFY affected configurations, CRDs, or APIs
```

**VERIFY these questions are answered:**
- [ ] Are there API/CRD schema changes?
- [ ] Are there deprecated features being removed?
- [ ] Are there configuration file format changes?
- [ ] Are there data migration requirements?
- [ ] Is there a recommended upgrade path (e.g., v7 → v8 → v9)?

**2. EXECUTE Dependency Check**
```bash
# IDENTIFY all components that depend on the upgrade target
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}: {range .spec.containers[*]}{.image}{"\n"}{end}{end}' | grep <component>
```

**3. CREATE Rollback Plan**
DOCUMENT the exact rollback procedure:
- Current version (for git revert target)
- Backup locations
- Rollback commands
- Estimated rollback time

### 5.2 Major Version Upgrade Categories

| Category | Examples | Risk Level | Required Prep |
|----------|----------|------------|---------------|
| **Databases** | PostgreSQL, MariaDB, MongoDB, Redis | CRITICAL | Full backup, dump verification, staged rollout |
| **GitOps/Core** | ArgoCD, External-Secrets, Cert-Manager | HIGH | CRD backup, sync pause, staged validation |
| **Monitoring** | Prometheus, Grafana, AlertManager | MEDIUM | Dashboard backup, alert rule export |
| **Application** | App-Template, individual apps | LOW-MEDIUM | Config review, dependency check |
| **Infrastructure** | Terraform providers, Go modules | LOW | State backup, plan review |

### 5.3 EXECUTE Staged Upgrade Process

For HIGH/CRITICAL risk upgrades, EXECUTE this staged approach:

```
[Stage 1: PREPARE]     → DOCUMENT, BACKUP, VALIDATE rollback
[Stage 2: DRY RUN]     → helm template, terraform plan, REVIEW diffs
[Stage 3: CANARY]      → UPGRADE in test/dev if available
[Stage 4: EXECUTE]     → UPGRADE with monitoring
[Stage 5: VALIDATE]    → EXECUTE full health check, functionality test
[Stage 6: STABILIZE]   → MONITOR for 30+ minutes before next upgrade
```

### 5.4 EXECUTE Post-Upgrade Validation Gates

**Gate 1: Basic Health (Immediate)**
```bash
# VERIFY component is running
kubectl get pods -n <namespace> -l app=<component>

# CHECK for error logs
kubectl logs -n <namespace> deploy/<component> --tail=50 | grep -i error
```

**Gate 2: Functional Health (Within 5 minutes)**
```bash
# ArgoCD: VERIFY all apps still synced
kubectl get applications -n argocd | grep -v "Synced.*Healthy"

# Secrets: VERIFY all ExternalSecrets synced
kubectl get externalsecrets -A | grep -v "SecretSynced"

# Ceph: VERIFY still healthy
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health
```

**Gate 3: Extended Validation (Within 30 minutes)**
- CONFIRM no new alerts firing
- CONFIRM no degraded services reported
- VERIFY user-facing endpoints responding correctly
- VERIFY log error rates stable

---

## Phase 6: Database Upgrade Protocols

> [!DANGER]
> **Database upgrades carry the highest risk of data loss.**
> NEVER proceed without verified, restorable backups.

### 6.1 EXECUTE Database Upgrade Pre-Flight Checklist

BEFORE upgrading ANY database (PostgreSQL, MariaDB, MongoDB, Redis, Valkey):

**Step 1: VERIFY Current State**
```bash
# IDENTIFY the database pod
kubectl get pods -A | grep -E "(postgres|mariadb|mongodb|redis|valkey)"

# CHECK current version
kubectl exec -n <namespace> <pod> -- <version_command>
# PostgreSQL: psql --version
# MariaDB: mariadb --version
# MongoDB: mongod --version
# Redis/Valkey: redis-server --version
```

**Step 2: CREATE Full Backup**
```bash
# PostgreSQL
kubectl exec -n <namespace> <pod> -- pg_dumpall -U postgres > /tmp/postgres_backup_$(date +%Y%m%d_%H%M%S).sql

# MariaDB
kubectl exec -n <namespace> <pod> -- mysqldump -u root --all-databases > /tmp/mariadb_backup_$(date +%Y%m%d_%H%M%S).sql

# MongoDB
kubectl exec -n <namespace> <pod> -- mongodump --out=/tmp/mongo_backup_$(date +%Y%m%d_%H%M%S)

# Redis (if persistence enabled)
kubectl exec -n <namespace> <pod> -- redis-cli BGSAVE
kubectl cp <namespace>/<pod>:/data/dump.rdb /tmp/redis_backup_$(date +%Y%m%d_%H%M%S).rdb
```

**Step 3: VERIFY Backup Integrity**
```bash
# COPY backup to local machine
kubectl cp <namespace>/<pod>:/tmp/<backup_file> ./backups/<backup_file>

# VERIFY backup file is not empty and has expected size
ls -lh ./backups/<backup_file>

# For SQL dumps, VERIFY structure
head -100 ./backups/<backup_file>
tail -10 ./backups/<backup_file>
```

**Step 4: DOCUMENT Recovery Procedure**
```markdown
## Recovery Procedure for <database>

1. SCALE DOWN dependent applications:
   kubectl scale deploy/<app> -n <namespace> --replicas=0

2. RESTORE from backup:
   kubectl exec -n <namespace> <pod> -- <restore_command> < /path/to/backup

3. VERIFY data integrity:
   kubectl exec -n <namespace> <pod> -- <verify_command>

4. SCALE UP applications:
   kubectl scale deploy/<app> -n <namespace> --replicas=1
```

### 6.2 EXECUTE Database Upgrade

**EXECUTE this sequence for database upgrades:**

```
1. [STOP]      SCALE DOWN all applications using the database
2. [BACKUP]   CREATE and VERIFY full backup (see 6.1)
3. [SNAPSHOT] CREATE PVC snapshot if available
4. [UPGRADE]  APPLY the version upgrade
5. [WAIT]     WAIT for pod to be Running (may take 5-10 min for migrations)
6. [VERIFY]   CONNECT and VERIFY data integrity
7. [START]    SCALE UP applications one at a time
8. [VALIDATE] VERIFY applications function correctly
```

**Database upgrade command template:**
```bash
# BEFORE upgrade - IDENTIFY dependent apps
DEPS=$(kubectl get pods -A -o json | jq -r '.items[] | select(.spec.containers[].env[]?.value | contains("<db-service>")) | .metadata.namespace + "/" + .metadata.name')

# SCALE DOWN dependents
for dep in $DEPS; do
  NS=$(echo $dep | cut -d'/' -f1)
  NAME=$(echo $dep | cut -d'/' -f2)
  kubectl scale deploy/$NAME -n $NS --replicas=0 --timeout=60s
done

# Now safe to upgrade database
# ... APPLY helm upgrade or UPDATE image ...

# After upgrade verification, SCALE BACK UP
for dep in $DEPS; do
  NS=$(echo $dep | cut -d'/' -f1)
  NAME=$(echo $dep | cut -d'/' -f2)
  kubectl scale deploy/$NAME -n $NS --replicas=1
done
```

### 6.3 Database-Specific Upgrade Notes

#### PostgreSQL (v17 → v18, v18+)
- **CRITICAL**: CHECK for removed/changed system catalogs
- RUN `pg_upgrade` compatibility check if doing in-place upgrade
- Major versions may require `pg_dump`/`pg_restore` cycle
- VERIFY extensions compatibility (e.g., TimescaleDB, PostGIS)

#### MariaDB (v11 → v12)
- CHECK for deprecated SQL modes
- VERIFY character set and collation compatibility
- REVIEW `my.cnf` for deprecated options
- May require `mysql_upgrade` after version bump

#### MongoDB (v7 → v8)
- CHECK feature compatibility version (FCV)
- May require `setFeatureCompatibilityVersion` before upgrade
- REVIEW aggregation pipeline changes
- CHECK index compatibility

#### Redis/Valkey (v7 → v8, v8 → v9)
- VERIFY RDB/AOF format compatibility
- CHECK for deprecated commands
- REVIEW cluster mode changes if applicable
- Persistence format may change

### 6.4 EXECUTE Database Upgrade Failure Recovery

IF a database upgrade fails:

```bash
# 1. CHECK pod status and logs
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> --previous

# 2. IF pod is CrashLoopBackOff, CHECK for:
#    - Migration failures
#    - Incompatible data format
#    - Missing permissions

# 3. ROLLBACK to previous version
git revert <commit>  # If using GitOps
# OR manually EDIT helm values to previous version

# 4. IF data corruption suspected:
#    - DO NOT start the old version on corrupted data
#    - RESTORE from backup first
kubectl exec -n <namespace> <pod> -- <restore_command> < /path/to/backup

# 5. VERIFY recovery
kubectl exec -n <namespace> <pod> -- <verify_command>
```

---

## Phase 7: Breaking Change Validation Checklist

### 7.1 EXECUTE Pre-Merge Validation for Major Updates

BEFORE merging ANY PR with major version bumps:

**1. CHECK CRD/API Changes**
```bash
# CHECK for CRD changes
kubectl get crds | grep <component>
kubectl get crd <crd-name> -o yaml > /tmp/crd_before.yaml
# After update:
kubectl get crd <crd-name> -o yaml > /tmp/crd_after.yaml
diff /tmp/crd_before.yaml /tmp/crd_after.yaml
```

**2. CHECK Configuration Schema Changes**
```bash
# Helm: COMPARE values schema
helm show values <chart> --version <old> > /tmp/values_old.yaml
helm show values <chart> --version <new> > /tmp/values_new.yaml
diff /tmp/values_old.yaml /tmp/values_new.yaml
```

**3. CHECK Secret/ConfigMap Format Changes**
- REVIEW if secret formats have changed
- CHECK for renamed keys
- VERIFY ExternalSecrets templates are compatible

### 7.2 EXECUTE Component-Specific Validation

#### ArgoCD (v8 → v9)
- [ ] VERIFY all Application resources still valid
- [ ] VERIFY ApplicationSets still generating correctly
- [ ] VERIFY sync waves and hooks still function
- [ ] VERIFY RBAC policies still applied
- [ ] VERIFY SSO/OIDC still working
- [ ] VERIFY notifications still firing

#### External-Secrets (v0.x → v1.x)
- [ ] VERIFY all ExternalSecret resources sync
- [ ] VERIFY ClusterSecretStore connections valid
- [ ] VERIFY secret refresh intervals working
- [ ] VERIFY template functions still compatible

#### Kube-Prometheus-Stack (major versions)
- [ ] VERIFY all Prometheus rules loaded
- [ ] VERIFY AlertManager config valid
- [ ] VERIFY ServiceMonitors discovered
- [ ] VERIFY Grafana datasources connected
- [ ] VERIFY custom dashboards loading

#### Grafana (v9 → v10)
- [ ] VERIFY all dashboards render
- [ ] VERIFY datasources connected
- [ ] VERIFY alerting rules migrated
- [ ] VERIFY user authentication working
- [ ] VERIFY plugins compatible

### 7.3 EXECUTE Post-Merge Validation Script

RUN this script after any major version upgrade:

```bash
#!/bin/bash
# post_upgrade_validation.sh

COMPONENT=$1
NAMESPACE=$2

echo "=== Post-Upgrade Validation for $COMPONENT ==="

# CHECK pod status
echo "[1/5] Pod Status:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$COMPONENT

# CHECK for errors in logs
echo "[2/5] Recent Errors:"
kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=$COMPONENT --tail=100 2>/dev/null | grep -i -E "(error|fatal|panic)" | head -20

# CHECK events
echo "[3/5] Recent Events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | grep $COMPONENT | tail -10

# CHECK ArgoCD sync status
echo "[4/5] ArgoCD Status:"
kubectl get applications -n argocd | grep $COMPONENT

# CHECK service endpoints
echo "[5/5] Service Endpoints:"
kubectl get endpoints -n $NAMESPACE | grep $COMPONENT

echo "=== Validation Complete ==="
```

### 7.4 EXECUTE Staged Rollout for Critical Updates

For CRITICAL updates (databases, ArgoCD, external-secrets), EXECUTE staged rollout:

**Stage 1: Pre-Flight (T-60 minutes)**
- [ ] VERIFY all backups completed
- [ ] DOCUMENT rollback procedure
- [ ] OPEN monitoring dashboards
- [ ] NOTIFY team (if applicable)

**Stage 2: Upgrade Window Start (T-0)**
- [ ] TAKE final backup snapshot
- [ ] SCALE DOWN dependent services (if required)
- [ ] MERGE upgrade PR
- [ ] INITIATE ArgoCD sync

**Stage 3: Immediate Validation (T+5 minutes)**
- [ ] VERIFY pod is Running
- [ ] VERIFY no CrashLoopBackOff
- [ ] VERIFY basic health endpoint responding

**Stage 4: Functional Validation (T+15 minutes)**
- [ ] START all dependent services
- [ ] VERIFY end-to-end functionality
- [ ] CONFIRM no error rate increase

**Stage 5: Extended Monitoring (T+60 minutes)**
- [ ] VERIFY no new alerts
- [ ] VERIFY performance metrics stable
- [ ] ADDRESS user reports (if any)

**Stage 6: Upgrade Complete (T+24 hours)**
- [ ] CONFIRM no issues reported
- [ ] UPDATE documentation
- [ ] CLOSE issue

---

## Phase 8: Escalation Procedures

### 8.1 ESCALATE When Required

ESCALATE to human intervention when:

- Action requires physical hardware access
- Data loss risk is present
- Credentials or secrets need rotation
- Network infrastructure changes needed
- Multiple failures cascade
- Root cause cannot be determined
- Action has been attempted 3+ times without success

### 8.2 EXECUTE Escalation Actions

1. **DOCUMENT the issue** clearly in the Gitea issue
2. **ADD `needs-human` label** if available
3. **STOP automated actions** that might make things worse
4. **PRESERVE logs and state** for debugging
5. **SUMMARIZE findings** for human review

### 8.3 ENSURE Safe States

IF unable to proceed, ENSURE the cluster is in a safe state:

- Ceph `noout` flag set (prevents data movement)
- No pending destructive operations
- Critical services are running
- Monitoring is active

---

## Gitea API Reference

### EXECUTE Update Issue Body
```bash
source ~/.config/gitea/.env
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": "Updated content..."}'
```

### EXECUTE Update Issue Title
```bash
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "[RESOLVED] Original Title"}'
```

### EXECUTE Close Issue
```bash
curl -s -X PATCH "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues/{issue_number}" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "closed"}'
```

### Token Location
```bash
# LOAD Gitea credentials
source ~/.config/gitea/.env    # bash/zsh
source ~/.config/gitea/gitea.fish  # fish

# Variables: GITEA_TOKEN, GITEA_URL
```

---

## Execution Checklist

COMPLETE all items before considering workflow finished:

- [ ] COMPLETE Phase 1: VERIFY access, LOCATE maintenance issue
- [ ] COMPLETE Phase 2: PARSE action items and PRIORITIZE
- [ ] COMPLETE Phase 2: EXECUTE actions one-by-one with verification
- [ ] COMPLETE Phase 2: MERGE/CLOSE Gitea PRs as specified in maintenance issue
- [ ] COMPLETE Phase 3: EXECUTE quick health checks after each action
- [ ] COMPLETE Phase 3: EXECUTE full recon validation
- [ ] COMPLETE Phase 3: CONFIRM all layers GREEN
- [ ] COMPLETE Phase 4: UPDATE issue with progress throughout
- [ ] COMPLETE Phase 4: IDENTIFY related issues and PRs
- [ ] COMPLETE Phase 4: DOCUMENT PR/Issue action log
- [ ] COMPLETE Phase 4: ADD exhaustive closure notes to main issue
- [ ] COMPLETE Phase 4: CLOSE main maintenance issue
- [ ] COMPLETE Phase 4: CLOSE related issues with references
- [ ] COMPLETE Phase 4: MERGE or CLOSE related PRs as appropriate
- [ ] COMPLETE Phase 4: VERIFY ArgoCD sync after PR merges
- [ ] CONFIRM Overall Status: **GREEN**

---

## Workflow State Machine

```
[START]
    |
    v
[Phase 1: DISCOVER Issue]
    |
    v
[Phase 2: EXECUTE Actions] <---------+
    |                                 |
    | (includes PR merges/closes)     |
    v                                 |
[Phase 3: VALIDATE]                   |
    |                                 |
    +-- All GREEN? --NO---------------+
    |
   YES
    |
    v
[Phase 4: IDENTIFY Related Issues & PRs]
    |
    v
[Phase 4: ADD Exhaustive Closure Notes]
    |
    v
[Phase 4: CLOSE Main Issue]
    |
    v
[Phase 4: CLOSE Related Issues]
    |
    v
[Phase 4: MERGE/CLOSE Related PRs]
    |
    v
[Phase 4: VERIFY ArgoCD Sync]
    |
    v
[END: All Layers GREEN, All Issues/PRs Resolved]
```

---

## Success Criteria

**This workflow is COMPLETE when ALL of the following are TRUE:**

1. ✅ **All action items** in the maintenance issue are checked off
2. ✅ **Metal Layer**: GREEN - All nodes Ready, resources healthy
3. ✅ **System Layer**: GREEN - Ceph HEALTH_OK, core pods healthy
4. ✅ **Platform Layer**: GREEN - All ArgoCD apps Synced/Healthy
5. ✅ **Apps Layer**: GREEN - All application pods running
6. ✅ **Overall Status**: GREEN
7. ✅ **Final recon report**: Confirms GREEN status
8. ✅ **All PRs actioned**: Merged or closed as specified in maintenance issue
9. ✅ **All related Issues closed**: With resolution references
10. ✅ **ArgoCD verified**: All merged PR changes synced successfully
11. ✅ **Exhaustive closure notes**: Added to main issue with full action log
12. ✅ **Main maintenance issue**: Closed with `[RESOLVED]` title
13. ✅ **Related issues and PRs**: Identified, referenced, and closed/merged

> [!CAUTION]
> **DO NOT STOP UNTIL ALL CRITERIA ARE MET.**

---

## Completion Criteria

**This workflow is COMPLETE when ALL of the following are TRUE:**

1. ✅ ALL action items in the maintenance issue are checked off
2. ✅ ALL four infrastructure layers report GREEN status
3. ✅ Final `/homelab-recon` validation confirms GREEN
4. ✅ ALL PRs specified in maintenance issue are merged or closed
5. ✅ ALL related issues are closed with resolution references
6. ✅ Exhaustive closure notes are added to main issue
7. ✅ Main maintenance issue is closed with `[RESOLVED]` title
8. ✅ ArgoCD sync is verified after all PR merges

> [!CAUTION]
> **DO NOT STOP UNTIL ALL CRITERIA ARE MET.**

---

## Mandatory Rules

These rules are NON-NEGOTIABLE:

1. **ALWAYS prioritize data safety over speed**
2. **EXECUTE one action at a time, VERIFY before proceeding**
3. **UPDATE the issue frequently for visibility**
4. **IF in doubt, PAUSE and ASSESS**
5. **USE `homelab-recon.md` to validate - this workflow complements it**
6. **NEVER proceed without GREEN validation between changes**
7. **ALWAYS document what was done with timestamps**
