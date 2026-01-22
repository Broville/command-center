#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# create-github-release.sh
# ==============================================================================
# Create a GitHub release with Command-Center packages
# Usage: create-github-release.sh <version>
# ==============================================================================

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"
VERSION_NO_V=${VERSION#v}

# Check that packages exist
PACKAGES=()
for pkg in .genreleases/command-center-*-"$VERSION".zip; do
  if [[ -f "$pkg" ]]; then
    PACKAGES+=("$pkg")
  fi
done

# Add Python build artifacts
for pkg in dist/*; do
  if [[ -f "$pkg" ]]; then
    PACKAGES+=("$pkg")
  fi
done

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo "Error: No packages found in .genreleases/ for version $VERSION" >&2
  echo "Run create-release-packages.sh first" >&2
  exit 1
fi

echo "Creating GitHub release $VERSION with ${#PACKAGES[@]} packages..."

gh release create "$VERSION" \
  "${PACKAGES[@]}" \
  --title "Command-Center $VERSION_NO_V" \
  --notes-file release_notes.md

echo "Release created successfully!"
