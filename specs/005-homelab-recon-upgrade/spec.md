# Feature Specification: Homelab Recon Workflow Pillars + Script-First Upgrades

**Feature Branch**: `005-homelab-recon-upgrade`  \
**Created**: 2026-01-31  \
**Status**: Draft  \
**Input**: "Implement this plan to upgrade src/command_center/assets/commands/homelab-recon.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pillarized Recon Workflow With Consistent Layer Ordering (Priority: P1)

As a homelab operator, I want `/homelab-recon` to be structured around the 5-pillars workflow and use a single, consistent layer ordering, so that recon runs predictably and produces a maintenance issue that `/homelab-action` can execute without ambiguity.

**Independent Test**: Read the command doc and confirm it contains a 5-pillar overview mapping to existing phases, and that every ordering rule references the same layer order.

**Acceptance Scenarios**:

1. **Given** I follow `/homelab-recon`, **When** I reach planning and task ordering rules, **Then** the layer order is consistent everywhere (e.g., Metal → Network → Storage → System → Platform → Apps).
2. **Given** I follow `/homelab-recon`, **When** I scan the document structure, **Then** it clearly communicates a 5-pillar flow (Validation → Context → Synthesis → Audit → Handoff).

---

### User Story 2 - Script-First Evidence Capture With Context Pack Artifacts (Priority: P1)

As a homelab operator, I want `/homelab-recon` to enforce script-first evidence capture into a standard on-disk context pack, so that recon results are reproducible, reviewable, and can be re-used during remediation/audit without re-running commands.

**Independent Test**: Confirm the doc instructs saving evidence to a predictable directory structure and prefers script outputs (including JSON where available).

**Acceptance Scenarios**:

1. **Given** a recon run is executed, **When** evidence capture completes, **Then** all evidence is persisted to disk in a standard location (context pack) and referenced from the status report.
2. **Given** a script is available for a check, **When** recon is executed, **Then** the doc instructs using the script (and JSON output where available) rather than manual command sequences.

---

### User Story 3 - Dynamic Task Tracking For Stateless, Long Recon Runs (Priority: P2)

As a homelab operator, I want `/homelab-recon` to initialize and maintain an explicit `recon-tasks.md` checklist during execution, so that an agent (or human) can resume work safely without losing progress.

**Independent Test**: Confirm the doc includes a task-tracking initialization step and references a reusable template shipped with the project.

**Acceptance Scenarios**:

1. **Given** recon starts, **When** the first validation step begins, **Then** `recon-tasks.md` is created from a template and used as the canonical progress tracker.
2. **Given** recon completes, **When** handoff is reached, **Then** the final status report includes (or links) the task checklist as an execution log.

---

### User Story 4 - Documentation Contract Correctness (Priority: P2)

As a homelab operator, I want `/homelab-recon` to be internally consistent and markdown-valid, so that it renders reliably and does not mislead execution (e.g., broken code fences or missing API calls).

**Independent Test**: Run markdown linting (or repo doc checks) and verify no obvious formatting errors exist; verify the Dependency Dashboard instructions include an explicit command to fetch the body.

**Acceptance Scenarios**:

1. **Given** I read the repo evidence section, **When** I follow the Dependency Dashboard instructions, **Then** I have a concrete command to fetch the issue body and extract unchecked tasks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `src/command_center/assets/commands/homelab-recon.md` MUST include a 5-pillar overview and map pillars to its existing phase/subphase steps.
- **FR-002**: `src/command_center/assets/commands/homelab-recon.md` MUST define and use one consistent layer ordering across planning, checklists, and gates.
- **FR-003**: `src/command_center/assets/commands/homelab-recon.md` MUST formalize a "Script-First" rule and provide a standard evidence directory layout (context pack).
- **FR-004**: `src/command_center/assets/commands/homelab-recon.md` MUST instruct creating and updating a `recon-tasks.md` checklist during execution.
- **FR-005**: The repository MUST include a recon task template file for bootstrapping `recon-tasks.md`.
- **FR-006**: `src/command_center/assets/commands/homelab-recon.md` MUST include an explicit command sequence to fetch the Dependency Dashboard issue body for task extraction.

### Non-Functional Requirements

- **NFR-001**: The upgraded doc MUST remain compatible with existing "maintenance issue contract" requirements (top-level atomic checkboxes, required sections).
- **NFR-002**: The upgraded doc MUST remain readable for humans while optimizing for agentic execution (clear gates, deterministic ordering, minimal ambiguity).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The doc contains a 5-pillar overview and consistent layer ordering everywhere it appears.
- **SC-002**: The doc specifies a standard context pack directory and consistently instructs saving evidence to disk.
- **SC-003**: The doc includes `recon-tasks.md` initialization and a shipped template file exists in the repo.
- **SC-004**: No obvious markdown formatting errors exist in the updated sections (e.g., no dangling code fences).
