# Implementation Plan: Gemini-CLI TOML Command Format

**Feature Branch**: `2-gemini-cli-toml-format`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)

## Technical Context

| Aspect | Value |
|--------|-------|
| Language/Version | Bash (POSIX-compatible) |
| Primary Dependencies | None (bash built-ins, standard Unix commands) |
| Storage | Filesystem (file generation) |
| Testing Framework | Manual verification / Shell script tests |
| Target Platform | Linux, macOS, Windows (via Git Bash/WSL) |
| Project Type | CLI Script Enhancement |
| Performance Goals | N/A (one-time setup script) |
| Constraints | Must maintain backward compatibility with Opencode/Antigravity |
| Scale/Scope | Modification to bootstrap.sh + TOML generation |

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-First Development | Compliant | Spec created before implementation |
| II. Test-Driven Quality | Compliant | Acceptance scenarios defined |
| III. Constitution Alignment | Compliant | Following workflow |
| IV. Iterative Refinement | Compliant | Phases followed in order |
| V. Documentation as Code | Compliant | Spec and plan maintained |

## Implementation Phases

### Phase 0: Research
No additional research needed - TOML format is well-defined.

### Phase 1: Design

#### TOML Command Format

Each command file will have this structure:

```toml
description = "Brief description of the command"

prompt = '''
[Full markdown content from source file, excluding YAML frontmatter]
'''
```

#### File Mappings

| Source File | Gemini-CLI Output |
|-------------|-------------------|
| `do-the-thing.md` | `~/.gemini/commands/do-the-thing.toml` |
| `commit.md` | `~/.gemini/commands/commit.toml` |
| `init.md` | `~/.gemini/commands/init.toml` |

#### Key Changes to bootstrap.sh

1. **Add `convert_md_to_toml()` function**: Parses markdown file, extracts description from YAML frontmatter, extracts body content, writes TOML format
2. **Update `bootstrap_to_gemini_cli()` function**: Use `convert_md_to_toml()` instead of direct copy, remove old `.md` files
3. **Update `verify_installation()` function**: Check for `.toml` files instead of `.md` files for Gemini-CLI

#### TOML Conversion Logic

```
1. Read source markdown file
2. Extract YAML frontmatter (between --- delimiters)
3. Parse 'description' field from frontmatter
4. Extract body content (everything after second ---)
5. Write TOML file with:
   - description = "extracted description"
   - prompt = '''extracted body content'''
```

### Phase 2: Implementation

See tasks.md for detailed task breakdown.

### Phase 3: Testing

1. Test TOML generation with dry-run
2. Verify TOML syntax is valid
3. Test actual bootstrap to Gemini-CLI
4. Verify old .md files are removed
5. Test verification checks for .toml files
6. Test Opencode/Antigravity still use .md format

## Project Structure

No structural changes beyond TOML file generation.

## Complexity Tracking

| Item | Complexity | Risk | Notes |
|------|------------|------|-------|
| TOML conversion function | Medium | Low | String parsing, TOML escaping |
| Update bootstrap function | Low | Low | Replace copy with convert |
| Update verification | Low | Low | Change file extensions |
| Clean up old files | Low | Low | Simple rm command |
