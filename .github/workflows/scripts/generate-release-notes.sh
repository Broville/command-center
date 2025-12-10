#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# generate-release-notes.sh
# ==============================================================================
# Generate release notes from git history
# Usage: generate-release-notes.sh <new_version> <last_tag>
# ==============================================================================

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <new_version> <last_tag>" >&2
  exit 1
fi

NEW_VERSION="$1"
LAST_TAG="$2"

# Get commits since last tag
if [ "$LAST_TAG" = "v0.0.0" ]; then
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -gt 10 ]; then
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~10..HEAD)
  else
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~$COMMIT_COUNT..HEAD 2>/dev/null || git log --oneline --pretty=format:"- %s")
  fi
else
  COMMITS=$(git log --oneline --pretty=format:"- %s" "$LAST_TAG"..HEAD)
fi

# Create release notes
cat > release_notes.md << EOF
Command-Center provides global workflow commands for AI coding assistants.

## Installation

Download the package for your IDE and extract to the appropriate location:

| IDE | Package | Extract To |
|-----|---------|------------|
| Opencode | \`command-center-opencode-${NEW_VERSION}.zip\` | \`~/.config/opencode/\` |
| Antigravity | \`command-center-antigravity-${NEW_VERSION}.zip\` | \`~/.gemini/antigravity/\` |

Or use the bootstrap script from the repository:

\`\`\`bash
git clone https://github.com/yourusername/command-center.git
cd command-center
./scripts/bootstrap.sh
\`\`\`

## Included Commands

- \`/do-the-thing\` - Execute complete Spec-Driven Development workflow
- \`/commit\` - Commit, push, and optionally create PR
- \`/init\` - Create/update AGENTS.md

## Changelog

$COMMITS

EOF

echo "Generated release notes:"
cat release_notes.md
