# Consolidated prerequisite checking script
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: .\check-prerequisites.ps1 [OPTIONS]
#
# OPTIONS:
#   -Json              Output in JSON format
#   -RequireTasks     Require tasks.md to exist (for implementation phase)
#   -IncludeTasks     Include tasks.md in AVAILABLE_DOCS list
#   -PathsOnly        Only output path variables (no validation)
#   -Help, -h          Show help message

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$Help
)

# Show help if requested
if ($Help) {
    @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json              Output in JSON format
  -RequireTasks     Require tasks.md to exist (for implementation phase)
  -IncludeTasks     Include tasks.md in AVAILABLE_DOCS list
  -PathsOnly        Only output path variables (no prerequisite validation)
  -Help             Show this help message

EXAMPLES:
  # Check task prerequisites (plan.md required)
  .\check-prerequisites.ps1 -Json
  
  # Check implementation prerequisites (plan.md + tasks.md required)
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  
  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly
"@
    exit 0
}

# Source common functions
$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir "common.ps1")

# Get feature paths and validate branch
$paths = Get-FeaturePaths

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# If paths-only mode, output paths and exit
if ($PathsOnly) {
    if ($Json) {
        # Minimal JSON paths payload (no validation performed)
        @{
            REPO_ROOT = $paths.REPO_ROOT
            BRANCH = $paths.CURRENT_BRANCH
            FEATURE_DIR = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN = $paths.IMPL_PLAN
            TASKS = $paths.TASKS
        } | ConvertTo-Json -Compress
    }
    else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# Validate required directories and files
if (-not (Test-Path $paths.FEATURE_DIR)) {
    Write-Error "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Error "Run /speckit.specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN)) {
    Write-Error "ERROR: plan.md not found in $($paths.FEATURE_DIR)"
    Write-Error "Run /speckit.plan first to create the implementation plan."
    exit 1
}

# Check for tasks.md if required
if ($RequireTasks -and -not (Test-Path $paths.TASKS)) {
    Write-Error "ERROR: tasks.md not found in $($paths.FEATURE_DIR)"
    Write-Error "Run /speckit.tasks first to create the task list."
    exit 1
}

# Build list of available documents
$docs = @()

# Always check these optional docs
if (Test-Path $paths.RESEARCH) { $docs += "research.md" }
if (Test-Path $paths.DATA_MODEL) { $docs += "data-model.md" }

# Check contracts directory (only if it exists and has files)
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue)) {
    $docs += "contracts/"
}

if (Test-Path $paths.QUICKSTART) { $docs += "quickstart.md" }

# Include tasks.md if requested and it exists
if ($IncludeTasks -and (Test-Path $paths.TASKS)) {
    $docs += "tasks.md"
}

# Output results
if ($Json) {
    # Build JSON object
    @{
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs
    } | ConvertTo-Json -Compress
}
else {
    # Text output
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"
    
    # Show status of each potential document
    Test-File -Path $paths.RESEARCH -Label "research.md" | Out-Null
    Test-File -Path $paths.DATA_MODEL -Label "data-model.md" | Out-Null
    Test-DirWithContent -Path $paths.CONTRACTS_DIR -Label "contracts/" | Out-Null
    Test-File -Path $paths.QUICKSTART -Label "quickstart.md" | Out-Null
    
    if ($IncludeTasks) {
        Test-File -Path $paths.TASKS -Label "tasks.md" | Out-Null
    }
}
