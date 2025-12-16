# Implementation Tasks: Gemini-CLI TOML Command Format

**Feature Branch**: `2-gemini-cli-toml-format`  
**Created**: 2025-12-16  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)

## Task Legend
- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- `[US#]` = User Story reference

---

## Phase 1: Setup

- [x] T001 [P] Define TOML file extension constant in `scripts/bootstrap.sh`

---

## Phase 2: Core Functions

- [x] T002 [US1] Add `convert_md_to_toml()` function in `scripts/bootstrap.sh`
  - Extract description from YAML frontmatter
  - Extract body content (after frontmatter)
  - Write TOML format with description and prompt fields
  - Use triple single-quotes for multi-line prompt content

- [x] T003 [US1] Add `cleanup_old_gemini_md_files()` function in `scripts/bootstrap.sh`
  - Remove existing `.md` command files from `~/.gemini/commands/`
  - Only run during Gemini-CLI bootstrap

---

## Phase 3: User Story 1 - Bootstrap Creates TOML Commands (P1)

- [x] T004 [US1] Update `bootstrap_to_gemini_cli()` to use TOML conversion
  - Replace direct file copy with `convert_md_to_toml()` calls
  - Generate `do-the-thing.toml`, `commit.toml`, `init.toml`
  - Call `cleanup_old_gemini_md_files()` before creating new files

---

## Phase 4: User Story 3 - Verification (P3)

- [x] T005 [US3] Update `verify_installation()` to check for `.toml` files for Gemini-CLI
  - Change file extension check from `.md` to `.toml` for Gemini-CLI section
  - Keep `.md` extension for Opencode and Antigravity sections

---

## Phase 5: Polish

- [x] T006 Update help text and banner comments to reflect TOML format for Gemini-CLI
- [x] T007 Test dry-run with `--gemini-cli` flag
- [x] T008 Test actual bootstrap to Gemini-CLI creates TOML files
- [x] T009 Test old .md files are cleaned up
- [x] T010 Test verification correctly checks TOML files
- [x] T011 Test Opencode/Antigravity still receive .md files (regression test)

---

## Dependencies

```
T001 → T002, T003 (parallel) → T004 → T005 → T006-T011
```

## Acceptance Criteria Mapping

| Task | Requirement | Acceptance Scenario |
|------|-------------|---------------------|
| T002 | FR-002, FR-003, FR-004 | US1-AS2, US2-AS1 |
| T003 | FR-005 | US1-AS3 |
| T004 | FR-001, FR-008 | US1-AS1 |
| T005 | FR-006 | US3-AS1, US3-AS2 |
| T006 | Documentation | Help text accuracy |
