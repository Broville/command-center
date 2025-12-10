# Phase 1: Context Loading

> **Appendix Reference**: For Constitution Creation, Human Intervention Points, and Output Examples, see [do-the-thing-appendix.md](./do-the-thing-appendix.md).

---

## 1.0 Check GitHub Repository Existence

Before any git operations, verify that a GitHub repository exists for this project.

### 1.0.1 Detect Repository Name

```bash
# Get the workspace/folder name (this becomes the expected repo name)
REPO_NAME=$(basename "$PWD")

# Get the GitHub username
GH_USER=$(gh api user --jq '.login' 2>/dev/null)
```

### 1.0.2 Check Remote Configuration

```bash
# Check if origin remote exists
git remote get-url origin 2>/dev/null

# If origin exists, extract owner/repo from URL
# Formats: git@github.com:owner/repo.git OR https://github.com/owner/repo.git
```

### 1.0.3 Verify Repository Exists on GitHub

```bash
# Check if the repository exists on GitHub
gh repo view "$GH_USER/$REPO_NAME" --json name 2>/dev/null
```

### 1.0.4 Repository Status Determination

| Condition | Status | Action |
|-----------|--------|--------|
| Origin remote exists AND repo accessible | ✅ REMOTE_AVAILABLE | Proceed to §1.1 |
| Origin remote exists BUT repo inaccessible | ⚠️ REMOTE_CONFIGURED_UNAVAILABLE | Warn and ask user |
| No origin remote AND repo exists on GitHub | ⚠️ REMOTE_MISSING | Offer to add remote |
| No origin remote AND repo NOT on GitHub | ❌ NO_REMOTE_REPO | Ask to create repo |

### 1.0.5 If Repository Does Not Exist

Output:
```
## Phase 1: Context Loading

⚠️ **GitHub repository not found.**

| Detail | Value |
|--------|-------|
| Expected Repository | [GH_USER]/[REPO_NAME] |
| Local Workspace | [PWD] |
| Git Initialized | Yes/No |

The repository "[REPO_NAME]" does not exist on GitHub for user "[GH_USER]".

Would you like me to create the repository on GitHub?

| Option | Action |
|--------|--------|
| Y | **Create Repository** - Create "[GH_USER]/[REPO_NAME]" on GitHub (private by default) |
| P | **Create Public Repository** - Create as a public repository |
| N | **Continue Without Remote** - Proceed with local-only workflow (no push/PR operations) |

Reply with Y, P, or N.
```

### 1.0.6 Execute User Choice

**Option Y - Create Private Repository:**
```bash
# Initialize git if needed
git init 2>/dev/null || true

# Create the repository on GitHub
gh repo create "$REPO_NAME" --private --source=. --remote=origin

# Verify creation
gh repo view "$GH_USER/$REPO_NAME" --json name
```

Set: `REMOTE_AVAILABLE=true`

Output:
```
✓ Repository created: https://github.com/[GH_USER]/[REPO_NAME]
✓ Remote 'origin' configured.
```

Proceed to §1.1.

**Option P - Create Public Repository:**
```bash
# Initialize git if needed
git init 2>/dev/null || true

# Create the repository on GitHub
gh repo create "$REPO_NAME" --public --source=. --remote=origin

# Verify creation
gh repo view "$GH_USER/$REPO_NAME" --json name
```

Set: `REMOTE_AVAILABLE=true`

Output:
```
✓ Public repository created: https://github.com/[GH_USER]/[REPO_NAME]
✓ Remote 'origin' configured.
```

Proceed to §1.1.

**Option N - Continue Without Remote:**

Set: `REMOTE_AVAILABLE=false`

Output:
```
⚠️ Continuing without remote repository.

The following operations will be skipped during this workflow:
- git push (all push operations)
- Pull request creation
- Remote branch operations

All other local operations (commits, branches, specs, implementation) will proceed normally.
```

Proceed to §1.1.

### 1.0.7 If Remote Missing but Repo Exists

If no origin remote is configured but the repo exists on GitHub:

```
## Phase 1: Context Loading

⚠️ **Remote not configured but repository exists.**

| Detail | Value |
|--------|-------|
| Repository Found | [GH_USER]/[REPO_NAME] |
| Local Workspace | [PWD] |
| Origin Remote | Not configured |

Would you like me to add the remote?

| Option | Action |
|--------|--------|
| Y | **Add Remote** - Configure origin to point to the existing repository |
| N | **Continue Without Remote** - Proceed with local-only workflow |

Reply with Y or N.
```

**Option Y - Add Remote:**
```bash
git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
# Or for SSH: git remote add origin "git@github.com:$GH_USER/$REPO_NAME.git"
```

Set: `REMOTE_AVAILABLE=true`

Proceed to §1.1.

### 1.0.8 Repository Check Complete

If repository exists and is accessible:
```
✓ Repository verified: [GH_USER]/[REPO_NAME]
```

Proceed to §1.1.

---

## 1.1 Check for Pending Work

Before starting any new specification work, verify the workspace is clean. Execute the following checks across all branches:

### 1.1.1 Git State Detection

```bash
# Fetch all remote branches (skip if REMOTE_AVAILABLE=false)
[ "$REMOTE_AVAILABLE" = "true" ] && git fetch --all --prune

# Check for uncommitted changes (staged and unstaged)
git status --porcelain

# List all local branches with unpushed commits
git branch -vv | grep -E '\[.*: ahead'

# List all feature branches (local and remote)
git branch -a | grep -E '[0-9]+-'

# Check for stashed changes
git stash list
```

### 1.1.2 Pending Items Inventory

Build an inventory of all pending work:

| Category | Check | Status | Remote Required |
|----------|-------|--------|-----------------|
| Uncommitted Changes | `git status --porcelain` not empty | ✓ Clean / ⚠ Pending | No |
| Staged Changes | `git diff --cached --stat` has output | ✓ Clean / ⚠ Pending | No |
| Unpushed Commits | Local commits not on remote | ✓ Clean / ⚠ Pending / ⊘ Skipped | Yes |
| Stashed Changes | `git stash list` not empty | ✓ Clean / ⚠ Pending | No |
| Open Feature Branches | Branches matching `[0-9]+-*` pattern | ✓ None / ⚠ Found | No |
| Unmerged PRs | Open PRs for current repo | ✓ None / ⚠ Found / ⊘ Skipped | Yes |

**Note**: If `REMOTE_AVAILABLE=false`, skip checks marked "Remote Required" and mark as "⊘ Skipped".

### 1.1.3 If Pending Work Detected

Output:
```
## Phase 1: Context Loading

⚠️ **Pending work detected that requires attention before starting a new spec.**

### Pending Items:

| Item | Branch/Location | Description |
|------|-----------------|-------------|
| [type] | [branch/path] | [details] |
...

### Current Branch: [branch_name]
### Working Directory Status: [clean/dirty]
```

Then present options:

```
**Recommended:** [Option based on context - see recommendation logic below]

How would you like to proceed?

| Option | Action | Remote Required |
|--------|--------|-----------------|
| A | **Commit & Push All** - Stage all changes, commit with auto-generated message, and push to current branch | Yes (commit only if no remote) |
| B | **Commit & Push with Message** - Stage all changes, commit with your message, and push | Yes (commit only if no remote) |
| C | **Stash Changes** - Stash current changes to work on later, proceed with clean state | No |
| D | **Discard Changes** - Discard all uncommitted changes (⚠️ destructive) | No |
| E | **Switch to Feature Branch** - Switch to an existing feature branch to continue that work | No |
| F | **Merge Feature Branch** - Merge a completed feature branch into main/default branch | Yes (local merge only if no remote) |
| G | **Create PR** - Create a pull request for the current or specified branch | Yes (unavailable if no remote) |
| H | **Review & Close PR** - Review and merge/close an existing open PR | Yes (unavailable if no remote) |
| I | **Delete Stale Branches** - Clean up merged or abandoned feature branches | Partial (local only if no remote) |
| J | **Pop Stash** - Apply and remove the most recent stash | No |
| K | **Proceed Anyway** - Continue with new spec (⚠️ may cause conflicts) | No |
| L | **Custom Instructions** - Provide your own instructions for handling pending work | Varies |

**Note**: If `REMOTE_AVAILABLE=false`, options G and H are unavailable. Options A, B, F, I will perform local operations only (no push).

Reply with option letter, or type custom instructions.
```

### 1.1.4 Recommendation Logic

Provide a recommendation based on detected state:

- If uncommitted changes + on feature branch → **Recommend B** (Commit & Push with Message) or **Commit Only** if no remote
- If uncommitted changes + on main branch → **Recommend C** (Stash Changes)
- If unpushed commits only + remote available → **Recommend A** (Commit & Push All)
- If unpushed commits only + no remote → **Recommend K** (Proceed) since push is not possible
- If stashed changes only → **Recommend J** (Pop Stash) or **K** (Proceed) based on stash age
- If open feature branches with no local changes → **Recommend F** (Merge) or **H** (Review PR) if remote available
- If multiple issues detected → **Recommend handling in order**: commits → pushes → PRs → branches

### 1.1.5 Execute User Choice

Based on user selection:

**Option A - Commit & Push All:**
```bash
git add -A
git commit -m "chore: finalize pending changes before new spec"
# Only push if remote is available
[ "$REMOTE_AVAILABLE" = "true" ] && git push origin HEAD
```

If `REMOTE_AVAILABLE=false`:
```
✓ Changes committed locally. Push skipped (no remote repository).
```

**Option B - Commit & Push with Message:**
```
What commit message would you like to use?
```
Then:
```bash
git add -A
git commit -m "[user message]"
# Only push if remote is available
[ "$REMOTE_AVAILABLE" = "true" ] && git push origin HEAD
```

If `REMOTE_AVAILABLE=false`:
```
✓ Changes committed locally. Push skipped (no remote repository).
```

**Option C - Stash Changes:**
```bash
git stash push -m "Pre-spec stash $(date +%Y-%m-%d_%H-%M-%S)"
```

**Option D - Discard Changes:**
```
⚠️ This will permanently discard all uncommitted changes. Type "CONFIRM" to proceed.
```
If confirmed:
```bash
git checkout -- .
git clean -fd
```

**Option E - Switch to Feature Branch:**
```
Which branch would you like to switch to?

| # | Branch | Last Commit | Status |
|---|--------|-------------|--------|
| 1 | [branch] | [date/message] | [ahead/behind] |
...

Enter branch number or name.
```
Then:
```bash
git checkout [branch]
```
Return to §1.1 to reassess state on new branch.

**Option F - Merge Feature Branch:**
```
Which branch would you like to merge?

| # | Branch | Last Commit | Merge Status |
|---|--------|-------------|--------------|
| 1 | [branch] | [date/message] | [clean/conflicts] |
...

Enter branch number or name.
```
Then:
```bash
git checkout main  # or default branch
git merge [branch]
# Only push and delete remote if remote is available
[ "$REMOTE_AVAILABLE" = "true" ] && git push origin HEAD
git branch -d [branch]  # delete local after successful merge
[ "$REMOTE_AVAILABLE" = "true" ] && git push origin --delete [branch]  # delete remote
```

If `REMOTE_AVAILABLE=false`:
```
✓ Branch merged locally. Remote operations skipped (no remote repository).
```

**Option G - Create PR:**

If `REMOTE_AVAILABLE=false`:
```
⚠️ Cannot create pull request - no remote repository configured.

To create a PR, first create a GitHub repository using option Y in §1.0.5.
```
Return to option selection.

If `REMOTE_AVAILABLE=true`:
```
Creating PR for branch: [current_branch]

Title: [auto-generated from branch name or last commit]
Base: main

Would you like to customize the PR? (yes/no)
```
If yes, gather title and description. Then create PR using GitHub CLI or API.

**Option H - Review & Close PR:**

If `REMOTE_AVAILABLE=false`:
```
⚠️ Cannot review pull requests - no remote repository configured.
```
Return to option selection.

If `REMOTE_AVAILABLE=true`:
```
Open PRs requiring attention:

| # | PR | Branch | Author | Status | Checks |
|---|-----|--------|--------|--------|--------|
| 1 | #[num] [title] | [branch] | [author] | [state] | [pass/fail] |
...

Enter PR number to review, or "list" for more details.
```
After selection, present PR details and options:
```
| Action | Description |
|--------|-------------|
| M | Merge this PR |
| C | Close without merging |
| R | Request changes |
| V | View full diff |
| B | Back to list |
```

**Option I - Delete Stale Branches:**
```
Branches that appear safe to delete:

| # | Branch | Status | Last Activity | Location |
|---|--------|--------|---------------|----------|
| 1 | [branch] | merged/stale | [date] | local/remote/both |
...

Enter branch numbers to delete (comma-separated), or "all" for all listed.
```
Then:
```bash
git branch -d [branch]  # for each selected (local)
# Only delete remote branches if remote is available
[ "$REMOTE_AVAILABLE" = "true" ] && git push origin --delete [branch]  # if remote exists
```

If `REMOTE_AVAILABLE=false`:
```
✓ Local branches deleted. Remote branch deletion skipped (no remote repository).
```

**Option J - Pop Stash:**
```
Available stashes:

| # | Stash | Date | Message |
|---|-------|------|---------|
| 0 | stash@{0} | [date] | [message] |
...

Enter stash number to apply (default: 0).
```
Then:
```bash
git stash pop stash@{[n]}
```
Return to §1.1 to reassess state.

**Option K - Proceed Anyway:**
```
⚠️ Proceeding with pending work may cause:
- Merge conflicts when switching branches
- Lost changes if not committed
- Confusion about which changes belong to which feature

Are you sure you want to proceed? (yes/no)
```
If yes, proceed to §1.2.

**Option L - Custom Instructions:**
```
Provide your instructions for handling the pending work:
```
Execute user's custom instructions, then return to §1.1 to verify clean state.

### 1.1.6 Verify Clean State

After executing any option (except K), re-run checks from §1.1.1.

- If clean: Proceed to §1.2
- If still pending items: Return to §1.1.3 and present remaining items

### 1.1.7 If No Pending Work

If all checks pass (workspace is clean):
```
✓ Workspace clean. Proceeding with context loading...
```
Proceed to §1.2.

---

## 1.2 Check Constitution

Check for constitution using path resolution order:

1. **Project-local**: `.do-the-thing/.specify/memory/constitution.md`
2. **Global Opencode**: `~/.config/opencode/.do-the-thing/.specify/memory/constitution.md`
3. **Global Antigravity**: `~/.gemini/antigravity/.do-the-thing/.specify/memory/constitution.md`

- **If exists** (in any location): Load as authoritative project constitution. Extract all MUST/SHOULD principles for later gates. Proceed to §1.3.

- **If missing AND new project** (no existing specs/): 
  
  Output:
  ```
  ## Phase 1: Context Loading
  
  No project constitution found. Creating constitution...
  ```
  
  Then execute Constitution Creation (see [Appendix A](./do-the-thing-appendix.md#appendix-a-constitution-creation)). After constitution is created, proceed to §1.3.

- **If missing AND existing project** (specs/ exists): Proceed to §1.3 without constitution.


---

## 1.3 Determine Feature Context

Parse environment for existing feature context:

- Check for `specs/<number>-<short-name>/` directories
- If JSON environment provides FEATURE_DIR, use it
- If multiple features exist and none specified, use the highest-numbered feature
- If no feature directory exists, proceed to Phase 2 (Specification)

---

## 1.4 Check for Unfinished Work

If FEATURE_DIR exists, scan `spec.md` for incomplete markers:
- `[FEATURE NAME]`, `[DATE]`, `[TODO]`, `[TBD]`
- Empty required sections
- Draft status with fewer than 3 user stories

If incomplete markers found:
```
Detected unfinished spec. Completing specification...
```
Resume Phase 2 (Specification) to complete the spec.

---

## 1.5 Validate User Input

If ALL true:
- No unfinished specs detected
- `$ARGUMENTS` is empty/blank  
- No existing feature context to continue

Then prompt once:
```
I need more information to proceed. Please describe the feature or task you want to work on.
```

Wait for response, then restart from §1.1.

---

## 1.6 Assess Current State

If FEATURE_DIR exists, check which artifacts are present:

| Artifact | Path | Status |
|----------|------|--------|
| spec.md | FEATURE_DIR/spec.md | Present/Missing |
| plan.md | FEATURE_DIR/plan.md | Present/Missing |
| tasks.md | FEATURE_DIR/tasks.md | Present/Missing |
| research.md | FEATURE_DIR/research.md | Present/Missing |
| data-model.md | FEATURE_DIR/data-model.md | Present/Missing |
| contracts/ | FEATURE_DIR/contracts/ | Present/Missing |
| checklists/ | FEATURE_DIR/checklists/ | Present/Missing |
| tests/reports/ | Test reports for this feature | Present/Missing |

Determine next phase based on state:

| State | Next Phase |
|-------|------------|
| No spec | Phase 2: Specification |
| Spec has `[NEEDS CLARIFICATION]` | Phase 3: Clarification |
| Spec exists, no plan | Phase 4: Planning |
| Plan exists, no tasks | Phase 5: Task Generation |
| Tasks exist, no analysis | Phase 6: Analysis |
| Analysis has issues | Phase 7: Remediation |
| Analysis clean, tasks incomplete | Phase 8: Implementation |
| All tasks complete, no test report | Phase 9: Testing & Validation |
| Test report has failures | Phase 9: Testing & Validation (remediation) |
| Test report passes | Spec Complete |

Proceed immediately to the determined phase.
