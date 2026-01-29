# Implementation Plan: ICMP-Aware Homelab Network Recon

**Feature Branch**: `004-homelab-recon-network-tests`  \
**Created**: 2026-01-29  \
**Spec**: [spec.md](./spec.md)

## Technical Context

| Aspect | Value |
|--------|-------|
| Language/Version | Bash + YAML + Markdown |
| Primary Dependencies | Standard Unix tools (`bash`, `curl`, `timeout`); optional (`smbclient`, `showmount`) |
| Storage | N/A |
| Testing Framework | Static checks (`bash -n`, optional `shellcheck`) + smoke runs (`--json`) |
| Target Platform | Linux/macOS; in-cluster BusyBox for `network-test-pod.yaml` |
| Project Type | CLI workflow + shell script maintenance |
| Performance Goals | Fast checks; avoid long blocking timeouts |
| Constraints | ICMP not universally available; scripts must remain useful without optional tools |
| Scale/Scope | Update existing scripts + documentation; no behavior changes outside reachability semantics |

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-First Development | Compliant | Spec created before implementation |
| II. Test-Driven Quality | Compliant | Acceptance scenarios + validation plan included |
| III. Constitution Alignment | Compliant | No phase skipped |
| IV. Iterative Refinement | Compliant | Small, staged changes |
| V. Documentation as Code | Compliant | Update docs alongside scripts |

## Implementation Phases

### Phase 0: Research

- Confirm which targets are known to block ICMP (baseline: Unraid NAS).
- Identify any doc/script mismatches (exit codes, guidance).

### Phase 1: Design

- Define reachability policy per target type:
  - **ICMP optional**: try ping for latency, but fall back to TCP/HTTP.
  - **ICMP disabled** (known blockers): skip ping; use TCP/HTTP.
- Ensure status semantics remain deterministic.

### Phase 2: Implementation

- Update `src/command_center/assets/scripts/homelab-network-check.sh` to avoid ICMP-only failures.
- Update `src/command_center/assets/scripts/homelab-nas-check.sh` to avoid ICMP reachability.
- Update `src/command_center/assets/scripts/network-test-pod.yaml` to avoid ICMP-only NAS validation.
- Update `src/command_center/assets/commands/homelab-recon.md` to correct exit codes and guidance.

### Phase 3: Validation

- Static: `bash -n` on modified scripts; optional `shellcheck` if present.
- Behavior: run scripts with `--json` locally (best-effort) and confirm expected exit-code mapping.

## Project Structure

No structural changes.

## Complexity Tracking

| Item | Complexity | Risk | Notes |
|------|------------|------|-------|
| Adjust reachability logic | Medium | Medium | Risk of changing status semantics; keep deterministic escalation |
| Update docs | Low | Low | Must match script exit codes |
| Update in-cluster test pod | Low | Low | BusyBox tool availability constraints |
