# Implementation Tasks: Homelab Recon Workflow Pillars + Script-First Upgrades

**Feature Branch**: `005-homelab-recon-upgrade`  \
**Created**: 2026-01-31  \
**Spec**: [spec.md](./spec.md)  \
**Plan**: [plan.md](./plan.md)

## Task Legend
- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- `[US#]` = User Story reference

---

## Phase 1: Discovery

- [x] T001 [P] [US1] Inventory gaps between `recon-workflow.md` and `src/command_center/assets/commands/homelab-recon.md`
- [x] T002 [US1] Identify and resolve ordering/structure inconsistencies in `src/command_center/assets/commands/homelab-recon.md`

---

## Phase 2: Assets

- [x] T003 [US3] Add a shipped template for `recon-tasks.md` initialization

---

## Phase 3: Documentation

- [x] T004 [US1] Add 5-pillar overview + mapping to `src/command_center/assets/commands/homelab-recon.md`
- [x] T005 [US2] Add Script-First rule + standard context pack directory guidance to `src/command_center/assets/commands/homelab-recon.md`
- [x] T006 [US3] Add dynamic `recon-tasks.md` tracking guidance to `src/command_center/assets/commands/homelab-recon.md`
- [x] T007 [US4] Fix formatting/correctness issues (e.g., dangling code fences; Dependency Dashboard body capture command)

---

## Phase 4: Testing & Validation

- [x] T008 Run repo tests/lint (best-effort); confirm modified markdown renders (no obvious formatting errors)

---

## Dependencies

```
T001 → T002 → (T003 in parallel with T004/T005/T006/T007) → T008
```
