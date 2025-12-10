# Create new feature branch and spec directory
# PowerShell equivalent of create-new-feature.sh

[CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$FeatureDescription,
    
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help
)

# Show help if requested
if ($Help) {
    @"
Usage: create-new-feature.ps1 [OPTIONS] <feature_description>

Options:
  -Json              Output in JSON format
  -ShortName <name>  Provide a custom short name (2-4 words) for the branch
  -Number N          Specify branch number manually (overrides auto-detection)
  -Help              Show this help message

Examples:
  .\create-new-feature.ps1 'Add user authentication system' -ShortName 'user-auth'
  .\create-new-feature.ps1 'Implement OAuth2 integration for API' -Number 5
"@
    exit 0
}

# Validate feature description
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: create-new-feature.ps1 [OPTIONS] <feature_description>"
    exit 1
}

$featureDescriptionStr = $FeatureDescription -join ' '

# Function to find the repository root by searching for existing project markers
function Find-RepoRoot {
    param([string]$StartPath)
    
    $dir = $StartPath
    while ($dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        if ((Test-Path (Join-Path $dir ".git")) -or (Test-Path (Join-Path $dir ".specify"))) {
            return $dir
        }
        $dir = Split-Path -Parent $dir
    }
    return $null
}

# Function to get highest number from specs directory
function Get-HighestFromSpecs {
    param([string]$SpecsDir)
    
    $highest = 0
    
    if (Test-Path $SpecsDir) {
        Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)') {
                $number = [int]$matches[1]
                if ($number -gt $highest) {
                    $highest = $number
                }
            }
        }
    }
    
    return $highest
}

# Function to get highest number from git branches
function Get-HighestFromBranches {
    $highest = 0
    
    try {
        $branches = git branch -a 2>$null
        if ($branches) {
            $branches | ForEach-Object {
                # Clean branch name: remove leading markers and remote prefixes
                $cleanBranch = $_ -replace '^\s*[\*\s]*', '' -replace '^remotes/[^/]*/', ''
                
                # Extract feature number if branch matches pattern ###-*
                if ($cleanBranch -match '^(\d{3})-') {
                    $number = [int]$matches[1]
                    if ($number -gt $highest) {
                        $highest = $number
                    }
                }
            }
        }
    }
    catch {
        # Git not available or error occurred
    }
    
    return $highest
}

# Function to check existing branches and return next available number
function Get-NextBranchNumber {
    param([string]$SpecsDir)
    
    # Fetch all remotes to get latest branch info (suppress errors if no remotes)
    try {
        git fetch --all --prune 2>$null | Out-Null
    }
    catch {
        # Ignore errors
    }
    
    # Get highest number from ALL branches
    $highestBranch = Get-HighestFromBranches
    
    # Get highest number from ALL specs
    $highestSpec = Get-HighestFromSpecs -SpecsDir $SpecsDir
    
    # Take the maximum of both
    $maxNum = [Math]::Max($highestBranch, $highestSpec)
    
    # Return next number
    return $maxNum + 1
}

# Function to clean and format a branch name
function New-CleanBranchName {
    param([string]$Name)
    
    return $Name.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-|-$', ''
}

# Function to generate branch name with stop word filtering
function New-BranchName {
    param([string]$Description)
    
    # Common stop words to filter out
    $stopWords = @('i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
                   'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
                   'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might',
                   'must', 'shall', 'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
                   'want', 'need', 'add', 'get', 'set')
    
    # Convert to lowercase and split into words
    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # Filter words: remove stop words and words shorter than 3 chars
    $meaningfulWords = $words | Where-Object {
        $word = $_
        ($word.Length -ge 3) -and ($stopWords -notcontains $word)
    }
    
    # Use first 3-4 meaningful words
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    }
    else {
        # Fallback to original logic
        return New-CleanBranchName -Name $Description
    }
}

# Resolve repository root
$scriptDir = Split-Path -Parent $PSCommandPath

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    $hasGit = $true
}
catch {
    $repoRoot = Find-RepoRoot -StartPath $scriptDir
    if (-not $repoRoot) {
        Write-Error "Error: Could not determine repository root. Please run this script from within the repository."
        exit 1
    }
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot "specs"
if (-not (Test-Path $specsDir)) {
    New-Item -ItemType Directory -Path $specsDir | Out-Null
}

# Generate branch name
if ($ShortName) {
    # Use provided short name, just clean it up
    $branchSuffix = New-CleanBranchName -Name $ShortName
}
else {
    # Generate from description with smart filtering
    $branchSuffix = New-BranchName -Description $featureDescriptionStr
}

# Determine branch number
if ($Number -eq 0) {
    if ($hasGit) {
        # Check existing branches on remotes
        $branchNumber = Get-NextBranchNumber -SpecsDir $specsDir
    }
    else {
        # Fall back to local directory check
        $highest = Get-HighestFromSpecs -SpecsDir $specsDir
        $branchNumber = $highest + 1
    }
}
else {
    $branchNumber = $Number
}

# Format feature number with leading zeros
$featureNum = "{0:D3}" -f $branchNumber
$branchName = "$featureNum-$branchSuffix"

# GitHub enforces a 244-byte limit on branch names
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    # Calculate how much we need to trim from suffix
    # Account for: feature number (3) + hyphen (1) = 4 chars
    $maxSuffixLength = $maxBranchLength - 4
    
    # Truncate suffix
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    # Remove trailing hyphen if truncation created one
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    
    Write-Warning "[specify] Warning: Branch name exceeded GitHub's 244-byte limit"
    Write-Warning "[specify] Original: $originalBranchName ($($originalBranchName.Length) bytes)"
    Write-Warning "[specify] Truncated to: $branchName ($($branchName.Length) bytes)"
}

# Create branch if git is available
if ($hasGit) {
    try {
        git checkout -b $branchName 2>$null
    }
    catch {
        Write-Warning "[specify] Failed to create branch: $_"
    }
}
else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

# Create feature directory
$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

# Copy template if it exists
$template = Join-Path $repoRoot ".specify\templates\spec-template.md"
$specFile = Join-Path $featureDir "spec.md"

if (Test-Path $template) {
    Copy-Item -Path $template -Destination $specFile
}
else {
    New-Item -ItemType File -Path $specFile | Out-Null
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

# Output results
if ($Json) {
    @{
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
    } | ConvertTo-Json -Compress
}
else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}
