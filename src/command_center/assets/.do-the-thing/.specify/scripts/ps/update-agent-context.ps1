# Update agent context files with information from plan.md
# PowerShell equivalent of update-agent-context.sh
#
# This script maintains AI agent context files by parsing feature specifications 
# and updating agent-specific configuration files with project information.
#
# Usage: .\update-agent-context.ps1 [agent_type]
# Agent types: claude|gemini|copilot|cursor-agent|qwen|opencode|codex|windsurf|kilocode|auggie|shai|q|bob|qoder
# Leave empty to update all existing agent files

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('claude', 'gemini', 'copilot', 'cursor-agent', 'qwen', 'opencode', 'codex', 
                 'windsurf', 'kilocode', 'auggie', 'roo', 'codebuddy', 'qoder', 'amp', 'shai', 'q', 'bob', '')]
    [string]$AgentType = ''
)

# Enable strict error handling
$ErrorActionPreference = 'Stop'

#==============================================================================
# Configuration and Global Variables
#==============================================================================

# Get script directory and load common functions
$scriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDir "common.ps1")

# Get all paths and variables from common functions
$paths = Get-FeaturePaths

$newPlan = $paths.IMPL_PLAN  # Alias for compatibility

# Agent-specific file paths
$agentFiles = @{
    claude = Join-Path $paths.REPO_ROOT "CLAUDE.md"
    gemini = Join-Path $paths.REPO_ROOT "GEMINI.md"
    copilot = Join-Path $paths.REPO_ROOT ".github\agents\copilot-instructions.md"
    'cursor-agent' = Join-Path $paths.REPO_ROOT ".cursor\rules\specify-rules.mdc"
    qwen = Join-Path $paths.REPO_ROOT "QWEN.md"
    opencode = Join-Path $paths.REPO_ROOT "AGENTS.md"
    codex = Join-Path $paths.REPO_ROOT "AGENTS.md"
    windsurf = Join-Path $paths.REPO_ROOT ".windsurf\rules\specify-rules.md"
    kilocode = Join-Path $paths.REPO_ROOT ".kilocode\rules\specify-rules.md"
    auggie = Join-Path $paths.REPO_ROOT ".augment\rules\specify-rules.md"
    roo = Join-Path $paths.REPO_ROOT ".roo\rules\specify-rules.md"
    codebuddy = Join-Path $paths.REPO_ROOT "CODEBUDDY.md"
    qoder = Join-Path $paths.REPO_ROOT "QODER.md"
    amp = Join-Path $paths.REPO_ROOT "AGENTS.md"
    shai = Join-Path $paths.REPO_ROOT "SHAI.md"
    q = Join-Path $paths.REPO_ROOT "AGENTS.md"
    bob = Join-Path $paths.REPO_ROOT "AGENTS.md"
}

# Template file
$templateFile = Join-Path $paths.REPO_ROOT ".specify\templates\agent-file-template.md"

# Global variables for parsed plan data
$script:newLang = ""
$script:newFramework = ""
$script:newDb = ""
$script:newProjectType = ""

#==============================================================================
# Utility Functions
#==============================================================================

function Write-Info { param([string]$Message) Write-Host "INFO: $Message" }
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$Message) Write-Error "ERROR: $Message" }
function Write-WarningMsg { param([string]$Message) Write-Warning "WARNING: $Message" }

#==============================================================================
# Validation Functions
#==============================================================================

function Test-Environment {
    # Check if we have a current branch/feature
    if (-not $paths.CURRENT_BRANCH) {
        Write-ErrorMsg "Unable to determine current feature"
        if ($paths.HAS_GIT) {
            Write-Info "Make sure you're on a feature branch"
        }
        else {
            Write-Info "Set SPECIFY_FEATURE environment variable or create a feature first"
        }
        exit 1
    }
    
    # Check if plan.md exists
    if (-not (Test-Path $newPlan)) {
        Write-ErrorMsg "No plan.md found at $newPlan"
        Write-Info "Make sure you're working on a feature with a corresponding spec directory"
        if (-not $paths.HAS_GIT) {
            Write-Info "Use: `$env:SPECIFY_FEATURE='your-feature-name' or create a new feature first"
        }
        exit 1
    }
    
    # Check if template exists (needed for new files)
    if (-not (Test-Path $templateFile)) {
        Write-WarningMsg "Template file not found at $templateFile"
        Write-WarningMsg "Creating new agent files will fail"
    }
}

#==============================================================================
# Plan Parsing Functions
#==============================================================================

function Get-PlanField {
    param(
        [string]$FieldPattern,
        [string]$PlanFile
    )
    
    $content = Get-Content $PlanFile -ErrorAction SilentlyContinue
    if (-not $content) { return "" }
    
    $line = $content | Where-Object { $_ -match "^\*\*$FieldPattern\*\*:\s*(.+)$" } | Select-Object -First 1
    
    if ($line -and $matches[1]) {
        $value = $matches[1].Trim()
        if ($value -notmatch 'NEEDS CLARIFICATION' -and $value -ne 'N/A') {
            return $value
        }
    }
    
    return ""
}

function Read-PlanData {
    param([string]$PlanFile)
    
    if (-not (Test-Path $PlanFile)) {
        Write-ErrorMsg "Plan file not found: $PlanFile"
        return $false
    }
    
    Write-Info "Parsing plan data from $PlanFile"
    
    $script:newLang = Get-PlanField -FieldPattern "Language/Version" -PlanFile $PlanFile
    $script:newFramework = Get-PlanField -FieldPattern "Primary Dependencies" -PlanFile $PlanFile
    $script:newDb = Get-PlanField -FieldPattern "Storage" -PlanFile $PlanFile
    $script:newProjectType = Get-PlanField -FieldPattern "Project Type" -PlanFile $PlanFile
    
    # Log what we found
    if ($script:newLang) { Write-Info "Found language: $($script:newLang)" }
    else { Write-WarningMsg "No language information found in plan" }
    
    if ($script:newFramework) { Write-Info "Found framework: $($script:newFramework)" }
    if ($script:newDb -and $script:newDb -ne "N/A") { Write-Info "Found database: $($script:newDb)" }
    if ($script:newProjectType) { Write-Info "Found project type: $($script:newProjectType)" }
    
    return $true
}

function Get-TechnologyStack {
    param(
        [string]$Lang,
        [string]$Framework
    )
    
    $parts = @()
    
    if ($Lang -and $Lang -ne "NEEDS CLARIFICATION") { $parts += $Lang }
    if ($Framework -and $Framework -ne "NEEDS CLARIFICATION" -and $Framework -ne "N/A") { $parts += $Framework }
    
    if ($parts.Count -eq 0) { return "" }
    return $parts -join " + "
}

#==============================================================================
# Template and Content Generation Functions
#==============================================================================

function Get-ProjectStructure {
    param([string]$ProjectType)
    
    if ($ProjectType -match 'web') {
        return "backend/`nfrontend/`ntests/"
    }
    return "src/`ntests/"
}

function Get-CommandsForLanguage {
    param([string]$Lang)
    
    switch -Regex ($Lang) {
        'Python' { return "cd src && pytest && ruff check ." }
        'Rust' { return "cargo test && cargo clippy" }
        'JavaScript|TypeScript' { return "npm test && npm run lint" }
        default { return "# Add commands for $Lang" }
    }
}

function Get-LanguageConventions {
    param([string]$Lang)
    return "$Lang`: Follow standard conventions"
}

function New-AgentFile {
    param(
        [string]$TargetFile,
        [string]$ProjectName,
        [string]$CurrentDate
    )
    
    if (-not (Test-Path $templateFile)) {
        Write-ErrorMsg "Template not found at $templateFile"
        return $false
    }
    
    Write-Info "Creating new agent context file from template..."
    
    $content = Get-Content $templateFile -Raw
    
    # Get substitution values
    $projectStructure = Get-ProjectStructure -ProjectType $script:newProjectType
    $commands = Get-CommandsForLanguage -Lang $script:newLang
    $languageConventions = Get-LanguageConventions -Lang $script:newLang
    
    # Build technology stack and recent change strings
    $techStack = if ($script:newLang -and $script:newFramework) {
        "- $($script:newLang) + $($script:newFramework) ($($paths.CURRENT_BRANCH))"
    }
    elseif ($script:newLang) {
        "- $($script:newLang) ($($paths.CURRENT_BRANCH))"
    }
    elseif ($script:newFramework) {
        "- $($script:newFramework) ($($paths.CURRENT_BRANCH))"
    }
    else {
        "- ($($paths.CURRENT_BRANCH))"
    }
    
    $recentChange = if ($script:newLang -and $script:newFramework) {
        "- $($paths.CURRENT_BRANCH): Added $($script:newLang) + $($script:newFramework)"
    }
    elseif ($script:newLang) {
        "- $($paths.CURRENT_BRANCH): Added $($script:newLang)"
    }
    elseif ($script:newFramework) {
        "- $($paths.CURRENT_BRANCH): Added $($script:newFramework)"
    }
    else {
        "- $($paths.CURRENT_BRANCH): Added"
    }
    
    # Perform substitutions
    $content = $content -replace '\[PROJECT NAME\]', $ProjectName
    $content = $content -replace '\[DATE\]', $CurrentDate
    $content = $content -replace '\[EXTRACTED FROM ALL PLAN\.MD FILES\]', $techStack
    $content = $content -replace '\[ACTUAL STRUCTURE FROM PLANS\]', $projectStructure
    $content = $content -replace '\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]', $commands
    $content = $content -replace '\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]', $languageConventions
    $content = $content -replace '\[LAST 3 FEATURES AND WHAT THEY ADDED\]', $recentChange
    
    # Create directory if needed
    $targetDir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Write to file
    Set-Content -Path $TargetFile -Value $content -NoNewline
    
    return $true
}

function Update-ExistingAgentFile {
    param(
        [string]$TargetFile,
        [string]$CurrentDate
    )
    
    Write-Info "Updating existing agent context file..."
    
    $content = Get-Content $TargetFile
    $newContent = @()
    
    $techStack = Get-TechnologyStack -Lang $script:newLang -Framework $script:newFramework
    $newTechEntries = @()
    $newChangeEntry = ""
    
    # Prepare new technology entries
    if ($techStack -and ($content -notmatch [regex]::Escape($techStack))) {
        $newTechEntries += "- $techStack ($($paths.CURRENT_BRANCH))"
    }
    
    if ($script:newDb -and $script:newDb -ne "N/A" -and $script:newDb -ne "NEEDS CLARIFICATION" -and 
        ($content -notmatch [regex]::Escape($script:newDb))) {
        $newTechEntries += "- $($script:newDb) ($($paths.CURRENT_BRANCH))"
    }
    
    # Prepare new change entry
    if ($techStack) {
        $newChangeEntry = "- $($paths.CURRENT_BRANCH): Added $techStack"
    }
    elseif ($script:newDb -and $script:newDb -ne "N/A" -and $script:newDb -ne "NEEDS CLARIFICATION") {
        $newChangeEntry = "- $($paths.CURRENT_BRANCH): Added $($script:newDb)"
    }
    
    # Process file
    $inTechSection = $false
    $inChangesSection = $false
    $techEntriesAdded = $false
    $changesEntriesAdded = $false
    $existingChangesCount = 0
    
    foreach ($line in $content) {
        # Handle Active Technologies section
        if ($line -eq "## Active Technologies") {
            $newContent += $line
            $inTechSection = $true
            continue
        }
        elseif ($inTechSection -and $line -match '^##\s') {
            # Add new tech entries before closing section
            if (-not $techEntriesAdded -and $newTechEntries.Count -gt 0) {
                $newContent += $newTechEntries
                $techEntriesAdded = $true
            }
            $newContent += $line
            $inTechSection = $false
            continue
        }
        elseif ($inTechSection -and -not $line.Trim()) {
            # Add new tech entries before empty line in tech section
            if (-not $techEntriesAdded -and $newTechEntries.Count -gt 0) {
                $newContent += $newTechEntries
                $techEntriesAdded = $true
            }
            $newContent += $line
            continue
        }
        
        # Handle Recent Changes section
        if ($line -eq "## Recent Changes") {
            $newContent += $line
            # Add new change entry right after heading
            if ($newChangeEntry) {
                $newContent += $newChangeEntry
            }
            $inChangesSection = $true
            $changesEntriesAdded = $true
            continue
        }
        elseif ($inChangesSection -and $line -match '^##\s') {
            $newContent += $line
            $inChangesSection = $false
            continue
        }
        elseif ($inChangesSection -and $line -match '^-\s') {
            # Keep only first 2 existing changes
            if ($existingChangesCount -lt 2) {
                $newContent += $line
                $existingChangesCount++
            }
            continue
        }
        
        # Update timestamp
        if ($line -match '\*\*Last updated\*\*:.*\d{4}-\d{2}-\d{2}') {
            $newContent += $line -replace '\d{4}-\d{2}-\d{2}', $CurrentDate
        }
        else {
            $newContent += $line
        }
    }
    
    # If sections don't exist, add them
    if (-not $techEntriesAdded -and $newTechEntries.Count -gt 0) {
        $newContent += ""
        $newContent += "## Active Technologies"
        $newContent += $newTechEntries
    }
    
    if (-not $changesEntriesAdded -and $newChangeEntry) {
        $newContent += ""
        $newContent += "## Recent Changes"
        $newContent += $newChangeEntry
    }
    
    # Write back to file
    Set-Content -Path $TargetFile -Value $newContent
    
    return $true
}

#==============================================================================
# Main Agent File Update Function
#==============================================================================

function Update-AgentFile {
    param(
        [string]$TargetFile,
        [string]$AgentName
    )
    
    Write-Info "Updating $AgentName context file: $TargetFile"
    
    $projectName = Split-Path -Leaf $paths.REPO_ROOT
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    
    # Create directory if it doesn't exist
    $targetDir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    if (-not (Test-Path $TargetFile)) {
        # Create new file from template
        if (New-AgentFile -TargetFile $TargetFile -ProjectName $projectName -CurrentDate $currentDate) {
            Write-Success "Created new $AgentName context file"
            return $true
        }
        else {
            Write-ErrorMsg "Failed to create new agent file"
            return $false
        }
    }
    else {
        # Update existing file
        if (Update-ExistingAgentFile -TargetFile $TargetFile -CurrentDate $currentDate) {
            Write-Success "Updated existing $AgentName context file"
            return $true
        }
        else {
            Write-ErrorMsg "Failed to update existing agent file"
            return $false
        }
    }
}

#==============================================================================
# Agent Selection and Processing
#==============================================================================

function Update-SpecificAgent {
    param([string]$Type)
    
    $agentNames = @{
        claude = "Claude Code"
        gemini = "Gemini CLI"
        copilot = "GitHub Copilot"
        'cursor-agent' = "Cursor IDE"
        qwen = "Qwen Code"
        opencode = "opencode"
        codex = "Codex CLI"
        windsurf = "Windsurf"
        kilocode = "Kilo Code"
        auggie = "Auggie CLI"
        roo = "Roo Code"
        codebuddy = "CodeBuddy CLI"
        qoder = "Qoder CLI"
        amp = "Amp"
        shai = "SHAI"
        q = "Amazon Q Developer CLI"
        bob = "IBM Bob"
    }
    
    if ($agentFiles.ContainsKey($Type)) {
        return Update-AgentFile -TargetFile $agentFiles[$Type] -AgentName $agentNames[$Type]
    }
    else {
        Write-ErrorMsg "Unknown agent type '$Type'"
        Write-ErrorMsg "Expected: claude|gemini|copilot|cursor-agent|qwen|opencode|codex|windsurf|kilocode|auggie|roo|amp|shai|q|bob|qoder"
        return $false
    }
}

function Update-AllExistingAgents {
    $foundAgent = $false
    
    $agentNames = @{
        claude = "Claude Code"
        gemini = "Gemini CLI"
        copilot = "GitHub Copilot"
        'cursor-agent' = "Cursor IDE"
        qwen = "Qwen Code"
        opencode = "Codex/opencode"
        windsurf = "Windsurf"
        kilocode = "Kilo Code"
        auggie = "Auggie CLI"
        roo = "Roo Code"
        codebuddy = "CodeBuddy CLI"
        shai = "SHAI"
        qoder = "Qoder CLI"
        q = "Amazon Q Developer CLI"
        bob = "IBM Bob"
    }
    
    # Check each possible agent file and update if it exists
    foreach ($agent in $agentFiles.Keys) {
        $targetFile = $agentFiles[$agent]
        if (Test-Path $targetFile) {
            Update-AgentFile -TargetFile $targetFile -AgentName $agentNames[$agent] | Out-Null
            $foundAgent = $true
        }
    }
    
    # If no agent files exist, create a default Claude file
    if (-not $foundAgent) {
        Write-Info "No existing agent files found, creating default Claude file..."
        Update-AgentFile -TargetFile $agentFiles['claude'] -AgentName "Claude Code" | Out-Null
    }
}

function Write-Summary {
    Write-Host ""
    Write-Info "Summary of changes:"
    
    if ($script:newLang) { Write-Host "  - Added language: $($script:newLang)" }
    if ($script:newFramework) { Write-Host "  - Added framework: $($script:newFramework)" }
    if ($script:newDb -and $script:newDb -ne "N/A") { Write-Host "  - Added database: $($script:newDb)" }
    
    Write-Host ""
    Write-Info "Usage: update-agent-context.ps1 [claude|gemini|copilot|cursor-agent|qwen|opencode|codex|windsurf|kilocode|auggie|codebuddy|shai|q|bob|qoder]"
}

#==============================================================================
# Main Execution
#==============================================================================

function Main {
    # Validate environment before proceeding
    Test-Environment
    
    Write-Info "=== Updating agent context files for feature $($paths.CURRENT_BRANCH) ==="
    
    # Parse the plan file to extract project information
    if (-not (Read-PlanData -PlanFile $newPlan)) {
        Write-ErrorMsg "Failed to parse plan data"
        exit 1
    }
    
    # Process based on agent type argument
    $success = $true
    
    if (-not $AgentType) {
        # No specific agent provided - update all existing agent files
        Write-Info "No agent specified, updating all existing agent files..."
        Update-AllExistingAgents
    }
    else {
        # Specific agent provided - update only that agent
        Write-Info "Updating specific agent: $AgentType"
        if (-not (Update-SpecificAgent -Type $AgentType)) {
            $success = $false
        }
    }
    
    # Print summary
    Write-Summary
    
    if ($success) {
        Write-Success "Agent context update completed successfully"
        exit 0
    }
    else {
        Write-ErrorMsg "Agent context update completed with errors"
        exit 1
    }
}

# Execute main function
Main
