# Implementation Plan: Add Gemini-CLI Support

**Feature Branch**: `1-add-gemini-cli-support`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)

## Technical Context

| Aspect | Value |
|--------|-------|
| Language/Version | Bash (POSIX-compatible) |
| Primary Dependencies | None (bash built-ins, standard Unix commands) |
| Storage | Filesystem (copy operations) |
| Testing Framework | Manual verification / Shell script tests |
| Target Platform | Linux, macOS, Windows (via Git Bash/WSL) |
| Project Type | CLI Script Enhancement |
| Performance Goals | N/A (one-time setup script) |
| Constraints | Must maintain backward compatibility with existing flags |
| Scale/Scope | Single file modification (bootstrap.sh) |

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-First Development | Compliant | Spec created before implementation |
| II. Test-Driven Quality | Compliant | Acceptance scenarios defined; verification step validates install |
| III. Constitution Alignment | Compliant | Following workflow |
| IV. Iterative Refinement | Compliant | Phases followed in order |
| V. Documentation as Code | Compliant | Spec and plan maintained |

## Implementation Phases

### Phase 0: Research
No additional research needed - Gemini-CLI paths clarified by user.

### Phase 1: Design

#### File Modifications Required

**scripts/bootstrap.sh**:
1. Add Gemini-CLI global locations as variables
2. Add `--gemini-cli` flag parsing
3. Add `detect_gemini_cli()` function
4. Add `bootstrap_to_gemini_cli()` function
5. Update auto-detection logic to include Gemini-CLI
6. Update verification to include Gemini-CLI
7. Update help text

#### Path Mappings

| Tool | Commands Location | Support Location |
|------|-------------------|------------------|
| Opencode | `~/.config/opencode/command/` | `~/.config/opencode/.do-the-thing/` |
| Antigravity | `~/.gemini/antigravity/global_workflows/` | `~/.gemini/antigravity/.do-the-thing/` |
| Gemini-CLI | `~/.gemini/commands/` | `~/.gemini/.do-the-thing/` |

#### Detection Logic

```
Gemini-CLI detected if:
  - `~/.gemini/` directory exists (but NOT just `~/.gemini/antigravity/`)
  - OR `gemini` command is in PATH
  
Distinction from Antigravity:
  - Antigravity uses: ~/.gemini/antigravity/
  - Gemini-CLI uses: ~/.gemini/ (root level)
  - Both can coexist - they use different subdirectories
```

### Phase 2: Implementation

See tasks.md for detailed task breakdown.

### Phase 3: Testing

1. Dry-run test with `--gemini-cli` flag
2. Actual bootstrap to Gemini-CLI
3. Verification of installed files
4. Test auto-detection when Gemini-CLI present
5. Test `--all` flag includes Gemini-CLI

## Project Structure

No structural changes - this is a single-file enhancement to `scripts/bootstrap.sh`.

## Complexity Tracking

| Item | Complexity | Risk | Notes |
|------|------------|------|-------|
| Add new flag | Low | Low | Follow existing pattern |
| Detection logic | Low | Medium | Need to distinguish from Antigravity |
| Bootstrap function | Low | Low | Copy existing pattern |
| Verification | Low | Low | Extend existing verification |
