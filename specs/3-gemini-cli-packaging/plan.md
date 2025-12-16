# Implementation Plan: Gemini-CLI Packaging Support

**Feature Branch**: `3-gemini-cli-packaging`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)

## Technical Context

| Aspect | Value |
|--------|-------|
| Script | `.github/workflows/scripts/create-release-packages.sh` |
| Language | Bash |
| New Target | `gemini-cli` |
| Output Format | TOML (for Gemini-CLI) |
| Output Path | `.genreleases/command-center-gemini-cli-{version}.zip` |

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-First Development | Compliant | Spec created |
| II. Test-Driven Quality | Compliant | Testing via manual execution of script |
| III. Constitution Alignment | Compliant | Following workflow |
| IV. Iterative Refinement | Compliant | Phases followed |
| V. Documentation as Code | Compliant | Plan documented |

## Implementation Phases

### Phase 1: Design

#### Script Modifications
1.  **Constants**: Update `ALL_AGENTS` to include `gemini-cli`.
2.  **Helper Function**: Add `convert_md_to_toml` function (adapted from `bootstrap.sh`).
    -   *Logic*:
        -   Extract description from YAML frontmatter (lines between first two `---`).
        -   Extract prompt body (everything after second `---`).
        -   Format as TOML: `description = "..."`, `prompt = '''...'''`.
3.  **Build Function**: Add `build_gemini_cli_package` function.
    -   Create directory structure: `base_dir/.gemini/commands/` and `base_dir/.gemini/.do-the-thing/`.
    -   Loop through `COMMAND_FILES`:
        -   Call `convert_md_to_toml` for each.
        -   Save as `.toml` in `.gemini/commands/`.
    -   Copy support files (`.do-the-thing`) to `.gemini/.do-the-thing/`.
    -   Zip contents.
4.  **Main Loop**: Ensure switch case handles `gemini-cli` (it should if `ALL_AGENTS` is updated and loop uses it).

### Phase 2: Implementation

-   Modify `.github/workflows/scripts/create-release-packages.sh`.

### Phase 3: Testing

-   Run `./create-release-packages.sh v0.0.9-test`.
-   Verify `command-center-gemini-cli-v0.0.9-test.zip` exists.
-   Unzip and inspect `do-the-thing.toml` content.
-   Verify `AGENTS=gemini-cli` works.
-   Verify default (no args) builds all 3.

## Complexity Tracking

| Item | Complexity | Risk | Notes |
|------|------------|------|-------|
| TOML Conversion | Low | Low | Logic exists in bootstrap.sh, just porting it. |
| Package Structure | Low | Low | Standard zip structure. |
| Script Integration | Low | Low | Adding a function and updating a list. |
