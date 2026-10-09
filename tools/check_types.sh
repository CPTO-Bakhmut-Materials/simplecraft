#!/usr/bin/env bash
# Type-checks the project with lua-language-server, using the rules in .luarc.json.
# Exits non-zero if any diagnostic is reported.
#
# Usage: tools/check_types.sh
# Needs: lua-language-server on PATH, or its path in $LUALS.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
luals="${LUALS:-lua-language-server}"
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT

# .luarc.json raises severities with groupSeverity, but --checklevel only looks at each
# diagnostic's own default, so anything above Hint would silently drop most rules.
"$luals" --check "$root" --checklevel=Hint --check_format=pretty --logpath="$logs"
