---
description: Execute the complete Spec-Driven Development workflow autonomously from initial idea through implementation. This is a self-contained orchestrator that performs all SDD phases internally without calling other slash commands.
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
prereq_scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
analysis_scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
plan_scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

The text the user typed after `/do-the-thing` **is** their initial feature idea or goal.

---

# Agentic Spec-Driven Development

This command executes the **complete SDD workflow autonomously**. Each phase is performed internally. It performs each step automatically.

## Execution Model

Output format for phase transitions:

```
## Phase N: [Phase Name]
[Execute phase work directly]
```

After completing each phase, immediately begin the next phase. Pause only when human input is genuinely required (constitution creation, clarification questions).

---

## Phase Documentation

Each phase is documented in detail in separate files. The workflow uses **path resolution** to find files:

### Path Resolution Order

Phase and appendix markdown files are located in **global app-specific directories**:

1. **Global Opencode**: `~/.config/opencode/.do-the-thing/`
2. **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/`

> **Note**: The workflow will use the appropriate global location based on which app (Opencode or Antigravity) is executing the command.

### Phase Files

| Phase | Description | File |
|-------|-------------|------|
| **Phase 1** | Context Loading | `do-the-thing-phase-1.md` |
| **Phase 2** | Specification | `do-the-thing-phase-2.md` |
| **Phase 3** | Clarification | `do-the-thing-phase-3.md` |
| **Phase 4** | Planning | `do-the-thing-phase-4.md` |
| **Phase 5** | Task Generation | `do-the-thing-phase-5.md` |
| **Phase 6** | Analysis | `do-the-thing-phase-6.md` |
| **Phase 7** | Remediation | `do-the-thing-phase-7.md` |
| **Phase 8** | Implementation | `do-the-thing-phase-8.md` |
| **Phase 9** | Testing & Validation | `do-the-thing-phase-9.md` |

**Appendix**: `do-the-thing-appendix.md` - Contains Constitution Creation, Human Intervention Points, Script Reference, and Output Format Examples.

### Constitution Location

The constitution is located at `.specify/memory/constitution.md` relative to the `.do-the-thing/` directory in the global app-specific location:

- **Global Opencode**: `~/.config/opencode/.do-the-thing/.specify/memory/constitution.md`
- **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/.specify/memory/constitution.md`

---

## Phase Overview

### Phase 1: Context Loading
- Check GitHub repository existence
- Check for pending work (uncommitted changes, stashes, branches, PRs)
- Check constitution
- Determine feature context
- Check for unfinished work
- Validate user input
- Assess current state

**See**: `do-the-thing-phase-1.md` in the global `.do-the-thing/` directory

---

### Phase 2: Specification
- Generate branch name
- Create feature branch
- Load spec template
- Generate specification with user stories and requirements
- Write specification
- Create quality checklists

**See**: `do-the-thing-phase-2.md` in the global `.do-the-thing/` directory

---

### Phase 3: Clarification
- Load spec and identify `[NEEDS CLARIFICATION]` markers
- Perform ambiguity scan
- Generate prioritized questions (max 5)
- Ask questions sequentially
- Update spec with answers

**See**: `do-the-thing-phase-3.md` in the global `.do-the-thing/` directory

---

### Phase 4: Planning
- Setup and load context
- Fill technical context
- Constitution check
- Research unknowns
- Design data model and API contracts
- Update agent context
- Determine project structure

**See**: `do-the-thing-phase-4.md` in the global `.do-the-thing/` directory

---

### Phase 5: Task Generation
- Load design documents
- Extract information from spec, plan, data model, contracts
- Generate tasks organized by phase
- Validate task completeness

**See**: `do-the-thing-phase-5.md` in the global `.do-the-thing/` directory

---

### Phase 6: Analysis
- Load all artifacts
- Build semantic models
- Run detection passes (duplication, ambiguity, underspecification, constitution alignment, coverage gaps, inconsistency)
- Assign severity levels
- Produce analysis report

**See**: `do-the-thing-phase-6.md` in the global `.do-the-thing/` directory

---

### Phase 7: Remediation

- Process issues by severity
- Fix constitution violations, missing artifacts, ambiguous requirements, coverage gaps
- Re-run analysis
- Gate check until all CRITICAL/HIGH/MEDIUM issues resolved

**See**: `do-the-thing-phase-7.md` in the global `.do-the-thing/` directory

---

### Phase 8: Implementation

- Check checklists
- Load implementation context
- Project setup (ignore files)
- Execute tasks phase by phase
- Browser verification after each user story (for UI applications)
- Track progress
- Report completion

**See**: `do-the-thing-phase-8.md` in the global `.do-the-thing/` directory
a
---

### Phase 9: Testing & Validation

- Prepare test environment
- Execute test suites (unit, integration, contract, linting, security, E2E, visual, accessibility, cross-browser, performance)
- Perform interactive browser validation (live testing with real browser)
- Generate test report
- Evaluate results
- Remediate failures (max 3 cycles)
- Update constitution with new capabilities
- Final completion

**See**: `do-the-thing-phase-9.md` in the global `.do-the-thing/` directory

---

## Appendix Reference

For detailed information on:

- **Appendix A**: Constitution Creation
- **Appendix B**: Human Intervention Points
- **Appendix C**: Script Reference
- **Appendix D**: Output Format Examples

**See**: `do-the-thing-appendix.md` in the global `.do-the-thing/` directory
