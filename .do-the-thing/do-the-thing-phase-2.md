# Phase 2: Specification

Output:
```
## Phase 2: Specification

Creating feature specification...
```

---

## 2.1 Generate Branch Name

From `$ARGUMENTS`, generate a concise short name (2-4 words):
- Use action-noun format (e.g., "user-auth", "fix-payment-timeout")
- Preserve technical terms and acronyms

---

## 2.2 Create Feature Branch

1. Fetch remote branches: `git fetch --all --prune`
2. Find highest feature number across:
   - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
   - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
   - Specs directories: `specs/[0-9]+-<short-name>`
3. Use N+1 for new feature number
4. Run `{SCRIPT}` with `--number N+1 --short-name "<short-name>" "<feature description>"`
5. Parse JSON output for BRANCH_NAME, SPEC_FILE, FEATURE_DIR

---

## 2.3 Load Spec Template

Read `templates/spec-template.md` for required structure.

---

## 2.4 Generate Specification

Parse `$ARGUMENTS` and extract:
- Actors (who uses this)
- Actions (what they do)
- Data (what's involved)
- Constraints (limitations)

Fill spec template with:

**User Scenarios & Testing** (mandatory):
- Create prioritized user stories (P1, P2, P3...)
- Each story must be independently testable
- Include acceptance scenarios in Given/When/Then format

**Requirements** (mandatory):
- Functional requirements (FR-001, FR-002...) - each must be testable
- Key entities if data is involved

**Success Criteria** (mandatory):
- Measurable, technology-agnostic outcomes
- No implementation details

For unclear aspects:
- Make informed guesses based on context and industry standards
- Mark with `[NEEDS CLARIFICATION: specific question]` only if:
  - Choice significantly impacts scope or UX
  - Multiple reasonable interpretations exist
  - No reasonable default exists
- **Maximum 3 `[NEEDS CLARIFICATION]` markers**

---

## 2.5 Write Specification

Write the completed spec to SPEC_FILE.

---

## 2.6 Create Quality Checklist

Generate `FEATURE_DIR/checklists/requirements.md`:

```markdown
# Specification Quality Checklist: [FEATURE NAME]

**Purpose**: Validate specification completeness before planning
**Created**: [DATE]

## Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] All mandatory sections completed

## Requirement Completeness
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable and technology-agnostic
- [ ] All acceptance scenarios defined
- [ ] Edge cases identified
- [ ] Scope clearly bounded

## Feature Readiness
- [ ] All functional requirements have clear acceptance criteria
- [ ] User scenarios cover primary flows
- [ ] Feature meets measurable outcomes defined in Success Criteria
- [ ] No implementation details leak into specification
```

---

## 2.6.1 Domain-Specific Checklists (Optional)

If the spec involves specific domains, generate additional checklists as "unit tests for requirements":

**Checklist Principle**: Test the REQUIREMENTS quality, not implementation behavior.
- ✅ "Are [requirement type] defined/specified/documented for [scenario]?"
- ✅ "Is [vague term] quantified/clarified with specific criteria?"
- ❌ NOT "Verify the button clicks correctly" (implementation test)

**Domain Detection** - Create checklists based on spec content:
- If UX/UI requirements present → `checklists/ux.md`
- If API/integration requirements → `checklists/api.md`
- If security/auth requirements → `checklists/security.md`
- If performance requirements → `checklists/performance.md`

**Checklist Item Format**:
```markdown
- [ ] CHK### - [Question about requirement quality] [Dimension, Spec §X.Y]
```

Dimensions: `[Completeness]`, `[Clarity]`, `[Consistency]`, `[Measurability]`, `[Coverage]`, `[Gap]`, `[Ambiguity]`

---

## 2.7 Validate and Proceed

- If spec has `[NEEDS CLARIFICATION]` markers: Proceed to Phase 3
- If spec is complete: Proceed to Phase 4
