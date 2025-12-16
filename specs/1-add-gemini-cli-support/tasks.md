# Implementation Tasks: Add Gemini-CLI Support

**Feature Branch**: `1-add-gemini-cli-support`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)

## Task Legend
- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- `[US#]` = User Story reference

---

## Phase 1: Setup

- [x] T001 [P] Add Gemini-CLI global location variables to `scripts/bootstrap.sh:37-41`
- [x] T002 [P] Add TARGET_GEMINI_CLI flag variable to `scripts/bootstrap.sh:44-46`

---

## Phase 2: Foundational

- [x] T003 Add `--gemini-cli` flag parsing to argument handler in `scripts/bootstrap.sh:272-300`
- [x] T004 Update help text to include `--gemini-cli` option in `scripts/bootstrap.sh:81-95`

---

## Phase 3: User Story 1 - Bootstrap to Gemini-CLI (P1)

- [x] T005 [US1] Add `detect_gemini_cli()` function in `scripts/bootstrap.sh:101-115`
- [x] T006 [US1] Add `bootstrap_to_gemini_cli()` function in `scripts/bootstrap.sh:184-208`
- [x] T007 [US1] Call `bootstrap_to_gemini_cli` when TARGET_GEMINI_CLI is true in `scripts/bootstrap.sh:344-351`

---

## Phase 4: User Story 2 - Auto-Detection (P2)

- [x] T008 [US2] Add Gemini-CLI to auto-detection block in `scripts/bootstrap.sh:318-342`
- [x] T009 [US2] Ensure `--all` flag behavior includes Gemini-CLI in `scripts/bootstrap.sh:286-289`

---

## Phase 5: User Story 3 - Verification (P3)

- [x] T010 [US3] Add Gemini-CLI verification section in `verify_installation()` function in `scripts/bootstrap.sh:214-264`

---

## Phase 6: Polish

- [x] T011 Update banner/documentation comments at top of file in `scripts/bootstrap.sh:1-21`
- [x] T012 Test dry-run with `--gemini-cli` flag
- [x] T013 Test actual bootstrap to Gemini-CLI
- [x] T014 Test auto-detection includes Gemini-CLI
- [x] T015 Test `--all` bootstraps to all three tools

---

## Dependencies

```
T001, T002 (parallel) → T003, T004 (parallel) → T005 → T006 → T007 → T008, T009 → T010 → T011-T015
```

## Acceptance Criteria Mapping

| Task | Requirement | Acceptance Scenario |
|------|-------------|---------------------|
| T005-T007 | FR-001, FR-003, FR-004 | US1-AS1, US1-AS2, US1-AS3 |
| T008-T009 | FR-002, FR-005, FR-006 | US2-AS1, US2-AS2 |
| T010 | FR-007 | US3-AS1, US3-AS2 |
| T004 | FR-008 | Help documentation |
