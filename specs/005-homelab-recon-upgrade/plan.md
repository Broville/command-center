# Implementation Plan: Homelab Recon Workflow Pillars + Script-First Upgrades

**Feature Branch**: `005-homelab-recon-upgrade`  \
**Created**: 2026-01-31  \
**Spec**: [spec.md](./spec.md)

## Technical Context

| Aspect | Value |
|--------|-------|
| Language/Version | Markdown (command docs + templates) |
| Primary Dependencies | N/A |
| Storage | N/A |
| Testing Framework | Repo checks (markdown lint if available) + unit tests (smoke) |
| Target Platform | Opencode/Antigravity/Gemini-CLI command consumption |
| Project Type | Command documentation + shipped template assets |
| Performance Goals | N/A |
| Constraints | Must preserve maintenance-issue contract; must remain readable and deterministic for agent execution |
| Scale/Scope | Update `/homelab-recon` command doc + add a recon tasks template asset |

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-First Development | Compliant | Spec created before implementation |
| II. Test-Driven Quality | Compliant | Changes validated via lint/tests where available |
| III. Constitution Alignment | Compliant | No phase skipped |
| IV. Iterative Refinement | Compliant | Doc change is staged and self-audited |
| V. Documentation as Code | Compliant | Primary deliverable is documentation + templates |

## Implementation Phases

### Phase 0: Research

- Identify gaps between `recon-workflow.md` and current `src/command_center/assets/commands/homelab-recon.md`.
- Identify inconsistencies (layer ordering, duplicated steps, markdown formatting issues).

### Phase 1: Design

- Define the 5 pillars and how they map onto existing phase/subphase numbering.
- Define the canonical layer ordering and apply it consistently.
- Define a standard on-disk context pack layout (where evidence files go, how they are referenced).
- Define a minimal recon task tracking template (`recon-tasks.md`) and where it is sourced from.

### Phase 2: Implementation

- Update `src/command_center/assets/commands/homelab-recon.md`:
  - Add 5-pillar overview + mapping.
  - Add Script-First rule and toolchain gate.
  - Add context pack directory conventions.
  - Add dynamic task tracking step.
  - Fix inconsistencies and formatting errors (layer ordering, code fences, missing commands).
- Add template asset for recon task tracking.

### Phase 3: Validation

- Run repo tests.
- If markdown linting exists, run it; otherwise do a manual scan for obvious formatting issues.

## Project Structure

No structural changes beyond adding a new shipped template asset and updating existing command documentation.

## Complexity Tracking

| Item | Complexity | Risk | Notes |
|------|------------|------|-------|
| Re-structuring the recon doc | Medium | Low | High edit volume; need to avoid breaking contract wording |
| Introducing recon-tasks template | Low | Low | Asset addition; referenced from the command doc |
| Fixing internal inconsistencies | Low | Low | Mostly mechanical, but correctness matters |
