# Feature Specification: Add Gemini-CLI Support

**Feature Branch**: `1-add-gemini-cli-support`  
**Created**: 2025-12-16  
**Status**: Draft  
**Input**: User description: "We currently have Antigravity and Opencode as options. Now let's add Gemini-CLI. The bootstrapping needs to apply the global rules/workflows where Gemini-CLI will see them globally."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bootstrap to Gemini-CLI (Priority: P1)

As a developer using Gemini-CLI, I want to run the bootstrap script with a `--gemini-cli` flag so that the do-the-thing workflows are installed to Gemini-CLI's global configuration location.

**Why this priority**: This is the core feature - without Gemini-CLI bootstrap support, the entire feature has no value. Gemini-CLI is Google's official CLI tool and installing workflows to its global location is the primary goal.

**Independent Test**: Can be fully tested by running `./bootstrap.sh --gemini-cli` and verifying files appear in `~/.gemini/` (the standard Gemini-CLI config location). Delivers the core value of Gemini-CLI support.

**Acceptance Scenarios**:

1. **Given** Gemini-CLI is installed on the system, **When** user runs `./bootstrap.sh --gemini-cli`, **Then** command files (do-the-thing.md, commit.md, init.md) are copied to Gemini-CLI's global commands location
2. **Given** Gemini-CLI is installed on the system, **When** user runs `./bootstrap.sh --gemini-cli`, **Then** support files (.do-the-thing directory) are copied to Gemini-CLI's global support location
3. **Given** Gemini-CLI is NOT installed on the system, **When** user runs `./bootstrap.sh --gemini-cli`, **Then** script warns user that Gemini-CLI was not detected

---

### User Story 2 - Auto-Detection of Gemini-CLI (Priority: P2)

As a developer running the bootstrap script without arguments, I want Gemini-CLI to be automatically detected alongside Opencode and Antigravity so that all my installed AI tools get the workflows.

**Why this priority**: Auto-detection provides seamless experience but is secondary to explicit targeting. Users can always use `--gemini-cli` flag if auto-detection fails.

**Independent Test**: Can be tested by running `./bootstrap.sh` on a system with Gemini-CLI installed and verifying it is detected and bootstrapped.

**Acceptance Scenarios**:

1. **Given** Gemini-CLI is installed on the system, **When** user runs `./bootstrap.sh` (no flags), **Then** Gemini-CLI is listed as "Detected" in the output
2. **Given** Gemini-CLI, Opencode, and Antigravity are all installed, **When** user runs `./bootstrap.sh --all`, **Then** all three are bootstrapped

---

### User Story 3 - Verification of Gemini-CLI Installation (Priority: P3)

As a developer, I want the bootstrap script to verify that Gemini-CLI files were correctly installed so that I have confidence the bootstrap succeeded.

**Why this priority**: Verification is a quality-of-life improvement but not essential for core functionality.

**Independent Test**: Can be tested by running bootstrap and checking the verification output shows Gemini-CLI files as present.

**Acceptance Scenarios**:

1. **Given** bootstrap has completed for Gemini-CLI, **When** verification runs, **Then** all installed files are listed with check marks
2. **Given** a file failed to install, **When** verification runs, **Then** missing file is indicated with an error mark

---

### Edge Cases

- What happens when Gemini-CLI config directory exists but gemini command is not in PATH?
- What happens when user has both Antigravity (in `~/.gemini/antigravity/`) and Gemini-CLI (in `~/.gemini/`) installed - how are they distinguished?
- What happens when the target directory has existing files that differ from source?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support a `--gemini-cli` flag to explicitly target Gemini-CLI for bootstrapping
- **FR-002**: System MUST detect Gemini-CLI installation by checking for `~/.gemini/` directory or `gemini` command in PATH
- **FR-003**: System MUST copy command files (do-the-thing.md, commit.md, init.md) to Gemini-CLI's global commands location
- **FR-004**: System MUST copy .do-the-thing support directory to Gemini-CLI's global support location
- **FR-005**: System MUST distinguish between Gemini-CLI (`~/.gemini/`) and Antigravity (`~/.gemini/antigravity/`) installations
- **FR-006**: System MUST include Gemini-CLI in the `--all` flag behavior
- **FR-007**: System MUST verify Gemini-CLI installation in the verification step
- **FR-008**: System MUST update help text to document the `--gemini-cli` flag

### Key Entities

- **Gemini-CLI Commands Location**: `~/.gemini/commands/` - Global directory where Gemini-CLI looks for custom commands/workflows
- **Gemini-CLI Custom Instructions**: `~/.gemini/GEMINI.md` - Global custom instructions file (not used by bootstrap, but important context)
- **Gemini-CLI Support Location**: `~/.gemini/.do-the-thing/` - Directory for .do-the-thing support files that Gemini-CLI can access globally

## Clarifications

### Q1: Where does Gemini-CLI look for global custom instructions/workflows?

**Answer**: Gemini-CLI uses the following locations:
- **Custom Instructions**: `~/.gemini/GEMINI.md` (Linux/Mac) or `C:\Users\%USERNAME%\.gemini\GEMINI.md` (Windows)
- **Commands Directory**: `~/.gemini/commands/` (Linux/Mac) or `C:\Users\%USERNAME%\.gemini\commands\` (Windows)

This means command files (do-the-thing.md, commit.md, init.md) should be copied to `~/.gemini/commands/` and support files to `~/.gemini/.do-the-thing/`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully bootstrap to Gemini-CLI with a single command (`./bootstrap.sh --gemini-cli`)
- **SC-002**: Auto-detection correctly identifies Gemini-CLI when installed alongside other tools
- **SC-003**: All three tools (Opencode, Antigravity, Gemini-CLI) can be bootstrapped simultaneously with `--all`
- **SC-004**: Verification confirms file presence for Gemini-CLI installations
