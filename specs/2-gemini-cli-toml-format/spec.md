# Feature Specification: Gemini-CLI TOML Command Format

**Feature Branch**: `2-gemini-cli-toml-format`  
**Created**: 2025-12-16  
**Status**: Draft  
**Input**: User description: "Need to make a shift in formatting for Gemini CLI. The commands must be in TOML format. The Gemini.md global rule is just fine as it is."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bootstrap Creates TOML Commands for Gemini-CLI (Priority: P1)

As a developer using Gemini-CLI, I want the bootstrap script to create TOML-formatted command files (instead of markdown with YAML frontmatter) so that Gemini-CLI can properly recognize and execute the commands.

**Why this priority**: This is the core change - without TOML format, Gemini-CLI commands won't work correctly. The bootstrap must produce files in the format Gemini-CLI expects.

**Independent Test**: Can be fully tested by running `./bootstrap.sh --gemini-cli` and verifying files in `~/.gemini/commands/` are in TOML format with `.toml` extension.

**Acceptance Scenarios**:

1. **Given** Gemini-CLI is installed, **When** user runs `./bootstrap.sh --gemini-cli`, **Then** command files are created as TOML files (`do-the-thing.toml`, `commit.toml`, `init.toml`) in `~/.gemini/commands/`
2. **Given** Gemini-CLI bootstrap completes, **When** user inspects command files, **Then** each file has valid TOML syntax with `description` and `prompt` fields
3. **Given** old markdown command files exist in `~/.gemini/commands/`, **When** user runs bootstrap, **Then** old `.md` files are removed and replaced with `.toml` files

---

### User Story 2 - Gemini-CLI TOML Commands Reference Prompt Content (Priority: P2)

As a developer, I want the TOML commands to contain the full prompt content (the markdown body) so that Gemini-CLI has access to the complete workflow instructions.

**Why this priority**: The TOML format must include the actual prompt content for Gemini-CLI to execute the commands properly.

**Independent Test**: Can be tested by inspecting the generated TOML files and verifying they contain the prompt markdown content from the source files.

**Acceptance Scenarios**:

1. **Given** bootstrap creates TOML command files, **When** user reads `do-the-thing.toml`, **Then** the `prompt` field contains the full markdown content from the source `do-the-thing.md` (excluding YAML frontmatter)
2. **Given** TOML command files exist, **When** user invokes `/do-the-thing` in Gemini-CLI, **Then** Gemini-CLI receives the full prompt content

---

### User Story 3 - Verification Shows TOML Files for Gemini-CLI (Priority: P3)

As a developer, I want the verification step to check for TOML files (not markdown) when verifying Gemini-CLI installation.

**Why this priority**: Verification must reflect the actual file format being used to provide accurate feedback.

**Independent Test**: Can be tested by running bootstrap with verification and checking that TOML file presence is validated.

**Acceptance Scenarios**:

1. **Given** bootstrap completes for Gemini-CLI, **When** verification runs, **Then** it checks for `.toml` files (`do-the-thing.toml`, `commit.toml`, `init.toml`)
2. **Given** only old `.md` files exist, **When** verification runs, **Then** missing TOML files are indicated with error marks

---

### Edge Cases

- What happens when both old `.md` and new `.toml` files exist? (Answer: Remove old `.md` files, keep only `.toml`)
- What happens when the markdown source contains characters that need escaping in TOML strings? (multi-line strings use triple quotes)
- How is the GEMINI.md global rule file handled? (Answer: Unchanged per user requirement)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create TOML-formatted command files (`.toml` extension) for Gemini-CLI bootstrapping
- **FR-002**: System MUST include a `description` field in each TOML command file matching the YAML frontmatter description
- **FR-003**: System MUST include a `prompt` field containing the full markdown content (body after frontmatter)
- **FR-004**: System MUST use TOML multi-line string syntax (triple single-quotes `'''`) for the prompt field
- **FR-005**: System MUST remove any existing `.md` command files in `~/.gemini/commands/` when bootstrapping to Gemini-CLI
- **FR-006**: System MUST update verification to check for `.toml` files instead of `.md` files for Gemini-CLI
- **FR-007**: System MUST NOT modify the `~/.gemini/GEMINI.md` global rule file
- **FR-008**: System MUST preserve existing behavior for Opencode and Antigravity (they continue using `.md` format)

### Key Entities

- **TOML Command File**: A file with `.toml` extension containing `description` (string) and `prompt` (multi-line string) fields
- **Markdown Command File**: The existing source files (`do-the-thing.md`, `commit.md`, `init.md`) with YAML frontmatter

## TOML Format

The TOML command files should follow this structure:

```toml
description = "Brief description of the command"

prompt = '''
[Full markdown content from the source file, excluding YAML frontmatter]
'''
```

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully bootstrap to Gemini-CLI and receive TOML-formatted command files
- **SC-002**: Generated TOML files pass TOML syntax validation
- **SC-003**: Gemini-CLI recognizes and can invoke the bootstrapped commands
- **SC-004**: Verification correctly identifies TOML files for Gemini-CLI installations
