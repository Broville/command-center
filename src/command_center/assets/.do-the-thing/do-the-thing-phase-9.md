# Phase 9: Testing & Validation

> **Appendix Reference**: For Human Intervention Points and Output Examples, see [do-the-thing-appendix.md](./do-the-thing-appendix.md).

Output:
```
## Phase 9: Testing & Validation

Running full application tests and validations...
```

---

## 9.1 Prepare Test Environment

Ensure test infrastructure is ready:

1. **Verify test framework** is installed per plan.md specifications
2. **Create test directory structure** if not exists:
   ```
   tests/
   ├── unit/
   ├── integration/
   ├── contract/
   ├── e2e/
   ├── visual/
   │   └── snapshots/
   ├── accessibility/
   └── performance/
   ```
3. **Create reports directory**:
   ```
   tests/reports/
   ```
4. **Install UI testing dependencies** (if UI application detected):
   - Playwright or Cypress for E2E
   - axe-core for accessibility
   - Lighthouse for performance

---

## 9.2 Execute Test Suites

Run all test categories in order:

### 9.2.1 Unit Tests
```bash
# Run unit tests with coverage (adjust command per tech stack)
# Python: pytest tests/unit/ --cov --cov-report=json
# Node.js: npm test -- --coverage --json
# Go: go test ./... -coverprofile=coverage.out -json
```

Capture:
- Total tests run
- Tests passed
- Tests failed
- Tests skipped
- Code coverage percentage

### 9.2.2 Integration Tests
```bash
# Run integration tests
# Python: pytest tests/integration/ -v
# Node.js: npm run test:integration
```

Capture:
- Service integration status
- API endpoint validations
- Database operations

### 9.2.3 Contract Tests (if contracts/ exists)
```bash
# Validate API contracts
# Check OpenAPI/GraphQL schemas against implementation
```

Capture:
- Contract compliance status
- Schema validation results

### 9.2.4 Linting & Static Analysis
```bash
# Run linters per tech stack
# Python: ruff check . && mypy .
# Node.js: eslint . && tsc --noEmit
# Go: golangci-lint run
```

Capture:
- Linting errors
- Type errors
- Code quality issues

### 9.2.5 Security Scan (if applicable)
```bash
# Run security checks
# Python: bandit -r src/
# Node.js: npm audit
# General: trivy fs .
```

Capture:
- Vulnerabilities found
- Severity levels

### 9.2.6 End-to-End (E2E) Tests (if UI/web application)

Detect if application has UI components (check for: React, Vue, Angular, Svelte, HTML templates, etc.)

```bash
# Run E2E tests with Playwright or Cypress
# Playwright: npx playwright test
# Cypress: npx cypress run
```

**Test all interactive elements:**
- Buttons: Click handlers, disabled states, loading states
- Links: Navigation, external links open correctly, anchor links
- Forms: Input validation, submission, error states, success feedback
- Modals/Dialogs: Open/close, focus trapping, escape key handling
- Dropdowns/Selects: Option selection, keyboard navigation
- Checkboxes/Radios: Toggle states, group behavior
- Tabs: Switching, keyboard navigation, active states
- Accordions: Expand/collapse, animation completion
- Tooltips: Hover triggers, positioning, content
- Navigation: Menu items, active states, responsive behavior

Capture:
- Elements tested
- Interaction success/failure
- Navigation flow completion

### 9.2.7 Visual Regression Testing (if UI application)

```bash
# Capture and compare screenshots
# Playwright: npx playwright test --update-snapshots (first run)
# Playwright: npx playwright test (subsequent runs compare)
# Percy: npx percy exec -- [test command]
# Chromatic: npx chromatic --project-token=xxx
```

**Visual checks:**
- Layout alignment and spacing
- Typography (font sizes, weights, line heights)
- Color consistency (brand colors, contrast ratios)
- Responsive breakpoints (mobile, tablet, desktop)
- Component visual states (hover, focus, active, disabled)
- Icon alignment and sizing
- Image aspect ratios and positioning
- Border radii and shadows
- Animation/transition smoothness

Capture:
- Screenshots per viewport size
- Visual diff percentage
- Changed regions highlighted

### 9.2.8 Accessibility (a11y) Testing (if UI application)

```bash
# Run accessibility audits
# axe-core: npx axe [url] or integrated in Playwright/Cypress
# pa11y: npx pa11y [url]
# Lighthouse: npx lighthouse [url] --only-categories=accessibility
```

**Accessibility checks:**
- WCAG 2.1 AA compliance
- Keyboard navigation (all interactive elements reachable)
- Focus indicators visible
- Screen reader compatibility (ARIA labels, roles, live regions)
- Color contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Alt text for images
- Form labels and error announcements
- Heading hierarchy (h1 → h2 → h3, no skips)
- Skip links present
- Touch target sizes (minimum 44x44px)

Capture:
- WCAG violations by level (A, AA, AAA)
- Elements with issues
- Remediation suggestions

### 9.2.9 Cross-Browser Testing (if UI application)

```bash
# Run tests across browsers
# Playwright: npx playwright test --project=chromium --project=firefox --project=webkit
# BrowserStack/Sauce Labs for extended browser matrix
```

**Browser matrix:**
| Browser | Versions | Status |
|---------|----------|--------|
| Chrome | Latest, Latest-1 | ✅/❌ |
| Firefox | Latest, Latest-1 | ✅/❌ |
| Safari | Latest, Latest-1 | ✅/❌ |
| Edge | Latest | ✅/❌ |
| Mobile Safari | iOS Latest | ✅/❌ |
| Chrome Mobile | Android Latest | ✅/❌ |

Capture:
- Pass/fail per browser
- Browser-specific issues
- Rendering differences

### 9.2.10 Performance Testing (if UI/API application)

```bash
# Lighthouse performance audit
# npx lighthouse [url] --only-categories=performance --output=json

# API load testing
# k6: k6 run loadtest.js
# Artillery: npx artillery run loadtest.yml
```

**UI Performance metrics:**
- First Contentful Paint (FCP) < 1.8s
- Largest Contentful Paint (LCP) < 2.5s
- First Input Delay (FID) < 100ms
- Cumulative Layout Shift (CLS) < 0.1
- Time to Interactive (TTI) < 3.8s
- Total Blocking Time (TBT) < 200ms

**API Performance metrics:**
- Response time p50, p95, p99
- Requests per second
- Error rate under load
- Memory/CPU utilization

Capture:
- Core Web Vitals scores
- Performance bottlenecks
- Optimization recommendations

### 9.2.11 Interactive Browser Validation (if UI application)

Use the browser tool to perform live, interactive validation of the running application in a containerized environment. This supplements automated E2E tests with real-world browser interaction against a production-like deployment.

**Prerequisites:**
1. **Build and start containers** using existing or project-specific scripts to mimic canary/production:
   ```bash
   # Use existing build/test script if available
   ./scripts/build_test.sh
   
   # Or if no script exists, create one that:
   # - Checks container runtime (Podman/Docker) is installed
   # - Reads version from VERSION file
   # - Cleans up any existing test containers
   # - Builds container image with <version>-canary tag
   # - Starts the containerized application via compose
   ```
   
   **Script Requirements (if creating new):**
   - Located in `scripts/` directory (e.g., `scripts/build_test.sh`)
   - Handles cleanup of existing containers
   - Builds with canary tag for testing
   - Starts all required services (frontend, backend, database)
   - Outputs accessible URL upon success
   - Provides helpful error messages on failure

2. **Verify containerized application** is accessible at the expected URL (e.g., `http://localhost:3000`)
3. **Check container health/logs** for startup errors:
   ```bash
   podman-compose logs --tail=50
   podman-compose ps
   ```
4. Prepare test scenarios based on implemented features

**Why Containerized Testing:**
- Mimics canary and production deployment environments
- Catches container-specific issues (environment variables, networking, volumes)
- Validates the complete application stack (frontend, backend, database)
- Ensures Docker/Podman build process works correctly
- Uses same build artifacts that will be deployed

**Browser Validation Steps:**

1. **Launch and Navigate**:
   - Use `browser_subagent` to navigate to the application URL
   - Verify the page loads without console errors
   - Capture initial screenshot for documentation

2. **Visual Inspection**:
   - Verify layout matches design specifications
   - Check responsive behavior at multiple viewport sizes (mobile: 375px, tablet: 768px, desktop: 1280px)
   - Confirm visual consistency across breakpoints
   - Capture screenshots at each viewport size

3. **Interactive Testing**:
   - Click all buttons and verify expected behavior
   - Navigate through all routes/pages
   - Fill and submit forms, verify validation and success states
   - Test modals, dropdowns, and interactive components
   - Verify keyboard navigation works correctly
   - Test any drag-and-drop or touch interactions

4. **Edge Cases**:
   - Test error states (invalid inputs, network failures)
   - Test empty states (no data scenarios)
   - Test loading states
   - Verify error messages are visible and helpful

5. **Cross-Feature Validation**:
   - Test user flows that span multiple features
   - Verify data persists correctly across navigation
   - Test authentication flows if applicable

**Recording Output:**
- Create recordings for key user flows using `browser_subagent` with descriptive `RecordingName`
- Store recordings as WebP videos for documentation
- Capture final state screenshots

**Capture:**
- Screenshots of each page/state tested
- Browser recordings of key user flows
- Console errors or warnings observed
- Interaction success/failure log
- Responsive design compliance

**Validation Criteria:**
| Check | Pass Criteria |
|-------|---------------|
| Page Load | No console errors, content visible within 3s |
| Navigation | All routes accessible, correct content displayed |
| Forms | Validation works, submission succeeds, feedback shown |
| Responsive | Layout correct at mobile, tablet, desktop |
| Interactions | All clickable elements respond correctly |
| State Management | Data persists correctly across navigation |

---

## 9.3 Generate Test Report

Create `tests/reports/[FEATURE_NUMBER]-[SHORT_NAME]-[TIMESTAMP].md`:

```markdown
# Test Report: [FEATURE NAME]

**Feature**: [NUMBER]-[SHORT_NAME]
**Branch**: [BRANCH_NAME]
**Generated**: [TIMESTAMP]
**Status**: ✅ PASSED / ❌ FAILED

---

## Summary

| Category | Total | Passed | Failed | Skipped | Status |
|----------|-------|--------|--------|---------|--------|
| Unit Tests | X | X | X | X | ✅/❌ |
| Integration Tests | X | X | X | X | ✅/❌ |
| Contract Tests | X | X | X | X | ✅/❌ |
| E2E Tests | X | X | X | X | ✅/❌ |
| Visual Regression | X | X | X | X | ✅/❌ |
| Accessibility | X | X | X | X | ✅/❌ |
| Cross-Browser | X | X | X | X | ✅/❌ |
| Performance | X | X | X | X | ✅/❌ |
| Linting | X | X | X | - | ✅/❌ |
| Security | X | X | X | - | ✅/❌ |

**Overall Coverage**: X%
**Total Issues**: X

---

## Detailed Results

[Include detailed tables for each test category as shown in appendix output examples]

---

## Coverage Report

| Module/File | Lines | Covered | Percentage |
|-------------|-------|---------|------------|
| [module] | X | X | X% |
...

**Total Coverage**: X%

---

## Failure Details

### [FAIL-001] [Test Name]
**File**: [test_file]
**Line**: [line_number]
**Category**: [unit/integration/e2e/visual/a11y/performance]
**Error**:
\`\`\`
[error message/stack trace]
\`\`\`
**Expected**: [expected behavior]
**Actual**: [actual behavior]
**Suggested Fix**: [recommendation]

---

## Recommendations

### Critical (Must Fix)
1. [Priority 1 recommendation]

### High Priority
1. [Priority 2 recommendation]

### Medium Priority
1. [Priority 3 recommendation]

### Low Priority / Enhancements
1. [Priority 4 recommendation]
```

---

## 9.4 Evaluate Results

Analyze test results:

| Condition | Result |
|-----------|--------|
| All tests pass AND coverage ≥ threshold | PASS → Proceed to §9.6 |
| Any unit/integration test fails | FAIL → Proceed to §9.5 |
| Any E2E test fails (broken user flow) | FAIL → Proceed to §9.5 |
| Visual regression > 5% diff | FAIL → Proceed to §9.5 |
| Critical accessibility violation (WCAG A) | FAIL → Proceed to §9.5 |
| Cross-browser failure on major browser | FAIL → Proceed to §9.5 |
| Core Web Vitals below threshold | FAIL → Proceed to §9.5 |
| Coverage below threshold | FAIL → Proceed to §9.5 |
| Critical security vulnerability | FAIL → Proceed to §9.5 |
| Linting errors (blocking) | FAIL → Proceed to §9.5 |

**Thresholds** (use constitution.md values if defined, otherwise defaults):
- Code coverage: 80%
- Visual regression diff: 5%
- Accessibility: WCAG 2.1 AA compliance
- Lighthouse performance score: 70/100

---

## 9.5 Test Failure Remediation

If any tests fail:

Output:
```
❌ **Test failures detected. Initiating remediation...**

| ID | Category | Test/Check | Issue | Severity |
|----|----------|------------|-------|----------|
| TF-001 | [category] | [test] | [issue] | CRITICAL/HIGH/MEDIUM |
...
```

### 9.5.1 Update Spec with Issues

Add a `## Test Failures` section to FEATURE_DIR/spec.md:

```markdown
## Test Failures (Remediation Required)

**Test Run**: [TIMESTAMP]
**Report**: tests/reports/[report_file].md

### Issues Requiring Resolution

| ID | Category | Description | Impact | Status |
|----|----------|-------------|--------|--------|
| TF-001 | [cat] | [description] | [impact] | 🔴 Open |
...

### Remediation Plan

1. TF-001: [specific fix plan]
2. TF-002: [specific fix plan]
...
```

### 9.5.2 Classify and Prioritize

- **CRITICAL**: Security vulnerabilities, data corruption risks, complete feature failure, WCAG A violations (legal compliance), broken primary user flows
- **HIGH**: Core functionality broken, integration failures, E2E test failures on happy path, visual regressions on key pages, keyboard navigation broken, Core Web Vitals failing
- **MEDIUM**: Edge case failures, coverage gaps, visual regressions on secondary pages, WCAG AA violations, cross-browser issues on non-primary browsers, performance below target but usable
- **LOW**: Style issues, minor warnings, WCAG AAA recommendations, minor visual inconsistencies, performance optimizations

### 9.5.3 Execute Remediation

For each failure (CRITICAL → HIGH → MEDIUM):

1. **Identify root cause** from test output and stack trace
2. **Locate affected code** in implementation
3. **Apply fix** following existing patterns in codebase
4. **Update affected tests** if test itself was incorrect
5. **Update visual snapshots** if visual change was intentional
6. **Mark issue as resolved** in spec.md

**UI-Specific Remediation:**
- **Button/Link failures**: Check event handlers, disabled states, href attributes
- **Form failures**: Validate input handling, error states, submission logic
- **Visual regression**: Compare snapshots, identify CSS changes, check responsive breakpoints
- **Accessibility**: Add ARIA labels, fix heading hierarchy, improve color contrast
- **Performance**: Optimize images, lazy load components, reduce bundle size

### 9.5.4 Re-run Tests

After all remediations:
```
Remediation complete. Re-running full test suite...
```

Return to §9.2 and execute full test suite again.

### 9.5.5 Remediation Loop Limit

Track remediation attempts:
- Maximum 3 full remediation cycles
- If still failing after 3 cycles:
  ```
  ⚠️ **Maximum remediation attempts reached.**
  
  Remaining failures:
  | ID | Test | Issue |
  |----|------|-------|
  ...
  
  Manual intervention required. See test report for details.
  ```
  Halt and await user input.

---

## 9.6 Update Constitution

After successful test pass, update `/memory/constitution.md` with new capabilities:

### 9.6.1 Detect New Capabilities

Scan implemented feature for:
- New modules/services added
- New API endpoints
- New data models
- New integrations
- New patterns established

### 9.6.2 Update Constitution Sections

Add or update sections as needed:

```markdown
## Project Capabilities

### Services
- [ServiceName]: [Description] (Added: [DATE], Feature: [NUMBER])
...

### API Endpoints
- [METHOD] [path]: [Description] (Added: [DATE])
...

### Data Models
- [ModelName]: [Description] (Added: [DATE])
...

### Integrations
- [IntegrationName]: [Description] (Added: [DATE])
...

## Code Patterns

### Established Patterns
- [PatternName]: [Description, where used, when to apply]
...

### Testing Standards
- Unit test coverage minimum: [X]%
- Integration test requirements: [description]
- Contract test requirements: [description]
```

### 9.6.3 Update Version

Increment constitution version:
- New capability added → Minor version bump (1.0.0 → 1.1.0)
- Principle changed → Major version bump (1.0.0 → 2.0.0)
- Documentation only → Patch version bump (1.0.0 → 1.0.1)

Update `Last Amended` date.

### 9.6.4 Update Project Version (if applicable)

If the project uses semantic versioning with VERSION and CHANGELOG files:

1. **Decide bump level using this algorithm:**
   - If the change introduces breaking API/DB schema or requires migration → **major**
   - Else if it adds new, backward-compatible features (new routes, pages, games) → **minor**
   - Else → **patch**

2. **Update files and create a release tag** (example for minor bump):

```bash
# Determine current version (reads from VERSION)
CURRENT=$(cat VERSION | tr -d " \n")
# Suggested new version (example script - adjust as needed)
# For minor bump (X.Y.Z -> X.(Y+1).0)
IFS='.' read -r MAJ MIN PATCH <<< "$CURRENT"
NEW="$MAJ.$((MIN+1)).0"

echo "$NEW" > VERSION

# Move Unreleased changes into CHANGELOG.md under new heading (manual edit recommended)
# Commit version and changelog updates
git add VERSION CHANGELOG.md
git commit -m "chore(release): bump version to $NEW"

# Tag the release and push tag
git tag -a "v$NEW" -m "Release v$NEW"
git push origin "v$NEW"
```

3. **Update CHANGELOG.md** following Keep a Changelog format:
   - Move `[Unreleased]` content into `## [X.Y.Z] - YYYY-MM-DD` section
   - Update the comparison links at the bottom to reference the new tag ranges

4. **Container tags** (if using Podman/Docker):
   - Test builds: `<version>-canary`
   - Production builds: `<version>`

5. **Automation note:** Consider scripting the version bump and changelog release-step, but keep changelog edits manual for accuracy.

---

## 9.7 Final Completion

After all tests pass and constitution is updated:

```
## Spec Complete ✅

**Feature**: [NUMBER]-[SHORT_NAME]
**Branch**: [BRANCH_NAME]

### Implementation Summary
- Tasks completed: X/Y
- User stories implemented: [list]
- Files created/modified: [count]

### Test Summary
- Unit Tests: X passed
- Integration Tests: X passed
- Contract Tests: X passed
- Code Coverage: X%
- Security Issues: 0

### Reports Generated
- Test Report: tests/reports/[report_file].md

### Constitution Updates
- Version: [OLD] → [NEW]
- New capabilities documented: [count]

### Next Steps

**If `REMOTE_AVAILABLE=true`:**
1. Review test report: tests/reports/[report_file].md
2. Create pull request for branch: [BRANCH_NAME]
3. Request code review
4. Merge to main after approval

**If `REMOTE_AVAILABLE=false`:**
1. Review test report: tests/reports/[report_file].md
2. ⚠️ No remote repository - changes are local only
3. To push changes later:
   - Create repository: `gh repo create [REPO_NAME] --private --source=. --remote=origin`
   - Push branch: `git push -u origin [BRANCH_NAME]`
   - Create PR: `gh pr create`
```
