#!/usr/bin/env bash

# Legacy bootstrap entrypoint.
# Delegates to `cmdctl init` so all bootstrap logic lives in one place.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if command -v uv >/dev/null 2>&1; then
    exec uv run --project "$REPO_DIR" cmdctl init "$@"
fi

if [[ -x "$REPO_DIR/.venv/bin/cmdctl" ]]; then
    exec "$REPO_DIR/.venv/bin/cmdctl" init "$@"
fi

if command -v cmdctl >/dev/null 2>&1; then
    exec cmdctl init "$@"
fi

cat >&2 <<'EOF'
[ERROR] Could not find a way to run `cmdctl init`.

Try one of the following:

  1) Install uv, then run:
     uv run --project . cmdctl init --all

  2) Install command-center globally, then run:
     uv tool install command-center --from git+https://github.com/brimdor/command-center.git
     cmdctl init --all
EOF

exit 1
