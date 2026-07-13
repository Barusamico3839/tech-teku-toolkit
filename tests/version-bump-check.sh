#!/usr/bin/env bash
# Fails if any DISTRIBUTABLE plugin content (everything under plugins/harnesseed/
# except docs/) changed vs <base-ref> without a plugin.json version bump — an
# un-bumped release makes 'claude plugin update' a silent no-op, so skills/hooks
# fixes would never reach installed users (live-verified 2026-07-13).
set -euo pipefail
BASE="${1:?usage: version-bump-check.sh <base-ref>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PLUG=plugins/harnesseed/.claude-plugin/plugin.json
if ! git rev-parse -q --verify "$BASE^{commit}" >/dev/null; then
  echo "base ref $BASE not found — skipping (first push?)"; exit 0
fi
if git diff --quiet "$BASE"...HEAD -- 'plugins/harnesseed/' ':(exclude)plugins/harnesseed/docs/' \
    ':(exclude)plugins/harnesseed/.claude-plugin/plugin.json'; then
  echo "no distributable plugin changes vs $BASE: OK"; exit 0
fi
if ! git cat-file -e "$BASE:$PLUG" 2>/dev/null; then
  echo "plugin.json absent at $BASE (new plugin): OK"; exit 0
fi
old="$(git show "$BASE:$PLUG" | python3 -c "import json,sys;print(json.load(sys.stdin)['version'])")"
new="$(python3 -c "import json;print(json.load(open('$PLUG'))['version'])")"
if [ "$old" = "$new" ]; then
  echo "FAIL: distributable plugin content changed vs $BASE but plugin.json version is still $new"
  echo "      (un-bumped releases make 'claude plugin update' a no-op and break /harnesseed:pull)"
  exit 1
fi
echo "plugin content changed and version bumped ($old -> $new): OK"
