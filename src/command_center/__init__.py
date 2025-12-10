"""
Command-Center CLI - Bootstrap tool for AI coding assistant workflows

Usage:
    # Persistent installation
    uv tool install cmdctl --from git+https://github.com/brimdor/command-center.git
    cmdctl init

    # One-time usage
    uvx --from git+https://github.com/brimdor/command-center.git cmdctl init
"""

import os
import shutil
import sys
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.panel import Panel
from rich.tree import Tree

# Initialize
app = typer.Typer(
    name="cmdctl",
    help="Command-Center: Bootstrap global workflow commands for AI coding assistants.",
    add_completion=False,
)
console = Console()

# Global locations
OPENCODE_COMMANDS = Path.home() / ".config" / "opencode" / "command"
OPENCODE_SUPPORT = Path.home() / ".config" / "opencode" / ".do-the-thing"
ANTIGRAVITY_COMMANDS = Path.home() / ".gemini" / "antigravity" / "global_workflows"
ANTIGRAVITY_SUPPORT = Path.home() / ".gemini" / "antigravity" / ".do-the-thing"

# Source files (relative to package)
WORKFLOW_FILES = ["do-the-thing.md", "commit.md", "init.md"]
SUPPORT_DIR = ".do-the-thing"


def get_assets_dir() -> Path:
    """Get the directory containing asset files."""
    module_path = Path(__file__).resolve()
    return module_path.parent / "assets"


def detect_opencode() -> bool:
    """Check if Opencode is installed or configured."""
    return (
        (Path.home() / ".config" / "opencode").exists()
        or shutil.which("opencode") is not None
    )


def detect_antigravity() -> bool:
    """Check if Antigravity is installed or configured."""
    return (Path.home() / ".gemini" / "antigravity").exists()


def copy_file(src: Path, dest: Path, dry_run: bool = False) -> bool:
    """Copy a file, creating parent directories as needed."""
    if dry_run:
        console.print(f"  [yellow]Would copy[/yellow] {src.name} → {dest}")
        return True

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        console.print(f"  [green]✓[/green] Copied {src.name} → {dest}")
        return True
    except Exception as e:
        console.print(f"  [red]✗[/red] Failed to copy {src.name}: {e}")
        return False


def copy_directory(src: Path, dest: Path, dry_run: bool = False) -> bool:
    """Copy a directory recursively."""
    if dry_run:
        console.print(f"  [yellow]Would copy directory[/yellow] {src.name}/ → {dest}")
        return True

    try:
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        console.print(f"  [green]✓[/green] Copied {src.name}/ → {dest}")
        return True
    except Exception as e:
        console.print(f"  [red]✗[/red] Failed to copy {src.name}/: {e}")
        return False


def bootstrap_to_target(
    name: str,
    commands_dir: Path,
    support_dir: Path,
    assets_dir: Path,
    dry_run: bool = False,
) -> bool:
    """Bootstrap workflow files to a target IDE."""
    console.print(f"\n[cyan]Bootstrapping to {name}...[/cyan]")

    success = True

    # Copy workflow files
    for filename in WORKFLOW_FILES:
        src = assets_dir / filename
        if src.exists():
            if not copy_file(src, commands_dir / filename, dry_run):
                success = False
        else:
            console.print(f"  [yellow]![/yellow] Source file not found: {src}")
            success = False

    # Copy support directory
    src_support = assets_dir / SUPPORT_DIR
    if src_support.exists():
        if not copy_directory(src_support, support_dir, dry_run):
            success = False
    else:
        console.print(f"  [yellow]![/yellow] Support directory not found: {src_support}")

    return success


def print_banner():
    """Print the CLI banner."""
    banner_text = """
╔═══════════════════════════════════════════════════════════════╗
║                   Command-Center CLI                          ║
║         Bootstrap workflows to global IDE locations           ║
╚═══════════════════════════════════════════════════════════════╝
"""
    console.print(Panel(banner_text.strip(), style="cyan", expand=False))


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
    all_targets: bool = typer.Option(
        False, "--all", help="Bootstrap to all detected IDEs (default behavior)"
    ),
):
    """
    Bootstrap workflow commands to global IDE locations.

    Deploys /do-the-thing, /commit, and /init commands to detected AI coding assistants.
    """
    print_banner()

    if dry_run:
        console.print("[yellow]DRY RUN MODE - No changes will be made[/yellow]\n")

    assets_dir = get_assets_dir()

    # Verify source files exist
    if not (assets_dir / "do-the-thing.md").exists():
        console.print(f"[red]Error:[/red] Asset files not found in {assets_dir}")
        console.print("Please ensure the package is installed correctly.")
        raise typer.Exit(1)

    # Determine targets
    target_opencode = opencode
    target_antigravity = antigravity

    # If no specific target, auto-detect
    if not opencode and not antigravity:
        console.print("[blue]Auto-detecting available IDEs...[/blue]")

        if detect_opencode():
            console.print("  [green]✓[/green] Detected: Opencode")
            target_opencode = True
        else:
            console.print("  [dim]○[/dim] Not detected: Opencode")

        if detect_antigravity():
            console.print("  [green]✓[/green] Detected: Antigravity")
            target_antigravity = True
        else:
            console.print("  [dim]○[/dim] Not detected: Antigravity")

        if not target_opencode and not target_antigravity:
            console.print(
                "\n[red]No supported IDEs detected![/red]"
            )
            console.print("Make sure Opencode or Antigravity is installed.")
            raise typer.Exit(1)

    # Bootstrap to targets
    success = True

    if target_opencode:
        if not bootstrap_to_target(
            "Opencode",
            OPENCODE_COMMANDS,
            OPENCODE_SUPPORT,
            assets_dir,
            dry_run,
        ):
            success = False

    if target_antigravity:
        if not bootstrap_to_target(
            "Antigravity",
            ANTIGRAVITY_COMMANDS,
            ANTIGRAVITY_SUPPORT,
            assets_dir,
            dry_run,
        ):
            success = False

    # Summary
    console.print()
    if success:
        console.print("[green]Bootstrap complete![/green]")
        console.print("\nYou can now use the following commands from any project:")
        console.print("  /do-the-thing  - Execute the complete SDD workflow")
        console.print("  /commit        - Commit, push, and optionally create PR")
        console.print("  /init          - Create/update AGENTS.md")
    else:
        console.print("[yellow]Bootstrap completed with warnings.[/yellow]")
        raise typer.Exit(1)


@app.command()
def check():
    """
    Verify installation status.

    Check that workflow files are properly installed in global IDE locations.
    """
    print_banner()
    console.print("[blue]Checking installation status...[/blue]\n")

    all_ok = True

    # Check Opencode
    console.print("[cyan]Opencode:[/cyan]")
    for filename in WORKFLOW_FILES:
        path = OPENCODE_COMMANDS / filename
        if path.exists():
            console.print(f"  [green]✓[/green] {path}")
        else:
            console.print(f"  [red]✗[/red] {path} [dim](missing)[/dim]")
            all_ok = False

    if OPENCODE_SUPPORT.exists():
        console.print(f"  [green]✓[/green] {OPENCODE_SUPPORT}/")
    else:
        console.print(f"  [dim]○[/dim] {OPENCODE_SUPPORT}/ [dim](not installed)[/dim]")

    # Check Antigravity
    console.print("\n[cyan]Antigravity:[/cyan]")
    for filename in WORKFLOW_FILES:
        path = ANTIGRAVITY_COMMANDS / filename
        if path.exists():
            console.print(f"  [green]✓[/green] {path}")
        else:
            console.print(f"  [red]✗[/red] {path} [dim](missing)[/dim]")
            all_ok = False

    if ANTIGRAVITY_SUPPORT.exists():
        console.print(f"  [green]✓[/green] {ANTIGRAVITY_SUPPORT}/")
    else:
        console.print(f"  [dim]○[/dim] {ANTIGRAVITY_SUPPORT}/ [dim](not installed)[/dim]")

    # Summary
    console.print()
    if all_ok:
        console.print("[green]All files verified successfully![/green]")
    else:
        console.print("[yellow]Some files are missing. Run 'cmdctl init' to install.[/yellow]")
        raise typer.Exit(1)


def main():
    """Entry point for the CLI."""
    app()


if __name__ == "__main__":
    main()
