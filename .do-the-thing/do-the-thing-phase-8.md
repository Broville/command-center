# Phase 8: Implementation

> **Appendix Reference**: For Human Intervention Points, see [do-the-thing-appendix.md](./do-the-thing-appendix.md#appendix-b-human-intervention-points).

Output:
```
## Phase 8: Implementation

Beginning implementation...
```

---

## 8.1 Check Checklists

If FEATURE_DIR/checklists/ exists, scan all checklist files:

```
| Checklist | Total | Completed | Incomplete | Status |
|-----------|-------|-----------|------------|--------|
| [name].md | X | Y | Z | ✓/✗ |
```

- If all complete: Proceed to §8.2
- If incomplete: Ask user "Some checklists are incomplete. Proceed anyway? (yes/no)"
  - If no: Halt
  - If yes: Proceed to §8.2

---

## 8.2 Load Implementation Context

Run `{ANALYSIS_SCRIPT}` (with `--json --require-tasks --include-tasks` flags) to validate all prerequisites exist.

Read:
- tasks.md (required)
- plan.md (required)
- data-model.md (if exists)
- contracts/ (if exists)
- research.md (if exists)
- quickstart.md (if exists)

---

## 8.3 Project Setup

Create/verify ignore files based on tech stack from plan.md:

**Detection & Creation Logic**:
- Check if git repo exists → create/verify `.gitignore`
- Check if Dockerfile exists or Docker in plan.md → create/verify `.dockerignore`
- Check if `.eslintrc*` exists → create/verify `.eslintignore`
- Check if `.prettierrc*` exists → create/verify `.prettierignore`

**Common patterns by technology:**
- Node.js: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
- Python: `__pycache__/`, `*.pyc`, `.venv/`, `dist/`, `*.egg-info/`
- Java: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
- Go: `*.exe`, `*.test`, `vendor/`
- Rust: `target/`, `debug/`, `release/`
- C#/.NET: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
- Ruby: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
- PHP: `vendor/`, `*.log`, `*.cache`, `*.env`
- Kotlin: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`
- C/C++: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`
- Swift: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`

**Universal:** `.DS_Store`, `Thumbs.db`, `*.tmp`, `.vscode/`, `.idea/`

**If ignore file exists**: Verify essential patterns present, append only missing critical patterns.
**If ignore file missing**: Create with full pattern set for detected technology.

---

## 8.4 Execute Tasks

Process tasks.md phase by phase:

**For each phase:**
1. Output phase header
2. Execute tasks in order
3. Respect dependencies:
   - Sequential tasks: Complete in order
   - `[P]` tasks: Can run in parallel
4. Mark completed tasks as `[X]` in tasks.md
5. Report progress

**Execution rules:**
- Setup phase first
- Foundational phase must complete before user stories
- User story phases can proceed in priority order
- Polish phase last

### 8.4.1 Browser Verification During Implementation (if UI application)

For UI applications, perform browser-based verification after completing each user story phase using containerized environments:

1. **Start Containerized Application** (if not already running):
   - Use existing build/test script if available:
     ```bash
     ./scripts/build_test.sh
     ```
   - Or start containers directly:
     ```bash
     podman-compose build
     podman-compose up -d
     ```
   - Verify the containerized application is accessible at the expected URL
   - Check container logs for any startup errors: `podman-compose logs --tail=20`

2. **Quick Visual Check**:
   - Use `browser_subagent` to navigate to the affected pages
   - Verify new components render correctly
   - Check for console errors or warnings
   - Capture a screenshot for reference

3. **Feature Smoke Test**:
   - Interact with newly implemented features
   - Verify basic functionality works as expected
   - Document any issues found

4. **Responsive Check**:
   - Resize viewport to mobile (375px width)
   - Verify layout adapts correctly
   - Return to desktop viewport

**If issues found:**
- Fix immediately before proceeding to next phase
- Update tasks.md with fix status
- Re-verify after fixes

**Note:** This is a quick sanity check during development, not comprehensive testing. Full browser testing occurs in Phase 9.

---

## 8.5 Progress Tracking

After each task:
- Report completion
- If error: Provide context and suggest fix
- Update tasks.md checkbox

---

## 8.6 Completion

After all tasks complete:
```
## Implementation Complete

**Summary:**
- Tasks completed: X/Y
- User stories implemented: [list]
- Files created/modified: [count]

Proceeding to testing and validation...
```

Proceed to Phase 9.
