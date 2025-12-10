# Phase 3: Clarification

Output:
```
## Phase 3: Clarification

Resolving specification ambiguities...
```

---

## 3.1 Load Spec

Read FEATURE_SPEC and identify all `[NEEDS CLARIFICATION: ...]` markers.

---

## 3.2 Perform Ambiguity Scan

Scan spec for these categories (mark each as Clear/Partial/Missing):

- Functional Scope & Behavior
- Domain & Data Model
- Interaction & UX Flow
- Non-Functional Quality Attributes
- Integration & External Dependencies
- Edge Cases & Failure Handling
- Constraints & Tradeoffs

---

## 3.3 Generate Questions

Create prioritized queue of clarification questions (maximum 5 total).

Each question must be answerable with:
- Multiple-choice (2-5 options), OR
- Short answer (≤5 words)

Only include questions that materially impact architecture, data modeling, or test design.

---

## 3.4 Ask Questions Sequentially

For each question, present ONE at a time:

**For multiple-choice:**
```
**Recommended:** Option [X] - [reasoning]

| Option | Description |
|--------|-------------|
| A | [description] |
| B | [description] |
| C | [description] |

Reply with the option letter, "yes" to accept recommendation, or your own short answer.
```

**For short-answer:**
```
**Suggested:** [proposed answer] - [reasoning]

Format: Short answer (≤5 words). Say "yes" to accept or provide your own.
```

After each answer:
- Record the answer
- Update the spec immediately:
  - Add to `## Clarifications` section
  - Update relevant requirement/story with the clarified detail
  - Remove the `[NEEDS CLARIFICATION]` marker
- Save the spec file
- Present next question

Stop when:
- All questions answered, OR
- User signals "done"/"proceed", OR
- 5 questions reached

---

## 3.5 Proceed to Planning

After clarifications complete:
```
Clarifications resolved. Proceeding to planning...
```

Proceed to Phase 4.
