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
    return {"RED": "🔴", "YELLOW": "🟡", "GREEN": "🟢"}.get(
        status.upper().strip(), "⚪"
    )


def format_table_row(items: list) -> str:
    """Format a list of items as a markdown table row."""
    return f"| {' | '.join(str(i) for i in items)} |\n"


def generate_issue_body(data: dict, template_path: Path = None) -> str:
    """Generate markdown issue body by filling the template."""

    # 1. Load Template
    if not template_path:
        # Default: ../templates/homelab-maintenance-issue-template.md relative to script
        # This assumes the script is in 'scripts/' and template is in 'templates/' at the same level
        template_path = (
            Path(__file__).resolve().parent.parent
            / "templates"
            / "homelab-maintenance-issue-template.md"
        )

    try:
        if not template_path.exists():
            # Fallback for debugging or if file missing - but realistically should fail
            print(f"WARNING: Template not found at {template_path}", file=sys.stderr)
            return f"# Error\nTemplate not found at {template_path}"

        raw_template = template_path.read_text(encoding="utf-8")
        # Extract content between ```markdown and closing ``` fences
        import re

        fence_match = re.search(
            r"```markdown\s*\n(.*)\n```\s*$", raw_template, re.DOTALL
        )
        if fence_match:
            template_content = fence_match.group(1)
        else:
            template_content = raw_template
    except Exception as e:
        print(f"ERROR: Failed to load template: {e}", file=sys.stderr)
        return f"# Error\nFailed to load template: {e}"

    now = datetime.now().strftime("%Y-%m-%d %H:%M %Z")
    date = data.get("date") or datetime.now().strftime("%Y-%m-%d")

    # Helper to safely get nested keys
    def get_val(d, path, default="N/A"):
        keys = path.split(".")
        curr = d
        for k in keys:
            if isinstance(curr, dict):
                curr = curr.get(k, {})
            else:
                return default
        return curr if not isinstance(curr, dict) else default

    # Helper for status/details pairs
    def get_status_details(layer, component):
        base = data.get("layers", {}).get(layer, {}).get(component, {})
        status = base.get("status", "N/A")
        details = base.get("details", "")
        return status_emoji(status), details

    # Extract all values for replacement
    values = {
        "date": date,
        "status_emoji": status_emoji(get_val(data, "status.overall", "RED")),
        "status_text": get_val(data, "status.overall", "RED"),
        "timestamp": now,
        "source_report": get_val(data, "status.source_report", "N/A"),
        "k3s_version": get_val(data, "cluster.k3s_version"),
        "node_count": get_val(data, "cluster.node_count"),
        "app_count": get_val(data, "cluster.app_count"),
        "ceph_status": get_val(data, "cluster.ceph_status"),
        # Metal
        "metal_nodes_status": get_status_details("metal", "nodes")[0],
        "metal_nodes_details": get_status_details("metal", "nodes")[1],
        "metal_versions_status": get_status_details("metal", "versions")[0],
        "metal_versions_details": get_status_details("metal", "versions")[1],
        "metal_cni_status": get_status_details("metal", "cni")[0],
        "metal_cni_details": get_status_details("metal", "cni")[1],
        "metal_kured_status": get_status_details("metal", "kured")[0],
        "metal_kured_details": get_status_details("metal", "kured")[1],
        # System
        "system_coredns_status": get_status_details("system", "coredns")[0],
        "system_coredns_details": get_status_details("system", "coredns")[1],
        "system_metrics_status": get_status_details("system", "metrics_server")[0],
        "system_metrics_details": get_status_details("system", "metrics_server")[1],
        "system_kubevip_status": get_status_details("system", "kube_vip")[0],
        "system_kubevip_details": get_status_details("system", "kube_vip")[1],
        "system_argocd_status": get_status_details("system", "argocd")[0],
        "system_argocd_details": get_status_details("system", "argocd")[1],
        # Storage
        "storage_ceph_status": get_status_details("storage", "ceph_health")[0],
        "storage_ceph_details": get_status_details("storage", "ceph_health")[1],
        "storage_osd_status": get_status_details("storage", "osds")[0],
        "storage_osds_details": get_status_details("storage", "osds")[1],
        "storage_usage_status": get_status_details("storage", "usage")[0],
        "storage_usage_details": get_status_details("storage", "usage")[1],
        "storage_pools_status": get_status_details("storage", "pools")[0],
        "storage_pools_details": get_status_details("storage", "pools")[1],
        "storage_mons_status": get_status_details("storage", "monitors")[0],
        "storage_mons_details": get_status_details("storage", "monitors")[1],
        "storage_mds_status": get_status_details("storage", "mds")[0],
        "storage_mds_details": get_status_details("storage", "mds")[1],
        # Platform
        "platform_ingress_status": get_status_details("platform", "ingress")[0],
        "platform_ingress_details": get_status_details("platform", "ingress")[1],
        "platform_certs_status": get_status_details("platform", "certs")[0],
        "platform_certs_details": get_status_details("platform", "certs")[1],
        "platform_secrets_status": get_status_details("platform", "secrets")[0],
        "platform_secrets_details": get_status_details("platform", "secrets")[1],
        "platform_certmgr_status": get_status_details("platform", "cert_manager")[0],
        "platform_certmgr_details": get_status_details("platform", "cert_manager")[1],
        # Apps
        "apps_pods_status": get_status_details("apps", "pods")[0],
        "apps_pods_details": get_status_details("apps", "pods")[1],
        "apps_gitea_status": get_status_details("apps", "gitea")[0],
        "apps_gitea_details": get_status_details("apps", "gitea")[1],
        "apps_grafana_status": get_status_details("apps", "grafana")[0],
        "apps_grafana_details": get_status_details("apps", "grafana")[1],
        "apps_kanidm_status": get_status_details("apps", "kanidm")[0],
        "apps_kanidm_details": get_status_details("apps", "kanidm")[1],
        # Observations
        "observations_node_activity": get_val(
            data, "observations.node_activity", "None"
        ),
        "observations_renovate": get_val(data, "observations.renovate", "None"),
        "net_workstation_status": get_val(
            data, "observations.network.workstation", "N/A"
        ),
        "net_gitea_status": get_val(data, "observations.network.gitea", "N/A"),
        "net_nas_status": get_val(data, "observations.network.nas", "N/A"),
        "net_gateway_status": get_val(data, "observations.network.gateway", "N/A"),
    }

    # Perform basic substitutions
    body = template_content
    for key, val in values.items():
        # Space-lenient replacement for {{ key }} or {{key}}
        body = body.replace(f"{{{{ {key} }}}}", str(val)).replace(
            f"{{{{{key}}}}}", str(val)
        )

    # Proposed Changes Rows
    proposed_rows = ""
    if data.get("proposed_changes"):
        for change in data.get("proposed_changes", []):
            deps = ", ".join(change.get("dependencies", [])) or "None"
            proposed_rows += f"| {change.get('id')} | {change.get('type')} | {change.get('layer')} | {change.get('priority')} | {change.get('impact')} | {change.get('downtime')} | {change.get('summary')} | {deps} |\n"
    else:
        proposed_rows = "| - | - | - | - | - | - | No changes required | - |\n"

    body = body.replace("{{ proposed_changes_rows }}", proposed_rows.strip())

    # Action Items List
    action_items_str = ""
    phases = {
        "A": "Preflight",
        "B": "Critical (P0)",
        "C": "High (P1)",
        "D": "Medium (P2)",
        "E": "Low (P3)",
        "F": "Final Validation",
    }
    items_by_phase = {}

    for item in data.get("action_items", []):
        phase = item.get("phase", "A")
        if phase not in items_by_phase:
            items_by_phase[phase] = []
        items_by_phase[phase].append(item)

    if items_by_phase:
        for phase_key in sorted(items_by_phase.keys()):
            phase_title = phases.get(phase_key, f"Phase {phase_key}")
            action_items_str += f"### {phase_title}\n\n"

            for item in items_by_phase[phase_key]:
                prio = item.get("priority", "")
                layer = item.get("layer", "")
                layer_str = f" {layer}" if layer else ""

                action_items_str += f"- [ ] **{item.get('id', '')} {prio}{layer_str}**: {item.get('title', 'Task')}\n"
                action_items_str += f"  - **Goal**: {item.get('goal', 'N/A')}\n"
                action_items_str += (
                    f"  - **Commands**: `{item.get('commands', 'N/A')}`\n"
                )
                action_items_str += f"  - **Expected**: {item.get('expected', 'N/A')}\n"
                action_items_str += f"  - **If fails**: {item.get('if_fails', 'N/A')}\n"
                action_items_str += (
                    f"  - **Rollback**: {item.get('rollback', 'N/A')}\n\n"
                )
    else:
        action_items_str = "No action items required - all layers GREEN.\n"

    body = body.replace("{{ action_items_list }}", action_items_str.strip())

    # Change Log Rows
    change_log_str = ""
    if data.get("change_log"):
        for log in data.get("change_log", []):
            change_log_str += f"| {log.get('timestamp')} | {log.get('phase')} | {log.get('item')} | {log.get('action')} | {log.get('result')} | {status_emoji(log.get('status_after', ''))} |\n"
    else:
        change_log_str = "| - | - | - | No actions yet | - | - |\n"

    body = body.replace("{{ change_log_rows }}", change_log_str.strip())

    return body


def create_issue(data: dict, template_path: Path = None) -> dict:
    """Create a new maintenance issue."""
    date = data.get("date") or datetime.now().strftime("%Y-%m-%d")
    title = data.get("title") or f"[Maintenance] {date} - Homelab"
    body = generate_issue_body(data, template_path)

    payload = {
        "title": title,
        "body": body,
        "labels": [MAINTENANCE_LABEL_ID],
        "assignees": [ASSIGNEE],
    }

    endpoint = f"/repos/{REPO_OWNER}/{REPO_NAME}/issues"
    return api_request(endpoint, method="POST", data=payload)


def update_issue(issue_number: int, data: dict, template_path: Path = None) -> dict:
    """Update an existing maintenance issue."""
    body = generate_issue_body(data, template_path)

    payload = {"body": body}

    endpoint = f"/repos/{REPO_OWNER}/{REPO_NAME}/issues/{issue_number}"
    return api_request(endpoint, method="PATCH", data=payload)


def main():
    parser = argparse.ArgumentParser(
        description="Create or update Gitea maintenance issues"
    )
    parser.add_argument("--input", "-i", help="Path to YAML input file (or use stdin)")
    parser.add_argument(
        "--check-existing", action="store_true", help="Just check for existing issue"
    )
    parser.add_argument(
        "--json-input", action="store_true", help="Input is JSON instead of YAML"
    )
    parser.add_argument("--template", help="Path to markdown template file")
    parser.add_argument(
        "--preview",
        action="store_true",
        help="Preview markdown body without making API calls",
    )
    args = parser.parse_args()

    if not GITEA_TOKEN and not args.preview:
        print("ERROR: GITEA_TOKEN environment variable not set", file=sys.stderr)
        print("Run: source ~/.config/gitea/.env", file=sys.stderr)
        sys.exit(1)

    template_path = Path(args.template) if args.template else None

    # Just check for existing issue
    if args.check_existing:
        if not GITEA_TOKEN:
            # Fail if token missing even for checking
            print("ERROR: GITEA_TOKEN environment variable not set", file=sys.stderr)
            sys.exit(1)

        issue = find_existing_maintenance_issue()
        if issue:
            print(
                json.dumps(
                    {
                        "exists": True,
                        "number": issue["number"],
                        "title": issue["title"],
                        "url": issue["html_url"],
                        "state": issue["state"],
                    }
                )
            )
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
        print(
            "ERROR: No input provided. Use --input FILE or pipe YAML to stdin.",
            file=sys.stderr,
        )
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
            print(
                "ERROR: PyYAML not installed and input is not valid JSON",
                file=sys.stderr,
            )
            print("Install with: pip install pyyaml", file=sys.stderr)
            sys.exit(1)

    # Preview mode
    if args.preview:
        print(generate_issue_body(data, template_path))
        sys.exit(0)

    # Check for existing issue
    existing = find_existing_maintenance_issue()

    if existing:
        print(f"Updating existing issue #{existing['number']}...", file=sys.stderr)
        result = update_issue(existing["number"], data, template_path)
        action = "updated"
    else:
        print("Creating new maintenance issue...", file=sys.stderr)
        result = create_issue(data, template_path)
        action = "created"

    # Output result
    print(
        json.dumps(
            {
                "action": action,
                "number": result["number"],
                "title": result["title"],
                "url": result["html_url"],
                "state": result["state"],
            }
        )
    )

    print(
        f"✓ Issue #{result['number']} {action}: {result['html_url']}", file=sys.stderr
    )


if __name__ == "__main__":
    main()
