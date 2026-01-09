# Phase 7: Remediation

> **Appendix Reference**: For Human Intervention Points, see [do-the-thing-appendix.md](./do-the-thing-appendix.md#appendix-b-human-intervention-points).

Output:
```
## Phase 7: Remediation

Resolving analysis issues...
```

---

## 7.1 Process Issues by Severity

For each issue (CRITICAL → HIGH → MEDIUM → LOW):

**Constitution violation:**
- Edit the violating artifact to comply
- Or document justified exception in Complexity Tracking

**Missing artifact:**
- Return to appropriate phase to create it

**Ambiguous requirement:**
- If clarification needed from user, ask specific question
- Otherwise, add measurable criteria based on industry standards

**Coverage gap:**
- Add missing tasks to tasks.md
- Or add missing requirements to spec.md

**Terminology drift:**
- Standardize term usage across all artifacts

**Duplicate/conflicting requirements:**
- Consolidate or resolve conflict
- Update all affected artifacts

---

## 7.2 Re-run Analysis

After all remediations:
```
Re-running analysis...
```

Return to Phase 6 (§6.3 onwards).

---

## 7.3 Gate Check

Repeat remediation cycle until:
- CRITICAL = 0
- HIGH = 0
- MEDIUM = 0

Then proceed to Phase 8.
