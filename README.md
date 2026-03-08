# Command-Center

Global workflow commands for AI coding assistants, inspired by [Spec-Kit](https://github.com/github/spec-kit).

## Overview

Command-Center provides reusable slash commands that can be deployed to your AI coding IDE/Agent globally. Once installed, these commands are available from any project.

### Available Commands

| Command | Description |
|---------|-------------|
| `/do-the-thing` | Execute the complete Spec-Driven Development workflow autonomously |
| `/commit` | Commit, push, and optionally create a PR with comprehensive review |
| `/init` | Create or update AGENTS.md for your project |

## Installation

### Option 1: CLI Tool (Recommended)

#### Persistent Installation
Install once and use everywhere:

```bash
uv tool install command-center --from git+https://github.com/brimdor/command-center.git
```

Then bootstrap your workflows:
```bash
cmdctl init           # Bootstrap to all detected IDEs
cmdctl init --opencode    # Bootstrap only to Opencode
cmdctl init --copilot     # Bootstrap only to VS Code Copilot
cmdctl init --claude      # Bootstrap only to Claude Code
cmdctl check          # Verify installation
```

#### One-time Usage
Run directly without installing:
```bash
uvx --from git+https://github.com/brimdor/command-center.git cmdctl init
```

### Option 2: Manual (Legacy)

```bash
# Clone the repository
git clone https://github.com/brimdor/command-center.git
cd command-center

# Run the bootstrap script
./scripts/bootstrap.sh
```

`scripts/bootstrap.sh` is now a thin wrapper that delegates to `cmdctl init`.

The bootstrap script will:

1. Auto-detect installed IDEs
2. Copy workflow commands to global locations
3. Copy supporting files (phase docs, templates, constitution)
4. Verify the installation

### Bootstrap Options

```bash
./scripts/bootstrap.sh --help          # Show help
./scripts/bootstrap.sh --dry-run       # Preview changes without applying
./scripts/bootstrap.sh --opencode      # Bootstrap only to Opencode
./scripts/bootstrap.sh --antigravity   # Bootstrap only to Antigravity
./scripts/bootstrap.sh --copilot       # Bootstrap only to VS Code Copilot
./scripts/bootstrap.sh --all           # Bootstrap to all detected IDEs (default)
```

## File Structure

```text
command-center/
├── do-the-thing.md          # Main SDD orchestrator command
├── commit.md                # Commit/push/PR workflow
├── init.md                  # AGENTS.md generator
├── scripts/
│   └── bootstrap.sh         # Installation script
└── .do-the-thing/
    ├── do-the-thing-phase-1.md   # Context Loading
    ├── do-the-thing-phase-2.md   # Specification
    ├── do-the-thing-phase-3.md   # Clarification
    ├── do-the-thing-phase-4.md   # Planning
    ├── do-the-thing-phase-5.md   # Task Generation
    ├── do-the-thing-phase-6.md   # Analysis
    ├── do-the-thing-phase-7.md   # Remediation
    ├── do-the-thing-phase-8.md   # Implementation
    ├── do-the-thing-phase-9.md   # Testing & Validation
    ├── do-the-thing-appendix.md  # Constitution creation, intervention points
    └── .specify/
        ├── memory/
        │   └── constitution.md   # Project constitution template
        ├── scripts/
        │   └── bash/             # Helper scripts
        └── templates/
            ├── spec-template.md
            ├── plan-template.md
            ├── tasks-template.md
            └── ...
```

## Global Installation Locations

| IDE/Agent | Commands | Support Files |
|-----------|----------|---------------|
| **Opencode** | `~/.config/opencode/command/` | `~/.config/opencode/.do-the-thing/` |
| **Antigravity** | `~/.gemini/antigravity/global_workflows/` | `~/.gemini/antigravity/.do-the-thing/` |
| **VS Code Copilot** | `~/.config/Code/User/prompts/*.prompt.md` (or `~/.config/Code - Insiders/User/prompts/*.prompt.md`) | `~/.copilot/.do-the-thing/` |
| **VS Code Copilot Rules** | `~/.copilot/instructions/*.instructions.md` | n/a |
| **Claude Code (Desktop/CLI)** | `~/.claude/skills/*/SKILL.md` | `~/.claude/.do-the-thing/` |

### Claude Code Path Matrix

Use this when mapping terminology across agents (Opencode/Antigravity/Copilot/Claude):

| Concept | Claude Location |
|---------|------------------|
| Global instructions | `~/.claude/CLAUDE.md` |
| Project instructions | `./CLAUDE.md` or `./.claude/CLAUDE.md` |
| Local project instructions | `./CLAUDE.local.md` |
| Global rules | `~/.claude/rules/**/*.md` |
| Project rules | `./.claude/rules/**/*.md` |
| Global skills | `~/.claude/skills/<skill>/SKILL.md` |
| Project skills | `./.claude/skills/<skill>/SKILL.md` |
| User settings | `~/.claude/settings.json` |
| Project settings | `./.claude/settings.json` |
| Project local settings | `./.claude/settings.local.json` |
| MCP (user/local scopes) | `~/.claude.json` |
| MCP (project scope) | `./.mcp.json` |
| Claude Desktop app MCP config | macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`, Windows: `%APPDATA%\Claude\claude_desktop_config.json` |

Notes:

- Claude Desktop chat config and Claude Code config are separate.
- Command-Center installs workflow commands as Claude skills (preferred modern format).
- Command-Center does not install Claude legacy command files (`.claude/commands`).

## Path Resolution

The `/do-the-thing` workflow uses path resolution to find phase files and constitution:

1. **Project-local** (preferred): `.do-the-thing/` in current project
2. **Global Opencode**: `~/.config/opencode/.do-the-thing/`
3. **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/`
4. **Global Copilot**: `~/.copilot/.do-the-thing/`
5. **Global Claude Code**: `~/.claude/.do-the-thing/`

This allows project-specific customizations while using global defaults.

## Constitution

The constitution defines your project's core principles:

- Edit `.do-the-thing/.specify/memory/constitution.md` to customize
- The workflow checks constitution alignment in Phase 6 (Analysis)
- Violations are remediated in Phase 7

## Updating

To update your global installation after pulling new changes:

```bash
cd command-center
git pull
./scripts/bootstrap.sh
```

## License

MIT
