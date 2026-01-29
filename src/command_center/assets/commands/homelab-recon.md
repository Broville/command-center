---
description: Comprehensive analysis, health check, and maintenance report for the entire Homelab
sync_locations:
  - .agent/workflows/homelab-recon.md
  - .opencode/command/homelab-recon.md
  - .gemini/commands/homelab-recon.toml
sync_note: IMPORTANT - This file must be kept in sync across all locations. When making changes, update ALL files.
---

> [!CAUTION]
> ## ⚡ EXECUTION IMPERATIVE
> **DO NOT ASK FOR CONFIRMATION. DO NOT ASK IF YOU SHOULD START.**
>
> Receiving this command is the authorization. BEGIN PHASE 1 IMMEDIATELY.
>
> The moment you receive `/homelab-recon`, you MUST:
> 1. **START** executing Phase 1 commands
> 2. **CONTINUE** through all phases until completion criteria are met
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
- Specific layers to focus on (Metal, System, Platform, Apps)
- Specific services or namespaces to investigate
- Whether to skip certain phases
- Any special instructions or constraints

---

# Homelab Recon → EXHAUSTIVE Maintenance Spec (Spec-Driven Development)

## Overview

This workflow produces an **EXHAUSTIVE** maintenance issue that `/homelab-action` can execute **safely in small tasks, in the proper order, without context loss**.

> [!IMPORTANT]
> **RECON = RESEARCH ONLY.** This workflow gathers evidence and creates/updates the maintenance issue.
> It does NOT execute actions, merge PRs, or modify infrastructure. That is `/homelab-action`'s job.

It is **Spec-Driven Development (SDD)** adapted to operations:
- **Context**: evidence capture (cluster + repo)
- **Spec**: the maintenance issue (what should change, and why)
- **Plan**: ordering + safety gates + stop conditions
- **Tasks**: top-level issue checkboxes (`- [ ]`) that are atomic
- **Analysis**: self-audit that the issue is complete and actionable
- **Remediation**: fill gaps, rerun analysis
- **Handoff**: maintenance issue ready for `/homelab-action` (RECON STOPS HERE)

> [!CAUTION]
> **FOUNDATIONAL RULES APPLY** - See `_foundational-rules.md`.
> This workflow is complete when the maintenance issue is ready for action (or confirms all layers are already GREEN).

> [!IMPORTANT]
> **Do NOT add comments to issues.** Comments are reserved for humans only.
> Always **edit the original issue body** to merge new data into the existing content.

## Definitions

**Maintenance Issue**: A **Gitea Issue** in the `ops/homelab` repository at `https://git.eaglepass.io/ops/homelab/issues` with the label `maintenance`. This is the single source of truth for all maintenance work. It is NOT a local file, NOT a GitHub issue, and NOT any other artifact. When this document refers to "maintenance issue," it means this specific Gitea Issue.

## References

- **Maintenance Issue Template**: `homelab-maintenance-issue-template.md` (MUST use for all maintenance issues)
- **Documentation**: https://homelab.eaglepass.io
- **Primary Repo**: https://git.eaglepass.io/ops/homelab
- **Fallback Repo**: https://github.com/brimdor/homelab (auto-synced)

---

## Maintenance Issue Contract (What `/homelab-action` Needs)

The maintenance issue is the **single source of truth**.

To prevent context loss, the issue body MUST:

1. USE **only top-level** executable checkboxes:
   - Every executable step starts with `- [ ]` at the beginning of the line.
   - Do not nest checkboxes for executable work.
2. MAKE every checkbox **atomic**:
   - One change (or one investigation) + one verification gate.
3. ENCODE ordering and priority in each checkbox line:
   - `A1 P0 ...`, `B3 P2 ...`, etc.
   - **Priority mapping**: `P0=CRITICAL`, `P1=HIGH`, `P2=MEDIUM`, `P3=LOW`.
4. INCLUDE **local context** directly under each checkbox (non-checkbox lines):
   - Goal
   - Commands (exact)
   - Expected (pass criteria)
   - If fails (next diagnostics)
   - Rollback (exact, or "N/A")
5. INCLUDE stable sections (headings), in this order:
   - `## Status`
   - `## Context Pack`
   - `## Proposed Changes (Spec)`
   - `## Execution Plan`
   - `## Action Items (Tasks)`
   - `## Change Log`
   - `## Closure (Filled by homelab-action)`

If any contract requirement is missing, TREAT it as a **blocking recon failure** and REMEDIATE before handoff.

---

## Phase 1: Context Loading (EXHAUSTIVE Evidence Capture)

### 1.1 Establish Access (Priority Order)

EXECUTE access establishment in this priority order:

1. **USE** workstation access for Kubernetes and repos (PRIMARY)
2. **FALLBACK** to controller only when workstation-to-cluster is unavailable:
   - SSH: `ssh brimdor@10.0.20.10`
   - Tools container: `cd ~/homelab && make tools`

### 1.2 Validate Access (MUST Succeed)

EXECUTE all validation commands - ALL must succeed before proceeding:

```bash
kubectl cluster-info
kubectl version --short

ssh -o ConnectTimeout=5 brimdor@10.0.20.10 "echo 'Controller accessible'"
```

> [!IMPORTANT]
> **SSH vs API Access**: SSH keys authenticate Git operations (clone/push/pull) but **CANNOT** query PRs/issues.
> The Gitea REST API requires an API token for programmatic access to PRs, issues, and other non-Git features.

**Gitea API Token Validation:**

```bash
# Bash/Zsh
source ~/.config/gitea/.env

# Fish shell alternative
set -x GITEA_TOKEN (cat ~/.config/gitea/.env | grep GITEA_TOKEN | cut -d= -f2)

# Validate token is actually set
if [ -z "$GITEA_TOKEN" ]; then
    echo "ERROR: GITEA_TOKEN is not set."
    echo "Generate one at: https://git.eaglepass.io/user/settings/applications"
    echo "Add to ~/.config/gitea/.env: GITEA_TOKEN=your_token_here"
    exit 1
fi

# Verify token works
curl -sf "https://git.eaglepass.io/api/v1/user" -H "Authorization: token $GITEA_TOKEN" | jq -r '.login'
```

### 1.3 Capture Baseline Health Snapshot

**Preferred Method: Script-Based (Recommended)**

```bash
# Run comprehensive recon script (SELECT ONE)
~/.gemini/scripts/recon.sh           # Antigravity
~/.config/opencode/scripts/recon.sh  # Opencode

# Or with JSON output for parsing (SELECT ONE)
~/.gemini/scripts/recon.sh --json              # Antigravity
~/.config/opencode/scripts/recon.sh --json     # Opencode
```

**Alternative: Manual Commands**

EXECUTE these commands and CAPTURE output as evidence:

```bash
# Nodes + capacity
kubectl get nodes -o wide
kubectl top nodes

# Workload health
kubectl get pods -A --sort-by=.metadata.namespace
kubectl get pods -A --no-headers | grep -v "Running\|Completed" || true

# GitOps health
kubectl get applications -n argocd
kubectl get applications -n argocd | grep -v "Synced.*Healthy" || true

# Recent events (last 200)
kubectl get events -A --sort-by=.lastTimestamp | tail -200
```

### 1.4 Capture Network Evidence

**Preferred Method: Script-Based (Recommended)**

```bash
# Run network health check script (SELECT ONE)
~/.gemini/scripts/homelab-network-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --verbose  # Opencode

# Or with JSON output for parsing (SELECT ONE)
~/.gemini/scripts/homelab-network-check.sh --json              # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --json     # Opencode
```

**Exit Codes**: 0=GREEN, 1=RED, 2=YELLOW

**Alternative: In-Cluster Testing (Pod-Based)**

```bash
# Deploy temporary network test pod (SELECT ONE)
kubectl apply -f ~/.gemini/scripts/network-test-pod.yaml           # Antigravity
kubectl apply -f ~/.config/opencode/scripts/network-test-pod.yaml  # Opencode

# Wait for completion and capture output
kubectl wait --for=condition=Ready pod/network-test-pod --timeout=60s || true
kubectl logs network-test-pod

# Cleanup
kubectl delete pod network-test-pod --ignore-not-found
```

**Method 2: External Network Testing (Script-Based)**

```bash
# Run comprehensive network health check (SELECT ONE)
~/.gemini/scripts/homelab-network-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --verbose  # Opencode

# Or with JSON output for parsing (SELECT ONE)
~/.gemini/scripts/homelab-network-check.sh --json              # Antigravity
~/.config/opencode/scripts/homelab-network-check.sh --json     # Opencode
```

**GREEN Criteria for Network Layer**:
| Check | GREEN | YELLOW | RED |
|-------|-------|--------|-----|
| VLAN Gateways | All reachable | 1-2 unreachable | 3+ unreachable |
| OPNSense | Reachable, ports open | Slow response | Unreachable |
| Latency | <50ms | 50-100ms | >100ms |
| Packet Loss | 0% | 1-5% | >5% |
| Internet | Both DNS servers reachable | 1 DNS reachable | None reachable |

### 1.5 Capture Storage/NAS Evidence (Unraid)

**Preferred Method: Script-Based (Recommended)**

```bash
# Run NAS health check script (SELECT ONE)
~/.gemini/scripts/homelab-nas-check.sh --verbose           # Antigravity
~/.config/opencode/scripts/homelab-nas-check.sh --verbose  # Opencode

# Or with JSON output for parsing (SELECT ONE)
~/.gemini/scripts/homelab-nas-check.sh --json              # Antigravity
~/.config/opencode/scripts/homelab-nas-check.sh --json     # Opencode
```

**Exit Codes**: 0=GREEN, 1=RED, 2=YELLOW

**Alternative: Manual Verification**

> **WARNING**: NAS (Unraid) blocks ICMP. Do NOT use `ping`. Use TCP port checks instead.

```bash
# Test NAS reachability via SMB (ICMP blocked!)
nc -zv 10.0.40.3 445

# Test NFS ports (if applicable)
nc -zv 10.0.40.3 2049

# Test web interface
curl -s -o /dev/null -w "%{http_code}" http://10.0.40.3
```

**GREEN Criteria for Storage/NAS Layer**:
| Check | GREEN | YELLOW | RED |
|-------|-------|--------|-----|
| SMB (445) | Port open | - | Port closed |
| NFS (2049) | Port open | - | Port closed |
| Web Interface | Accessible | Auth required | Unreachable |
| Read Latency | <50ms | 50-100ms | >100ms |
| Write Latency | <100ms | 100-200ms | >200ms |

### 1.6 Capture System/Core Evidence (kube-system, CNI)

EXECUTE these commands and CAPTURE output as evidence:

```bash
kubectl get pods -n kube-system -o wide
kubectl get pods -n kube-system --no-headers | grep -v "Running\|Completed" || true

# Cilium (if present)
kubectl -n kube-system get ds | grep -i cilium || true
kubectl -n kube-system get pods -l k8s-app=cilium -o wide || true
```

### 1.7 Capture Ceph Storage Evidence (Rook/Ceph)

EXECUTE these commands and CAPTURE output as evidence:

```bash
kubectl -n rook-ceph get pods -o wide
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph df
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg stat
```

If Ceph is NOT `HEALTH_OK`, ALSO CAPTURE:
- `ceph crash ls-new` and `ceph crash info <id>` (for each new crash)
- rook-ceph operator logs (recent)

### 1.8 Capture Platform Evidence (Ingress, Certs, Secrets, Observability)

EXECUTE these commands and CAPTURE output as evidence:

```bash
# Ingress
kubectl get pods -n ingress-nginx -o wide
kubectl get svc -n ingress-nginx
kubectl get ingress -A

# Certificates
kubectl get certificate -A
kubectl get certificaterequest -A | tail -200
kubectl get order -A | tail -200
kubectl get challenge -A | tail -200

# External Secrets
kubectl get externalsecret -A
kubectl get secretstore -A || true
kubectl get clustersecretstore -A || true

# Monitoring namespaces (inventory)
kubectl get pods -n monitoring-system -o wide || true
kubectl get pods -n grafana -o wide || true
```

### 1.9 Capture Apps Evidence (error-focused)

EXECUTE these commands to IDENTIFY problematic pods:

```bash
kubectl get pods -A --no-headers | grep -E "CrashLoopBackOff|Error|ImagePullBackOff|Pending" || true
kubectl get svc -A
```

For EACH non-running pod found, EXECUTE and CAPTURE:
- `kubectl describe pod -n <ns> <pod>`
- `kubectl logs -n <ns> <pod> --tail=200` (and `--previous` if crashed)

### 1.10 Capture Repo Evidence (Issues + PRs)

> [!IMPORTANT]
> **API Token Required**: SSH access only works for Git operations (clone/push/pull).
> Querying PRs and issues requires the Gitea REST API with `GITEA_TOKEN`.

EXECUTE repo evidence capture using the Gitea REST API:

#### 1.10.1 List Open Pull Requests

```bash
# Load token (choose your shell)
source ~/.config/gitea/.env                                                    # Bash/Zsh
set -x GITEA_TOKEN (cat ~/.config/gitea/.env | grep GITEA_TOKEN | cut -d= -f2) # Fish

# Get all open PRs in ops/homelab
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls?state=open" \
  -H "Authorization: token $GITEA_TOKEN" | \
  jq -r '.[] | "PR #\(.number): \(.title) by \(.user.login) (created: \(.created_at | split("T")[0]))"'
```

#### 1.10.2 List Open Issues (excluding maintenance label)

```bash
# Get all open issues
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/issues?state=open" \
  -H "Authorization: token $GITEA_TOKEN" | \
  jq -r '.[] | select(.labels | map(.name) | index("maintenance") | not) | "Issue #\(.number): \(.title)"'
```

#### 1.10.3 Detailed PR Data for Maintenance Issue

For each open PR, CAPTURE detailed information:

```bash
curl -s "https://git.eaglepass.io/api/v1/repos/ops/homelab/pulls?state=open" \
  -H "Authorization: token $GITEA_TOKEN" | \
  jq '[.[] | {
    number: .number,
    title: .title,
    author: .user.login,
    created_at: .created_at,
    mergeable: .mergeable,
    base: .base.ref,
    head: .head.ref,
    labels: [.labels[]?.name]
  }]'
```

DOCUMENT minimum fields per PR:
- PR number, title, author, created_at (age)
- mergeable state (and blocker if not)
- component affected, version delta
- risk (Low/Medium/High/Critical)

---

## Phase 2: Specification (Define the Maintenance Spec)

EXECUTE these steps to define the maintenance spec:

1. **IDENTIFY** all changes to be made based on Phase 1 evidence
2. **DOCUMENT** the reason (root cause, security, updates) for each change
3. **DEFINE** constraints: ordering dependencies, downtime windows, maintenance windows
4. **SET** acceptance criteria: ALL layers must reach GREEN status

The maintenance issue is the spec. ENSURE it captures:
- What changes will be made
- Why (findings, security, updates)
- Constraints (ordering, downtime, windows)
- Acceptance criteria (GREEN)

---

## Phase 3: Clarification (Decision Gates)

EXECUTE these decision rules:

1. **ASK** humans only when required by escalation rules
2. **ENCODE** all other decisions as tasks (checkboxes) so execution can proceed without missing context
3. **DOCUMENT** each decision gate with clear criteria for when human input is required

---

## Phase 4: Planning (Order, Gates, Stop Conditions)

### 4.1 Ordering Rules

APPLY these ordering rules to all tasks:

1. **PROCESS** priorities in order: `P0 → P1 → P2 → P3`
2. **ORDER** within a priority: `Metal → System → Platform → Apps`
3. **SCHEDULE** databases always last within a priority
4. **EXECUTE** one change at a time; validate GREEN after each

### 4.2 Universal Validation Gate (EXECUTE After Every Change)

EXECUTE this validation gate after every change:

```bash
kubectl get nodes | grep -v "Ready" || true
kubectl get pods -n kube-system | grep -v "Running\|Completed" || true
kubectl get applications -n argocd | grep -v "Synced.*Healthy" || true
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health
kubectl get pods -A --no-headers | grep -v "Running\|Completed" || true
```

**PASS Criteria** - ALL must be true:
- All greps return no output
- `ceph health` returns `HEALTH_OK`

**STOP Conditions** - HALT execution if any occur:
- Any non-GREEN result
- Any missing information needed to rollback safely

---

## Phase 5: Task Generation (Report + Maintenance Issue)

### 5.1 CREATE Status Report (Evidence Archive)

WRITE a report to `reports/`:
- Filename: `reports/status-report-YYYY-MM-DD.md`
- Content: raw evidence from Phase 1
- Purpose: archive for reference; maintenance issue stores actionable spec + tasks

### 5.2 CHECK for Existing Maintenance Issue

> [!CAUTION]
> You MUST check for an existing open maintenance issue BEFORE creating a new one.
> Creating duplicate maintenance issues is NOT ACCEPTABLE.

**Preferred Method: Script-Based (Recommended)**

```bash
# Check for existing issue
source ~/.config/gitea/.env
~/homelab/scripts/homelab-maintenance-issue.py --check-existing
```

**Output**: JSON with `exists`, `number`, `url` if found.

**Alternative: MCP Tool**

USE MCP tool: `gitea_list_repo_issues` with `state: open` and filter for label `maintenance`

**Decision Tree**:
- **IF issue found**: PROCEED to 5.3 (UPDATE existing issue)
- **IF no issue found**: PROCEED to 5.4 (CREATE new issue)

### 5.3 UPDATE Existing Maintenance Issue

**Preferred Method: Script-Based (Recommended)**

1. **POPULATE** the YAML schema with evidence data
2. **EXECUTE** the script to update the issue

```bash
# Populate YAML with evidence data, then (SELECT ONE):
source ~/.config/gitea/.env
python3 ~/.gemini/scripts/homelab-maintenance-issue.py --input /tmp/maintenance-data.yaml           # Antigravity
python3 ~/.config/opencode/scripts/homelab-maintenance-issue.py --input /tmp/maintenance-data.yaml  # Opencode
```

The script automatically:
- Finds the existing open maintenance issue
- Generates the markdown body from the YAML data
- Updates the issue body (NO COMMENTS)

**Alternative: MCP Tool**

```bash
# USE MCP tool: gitea_edit_issue
```

### 5.4 CREATE New Maintenance Issue

**Preferred Method: Script-Based (Recommended)**

1. **POPULATE** the YAML schema (`homelab-maintenance-issue.schema.yaml`) with evidence data
2. **EXECUTE** the script to create the issue

```bash
# Populate YAML with evidence data, then (SELECT ONE):
source ~/.config/gitea/.env
python3 ~/.gemini/scripts/homelab-maintenance-issue.py --input /tmp/maintenance-data.yaml           # Antigravity
python3 ~/.config/opencode/scripts/homelab-maintenance-issue.py --input /tmp/maintenance-data.yaml  # Opencode
```

The script automatically:
- Generates the markdown body from the YAML data
- Creates the issue with correct title format
- Adds the `maintenance` label (ID: 10)
- Assigns to `gitea_admin`

**YAML Schema Location** (SELECT ONE):
- Antigravity: `~/.gemini/scripts/homelab-maintenance-issue.schema.yaml`
- Opencode: `~/.config/opencode/scripts/homelab-maintenance-issue.schema.yaml`

**Alternative: MCP Tool**

```bash
# USE MCP tools: gitea_create_issue + gitea_add_issue_labels
```

### 5.5 Maintenance Issue Structure Requirements

> The maintenance issue MUST follow the structure defined in:
> - Antigravity: `~/.gemini/scripts/homelab-maintenance-issue-template.md`
> - Opencode: `~/.config/opencode/scripts/homelab-maintenance-issue-template.md`
> This template is the contract - any deviation is a workflow failure.

**Required Sections** (in order):
1. **Status** - Overall status, last updated, source report
2. **Context Pack** - Cluster identity, health evidence, repo inventory
3. **Proposed Changes (Spec)** - Table with ID, Type, Layer, Priority, Impact, Downtime, Summary, Dependencies
4. **Execution Plan** - Ordering rules, validation gate, stop conditions
5. **Action Items (Tasks)** - Ordered checkboxes with Goal/Commands/Expected/If-fails/Rollback
6. **Change Log** - Timestamped record of actions taken
7. **Closure** - Filled by homelab-action when complete

**Action Item Ordering Rules**:
| Order | Criteria | Example |
|:-----:|----------|---------|
| 1st | Priority | P0 before P1 before P2 before P3 |
| 2nd | Layer | Metal → System → Platform → Apps |
| 3rd | Dependencies | Prerequisites before dependent items |
| 4th | Risk | Lower risk items before higher risk |
| Last | Databases | Always processed last within priority |

**Each Action Item MUST Include**:
- **Goal**: What this action achieves
- **Commands**: Exact commands to run
- **Expected**: Success criteria
- **If fails**: Next diagnostic steps
- **Rollback**: Exact rollback commands or "N/A"

---

## Phase 6: Analysis (Automated Self-Audit - USER INTERACTION FORBIDDEN)

> [!CAUTION]
> **AGENT AUTHORITY ONLY**: This phase is an **AUTOMATED SELF-AUDIT**.
> **DO NOT** stop to ask the user to verify. **YOU** must verify against the criteria below.
> The only valid stopping point is Phase 8 (Handoff).

Before handing off to `/homelab-action`, EXECUTE this self-audit checklist **AUTONOMOUSLY**:

- [ ] **VERIFY** every non-GREEN finding has a remediation task OR an explicit decision gate
- [ ] **VERIFY** every PR has: spec row + merge/close decision + validation task
- [ ] **VERIFY** every major/breaking update has: release notes + breaking-change checklist + staged rollout tasks
- [ ] **VERIFY** risky steps include backups + rollback procedures
- [ ] **VERIFY** tasks are top-level `- [ ]`, atomic, and ordered per Phase 4
- [ ] **CONFIRM** all contract requirements from "Maintenance Issue Contract" section are met

**IF ANY CHECK FAILS**: RETURN to Phase 1 and GATHER missing data.
**IF ALL CHECKS PASS**: PROCEED IMMEDIATELY to Phase 8. DO NOT ASK FOR PERMISSION.

---

## Phase 7: Remediation (Fix Gaps)

EXECUTE these steps if Phase 6 audit failed:

1. **IDENTIFY** specific gaps from Phase 6 audit failures
2. **GATHER** missing data by re-executing relevant Phase 1 steps
3. **UPDATE** the maintenance issue body (no comments) with corrected/complete information
4. **RE-RUN** Phase 6 self-audit
5. **REPEAT** until ALL Phase 6 checks pass

---

## Phase 8: Handoff (Recon Complete)

> [!IMPORTANT]
> **RECON STOPS HERE.** This workflow does NOT execute actions or make changes.
> The maintenance issue is now ready for `/homelab-action` to consume.

When Phase 7 (Remediation) completes successfully (or was skipped because Phase 6 passed), the recon workflow is COMPLETE.

**What happens next** (NOT part of this workflow):
1. The **user** or a **scheduled job** runs `/homelab-action`
2. `/homelab-action` consumes the maintenance issue and executes the tasks
3. After action completes, `/homelab-recon` can be run again for validation

**This workflow's deliverables**:
1. ✅ Status report at `reports/status-report-YYYY-MM-DD.md`
2. ✅ Maintenance issue created/updated in Gitea with all required sections
3. ✅ All evidence captured and documented
4. ✅ All action items are atomic, ordered, and include rollback procedures

> [!CAUTION]
> **DO NOT** proceed to execute `/homelab-action` as part of this workflow.
> **DO NOT** make any cluster changes, merge PRs, or modify infrastructure.
> This is RECON ONLY.

---

## MCP Tool Integration

### Available MCP Servers

| Server | Purpose | Example Tools |
|--------|---------|---------------|
| **kubernetes** | Cluster operations | `mcp_kubernetes_kubectl_get`, `mcp_kubernetes_kubectl_apply` |
| **shell** | Shell command execution | `mcp_shell_shell_exec` |

### Gitea Access (REST API)

> [!NOTE]
> No Gitea MCP server is currently configured. Use the REST API directly with `curl`.

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List PRs | GET | `/api/v1/repos/ops/homelab/pulls?state=open` |
| List Issues | GET | `/api/v1/repos/ops/homelab/issues?state=open` |
| Get Issue | GET | `/api/v1/repos/ops/homelab/issues/{index}` |
| Update Issue | PATCH | `/api/v1/repos/ops/homelab/issues/{index}` |
| Create Issue | POST | `/api/v1/repos/ops/homelab/issues` |
| Add Labels | POST | `/api/v1/repos/ops/homelab/issues/{index}/labels` |

**All requests require header**: `Authorization: token $GITEA_TOKEN`

**Token Location**:
```bash
~/.config/gitea/.env        # Format: GITEA_TOKEN=your_token_here
```

**API Base URL**: `https://git.eaglepass.io/api/v1`

---

## Execution Checklist

COMPLETE **ALL** items before considering workflow finished:

### Phase 1: Context Loading
- [ ] 1.1 Access established (workstation or controller fallback)
- [ ] 1.2 Access validated (kubectl, SSH, Gitea API all succeed)
- [ ] 1.3 Baseline health snapshot captured
- [ ] 1.4 Network evidence captured (VLANs, OPNSense, latency)
- [ ] 1.5 Storage/NAS evidence captured (Unraid reachability, shares)
- [ ] 1.6 System/Core evidence captured (kube-system, CNI)
- [ ] 1.7 Ceph Storage evidence captured (Rook/Ceph)
- [ ] 1.8 Platform evidence captured (Ingress, Certs, Secrets, Observability)
- [ ] 1.9 Apps evidence captured (error-focused)
- [ ] 1.10 Repo evidence captured (Issues + PRs)

### Phase 2: Specification
- [ ] 2.1 All changes identified from Phase 1 evidence
- [ ] 2.2 Reasons documented for each change
- [ ] 2.3 Constraints defined (ordering, downtime, windows)
- [ ] 2.4 Acceptance criteria set (ALL layers GREEN)

### Phase 3: Clarification
- [ ] 3.1 Decision gates identified
- [ ] 3.2 Human escalation rules applied where required
- [ ] 3.3 All other decisions encoded as tasks

### Phase 4: Planning
- [ ] 4.1 Tasks ordered by priority (P0→P3) and layer (Metal→Network→Storage→System→Platform→Apps)
- [ ] 4.2 Validation gate defined for post-change checks
- [ ] 4.3 Stop conditions documented

### Phase 5: Task Generation
- [ ] 5.1 Status report written to `reports/status-report-YYYY-MM-DD.md`
- [ ] 5.2 Maintenance issue created OR updated (body edited, no comments)
- [ ] 5.3 Issue follows contract template (all required sections present)

### Phase 6: Analysis (Automated Self-Audit)
- [ ] 6.1 Every non-GREEN finding has a remediation task or decision gate
- [ ] 6.2 Every PR has spec row + decision + validation task
- [ ] 6.3 Major/breaking updates have release notes + staged rollout
- [ ] 6.4 Risky steps include backups + rollback procedures
- [ ] 6.5 Tasks are top-level `- [ ]`, atomic, and ordered
- [ ] 6.6 ALL contract requirements met (AGENT VERIFIED)

### Phase 7: Remediation (if Phase 6 failed)
- [ ] 7.1 Gaps identified from Phase 6 failures
- [ ] 7.2 Missing data gathered via Phase 1 re-execution
- [ ] 7.3 Maintenance issue updated with corrections
- [ ] 7.4 Phase 6 self-audit re-run and PASSED

### Phase 8: Handoff (Recon Complete)
- [ ] 8.1 Status report written and complete
- [ ] 8.2 Maintenance issue ready for `/homelab-action` consumption
- [ ] 8.3 NO changes made to cluster, repos, or infrastructure

---

## Completion Criteria

**This workflow is COMPLETE when ALL of the following are TRUE:**

1. ✅ Phase 1 evidence is fully captured and documented (all 10 sub-items)
2. ✅ Status report exists at `reports/status-report-YYYY-MM-DD.md`
3. ✅ Maintenance issue is created/updated with ALL required sections filled
4. ✅ Phase 6 self-audit passes (ALL checks verified)
5. ✅ Maintenance issue is ready for `/homelab-action` to consume

> [!CAUTION]
> **RECON DOES NOT**:
> - Execute `/homelab-action`
> - Make cluster changes
> - Merge PRs
> - Close issues
> - Modify infrastructure
>
> If all layers are already GREEN, the maintenance issue will reflect that with no action items.

---

## Mandatory Rules

These rules are NON-NEGOTIABLE:

1. **EXECUTE evidence capture EXHAUSTIVELY - no partial snapshots**
2. **ALWAYS EDIT the issue body, NEVER add comments**
3. **VALIDATE ALL layers before considering recon complete**
4. **ZERO tolerance for incomplete maintenance issues**
5. **IF any Phase 6 audit check fails, RETURN to Phase 1**
6. **NEVER proceed to handoff without a contract-complete maintenance issue**
7. **ALWAYS document findings with timestamps and evidence**

