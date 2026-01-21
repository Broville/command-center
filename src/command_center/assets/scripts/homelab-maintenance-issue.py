#!/usr/bin/env python3
"""
homelab-maintenance-issue.py - Create or update Gitea maintenance issues

Usage:
    # From YAML file
    homelab-maintenance-issue.py --input data.yaml

    # From stdin (pipe YAML)
    cat data.yaml | homelab-maintenance-issue.py

    # Check for existing issue only
    homelab-maintenance-issue.py --check-existing

Environment Variables:
    GITEA_TOKEN  - Gitea API access token (required)
    GITEA_URL    - Gitea base URL (default: https://git.eaglepass.io)

Exit Codes:
    0 - Success
    1 - Error
    2 - No changes needed (issue already up-to-date)
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


# Configuration
GITEA_URL = os.environ.get("GITEA_URL", "https://git.eaglepass.io")
GITEA_TOKEN = os.environ.get("GITEA_TOKEN", "")
REPO_OWNER = "ops"
REPO_NAME = "homelab"
MAINTENANCE_LABEL_ID = 10
ASSIGNEE = "gitea_admin"


def api_request(endpoint: str, method: str = "GET", data: dict = None) -> dict:
    """Make a Gitea API request."""
    url = f"{GITEA_URL}/api/v1{endpoint}"
    headers = {
        "Authorization": f"token {GITEA_TOKEN}",
        "Content-Type": "application/json",
    }

    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, headers=headers, method=method)

    try:
        with urlopen(req, timeout=30) as response:
            return json.loads(response.read().decode())
    except HTTPError as e:
        error_body = e.read().decode() if e.fp else ""
        raise RuntimeError(f"API error {e.code}: {error_body}")
    except URLError as e:
        raise RuntimeError(f"Connection error: {e.reason}")


def find_existing_maintenance_issue() -> dict | None:
    """Find an open maintenance issue if one exists."""
    endpoint = f"/repos/{REPO_OWNER}/{REPO_NAME}/issues?state=open&labels=maintenance"
    issues = api_request(endpoint)

    for issue in issues:
        # Skip PRs (they also appear in issues endpoint)
        if "pull_request" in issue and issue["pull_request"]:
            continue
        return issue
    return None


def status_emoji(status: str) -> str:
    """Convert status string to emoji."""
    return {"RED": "🔴", "YELLOW": "🟡", "GREEN": "🟢"}.get(status.upper(), "⚪")


def generate_issue_body(data: dict) -> str:
    """Generate markdown issue body from structured data."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M %Z")
    date = data.get("date") or datetime.now().strftime("%Y-%m-%d")

    # Status section
    body = f"""# [Maintenance] {date} - Homelab

## Status

| Field | Value |
|-------|-------|
| **Overall Status** | {status_emoji(data['status']['overall'])} {data['status']['overall']} |
| **Last Updated** | {now} |
| **Source Report** | `{data['status'].get('source_report', 'N/A')}` |
| **Assigned To** | {data['status'].get('assigned_to', ASSIGNEE)} |

---

## Context Pack

### Cluster Identity
| Component | Value |
|-----------|-------|
| K3s Version | {data['cluster'].get('k3s_version', 'N/A')} |
| Node Count | {data['cluster'].get('node_count', 'N/A')} |
| ArgoCD Apps | {data['cluster'].get('argocd_apps_total', 'N/A')} total |
| Ceph Status | {data['cluster'].get('ceph_status', 'N/A')} |

### Current Health Evidence (Snapshot)
| Layer | Status | Summary |
|-------|:------:|---------|
"""

    # Layer health
    layers = data.get("layers", {})
    layer_order = ["metal", "network", "storage_nas", "system", "platform", "apps"]
    layer_names = {
        "metal": "Metal",
        "network": "Network",
        "storage_nas": "Storage (NAS)",
        "system": "System",
        "platform": "Platform",
        "apps": "Apps",
    }

    for layer_key in layer_order:
        layer = layers.get(layer_key, {})
        status = layer.get("status", "GREEN")
        summary = layer.get("summary", "")
        body += f"| **{layer_names[layer_key]}** | {status_emoji(status)} | {summary} |\n"

    # Non-running pods
    non_running = data.get("non_running_pods", [])
    if non_running:
        body += """
### Non-Running Pods
| Namespace | Pod | Status | Age |
|-----------|-----|--------|-----|
"""
        for pod in non_running:
            body += f"| {pod['namespace']} | {pod['pod']} | {pod['status']} | {pod.get('age', 'N/A')} |\n"

    # Repo inventory
    repo = data.get("repo_inventory", {})
    body += f"""
### Repo Inventory (Actionable)
| Category | Count | Details |
|----------|:-----:|---------|
| Open Renovate PRs | {len(repo.get('open_renovate_prs', []))} | {', '.join(f'#{p}' for p in repo.get('open_renovate_prs', [])) or 'None'} |
| Open User PRs | {len(repo.get('open_user_prs', []))} | {', '.join(f'#{p}' for p in repo.get('open_user_prs', [])) or 'None'} |
| Open Non-Maintenance Issues | {len(repo.get('open_issues', []))} | {', '.join(f'#{i}' for i in repo.get('open_issues', [])) or 'None'} |

---

## Proposed Changes (Spec)

| ID | Type | Layer | Priority | Impact | Downtime | Summary | Dependencies |
|:--:|------|:-----:|:--------:|:------:|:--------:|---------|:------------:|
"""

    # Proposed changes
    for change in data.get("proposed_changes", []):
        deps = ", ".join(change.get("dependencies", [])) or "None"
        body += f"| {change['id']} | {change['type']} | {change['layer']} | {change['priority']} | {change['impact']} | {change['downtime']} | {change['summary']} | {deps} |\n"

    if not data.get("proposed_changes"):
        body += "| - | - | - | - | - | - | No changes required | - |\n"

    body += """
---

## Execution Plan

### Ordering Rules Applied
1. Priority: P0 → P1 → P2 → P3
2. Layer: Metal → Network → Storage → System → Platform → Apps
3. Dependencies: Complete prerequisites before dependent items
4. Databases: Always last within a priority level

### Validation Gate (Run After EVERY Change)
```bash
# Run comprehensive validation
~/homelab/scripts/recon.sh
~/homelab/scripts/homelab-network-check.sh --json
~/homelab/scripts/homelab-nas-check.sh --json
```

### Stop Conditions
- ❌ Any validation check fails
- ❌ Unknown rollback procedure
- ❌ Human escalation required

---

## Action Items (Tasks)

"""

    # Group action items by phase
    phases = {"A": "Preflight", "B": "Critical (P0)", "C": "High (P1)", "D": "Medium (P2)", "E": "Low (P3)", "F": "Final Validation"}
    items_by_phase = {}
    for item in data.get("action_items", []):
        phase = item.get("phase", "A")
        if phase not in items_by_phase:
            items_by_phase[phase] = []
        items_by_phase[phase].append(item)

    for phase_key in sorted(items_by_phase.keys()):
        body += f"\n### Phase {phase_key}: {phases.get(phase_key, 'Other')}\n"
        for item in items_by_phase[phase_key]:
            layer_str = f" {item['layer']}" if item.get("layer") else ""
            body += f"""- [ ] **{item['id']} {item['priority']}{layer_str}**: {item['title']}
  - **Goal**: {item.get('goal', 'N/A')}
  - **Commands**: `{item.get('commands', 'N/A')}`
  - **Expected**: {item.get('expected', 'N/A')}
  - **If fails**: {item.get('if_fails', 'N/A')}
  - **Rollback**: {item.get('rollback', 'N/A')}

"""

    if not data.get("action_items"):
        body += "No action items required - all layers GREEN.\n"

    body += """---

## Change Log

| Timestamp | Phase | Item | Action | Result | Status After |
|-----------|:-----:|------|--------|--------|:------------:|
"""

    for log in data.get("change_log", []):
        body += f"| {log['timestamp']} | {log['phase']} | {log['item']} | {log['action']} | {log['result']} | {status_emoji(log['status_after'])} |\n"

    if not data.get("change_log"):
        body += "| - | - | - | No actions yet | - | - |\n"

    body += """
---

## Closure (Filled by homelab-action on completion)

### Resolution Summary
| Field | Value |
|-------|-------|
| **Status** | PENDING |
| **Started** | - |
| **Completed** | - |
| **Duration** | - |
| **Resolved By** | - |

---

*Created/Updated by homelab-recon workflow*
*Last modified: """ + now + "*"

    return body


def create_issue(data: dict) -> dict:
    """Create a new maintenance issue."""
    date = data.get("date") or datetime.now().strftime("%Y-%m-%d")
    title = data.get("title") or f"[Maintenance] {date} - Homelab"
    body = generate_issue_body(data)

    payload = {
        "title": title,
        "body": body,
        "labels": [MAINTENANCE_LABEL_ID],
        "assignees": [ASSIGNEE],
    }

    endpoint = f"/repos/{REPO_OWNER}/{REPO_NAME}/issues"
    return api_request(endpoint, method="POST", data=payload)


def update_issue(issue_number: int, data: dict) -> dict:
    """Update an existing maintenance issue."""
    body = generate_issue_body(data)

    payload = {"body": body}

    endpoint = f"/repos/{REPO_OWNER}/{REPO_NAME}/issues/{issue_number}"
    return api_request(endpoint, method="PATCH", data=payload)


def main():
    parser = argparse.ArgumentParser(description="Create or update Gitea maintenance issues")
    parser.add_argument("--input", "-i", help="Path to YAML input file (or use stdin)")
    parser.add_argument("--check-existing", action="store_true", help="Just check for existing issue")
    parser.add_argument("--json-input", action="store_true", help="Input is JSON instead of YAML")
    args = parser.parse_args()

    if not GITEA_TOKEN:
        print("ERROR: GITEA_TOKEN environment variable not set", file=sys.stderr)
        print("Run: source ~/.config/gitea/.env", file=sys.stderr)
        sys.exit(1)

    # Just check for existing issue
    if args.check_existing:
        issue = find_existing_maintenance_issue()
        if issue:
            print(json.dumps({
                "exists": True,
                "number": issue["number"],
                "title": issue["title"],
                "url": issue["html_url"],
                "state": issue["state"],
            }))
        else:
            print(json.dumps({"exists": False}))
        sys.exit(0)

    # Read input data
    if args.input:
        with open(args.input, "r") as f:
            content = f.read()
    elif not sys.stdin.isatty():
        content = sys.stdin.read()
    else:
        print("ERROR: No input provided. Use --input FILE or pipe YAML to stdin.", file=sys.stderr)
        sys.exit(1)

    # Parse input
    if args.json_input:
        data = json.loads(content)
    elif YAML_AVAILABLE:
        data = yaml.safe_load(content)
    else:
        # Try JSON as fallback
        try:
            data = json.loads(content)
        except json.JSONDecodeError:
            print("ERROR: PyYAML not installed and input is not valid JSON", file=sys.stderr)
            print("Install with: pip install pyyaml", file=sys.stderr)
            sys.exit(1)

    # Check for existing issue
    existing = find_existing_maintenance_issue()

    if existing:
        print(f"Updating existing issue #{existing['number']}...", file=sys.stderr)
        result = update_issue(existing["number"], data)
        action = "updated"
    else:
        print("Creating new maintenance issue...", file=sys.stderr)
        result = create_issue(data)
        action = "created"

    # Output result
    print(json.dumps({
        "action": action,
        "number": result["number"],
        "title": result["title"],
        "url": result["html_url"],
        "state": result["state"],
    }))

    print(f"✓ Issue #{result['number']} {action}: {result['html_url']}", file=sys.stderr)


if __name__ == "__main__":
    main()
