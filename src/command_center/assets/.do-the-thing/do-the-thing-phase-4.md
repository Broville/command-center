# Phase 4: Planning

Output:
```
## Phase 4: Planning

Generating implementation plan and design artifacts...
```

---

## 4.1 Setup

Run `{PLAN_SCRIPT}` and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH.

---

## 4.2 Load Context

- Read FEATURE_SPEC
- Read `/memory/constitution.md` (if exists)
- Load plan template structure

---

## 4.3 Fill Technical Context

In plan.md, fill:
- Language/Version
- Primary Dependencies
- Storage
- Testing framework
- Target Platform
- Project Type
- Performance Goals
- Constraints
- Scale/Scope

Mark unknowns as `NEEDS CLARIFICATION` for research.

---

## 4.4 Constitution Check

If constitution exists, evaluate all principles against the planned approach:
- List each principle
- Mark compliance status
- If violations exist, document justification in Complexity Tracking table

---

## 4.5 Phase 0: Research

For each `NEEDS CLARIFICATION` in Technical Context:
1. Research the unknown
2. Document in `research.md`:
   ```markdown
   ## [Topic]
   **Decision**: [what was chosen]
   **Rationale**: [why chosen]
   **Alternatives Considered**: [what else evaluated]
   ```

Output: `research.md` with all technical unknowns resolved.

---

## 4.6 Phase 1: Design & Contracts

**Data Model** (`data-model.md`):
- Extract entities from spec
- Define fields, relationships, validation rules
- Document state transitions if applicable

**API Contracts** (`contracts/`):
- For each user action → endpoint
- Generate OpenAPI/GraphQL schemas
- Use standard REST patterns

**Quickstart** (`quickstart.md`):
- Integration scenarios
- Test data setup
- Development workflow

---

## 4.7 Update Agent Context

Run `{AGENT_SCRIPT}` to update agent-specific context files with new technology from this plan.

---

## 4.8 Determine Project Structure

Based on project type, select structure:

**Single project** (default):
```
src/
├── models/
├── services/
├── cli/
└── lib/
tests/
├── contract/
├── integration/
└── unit/
```

**Web application** (frontend + backend):
```
backend/
├── src/
└── tests/
frontend/
├── src/
└── tests/
```

**Mobile + API**:
```
api/
└── src/
ios/ or android/
└── [platform structure]
```

Document selected structure in plan.md.

---

## 4.9 Write Plan

Save completed plan.md with all sections filled.

Proceed to Phase 5.
