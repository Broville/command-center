# Implementation Tasks: ICMP-Aware Homelab Network Recon

**Feature Branch**: `004-homelab-recon-network-tests`  \
**Created**: 2026-01-29  \
**Spec**: [spec.md](./spec.md)  \
**Plan**: [plan.md](./plan.md)

## Task Legend
- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- `[US#]` = User Story reference

---

## Phase 1: Setup

- [x] T001 [P] Inventory ICMP usage in scripts (`src/command_center/assets/scripts/*.sh`, `src/command_center/assets/scripts/*.yaml`)

---

## Phase 2: Foundational

- [x] T002 [US1] Make `src/command_center/assets/scripts/homelab-network-check.sh` ICMP-aware (fallback to TCP/HTTP where needed)
- [x] T003 [US2] Remove ICMP reachability dependency from `src/command_center/assets/scripts/homelab-nas-check.sh`
- [x] T004 [US1] Update `src/command_center/assets/scripts/network-test-pod.yaml` to avoid ICMP-only checks for NAS

---

## Phase 3: Documentation

- [x] T005 [US3] Fix script exit-code documentation + ICMP guidance in `src/command_center/assets/commands/homelab-recon.md`

---

## Phase 4: Testing & Validation

- [x] T006 Run static checks: `bash -n` on modified scripts (and `shellcheck` if available)
- [x] T007 Run smoke checks: execute scripts with `--json` (best-effort) and confirm exit-code mapping

---

## Dependencies

```
T001 → (T002, T003, T004 in parallel) → T005 → (T006, T007)
```
