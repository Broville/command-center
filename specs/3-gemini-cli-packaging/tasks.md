# Implementation Tasks: Gemini-CLI Packaging Support

**Feature Branch**: `3-gemini-cli-packaging`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)

## Task Legend
- `[P]` = Parallelizable
- `[US#]` = User Story reference

---

## Phase 1: Script Modification

- [ ] T001 [US1] Update `ALL_AGENTS` constant in `.github/workflows/scripts/create-release-packages.sh` to include `gemini-cli`.
- [ ] T002 [US1] Add `convert_md_to_toml` function to script.
- [ ] T003 [US1] Add `build_gemini_cli_package` function to script.
  - Create directory structure.
  - Implement loop to convert commands to TOML.
  - Copy support files.
  - Zip package.
- [ ] T004 [US2] Update main loop case statement (if needed, or verify it handles dynamic list).

---

## Phase 2: Testing & Validation

- [ ] T005 [US1] Test build with `AGENTS=gemini-cli`.
- [ ] T006 [US1] Verify TOML content in generated package.
- [ ] T007 [US2] Test build with default args (all agents).

---

## Acceptance Criteria Mapping

| Task | Requirement | Acceptance Scenario |
|------|-------------|---------------------|
| T001, T004 | FR-001, FR-002 | US2-AS1 |
| T002, T003 | FR-003, FR-004, FR-005, FR-006, FR-007 | US1-AS1, US1-AS2, US1-AS3 |
| T005, T006 | Testing | US1 Validation |
| T007 | Testing | US2 Validation |
