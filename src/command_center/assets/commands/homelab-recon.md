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

It is **Spec-Driven Development (SDD)** adapted to operations:
- **Context**: evidence capture (cluster + repo)
- **Spec**: the maintenance issue (what should change, and why)
- **Plan**: ordering + safety gates + stop conditions
- **Tasks**: top-level issue checkboxes (`- [ ]`) that are atomic
- **Analysis**: self-audit that the issue is complete and actionable
- **Remediation**: fill gaps, rerun analysis
- **Implementation**: delegated to `/homelab-action`
- **Validation**: recon + troubleshoot + recon until GREEN

> [!CAUTION]
> **FOUNDATIONAL RULES APPLY** - See `_foundational-rules.md`.
> The workflow is NOT complete until ALL layers are GREEN (or issues are fully captured in a maintenance issue for action).

> [!IMPORTANT]
> **Do NOT add comments to issues.** Comments are reserved for humans only.
> Always **edit the original issue body** to merge new data into the existing content.

## References

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

source ~/.config/gitea/.env
curl -s "https://git.eaglepass.io/api/v1/user" -H "Authorization: token $GITEA_TOKEN" | jq -r '.login'
```

### 1.3 Capture Baseline Health Snapshot

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

### 1.4 Capture System/Core Evidence (kube-system, CNI)

EXECUTE these commands and CAPTURE output as evidence:

```bash
kubectl get pods -n kube-system -o wide
kubectl get pods -n kube-system --no-headers | grep -v "Running\|Completed" || true

# Cilium (if present)
kubectl -n kube-system get ds | grep -i cilium || true
kubectl -n kube-system get pods -l k8s-app=cilium -o wide || true
```

### 1.5 Capture Storage Evidence (Rook/Ceph)

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

### 1.6 Capture Platform Evidence (Ingress, Certs, Secrets, Observability)

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

### 1.7 Capture Apps Evidence (error-focused)

EXECUTE these commands to IDENTIFY problematic pods:

```bash
kubectl get pods -A --no-headers | grep -E "CrashLoopBackOff|Error|ImagePullBackOff|Pending" || true
kubectl get svc -A
```

For EACH non-running pod found, EXECUTE and CAPTURE:
- `kubectl describe pod -n <ns> <pod>`
- `kubectl logs -n <ns> <pod> --tail=200` (and `--previous` if crashed)

### 1.8 Capture Repo Evidence (Issues + PRs)

EXECUTE repo evidence capture using these methods:

**Preferred Method**: USE MCP tools (`gitea_list_repo_pull_requests`, `gitea_list_repo_issues`)
**Fallback Method**: USE Gitea API (only if MCP unavailable)

CAPTURE for each category:
- Open PRs (Renovate vs user)
- Open issues (excluding `maintenance`)
- Mergeable vs conflicted PRs

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

### 5.2 CREATE or UPDATE Maintenance Issue

EXECUTE these steps in order:

1. **FIND** the latest open issue labeled `maintenance`
2. **IF FOUND**: EDIT body (no comments), MERGE new findings into existing content
3. **IF NOT FOUND**: CREATE a new issue titled `[Maintenance] YYYY-MM-DD - Homelab`
4. **ALWAYS** add label `maintenance` (ID: 10)
5. **ALWAYS** assign `gitea_admin`

### 5.3 Maintenance Issue Template (Contract-Complete)

USE this template for the maintenance issue:

```markdown
# [Maintenance] YYYY-MM-DD - Homelab

## Status
- **Overall**: GREEN / YELLOW / RED
- **Last Updated**: YYYY-MM-DD HH:MM TZ
- **Source Report**: `reports/status-report-YYYY-MM-DD.md`

---

## Context Pack

### Cluster Identity
- K3s version: ...
- Node count: ...
- ArgoCD apps: ...
- Ceph: HEALTH_OK/...

### Current Health Evidence (Snapshot)
- Nodes: ...
- Non-running pods: ...
- ArgoCD non-healthy apps: ...
- Ceph health summary: ...

### Repo Inventory (Actionable)
- Open Renovate PRs: ...
- Open user PRs: ...
- Open non-maintenance issues: ...

---

## Proposed Changes (Spec)

| Item | Type | Layer | Priority | Risk | Summary | Notes |
|------|------|:-----:|:--------:|:----:|---------|-------|

---

## Execution Plan
- Ordering: P0→P3, Metal→Apps, DB last
- Validation gate: run after every change
- Stop conditions: any non-GREEN, any unknown rollback

---

## Action Items (Tasks)

> All executable steps MUST be top-level `- [ ]` checkboxes.
> Each checkbox MUST be atomic.

### Phase A: Preflight
- [ ] A1 P0 Preflight: verify access (kubectl/controller/gitea)
- [ ] A2 P0 Preflight: capture baseline snapshot (nodes/pods/apps/ceph)

### Phase B: Remediate Current Findings
- [ ] B1 P0 System: resolve any Ceph HEALTH_WARN/ERR

### Phase C: Planned Changes (ordered)
- [ ] C1 P2 PR #X: read release notes + list breaking changes
- [ ] C2 P2 PR #X: merge PR
- [ ] C3 P2 PR #X: run validation gate, document outcome

### Phase D: Final Validation
- [ ] D1 P0 Run `/homelab-recon` (final)

---

## Change Log
| Timestamp | Step | Item | Result | Status After |
|-----------|:----:|------|--------|:------------:|

---

## Closure (Filled by homelab-action)
(Use the closure template defined in `homelab-action.md`)
```

---

## Phase 6: Analysis (Self-Audit: Is the Issue Truly EXHAUSTIVE?)

Before handing off to `/homelab-action`, EXECUTE this self-audit checklist:

- [ ] **VERIFY** every non-GREEN finding has a remediation task OR an explicit decision gate
- [ ] **VERIFY** every PR has: spec row + merge/close decision + validation task
- [ ] **VERIFY** every major/breaking update has: release notes + breaking-change checklist + staged rollout tasks
- [ ] **VERIFY** risky steps include backups + rollback procedures
- [ ] **VERIFY** tasks are top-level `- [ ]`, atomic, and ordered per Phase 4
- [ ] **CONFIRM** all contract requirements from "Maintenance Issue Contract" section are met

**IF ANY CHECK FAILS**: RETURN to Phase 1 and GATHER missing data.

---

## Phase 7: Remediation (Fix Gaps)

EXECUTE these steps if Phase 6 audit failed:

1. **IDENTIFY** specific gaps from Phase 6 audit failures
2. **GATHER** missing data by re-executing relevant Phase 1 steps
3. **UPDATE** the maintenance issue body (no comments) with corrected/complete information
4. **RE-RUN** Phase 6 self-audit
5. **REPEAT** until ALL Phase 6 checks pass

---

## Phase 8: Implementation (Delegate)

EXECUTE `/homelab-action` to consume the maintenance issue tasks.

**DO NOT PROCEED** to Phase 9 until `/homelab-action` completes.

---

## Phase 9: Validation & Closure

After `/homelab-action` completes, EXECUTE these steps in order:

1. **RUN** `/homelab-recon` to confirm all layers GREEN
2. **IF ANY** layer is not GREEN: RUN `/homelab-troubleshoot` to drive back to GREEN
3. **RUN** `/homelab-recon` again as final proof
4. **ENSURE** the maintenance issue is closed with `[RESOLVED]` and includes closure notes
5. **VERIFY** closure notes document: what was done, final state, any follow-up items

---

## MCP Tool Integration (Preferred Method)

USE MCP tools for all repo interactions when available:

- `gitea_list_repo_issues` - LIST open issues
- `gitea_list_repo_pull_requests` - LIST open PRs
- `gitea_create_issue` - CREATE new maintenance issue
- `gitea_edit_issue` - UPDATE existing issue body
- `gitea_add_issue_labels` - ADD labels to issue

---

## Gitea API Fallback (Emergency Only)

> [!WARNING]
> USE only if MCP tools are unavailable.

### Token Location
```bash
~/.config/gitea/.env        # bash/zsh
~/.config/gitea/gitea.fish  # fish
```

### API Base URL
`https://git.eaglepass.io/api/v1`

---

## Execution Checklist

COMPLETE all items before considering workflow finished:

- [ ] Phase 1: Access verified, evidence captured
- [ ] Phase 5: Status report written to `reports/`
- [ ] Phase 5: Maintenance issue created/updated (no comments)
- [ ] Phase 6: Maintenance issue passes self-audit (ALL checks verified)
- [ ] Phase 9: Final recon + troubleshoot loop yields all GREEN

---

## Completion Criteria

**This workflow is COMPLETE when ALL of the following are TRUE:**

1. ✅ Phase 1 evidence is fully captured and documented
2. ✅ Status report exists at `reports/status-report-YYYY-MM-DD.md`
3. ✅ Maintenance issue is created/updated with ALL required sections filled
4. ✅ Phase 6 self-audit passes (ALL checks verified)
5. ✅ ALL infrastructure layers report GREEN status
6. ✅ Maintenance issue is closed with `[RESOLVED]` status and closure notes

> [!CAUTION]
> **DO NOT STOP UNTIL ALL CRITERIA ARE MET.**

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

