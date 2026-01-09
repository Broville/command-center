# Appendix: Spec-Driven Development

This document contains appendix items referenced by the main workflow phases.

---

## Appendix A: Constitution Creation

When no constitution is found (checked in order: project-local `.do-the-thing/.specify/memory/constitution.md`, then global locations) and this is a new project:

### A.1 Gather Principles

Ask user:
```
No project constitution exists. I need to establish project principles.

What are the core principles for this project? (Examples: simplicity, security-first, test coverage requirements, tech stack constraints)

Provide 3-5 guiding principles, or say "default" for standard principles.
```

### A.2 Create Constitution

If user says "default", use:
- Simplicity over complexity
- Test before merge
- Security by default
- Documentation required

Otherwise, use user-provided principles.

### A.3 Write Constitution

Create constitution at `.do-the-thing/.specify/memory/constitution.md` (project-local):

```markdown
# Project Constitution

**Version**: 1.0.0
**Ratified**: [TODAY]
**Last Amended**: [TODAY]

## Principles

### Principle 1: [Name]
[Description of what this means and why it matters]
**Compliance**: [How to verify compliance]

### Principle 2: [Name]
...

## Governance

### Amendment Process
Changes to this constitution require explicit discussion and version increment.

### Compliance Review
All specs, plans, and implementations must pass constitution check gates.
```

### A.4 Proceed

After constitution created, return to Phase 1.3.

---

## Appendix B: Human Intervention Points

Human input is required ONLY in these situations:

1. **GitHub Repository Check** (§1.0): When repository does not exist and user must decide whether to create it or continue without remote
2. **Pending Work Resolution** (§1.1): When uncommitted changes, unpushed commits, stashes, open branches, or PRs exist
3. **Constitution Creation** (§Appendix A): When establishing project principles for a new project
4. **Clarification Questions** (§3.4): When spec has ambiguities requiring user decisions
5. **Empty Input** (§1.5): When no feature idea provided and no context to continue
6. **Checklist Override** (§8.1): When user must decide whether to proceed with incomplete checklists
7. **Ambiguity Resolution** (§7.1): When remediation requires clarification that cannot be inferred
8. **Test Failure Remediation Limit** (§9.5.5): When maximum remediation attempts (3) reached without resolving all test failures
9. **Browser Validation Failure** (§8.4.1, §9.2.11): When browser-based issues cannot be auto-remediated after multiple attempts (e.g., complex layout issues, third-party integration failures)

All other transitions execute autonomously.

**Note**: When `REMOTE_AVAILABLE=false`, the workflow continues but skips all remote operations (push, PR creation, remote branch deletion). This is tracked as a workflow state, not a human intervention point after the initial decision.

---

## Appendix C: Script Reference

This command uses the following scripts from the frontmatter:

| Script Key | Script | Flags | Used In |
|------------|--------|-------|--------|
| `{SCRIPT}` | `create-new-feature.sh` | `--json --number N --short-name "name"` | Phase 2.2 |
| `{PLAN_SCRIPT}` | `setup-plan.sh` | `--json` | Phase 4.1 |
| `{PREREQ_SCRIPT}` | `check-prerequisites.sh` | `--json` | Phase 5.1 |
| `{ANALYSIS_SCRIPT}` | `check-prerequisites.sh` | `--json --require-tasks --include-tasks` | Phase 6.1, 8.2 |
| `{AGENT_SCRIPT}` | `update-agent-context.sh` | `<agent_type>` | Phase 4.7 |

**Important**: The `check-prerequisites.sh` script is called with different flags depending on the phase:
- **Phase 5** (Task Generation): Use `--json` only (tasks don't exist yet)
- **Phase 6/8** (Analysis/Implementation): Use `--json --require-tasks --include-tasks`

---

## Appendix D: Output Format Examples

**Repository check - not found:**
```
## Phase 1: Context Loading

⚠️ **GitHub repository not found.**

| Detail | Value |
|--------|-------|
| Expected Repository | johndoe/my-project |
| Local Workspace | /home/johndoe/projects/my-project |
| Git Initialized | Yes |

The repository "my-project" does not exist on GitHub for user "johndoe".

Would you like me to create the repository on GitHub?

| Option | Action |
|--------|--------|
| Y | **Create Repository** - Create "johndoe/my-project" on GitHub (private by default) |
| P | **Create Public Repository** - Create as a public repository |
| N | **Continue Without Remote** - Proceed with local-only workflow (no push/PR operations) |

Reply with Y, P, or N.
```

**Repository created:**
```
✓ Repository created: https://github.com/johndoe/my-project
✓ Remote 'origin' configured.
```

**Continuing without remote:**
```
⚠️ Continuing without remote repository.

The following operations will be skipped during this workflow:
- git push (all push operations)
- Pull request creation
- Remote branch operations

All other local operations (commits, branches, specs, implementation) will proceed normally.
```

**Phase transition:**
```
## Phase 4: Planning

Generating implementation plan and design artifacts...
```

**Clarification question:**
```
The spec mentions "fast response times" without defining a threshold.

**Recommended:** Option B - Sub-500ms provides good UX without requiring aggressive optimization

| Option | Description |
|--------|-------------|
| A | Sub-100ms (aggressive) |
| B | Sub-500ms (balanced) |
| C | Sub-1s (relaxed) |

Reply with option letter, "yes" for recommended, or your own answer.
```

**After clarification answer:**
```
Updated spec with latency requirement: 500ms. Proceeding...
```

**Analysis finding:**
```
| ID | Category | Severity | Location | Summary | Recommendation |
|----|----------|----------|----------|---------|----------------|
| C1 | Coverage | HIGH | FR-003 | No task covers password reset | Add task in US2 phase |
```

**Task execution:**
```
### Phase 3: User Story 1 - User Authentication

- [X] T012 [US1] Create User model in src/models/user.py
- [X] T013 [US1] Implement AuthService in src/services/auth.py
- [ ] T014 [US1] Create login endpoint in src/api/auth.py
```

**Test results - all passing:**
```
## Phase 9: Testing & Validation

Running full application tests and validations...

✅ Unit Tests: 42/42 passed (98% coverage)
✅ Integration Tests: 12/12 passed
✅ Contract Tests: 8/8 passed
✅ E2E Tests: 18/18 passed
   - Buttons: 24/24 functional
   - Links: 15/15 navigating correctly
   - Forms: 8/8 submitting properly
✅ Visual Regression: 0 diffs detected
✅ Accessibility: WCAG 2.1 AA compliant (0 violations)
✅ Cross-Browser: All 6 browsers passing
✅ Performance: Lighthouse 92/100
   - LCP: 1.2s ✓
   - FID: 45ms ✓
   - CLS: 0.02 ✓
✅ Linting: 0 errors
✅ Security Scan: 0 vulnerabilities

Test report generated: tests/reports/001-user-auth-2025-11-27T14-30-00.md
```

**Test results - failures detected:**
```
❌ **Test failures detected. Initiating remediation...**

| ID | Category | Test/Check | Issue | Severity |
|----|----------|------------|-------|----------|
| TF-001 | Unit | test_user_login | AssertionError: expected 200, got 401 | HIGH |
| TF-002 | Integration | test_db_connection | ConnectionTimeout after 30s | CRITICAL |
| TF-003 | E2E | login_button_click | Button not responding to click | HIGH |
| TF-004 | Visual | login_page_desktop | 8% diff detected in header area | MEDIUM |
| TF-005 | Accessibility | form_labels | Missing label for email input | HIGH |
| TF-006 | Performance | LCP | 3.2s (target: <2.5s) | MEDIUM |
| TF-007 | Linting | src/auth.py:45 | Undefined variable 'user_id' | MEDIUM |

Updating spec with test failures...
Beginning remediation cycle 1/3...
```

**Test remediation success:**
```
Remediation complete. Re-running full test suite...

✅ All tests passing after remediation cycle 1.
Test report generated: tests/reports/001-user-auth-2025-11-27T14-35-00.md
```

**Browser verification during implementation:**
```
### Browser Verification: User Story 1

Starting containerized application...
$ ./scripts/build_test.sh
[1/5] Checking Podman installation... ✓
[2/5] Reading version... 1.2.0
[3/5] Cleaning up existing container... ✓
[4/5] Building container image... ✓
[5/5] Starting container... ✓

✓ Containers running: frontend, backend, database
✓ Application accessible at http://localhost:3000

**Visual Check:**
- [x] Page loads without console errors
- [x] New components render correctly
- [x] Screenshot captured: implementation_us1_check.webp

**Feature Smoke Test:**
- [x] Login form visible and styled correctly
- [x] Form validation triggers on invalid input
- [x] Submit button responds to click

**Responsive Check:**
- [x] Mobile viewport (375px): Layout adapts correctly
- [x] Desktop viewport: Layout correct

✅ Browser verification passed. Proceeding to next phase.
```

**Browser verification - issues found:**
```
### Browser Verification: User Story 2

**Container Status:**
$ podman-compose ps
✓ All containers healthy

**Visual Check:**
- [x] Page loads without console errors
- [!] Component rendering issue detected

**Issues Found:**
| Issue | Location | Description |
|-------|----------|-------------|
| BV-001 | Header | Logo not displaying (broken image path in container) |
| BV-002 | Navigation | Mobile menu not opening on tap |

Fixing issues before proceeding...
- [x] BV-001: Fixed image path in Header component
- [x] BV-002: Added touch event handler to mobile menu

Rebuilding containers...
$ ./scripts/build_test.sh
[3/5] Cleaning up existing container... ✓
[4/5] Building container image... ✓
[5/5] Starting container... ✓

Re-verifying...
✅ All issues resolved. Browser verification passed.
```

**Interactive browser validation (Phase 9):**
```
### 9.2.11 Interactive Browser Validation

**Container Environment:** Canary (via ./scripts/build_test.sh)
**Application URL:** http://localhost:3000
**Container Status:** All services running ✓

#### Viewport Testing:
| Viewport | Size | Layout | Navigation | Forms | Status |
|----------|------|--------|------------|-------|--------|
| Mobile | 375px | ✅ Correct | ✅ Works | ✅ Functional | PASS |
| Tablet | 768px | ✅ Correct | ✅ Works | ✅ Functional | PASS |
| Desktop | 1280px | ✅ Correct | ✅ Works | ✅ Functional | PASS |

#### Page Testing:
| Page | Load Time | Console Errors | Visual | Interactions | Status |
|------|-----------|----------------|--------|--------------|--------|
| / (Home) | 1.2s | 0 | ✅ | ✅ | PASS |
| /login | 0.8s | 0 | ✅ | ✅ | PASS |
| /dashboard | 1.5s | 0 | ✅ | ✅ | PASS |
| /settings | 0.9s | 0 | ✅ | ✅ | PASS |

#### User Flow Testing:
| Flow | Steps | Result | Recording |
|------|-------|--------|-----------|
| Login Flow | 5 | ✅ PASS | login_flow_demo.webp |
| Dashboard Navigation | 8 | ✅ PASS | dashboard_nav.webp |
| Form Submission | 4 | ✅ PASS | form_submit.webp |

#### Browser Validation Summary:
- Pages Tested: 4/4 ✅
- Viewports Tested: 3/3 ✅
- User Flows Validated: 3/3 ✅
- Console Errors: 0
- Recordings Created: 3

✅ Interactive Browser Validation: PASSED
```

**Spec completion (with remote):**
```
## Spec Complete ✅

**Feature**: 001-user-auth
**Branch**: 001-user-auth

### Implementation Summary
- Tasks completed: 24/24
- User stories implemented: US1, US2, US3
- Files created/modified: 18

### Test Summary
- Unit Tests: 42 passed
- Integration Tests: 12 passed
- E2E Tests: 18 passed (47 elements verified)
- Visual Regression: 0 diffs
- Accessibility: WCAG 2.1 AA compliant
- Cross-Browser: 6/6 browsers passing
- Performance: Lighthouse 92/100
- Code Coverage: 94%
- Security Issues: 0

### Reports Generated
- Test Report: tests/reports/001-user-auth-2025-11-27T14-35-00.md

### Constitution Updates
- Version: 1.0.0 → 1.1.0
- New capabilities documented: 3 (AuthService, UserModel, /api/auth endpoints)

### Next Steps
1. Review test report: tests/reports/001-user-auth-2025-11-27T14-35-00.md
2. Create pull request for branch: 001-user-auth
3. Request code review
4. Merge to main after approval
```

**Spec completion (without remote):**
```
## Spec Complete ✅

**Feature**: 001-user-auth
**Branch**: 001-user-auth

### Implementation Summary
- Tasks completed: 24/24
- User stories implemented: US1, US2, US3
- Files created/modified: 18

### Test Summary
- Unit Tests: 42 passed
- Integration Tests: 12 passed
- Code Coverage: 94%
- Security Issues: 0

### Reports Generated
- Test Report: tests/reports/001-user-auth-2025-11-27T14-35-00.md

### Constitution Updates
- Version: 1.0.0 → 1.1.0
- New capabilities documented: 3 (AuthService, UserModel, /api/auth endpoints)

### Next Steps
1. Review test report: tests/reports/001-user-auth-2025-11-27T14-35-00.md
2. ⚠️ No remote repository - changes are local only
3. To push changes later:
   - Create repository: `gh repo create my-project --private --source=. --remote=origin`
   - Push branch: `git push -u origin 001-user-auth`
   - Create PR: `gh pr create`
```
