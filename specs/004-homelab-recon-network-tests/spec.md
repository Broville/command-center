# Feature Specification: ICMP-Aware Homelab Network Recon

**Feature Branch**: `004-homelab-recon-network-tests`  \
**Created**: 2026-01-29  \
**Status**: Draft  \
**Input**: "Update the homelab-recon command. ICMP is not a viable option for some of the network testing. There needs to be an adjustment to scripts as well so that ICMP is only used where it actually works. As far as I know, all layers of the homelab is green. Run some quick tests and make adjustments to the scripts and homelab-recon to return proper results. Use multiple methods to determine the validity of the scripts."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Network Checks Don't Fail When ICMP Is Blocked (Priority: P1)

As a homelab operator, I want network checks used by `/homelab-recon` to use non-ICMP methods (TCP/HTTP/DNS) where ICMP is blocked, so that recon reports accurate GREEN/YELLOW/RED status.

**Independent Test**: Run the network scripts and confirm that an ICMP-blocking target (e.g., Unraid NAS) is checked via TCP/HTTP and does not falsely report unreachable.

**Acceptance Scenarios**:

1. **Given** a target that blocks ICMP but has expected TCP ports open, **When** the network check runs, **Then** it reports the target as reachable (GREEN) and does not mark the overall status RED solely due to ICMP failure.
2. **Given** a target that is truly unreachable (no ICMP and no TCP reachability), **When** the network check runs, **Then** it reports RED for that target and the overall status escalates appropriately.

### User Story 2 - NAS Checks Avoid ICMP By Default (Priority: P1)

As a homelab operator, I want NAS health checks to avoid ICMP by default, so that Unraid is validated using ports and HTTP without false negatives.

**Independent Test**: Run the NAS script and verify it does not call `ping` for reachability; reachability is established using TCP port checks and/or HTTP.

**Acceptance Scenarios**:

1. **Given** Unraid is up and SMB is reachable, **When** the NAS check runs, **Then** it reports GREEN reachability without ICMP.
2. **Given** Unraid is down, **When** the NAS check runs, **Then** it reports RED and aborts deeper checks.

### User Story 3 - Recon Command Documentation Matches Script Behavior (Priority: P2)

As a homelab operator, I want `/homelab-recon` documentation to reflect correct script exit codes and network-test guidance, so that automation and humans interpret results consistently.

**Independent Test**: Confirm the command doc states `0=GREEN, 1=YELLOW, 2=RED` for both `homelab-network-check.sh` and `homelab-nas-check.sh` and clearly indicates where ICMP is expected vs optional.

**Acceptance Scenarios**:

1. **Given** the docs are read, **When** an operator uses the scripts, **Then** the exit code meanings match the scripts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `homelab-network-check.sh` MUST support ICMP-blocking targets by using at least one non-ICMP reachability method (TCP connect and/or HTTP).
- **FR-002**: `homelab-network-check.sh` MUST only treat ICMP failure as a hard failure (RED) when ICMP is explicitly required for that target.
- **FR-003**: `homelab-nas-check.sh` MUST NOT use ICMP for reachability checks by default.
- **FR-004**: `network-test-pod.yaml` MUST avoid ICMP-only validation for targets known to block ICMP (at minimum, Unraid NAS).
- **FR-005**: `src/command_center/assets/commands/homelab-recon.md` MUST state correct exit codes for the scripts it recommends.

### Non-Functional Requirements

- **NFR-001**: Scripts MUST remain bash-compatible and should degrade gracefully if optional tools are missing.
- **NFR-002**: Status escalation MUST be deterministic (GREEN < YELLOW < RED).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: NAS reachability is determined via TCP/HTTP; ICMP is not required.
- **SC-002**: Network tests no longer produce false RED results due solely to ICMP being blocked.
- **SC-003**: Recon documentation matches script exit codes and guidance.
