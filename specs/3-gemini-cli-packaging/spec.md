# Feature Specification: Gemini-CLI Packaging Support

**Feature Branch**: `3-gemini-cli-packaging`  
**Created**: 2025-12-16  
**Status**: Draft  
**Input**: User description: "We added Gemini CLI support but the package release process needs to include the Gemini CLI packaging as well and it needs to bootstrap for Gemini CLI when the option is picked or --all is used."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Gemini-CLI Release Package (Priority: P1)

As a release manager, I want the release script to generate a specific package for Gemini-CLI that contains TOML-formatted commands, so that Gemini-CLI users can install the workflows manually if needed.

**Why this priority**: Essential for distributing the Gemini-CLI support added in previous features.

**Independent Test**: Run `.github/workflows/scripts/create-release-packages.sh v0.0.8` (or similar) and verify a `command-center-gemini-cli-v0.0.8.zip` is created containing TOML files.

**Acceptance Scenarios**:

1. **Given** the release script is run with `AGENTS=gemini-cli` (or including it), **When** the script completes, **Then** a zip file named `command-center-gemini-cli-{version}.zip` exists in `.genreleases`.
2. **Given** the Gemini-CLI package is created, **When** extracted, **Then** it contains `.toml` command files in a `.gemini/commands/` equivalent structure (or flattened for easy install).
3. **Given** the Gemini-CLI package is created, **When** extracted, **Then** the TOML files contain the correct description and prompt content derived from the markdown sources.

### User Story 2 - Include Gemini-CLI in Default Build (Priority: P2)

As a release manager, I want Gemini-CLI to be included by default when running the release script without specific agent arguments, so that all supported platforms are packaged automatically.

**Why this priority**: Ensures consistent releases for all platforms without manual intervention.

**Independent Test**: Run `.github/workflows/scripts/create-release-packages.sh v0.0.8` without `AGENTS` var and verify all 3 packages (opencode, antigravity, gemini-cli) are created.

**Acceptance Scenarios**:

1. **Given** the release script is run without `AGENTS` set, **When** it completes, **Then** packages for Opencode, Antigravity, AND Gemini-CLI are created.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `create-release-packages.sh` script MUST accept `gemini-cli` as a valid value in the `AGENTS` list.
- **FR-002**: The script MUST include `gemini-cli` in the default list of agents if `AGENTS` is not provided.
- **FR-003**: The script MUST implement a `build_gemini_cli_package` function.
- **FR-004**: The `build_gemini_cli_package` function MUST convert markdown command files (`do-the-thing.md`, etc.) to TOML format (`do-the-thing.toml`, etc.).
- **FR-005**: The TOML conversion logic MUST match the logic used in `scripts/bootstrap.sh` (description from frontmatter, body as prompt).
- **FR-006**: The Gemini-CLI package structure MUST mirror the expected installation path or be easily installable (e.g., placing commands in `.gemini/commands/` within the zip).
- **FR-007**: The script MUST properly zip the Gemini-CLI artifacts into `command-center-gemini-cli-{version}.zip`.

### Key Entities

- **Release Script**: `.github/workflows/scripts/create-release-packages.sh`
- **Gemini-CLI Package**: `command-center-gemini-cli-{version}.zip`
- **TOML Commands**: `.toml` files generated from `.md` sources.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running the release script generates a valid zip file for Gemini-CLI.
- **SC-002**: The generated zip file contains valid TOML files.
- **SC-003**: The TOML content matches the source markdown content.
- **SC-004**: The release process supports all 3 targets (Opencode, Antigravity, Gemini-CLI) simultaneously.
