# Phase 6: Analysis

Output:
```
## Phase 6: Analysis

Performing cross-artifact consistency analysis...
```

---

## 6.1 Load Artifacts

Run `{ANALYSIS_SCRIPT}` (with `--json --require-tasks --include-tasks` flags) and parse FEATURE_DIR, AVAILABLE_DOCS.

Read:
- FEATURE_DIR/spec.md
- FEATURE_DIR/plan.md
- FEATURE_DIR/tasks.md (REQUIRED - abort if missing)
- /memory/constitution.md (if exists)

---

## 6.2 Build Semantic Models

Create internal mappings:
- Requirements inventory (FR-001 → slug)
- User story inventory
- Task coverage mapping (task → requirement/story)
- Constitution rule set

---

## 6.3 Detection Passes

**A. Duplication Detection**
- Near-duplicate requirements
- Redundant tasks

**B. Ambiguity Detection**
- Vague adjectives without metrics (fast, scalable, secure)
- Unresolved placeholders (TODO, ???)

**C. Underspecification**
- Requirements missing measurable outcomes
- Tasks referencing undefined components

**D. Constitution Alignment**
- MUST principle violations → CRITICAL
- Missing mandated sections

**E. Coverage Gaps**
- Requirements with zero tasks
- Tasks with no mapped requirement

**F. Inconsistency**
- Terminology drift
- Conflicting requirements
- Task ordering contradictions

---

## 6.4 Assign Severity

- **CRITICAL**: Constitution MUST violation, missing core artifact, zero-coverage blocking requirement
- **HIGH**: Duplicate/conflicting requirement, untestable criterion, ambiguous security/performance
- **MEDIUM**: Terminology drift, missing non-functional coverage, underspecified edge case
- **LOW**: Style/wording, minor redundancy

---

## 6.5 Produce Analysis Report

Output (do not write to file):

```markdown
## Specification Analysis Report

| ID | Category | Severity | Location | Summary | Recommendation |
|----|----------|----------|----------|---------|----------------|
| A1 | [cat] | [sev] | [loc] | [summary] | [recommendation] |

**Coverage Summary:**
| Requirement | Has Task? | Task IDs |
|-------------|-----------|----------|

**Metrics:**
- Total Requirements: X
- Total Tasks: Y
- Coverage: Z%
- Critical Issues: N
```

---

## 6.6 Determine Next Phase

- If CRITICAL/HIGH/MEDIUM issues exist: Proceed to Phase 7 (Remediation)
- If only LOW or no issues: Proceed to Phase 8 (Implementation)
