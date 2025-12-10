"""
Command-Center CLI - Bootstrap tool for AI coding assistant workflows

Usage:
    # Interactive Wizard (Recommended)
    cmdctl init

    # Non-interactive / CI
    cmdctl init --all --headless
    cmdctl init --opencode --headless
"""

import os
import shutil
import time
from pathlib import Path
from typing import List, Optional

import typer
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.style import Style
from rich.theme import Theme

# Initialize with custom theme
custom_theme = Theme({
    "info": "cyan",
    "warning": "yellow",
    "error": "red",
    "success": "green",
    "title": "bold cyan",
})
console = Console(theme=custom_theme)
app = typer.Typer(
    name="cmdctl",
    help="Command-Center: Bootstrap global workflow commands for AI coding assistants.",
    add_completion=False,
)

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
        console.print(f"  [warning]DRY RUN:[/warning] Copy {src.name} -> {dest}")
        return True

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        # console.print(f"  [success]✓[/success] Copied {src.name}") # Too verbose for wizard
        return True
    except Exception as e:
        console.print(f"  [error]✗[/error] Failed to copy {src.name}: {e}")
        return False


def copy_directory(src: Path, dest: Path, dry_run: bool = False) -> bool:
    """Copy a directory recursively."""
    if dry_run:
        console.print(f"  [warning]DRY RUN:[/warning] Copy directory {src.name}/ -> {dest}")
        return True

    try:
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        return True
    except Exception as e:
        console.print(f"  [error]✗[/error] Failed to copy {src.name}/: {e}")
        return False


def bootstrap_to_target(
    name: str,
    commands_dir: Path,
    support_dir: Path,
    assets_dir: Path,
    dry_run: bool = False,
) -> bool:
    """Bootstrap workflow files to a target IDE."""
    success = True

    # Copy workflow files
    for filename in WORKFLOW_FILES:
        src = assets_dir / filename
        if src.exists():
            if not copy_file(src, commands_dir / filename, dry_run):
                success = False
        else:
            console.print(f"  [warning]![/warning] Asset missing: {filename}")
            success = False

    # Copy support directory
    src_support = assets_dir / SUPPORT_DIR
    if src_support.exists():
        if not copy_directory(src_support, support_dir, dry_run):
            success = False
    else:
        console.print(f"  [warning]![/warning] Support dir missing: {SUPPORT_DIR}")

    return success


def print_banner():
    """Print the CLI banner."""
    banner_text = """
   ______                                          __      ______            __       
  / ____/___  ____ ___  ____ ___  ____ _____  ____/ /     / ____/__  ____  / /____  _____
 / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  /_____/ /   / _ \/ __ \/ __/ _ \/ ___/
/ /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ /_____/ /___/  __/ / / / /_/  __/ /    
\____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/      \____/\___/_/ /_/\__/\___/_/     
                                                                                         
    """
    console.print(Panel.fit(banner_text, border_style="cyan", title="v1.1.0", subtitle="Global Workflow Bootstrapper"))


def run_wizard(dry_run: bool):
    """Run the interactive setup wizard."""
    print_banner()
    console.print("[italic]Welcome! Let's get your AI coding assistants supercharged.[/italic]\n")

    assets_dir = get_assets_dir()
    if not (assets_dir / "do-the-thing.md").exists():
        console.print(f"[error]CRITICAL:[/error] Asset files not found in {assets_dir}")
        raise typer.Exit(1)

    # 1. Detection
    with console.status("[bold cyan]Scanning for installed agents...[/bold cyan]", spinner="dots"):
        time.sleep(1) # Dramatic effect
        has_opencode = detect_opencode()
        has_antigravity = detect_antigravity()

    detected = []
    if has_opencode:
        detected.append("Opencode")
    if has_antigravity:
        detected.append("Antigravity")
    
    if not detected:
         console.print("[warning]No known AI assistants detected.[/warning]")
         if not Confirm.ask("Do you want to proceed anyway?", default=False):
             console.print("Aborting.")
             raise typer.Exit(0)
    else:
        console.print(f"  [success]✓[/success] Detected: [bold]{', '.join(detected)}[/bold]\n")

    # 2. Selection
    targets = []
    
    # Checkbox-style selection (simulated with prompts for now as rich doesn't have native checkbox prompt easily without other deps)
    console.print("[bold]Where should we install the workflows?[/bold]")
    
    if Confirm.ask(f"Install to [cyan]Opencode[/cyan]?", default=has_opencode):
        targets.append("opencode")
    
    if Confirm.ask(f"Install to [cyan]Antigravity[/cyan]?", default=has_antigravity):
        targets.append("antigravity")

    if not targets:
        console.print("[yellow]No targets selected. Exiting.[/yellow]")
        raise typer.Exit(0)

    # 3. Confirmation
    console.print(f"\n[bold]Plan:[/bold] Bootstrap workflows to [cyan]{', '.join(t.capitalize() for t in targets)}[/cyan]")
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
        transient=True
    ) as progress:
        
        if "opencode" in targets:
            task = progress.add_task("Bootstrapping Opencode...", total=None)
            if not bootstrap_to_target("Opencode", OPENCODE_COMMANDS, OPENCODE_SUPPORT, assets_dir, dry_run):
                success_all = False
            time.sleep(0.5) # UX pacing
            progress.remove_task(task)
            console.print("  [success]✓[/success] Opencode configured")

        if "antigravity" in targets:
            task = progress.add_task("Bootstrapping Antigravity...", total=None)
            if not bootstrap_to_target("Antigravity", ANTIGRAVITY_COMMANDS, ANTIGRAVITY_SUPPORT, assets_dir, dry_run):
                success_all = False
            time.sleep(0.5) # UX pacing
            progress.remove_task(task)
            console.print("  [success]✓[/success] Antigravity configured")

    # 5. Summary
    console.print()
    if success_all:
        console.print(Panel(
            "[bold green]Success! Your agents are ready.[/bold green]\n\n"
            "Try these commands in your chat:\n"
            "  [cyan]/do-the-thing[/cyan]  - Autonomous Spec-Driven Development\n"
            "  [cyan]/commit[/cyan]        - Smart Commit & PR\n"
            "  [cyan]/init[/cyan]          - Generate AGENTS.md",
            title="Installation Complete",
            border_style="green"
        ))
    else:
        console.print("[error]Completed with errors. Please check the output above.[/error]")
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
    all_targets: bool = typer.Option(
        False, "--all", help="Bootstrap to all detected IDEs"
    ),
    headless: bool = typer.Option(
        False, "--headless", help="Run in non-interactive mode (requires flags)"
    )
):
    """
    Bootstrap workflow commands to global IDE locations.
    """
    
    # Interactive Mode (Default if no specific targets and not headless)
    if not headless and not (opencode or antigravity or all_targets):
        run_wizard(dry_run)
        return

    # Headless / Flag Mode
    console.print("[bold]Running in Headless Mode[/bold]")
    assets_dir = get_assets_dir()
    
    if not (assets_dir / "do-the-thing.md").exists():
        console.print(f"[error]Error:[/error] Asset files not found in {assets_dir}")
        raise typer.Exit(1)

    target_opencode = opencode
    target_antigravity = antigravity

    if all_targets:
        target_opencode = detect_opencode()
        target_antigravity = detect_antigravity()

    # Fallback if nothing selected but headless wasn't strict? 
    # Actually if they ran `cmdctl init --headless` with no other flags, we should prob auto-detect.
    if not target_opencode and not target_antigravity and headless and not (opencode or antigravity):
         target_opencode = detect_opencode()
         target_antigravity = detect_antigravity()

    if not target_opencode and not target_antigravity:
        console.print("[error]No targets specified or detected.[/error]")
        raise typer.Exit(1)

    if target_opencode:
        bootstrap_to_target("Opencode", OPENCODE_COMMANDS, OPENCODE_SUPPORT, assets_dir, dry_run)

    if target_antigravity:
        bootstrap_to_target("Antigravity", ANTIGRAVITY_COMMANDS, ANTIGRAVITY_SUPPORT, assets_dir, dry_run)
    
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
    for filename in WORKFLOW_FILES:
        path = OPENCODE_COMMANDS / filename
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
    for filename in WORKFLOW_FILES:
        path = ANTIGRAVITY_COMMANDS / filename
        if path.exists():
            console.print(f"  [success]✓[/success] {path}")
        else:
            console.print(f"  [error]✗[/error] {path} [dim](missing)[/dim]")
            all_ok = False

    if ANTIGRAVITY_SUPPORT.exists():
        console.print(f"  [success]✓[/success] {ANTIGRAVITY_SUPPORT}/")
    else:
        console.print(f"  [dim]○[/dim] {ANTIGRAVITY_SUPPORT}/ [dim](not installed)[/dim]")

    console.print()
    if all_ok:
        console.print("[success]All files verified successfully![/success]")
    else:
        console.print("[warning]Some files are missing. Run 'cmdctl init' to install.[/warning]")
        raise typer.Exit(1)


def main():
    """Entry point for the CLI."""
    app()


if __name__ == "__main__":
    main()
