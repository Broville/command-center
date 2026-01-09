# Phase 5: Task Generation

Output:
```
## Phase 5: Task Generation

Generating implementation tasks...
```

---

## 5.1 Setup

Run `{PREREQ_SCRIPT}` (with `--json` flags only, NOT `--require-tasks`) and parse FEATURE_DIR, AVAILABLE_DOCS.

**Note**: Tasks don't exist yet at this phase, so do not use `--require-tasks` flag.

---

## 5.2 Load Design Documents

Read from FEATURE_DIR:
- **Required**: plan.md, spec.md
- **Optional**: data-model.md, contracts/, research.md, quickstart.md

---

## 5.3 Extract Information

From spec.md:
- User stories with priorities (P1, P2, P3...)
- Functional requirements
- Edge cases

From plan.md:
- Tech stack and libraries
- Project structure
- Dependencies

From data-model.md (if exists):
- Entities and relationships

From contracts/ (if exists):
- API endpoints

---

## 5.4 Generate Tasks

Create `tasks.md` with this structure:

**Task Format**: `- [ ] [TaskID] [P?] [Story?] Description with file path`
- `[P]` = parallelizable
- `[Story]` = user story label (US1, US2, etc.)

**Phase 1: Setup** (shared infrastructure)
- Project structure creation
- Dependency initialization
- Linting/formatting configuration

**Phase 2: Foundational** (blocking prerequisites)
- Database schema
- Authentication framework
- API routing structure
- Base models
- Error handling
- Must complete before user stories

**Phase 3+: User Stories** (one phase per story, in priority order)
- Each story is independently testable
- Within each: Models → Services → Endpoints → Integration
- Include `[US#]` label on all tasks

**Final Phase: Polish**
- Cross-cutting concerns
- Documentation
- Performance optimization

---

## 5.5 Validate Tasks

Ensure:
- All tasks have checkbox, ID, and file path
- User story tasks have `[US#]` labels
- Dependencies are clear
- Each user story phase is independently testable

---

## 5.6 Write Tasks

Save completed tasks.md.

Proceed to Phase 6.
