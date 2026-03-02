"""
Command-Center CLI - Bootstrap tool for AI coding assistant workflows

Usage:
    # Interactive Wizard (Recommended)
    cmdctl init

    # Non-interactive / CI
    cmdctl init --all --headless
    cmdctl init --opencode --headless
    cmdctl init --copilot --headless
"""

import os
import re
import shutil
import time
from pathlib import Path
from typing import List, Optional, Tuple

import typer
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.style import Style
from rich.theme import Theme

# Initialize with custom theme
custom_theme = Theme(
    {
        "info": "cyan",
        "warning": "yellow",
        "error": "red",
        "success": "green",
        "title": "bold cyan",
    }
)
console = Console(theme=custom_theme)
app = typer.Typer(
    name="cmdctl",
    help="Command-Center: Bootstrap global workflow commands for AI coding assistants.",
    add_completion=False,
)

# Global locations
OPENCODE_COMMANDS = Path.home() / ".config" / "opencode" / "command"
OPENCODE_RULES = Path.home() / ".config" / "opencode" / "rules"
OPENCODE_SCRIPTS = Path.home() / ".config" / "opencode" / "scripts"
OPENCODE_TEMPLATES = Path.home() / ".config" / "opencode" / "templates"
OPENCODE_SUPPORT = Path.home() / ".config" / "opencode" / ".do-the-thing"
OPENCODE_AGENTS_MD = Path.home() / ".config" / "opencode" / "AGENTS.md"
ANTIGRAVITY_COMMANDS = Path.home() / ".gemini" / "antigravity" / "global_workflows"
ANTIGRAVITY_RULES = Path.home() / ".gemini" / "rules"
ANTIGRAVITY_SCRIPTS = Path.home() / ".gemini" / "scripts"
ANTIGRAVITY_TEMPLATES = Path.home() / ".gemini" / "templates"
ANTIGRAVITY_SUPPORT = Path.home() / ".gemini" / "antigravity" / ".do-the-thing"
COPILOT_INSTRUCTIONS = Path.home() / ".copilot" / "instructions"
COPILOT_SUPPORT = Path.home() / ".copilot" / ".do-the-thing"
COPILOT_PROMPTS_STABLE = Path.home() / ".config" / "Code" / "User" / "prompts"
COPILOT_PROMPTS_INSIDERS = (
    Path.home() / ".config" / "Code - Insiders" / "User" / "prompts"
)

# Source files (relative to package assets directory)
# Commands are workflow files invoked via /command
COMMAND_FILES = [
    "do-the-thing.md",
    "commit.md",
    "init.md",
    "create_mcp.md",
    "homelab-action.md",
    "homelab-recon.md",
    "homelab-troubleshoot.md",
]
# Rules are reference files auto-loaded for context
RULE_FILES = [
    "HOMELAB_foundational_rules.md",
    "HOMELAB_network.md",
    "HOMELAB_cluster.md",
    "HOMELAB_access.md",
    "homelab-reference.md",
]
# Scripts are executable helper scripts
SCRIPT_FILES = [
    "recon.sh",
    "homelab-maintenance-issue.py",
    "homelab-network-check.sh",
    "homelab-nas-check.sh",
    "network-test-pod.yaml",
]
# Templates are structured data files
TEMPLATE_FILES = [
    "homelab-maintenance-issue.schema.yaml",
    "homelab-maintenance-issue-template.md",
    "homelab-troubleshoot-report.schema.yaml",
    "homelab-troubleshoot-report-template.md",
    "recon-tasks-template.md",
]
SUPPORT_DIR = ".do-the-thing"


def get_assets_dir() -> Path:
    """Get the directory containing asset files."""
    module_path = Path(__file__).resolve()
    return module_path.parent / "assets"


def detect_opencode() -> bool:
    """Check if Opencode is installed or configured."""
    return (Path.home() / ".config" / "opencode").exists() or shutil.which(
        "opencode"
    ) is not None


def detect_antigravity() -> bool:
    """Check if Antigravity is installed or configured."""
    return (Path.home() / ".gemini" / "antigravity").exists()


def get_copilot_prompt_dirs() -> List[Path]:
    """Get prompt directories for detected VS Code profiles."""
    candidates: List[Path] = []

    if (Path.home() / ".config" / "Code" / "User").exists() or shutil.which(
        "code"
    ) is not None:
        candidates.append(COPILOT_PROMPTS_STABLE)

    if (Path.home() / ".config" / "Code - Insiders" / "User").exists() or shutil.which(
        "code-insiders"
    ) is not None:
        candidates.append(COPILOT_PROMPTS_INSIDERS)

    # If Copilot instructions path exists but we couldn't detect a profile path,
    # default to VS Code stable profile prompts path.
    if not candidates and COPILOT_INSTRUCTIONS.exists():
        candidates.append(COPILOT_PROMPTS_STABLE)

    seen = set()
    unique_candidates: List[Path] = []
    for path in candidates:
        key = str(path)
        if key not in seen:
            seen.add(key)
            unique_candidates.append(path)

    return unique_candidates


def detect_copilot() -> bool:
    """Check if VS Code/GitHub Copilot is installed or configured."""
    return bool(get_copilot_prompt_dirs()) or COPILOT_INSTRUCTIONS.exists()


def copy_file(src: Path, dest: Path, dry_run: bool = False) -> bool:
    """Copy a file, creating parent directories as needed."""
    if dry_run:
        console.print(f"  [cyan]~[/cyan] Would copy {src.name} -> {dest}")
        return True

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        console.print(f"  [success]✓[/success] {src.name}")
        return True
    except Exception as e:
        console.print(f"  [error]✗[/error] Failed to copy {src.name}: {e}")
        return False


def write_text_file(
    content: str, dest: Path, dry_run: bool = False, label: Optional[str] = None
) -> bool:
    """Write text to a file, creating parent directories as needed."""
    display = label or dest.name
    if dry_run:
        console.print(f"  [cyan]~[/cyan] Would write {display} -> {dest}")
        return True

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content)
        console.print(f"  [success]✓[/success] {display}")
        return True
    except Exception as e:
        console.print(f"  [error]✗[/error] Failed to write {display}: {e}")
        return False


def split_markdown_frontmatter(content: str) -> Tuple[Optional[str], str]:
    """Split markdown file into (frontmatter, body)."""
    if not content.startswith("---\n"):
        return None, content

    lines = content.splitlines()
    end_index = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_index = i
            break

    if end_index is None:
        return None, content

    frontmatter = "\n".join(lines[1:end_index])
    body = "\n".join(lines[end_index + 1 :])
    return frontmatter, body


def extract_frontmatter_description(frontmatter: Optional[str], fallback: str) -> str:
    """Extract description field from YAML-like frontmatter."""
    if not frontmatter:
        return fallback

    match = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
    if not match:
        return fallback

    description = match.group(1).strip()
    if (description.startswith('"') and description.endswith('"')) or (
        description.startswith("'") and description.endswith("'")
    ):
        description = description[1:-1]

    return description or fallback


def yaml_quote(value: str) -> str:
    """Quote a value safely for simple YAML frontmatter."""
    return "'" + value.replace("'", "''") + "'"


def adapt_do_the_thing_for_copilot(body: str) -> str:
    """Add Copilot support paths to do-the-thing command text."""
    body = body.replace(
        "1. **Global Opencode**: `~/.config/opencode/.do-the-thing/`\n2. **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/`",
        "1. **Global Opencode**: `~/.config/opencode/.do-the-thing/`\n2. **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/`\n3. **Global Copilot**: `~/.copilot/.do-the-thing/`",
    )
    body = body.replace(
        "based on which app (Opencode or Antigravity) is executing the command.",
        "based on which app (Opencode, Antigravity, or Copilot) is executing the command.",
    )
    body = body.replace(
        "- **Global Opencode**: `~/.config/opencode/.do-the-thing/.specify/memory/constitution.md`\n- **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/.specify/memory/constitution.md`",
        "- **Global Opencode**: `~/.config/opencode/.do-the-thing/.specify/memory/constitution.md`\n- **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/.specify/memory/constitution.md`\n- **Global Copilot**: `~/.copilot/.do-the-thing/.specify/memory/constitution.md`",
    )
    return body


def render_copilot_prompt(src: Path) -> str:
    """Render a command markdown file to Copilot .prompt.md format."""
    content = src.read_text()
    frontmatter, body = split_markdown_frontmatter(content)
    description = extract_frontmatter_description(frontmatter, f"Run /{src.stem}")

    if src.name == "do-the-thing.md":
        body = adapt_do_the_thing_for_copilot(body)

    rendered = (
        "---\n"
        f"name: {yaml_quote(src.stem)}\n"
        f"description: {yaml_quote(description)}\n"
        "agent: 'agent'\n"
        "---\n\n" + body.lstrip("\n")
    )

    if not rendered.endswith("\n"):
        rendered += "\n"

    return rendered


def render_copilot_instruction(src: Path) -> str:
    """Render a rule markdown file to Copilot .instructions.md format."""
    content = src.read_text()
    _, body = split_markdown_frontmatter(content)
    description = f"Global rule set for {src.stem.replace('_', ' ')}"

    rendered = (
        "---\n"
        f"name: {yaml_quote(src.stem)}\n"
        f"description: {yaml_quote(description)}\n"
        "applyTo: '**'\n"
        "---\n\n" + body.lstrip("\n")
    )

    if not rendered.endswith("\n"):
        rendered += "\n"

    return rendered


def copy_directory(src: Path, dest: Path, dry_run: bool = False) -> bool:
    """Copy a directory recursively."""
    if dry_run:
        console.print(f"  [cyan]~[/cyan] Would copy {src.name}/ -> {dest}")
        return True

    try:
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        console.print(f"  [success]✓[/success] {src.name}/ (directory)")
        return True
    except Exception as e:
        console.print(f"  [error]✗[/error] Failed to copy {src.name}/: {e}")
        return False


def bootstrap_to_copilot(assets_dir: Path, dry_run: bool = False) -> bool:
    """Bootstrap workflow files to VS Code GitHub Copilot global locations."""
    success = True
    prompt_count = 0
    instruction_count = 0

    prompt_dirs = get_copilot_prompt_dirs()
    if not prompt_dirs:
        prompt_dirs = [COPILOT_PROMPTS_STABLE]

    console.print("\n[bold cyan]Setting up VS Code GitHub Copilot[/bold cyan]")
    for prompt_dir in prompt_dirs:
        console.print(f"  [dim]Prompt files: {prompt_dir}[/dim]")
    console.print(f"  [dim]Instructions: {COPILOT_INSTRUCTIONS}[/dim]")
    console.print(f"  [dim]Support: {COPILOT_SUPPORT}[/dim]")

    # Copy prompt files (.prompt.md)
    console.print("\n  [bold]Prompt Files:[/bold]")
    commands_src = assets_dir / "commands"
    for filename in COMMAND_FILES:
        src = commands_src / filename
        if not src.exists():
            console.print(f"  [warning]![/warning] Asset missing: commands/{filename}")
            success = False
            continue

        prompt_content = render_copilot_prompt(src)
        prompt_name = f"{src.stem}.prompt.md"
        for prompt_dir in prompt_dirs:
            if write_text_file(
                prompt_content, prompt_dir / prompt_name, dry_run, prompt_name
            ):
                prompt_count += 1
            else:
                success = False

    # Copy instructions files (.instructions.md)
    console.print("\n  [bold]Instruction Files:[/bold]")
    rules_src = assets_dir / "rules"
    for filename in RULE_FILES:
        src = rules_src / filename
        if not src.exists():
            console.print(f"  [warning]![/warning] Asset missing: rules/{filename}")
            success = False
            continue

        instruction_content = render_copilot_instruction(src)
        instruction_name = f"{src.stem}.instructions.md"
        if write_text_file(
            instruction_content,
            COPILOT_INSTRUCTIONS / instruction_name,
            dry_run,
            instruction_name,
        ):
            instruction_count += 1
        else:
            success = False

    # Copy support directory for do-the-thing assets
    console.print("\n  [bold]Support:[/bold]")
    src_support = assets_dir / SUPPORT_DIR
    if src_support.exists():
        if not copy_directory(src_support, COPILOT_SUPPORT, dry_run):
            success = False
    else:
        console.print(f"  [warning]![/warning] Support dir missing: {SUPPORT_DIR}")
        success = False

    console.print("\n[bold cyan]Bootstrap Report Summary[/bold cyan]")
    table = Table(
        title="VS Code Copilot Components",
        show_header=True,
        header_style="bold magenta",
        box=None,
    )
    table.add_column("Component Type", style="cyan")
    table.add_column("Count", justify="right", style="green")
    table.add_column("Status", justify="center")

    expected_prompts = len(COMMAND_FILES) * len(prompt_dirs)
    prompt_status = (
        "[success]OK[/success]"
        if prompt_count == expected_prompts
        else f"[warning]{prompt_count}/{expected_prompts}[/warning]"
    )
    instruction_status = (
        "[success]OK[/success]"
        if instruction_count == len(RULE_FILES)
        else f"[warning]{instruction_count}/{len(RULE_FILES)}[/warning]"
    )
    support_status = (
        "[success]OK[/success]"
        if src_support.exists()
        else "[warning]Missing[/warning]"
    )

    table.add_row("Prompt Files", str(prompt_count), prompt_status)
    table.add_row("Instruction Files", str(instruction_count), instruction_status)
    table.add_row("Support", "1" if src_support.exists() else "0", support_status)

    console.print(table)

    if success:
        console.print("\n  [success]✓ VS Code Copilot setup complete[/success]")
    else:
        console.print(
            "\n  [warning]⚠ VS Code Copilot setup completed with warnings[/warning]"
        )

    return success


def bootstrap_to_target(
    name: str,
    commands_dir: Path,
    rules_dir: Path,
    scripts_dir: Path,
    templates_dir: Path,
    support_dir: Path,
    assets_dir: Path,
    dry_run: bool = False,
) -> bool:
    """Bootstrap workflow files to a target IDE."""
    success = True
    cmd_count = 0
    rule_count = 0
    script_count = 0
    template_count = 0

    console.print(f"\n[bold cyan]Setting up {name}[/bold cyan]")
    console.print(f"  [dim]Commands: {commands_dir}[/dim]")
    console.print(f"  [dim]Rules: {rules_dir}[/dim]")
    console.print(f"  [dim]Scripts: {scripts_dir}[/dim]")
    console.print(f"  [dim]Templates: {templates_dir}[/dim]")

    # Copy command files (from assets/commands/)
    console.print("\n  [bold]Commands:[/bold]")
    commands_src = assets_dir / "commands"
    for filename in COMMAND_FILES:
        src = commands_src / filename
        if src.exists():
            if copy_file(src, commands_dir / filename, dry_run):
                cmd_count += 1
            else:
                success = False
        else:
            console.print(f"  [warning]![/warning] Asset missing: commands/{filename}")
            success = False

    # Copy rule files (from assets/rules/) to RULES directory (NOT commands)
    console.print("\n  [bold]Rules:[/bold]")
    rules_src = assets_dir / "rules"
    for filename in RULE_FILES:
        src = rules_src / filename
        if src.exists():
            if copy_file(src, rules_dir / filename, dry_run):
                rule_count += 1
            else:
                success = False
        else:
            console.print(f"  [warning]![/warning] Asset missing: rules/{filename}")

    # Copy script files (from assets/scripts/)
    console.print("\n  [bold]Scripts:[/bold]")
    scripts_src = assets_dir / "scripts"
    for filename in SCRIPT_FILES:
        src = scripts_src / filename
        if src.exists():
            if copy_file(src, scripts_dir / filename, dry_run):
                script_count += 1
            else:
                success = False
        else:
            console.print(f"  [warning]![/warning] Asset missing: scripts/{filename}")

    # Copy template files (from assets/templates/)
    console.print("\n  [bold]Templates:[/bold]")
    templates_src = assets_dir / "templates"
    for filename in TEMPLATE_FILES:
        src = templates_src / filename
        if src.exists():
            if copy_file(src, templates_dir / filename, dry_run):
                template_count += 1
            else:
                success = False
        else:
            console.print(f"  [warning]![/warning] Asset missing: templates/{filename}")

    # Copy support directory
    console.print("\n  [bold]Support:[/bold]")
    src_support = assets_dir / SUPPORT_DIR
    if src_support.exists():
        if copy_directory(src_support, support_dir, dry_run):
            pass
        else:
            success = False
    else:
        console.print(f"  [warning]![/warning] Support dir missing: {SUPPORT_DIR}")

    # Summary Report Table
    console.print("\n[bold cyan]Bootstrap Report Summary[/bold cyan]")
    table = Table(
        title=f"{name} Components",
        show_header=True,
        header_style="bold magenta",
        box=None,
    )
    table.add_column("Component Type", style="cyan")
    table.add_column("Count", justify="right", style="green")
    table.add_column("Status", justify="center")

    def get_status(count, files):
        if count == len(files):
            return "[success]OK[/success]"
        return f"[warning]{count}/{len(files)}[/warning]"

    table.add_row("Commands", str(cmd_count), get_status(cmd_count, COMMAND_FILES))
    table.add_row("Rules", str(rule_count), get_status(rule_count, RULE_FILES))
    table.add_row("Scripts", str(script_count), get_status(script_count, SCRIPT_FILES))
    table.add_row(
        "Templates", str(template_count), get_status(template_count, TEMPLATE_FILES)
    )
    table.add_row(
        "Support",
        "1" if src_support.exists() else "0",
        "[success]OK[/success]"
        if src_support.exists()
        else "[warning]Missing[/warning]",
    )

    console.print(table)

    # IDE-specific extras
    if name == "Antigravity":
        console.print("\n  [bold]Antigravity Extras:[/bold]")

        # Update GEMINI.md Master Rule with links to rules
        gemini_master = Path.home() / ".gemini" / "GEMINI.md"
        gemini_content = """# Antigravity Global Rules & Reference (GEMINI)

This file serves as the **Master Table of Contents** for all project-specific rules and global context.
**You MUST strictly adhere to the rules defined for your active project.**

---

## 🏗️ Project Rules (Table of Contents)

Identify the current project context and apply the corresponding rules.

### 1. Homelab Infrastructure
**Triggers**: Working on `homelab` repo, Kubernetes, Ceph, ArgoCD, OPNSense, or `ops/homelab`.

> [!CAUTION]
> **Foundational Rules Apply**: You MUST follow the Homelab Foundational Rules.
> - **ALL GREEN** status required across Metal, System, Platform, and Apps layers.
> - **Zero Tolerance** for issues.
> - **No Pause** until complete.

**Rules** (located in `~/.gemini/rules/`):
- [Foundational Rules](file:///home/brimdor/.gemini/rules/HOMELAB_foundational_rules.md) - ABSOLUTE rules (1-7)
- [Network Reference](file:///home/brimdor/.gemini/rules/HOMELAB_network.md) - VLANs, devices
- [Cluster Reference](file:///home/brimdor/.gemini/rules/HOMELAB_cluster.md) - Nodes, services, storage
- [Access Reference](file:///home/brimdor/.gemini/rules/HOMELAB_access.md) - SSH, kubectl, external access
- [Master Reference](file:///home/brimdor/.gemini/rules/homelab-reference.md) - Table of Contents

**Workflows**:
- `/homelab-recon` - Health check & maintenance report
- `/homelab-action` - Execute maintenance items
- `/homelab-troubleshoot` - Diagnose issues

### 2. Command Center
**Triggers**: Working on `command-center` repo, `cmdctl` CLI.

- **Objective**: Bootstrap global workflows to user environments.
- **Rule**: Ensure `assets/` directory covers ALL global rules.
- **Build**: Verify `pyproject.toml` includes all assets.

---

## 🛠️ Global Tool Configurations

### Gitea API Configuration

**Token Location**: `~/.config/gitea/.env`

**Environment Variables**:
- `GITEA_TOKEN`: API access token
- `GITEA_URL`: `https://git.eaglepass.io`

**Usage**:
```bash
source ~/.config/gitea/.env
curl -H "Authorization: token $GITEA_TOKEN" "$GITEA_URL/api/v1/..."
```

**Common Endpoints**:
- API Docs: https://git.eaglepass.io/api/swagger
- Primary Repo: `ops/homelab`
"""
        if not dry_run:
            try:
                gemini_master.parent.mkdir(parents=True, exist_ok=True)
                gemini_master.write_text(gemini_content)
                console.print(f"  [success]✓[/success] GEMINI.md (master rule)")
            except Exception as e:
                console.print(f"  [error]✗[/error] Failed to update GEMINI.md: {e}")
                success = False
        else:
            console.print(f"  [cyan]~[/cyan] Would update GEMINI.md at {gemini_master}")

    elif name == "Opencode":
        console.print("\n  [bold]Opencode Extras:[/bold]")

        # Create AGENTS.md for auto-loading rules
        agents_content = """# OpenCode Global Agent Instructions

This file is auto-loaded by OpenCode to provide system-wide context.

## Homelab Infrastructure Rules

When working on homelab-related tasks, follow the rules in `~/.config/opencode/rules/`:

- **Foundational Rules**: `HOMELAB_foundational_rules.md` - ABSOLUTE rules (1-7)
- **Network Reference**: `HOMELAB_network.md` - VLANs, devices
- **Cluster Reference**: `HOMELAB_cluster.md` - Nodes, services, storage
- **Access Reference**: `HOMELAB_access.md` - SSH, kubectl, external access

> **CRITICAL**: ALL GREEN status required across Metal, System, Platform, and Apps layers.

## Available Commands

- `/homelab-recon` - Health check & maintenance report
- `/homelab-action` - Execute maintenance items
- `/homelab-troubleshoot` - Diagnose issues
- `/do-the-thing` - Spec-Driven Development workflow
- `/commit` - Comprehensive commit workflow
"""
        if not dry_run:
            try:
                OPENCODE_AGENTS_MD.parent.mkdir(parents=True, exist_ok=True)
                OPENCODE_AGENTS_MD.write_text(agents_content)
                console.print(f"  [success]✓[/success] AGENTS.md (auto-loaded rules)")
            except Exception as e:
                console.print(f"  [error]✗[/error] Failed to create AGENTS.md: {e}")
                success = False
        else:
            console.print(
                f"  [cyan]~[/cyan] Would create AGENTS.md at {OPENCODE_AGENTS_MD}"
            )

    # Summary
    if success:
        console.print(f"\n  [success]✓ {name} setup complete[/success]")
    else:
        console.print(f"\n  [warning]⚠ {name} setup completed with warnings[/warning]")

    return success


def print_banner():
    """Print the CLI banner."""
    banner_text = r"""
   ______                                          __      ______            __       
  / ____/___  ____ ___  ____ ___  ____ _____  ____/ /     / ____/__  ____  / /____  _____
 / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  /_____/ /   / _ \/ __ \/ __/ _ \/ ___/
/ /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ /_____/ /___/  __/ / / / /_/  __/ /    
\____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/      \____/\___/_/ /_/\__/\___/_/     
                                                                                         
    """
    console.print(
        Panel.fit(
            banner_text,
            border_style="cyan",
            title="v1.2.0",
            subtitle="Global Workflow Bootstrapper",
        )
    )


def run_wizard(dry_run: bool):
    """Run the interactive setup wizard."""
    print_banner()
    console.print(
        "[italic]Welcome! Let's get your AI coding assistants supercharged.[/italic]\n"
    )

    assets_dir = get_assets_dir()
    if not (assets_dir / "commands" / "do-the-thing.md").exists():
        console.print(f"[error]CRITICAL:[/error] Asset files not found in {assets_dir}")
        raise typer.Exit(1)

    # 1. Detection
    with console.status(
        "[bold cyan]Scanning for installed agents...[/bold cyan]", spinner="dots"
    ):
        time.sleep(1)  # Dramatic effect
        has_opencode = detect_opencode()
        has_antigravity = detect_antigravity()
        has_copilot = detect_copilot()

    detected = []
    if has_opencode:
        detected.append("Opencode")
    if has_antigravity:
        detected.append("Antigravity")
    if has_copilot:
        detected.append("VS Code Copilot")

    if not detected:
        console.print("[warning]No known AI assistants detected.[/warning]")
        if not Confirm.ask("Do you want to proceed anyway?", default=False):
            console.print("Aborting.")
            raise typer.Exit(0)
    else:
        console.print(
            f"  [success]✓[/success] Detected: [bold]{', '.join(detected)}[/bold]\n"
        )

    # 2. Selection
    targets = []

    # Checkbox-style selection (simulated with prompts for now as rich doesn't have native checkbox prompt easily without other deps)
    console.print("[bold]Where should we install the workflows?[/bold]")

    if Confirm.ask(f"Install to [cyan]Opencode[/cyan]?", default=has_opencode):
        targets.append("opencode")

    if Confirm.ask(f"Install to [cyan]Antigravity[/cyan]?", default=has_antigravity):
        targets.append("antigravity")

    if Confirm.ask(f"Install to [cyan]VS Code Copilot[/cyan]?", default=has_copilot):
        targets.append("copilot")

    if not targets:
        console.print("[yellow]No targets selected. Exiting.[/yellow]")
        raise typer.Exit(0)

    # 3. Confirmation
    console.print(
        f"\n[bold]Plan:[/bold] Bootstrap workflows to [cyan]{', '.join(t.capitalize() for t in targets)}[/cyan]"
    )
    if dry_run:
        console.print("[warning]DRY RUN MODE ENABLED[/warning]")

    if not Confirm.ask("Ready to blast off?", default=True):
        console.print("Aborted.")
        raise typer.Exit(0)

    # 4. Execution
    console.print()
    success_all = True

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        if "opencode" in targets:
            task = progress.add_task("Bootstrapping Opencode...", total=None)
            if not bootstrap_to_target(
                "Opencode",
                OPENCODE_COMMANDS,
                OPENCODE_RULES,
                OPENCODE_SCRIPTS,
                OPENCODE_TEMPLATES,
                OPENCODE_SUPPORT,
                assets_dir,
                dry_run,
            ):
                success_all = False
            time.sleep(0.5)  # UX pacing
            progress.remove_task(task)
            console.print("  [success]✓[/success] Opencode configured")

        if "antigravity" in targets:
            task = progress.add_task("Bootstrapping Antigravity...", total=None)
            if not bootstrap_to_target(
                "Antigravity",
                ANTIGRAVITY_COMMANDS,
                ANTIGRAVITY_RULES,
                ANTIGRAVITY_SCRIPTS,
                ANTIGRAVITY_TEMPLATES,
                ANTIGRAVITY_SUPPORT,
                assets_dir,
                dry_run,
            ):
                success_all = False
            time.sleep(0.5)  # UX pacing
            progress.remove_task(task)
            console.print("  [success]✓[/success] Antigravity configured")

        if "copilot" in targets:
            task = progress.add_task("Bootstrapping VS Code Copilot...", total=None)
            if not bootstrap_to_copilot(assets_dir, dry_run):
                success_all = False
            time.sleep(0.5)  # UX pacing
            progress.remove_task(task)
            console.print("  [success]✓[/success] VS Code Copilot configured")

    # 5. Summary
    console.print()
    if success_all:
        console.print(
            Panel(
                "[bold green]Success! Your agents are ready.[/bold green]\n\n"
                "Try these commands in your chat:\n"
                "  [cyan]/do-the-thing[/cyan]  - Autonomous Spec-Driven Development\n"
                "  [cyan]/commit[/cyan]        - Smart Commit & PR\n"
                "  [cyan]/init[/cyan]          - Generate AGENTS.md",
                title="Installation Complete",
                border_style="green",
            )
        )
    else:
        console.print(
            "[error]Completed with errors. Please check the output above.[/error]"
        )
        raise typer.Exit(1)


@app.command()
def init(
    dry_run: bool = typer.Option(
        False, "--dry-run", help="Preview changes without applying"
    ),
    opencode: bool = typer.Option(
        False, "--opencode", help="Bootstrap only to Opencode"
    ),
    antigravity: bool = typer.Option(
        False, "--antigravity", help="Bootstrap only to Antigravity"
    ),
    copilot: bool = typer.Option(
        False, "--copilot", help="Bootstrap only to VS Code GitHub Copilot"
    ),
    all_targets: bool = typer.Option(
        False, "--all", help="Bootstrap to all detected IDEs"
    ),
    headless: bool = typer.Option(
        False, "--headless", help="Run in non-interactive mode (requires flags)"
    ),
):
    """
    Bootstrap workflow commands to global IDE locations.
    """

    # Interactive Mode (Default if no specific targets and not headless)
    if not headless and not (opencode or antigravity or copilot or all_targets):
        run_wizard(dry_run)
        return

    # Headless / Flag Mode
    console.print("[bold]Running in Headless Mode[/bold]")
    assets_dir = get_assets_dir()

    if not (assets_dir / "commands" / "do-the-thing.md").exists():
        console.print(f"[error]Error:[/error] Asset files not found in {assets_dir}")
        raise typer.Exit(1)

    target_opencode = opencode
    target_antigravity = antigravity
    target_copilot = copilot

    if all_targets:
        target_opencode = detect_opencode()
        target_antigravity = detect_antigravity()
        target_copilot = detect_copilot()

    # Fallback if nothing selected but headless wasn't strict?
    # Actually if they ran `cmdctl init --headless` with no other flags, we should prob auto-detect.
    if (
        not target_opencode
        and not target_antigravity
        and not target_copilot
        and headless
        and not (opencode or antigravity or copilot)
    ):
        target_opencode = detect_opencode()
        target_antigravity = detect_antigravity()
        target_copilot = detect_copilot()

    if not target_opencode and not target_antigravity and not target_copilot:
        console.print("[error]No targets specified or detected.[/error]")
        raise typer.Exit(1)

    if target_opencode:
        bootstrap_to_target(
            "Opencode",
            OPENCODE_COMMANDS,
            OPENCODE_RULES,
            OPENCODE_SCRIPTS,
            OPENCODE_TEMPLATES,
            OPENCODE_SUPPORT,
            assets_dir,
            dry_run,
        )

    if target_antigravity:
        bootstrap_to_target(
            "Antigravity",
            ANTIGRAVITY_COMMANDS,
            ANTIGRAVITY_RULES,
            ANTIGRAVITY_SCRIPTS,
            ANTIGRAVITY_TEMPLATES,
            ANTIGRAVITY_SUPPORT,
            assets_dir,
            dry_run,
        )

    if target_copilot:
        bootstrap_to_copilot(assets_dir, dry_run)

    console.print("[success]Done.[/success]")


@app.command()
def check():
    """
    Verify installation status.
    """
    print_banner()
    console.print("[bold]Checking installation status...[/bold]\n")

    all_ok = True

    # Check Opencode
    console.print("[cyan]Opencode:[/cyan]")
    for filename in COMMAND_FILES:
        path = OPENCODE_COMMANDS / filename
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    for filename in RULE_FILES:
        path = OPENCODE_RULES / filename
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    if OPENCODE_SUPPORT.exists():
        console.print(f"  [success]✓[/success] {OPENCODE_SUPPORT}/")
    else:
        console.print(f"  [dim]○[/dim] {OPENCODE_SUPPORT}/ [dim](not installed)[/dim]")

    # Check Antigravity
    console.print("\n[cyan]Antigravity:[/cyan]")
    for filename in COMMAND_FILES:
        path = ANTIGRAVITY_COMMANDS / filename
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    for filename in RULE_FILES:
        path = ANTIGRAVITY_RULES / filename
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    if ANTIGRAVITY_SUPPORT.exists():
        console.print(f"  [success]✓[/success] {ANTIGRAVITY_SUPPORT}/")
    else:
        console.print(
            f"  [dim]○[/dim] {ANTIGRAVITY_SUPPORT}/ [dim](not installed)[/dim]"
        )

    # Check VS Code Copilot
    console.print("\n[cyan]VS Code Copilot:[/cyan]")
    prompt_dirs = get_copilot_prompt_dirs()
    if not prompt_dirs:
        prompt_dirs = [COPILOT_PROMPTS_STABLE]

    for prompt_dir in prompt_dirs:
        for filename in COMMAND_FILES:
            prompt_file = f"{Path(filename).stem}.prompt.md"
            path = prompt_dir / prompt_file
            if path.exists():
                console.print(f"  [success]✓[/success] {path}")
            else:
                console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
                all_ok = False

    for filename in RULE_FILES:
        instruction_file = f"{Path(filename).stem}.instructions.md"
        path = COPILOT_INSTRUCTIONS / instruction_file
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    if COPILOT_SUPPORT.exists():
        console.print(f"  [success]✓[/success] {COPILOT_SUPPORT}/")
    else:
        console.print(f"  [dim]○[/dim] {COPILOT_SUPPORT}/ [dim](not installed)[/dim]")

    console.print()
    if all_ok:
        console.print("[success]All files verified successfully![/success]")
    else:
        console.print(
            "[warning]Some files are missing. Run 'cmdctl init' to install.[/warning]"
        )
        raise typer.Exit(1)


def main():
    """Entry point for the CLI."""
    app()


if __name__ == "__main__":
    main()
