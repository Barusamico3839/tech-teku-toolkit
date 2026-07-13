#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COLLECT="$ROOT/plugins/harnesseed/skills/checkup/collect.py"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- full fixture ---
CFG="$TMP/cfg"; PROJ="$TMP/proj"
mkdir -p "$CFG/plugins/marketplaces/mkt-a" "$CFG/plugins/marketplaces/mkt-b" "$CFG/skills/one" "$CFG/skills/two" "$CFG/workflows" "$PROJ"
cat > "$CFG/settings.json" <<'EOF'
{
  "permissions": {"allow": ["Bash(ls:*)", "Read"], "deny": ["Read(.env)"], "ask": []},
  "enabledPlugins": {"a@m": true, "b@m": true, "c@m": false},
  "hooks": {"SessionStart": [], "PostToolUse": []},
  "outputStyle": "Proactive",
  "model": "opus",
  "env": {"SECRET_TOKEN": "do-not-leak-me"}
}
EOF
printf '{"version":2,"plugins":{"a@m":[{}],"b@m":[{}]}}' > "$CFG/plugins/installed_plugins.json"
printf '{"mcpServers":{}}' > "$CFG/.mcp.json"
printf '# global\n' > "$CFG/CLAUDE.md"
printf '# project\n' > "$PROJ/CLAUDE.md"
printf '{"mcpServers":{}}' > "$PROJ/.mcp.json"

OUT="$(python3 "$COLLECT" "$CFG" "$PROJ")"
check "collector exits 0 on full fixture" 0 $?
printf '%s' "$OUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
s = d['settings']
assert s['exists'] and s['parse_ok'], s
assert s['permission_rules'] == {'allow': 2, 'deny': 1, 'ask': 0}, s
assert s['enabled_plugins'] == 2 and s['disabled_plugins'] == 1, s
assert sorted(s['hooks_events']) == ['PostToolUse', 'SessionStart'], s
assert s['output_style'] == 'Proactive' and s['model'] == 'opus', s
assert d['plugins']['installed'] == 2 and sorted(d['plugins']['marketplaces']) == ['mkt-a', 'mkt-b'], d['plugins']
assert d['mcp'] == {'user_file': True, 'project_file': True}, d['mcp']
assert d['claude_md'] == {'global': True, 'project': True}, d['claude_md']
assert d['skills_dirs'] == 2 and d['workflows']['dir_exists'], d
assert 'do-not-leak-me' not in json.dumps(d), 'SECRET LEAKED'
"
check "full fixture fields + no secret leak" 0 $?

# --- empty config ---
EMPTY="$TMP/empty"; mkdir -p "$EMPTY"
OUT2="$(python3 "$COLLECT" "$EMPTY")"
check "collector exits 0 on empty config" 0 $?
printf '%s' "$OUT2" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['settings']['exists'] is False, d
assert d['plugins']['installed'] == 0 and d['plugins']['marketplaces'] == [], d
assert d['claude_md'] == {'global': False, 'project': False}, d
"
check "empty config all-false/zero" 0 $?

# --- broken settings.json ---
BROKEN="$TMP/broken"; mkdir -p "$BROKEN"
printf 'not json' > "$BROKEN/settings.json"
OUT3="$(python3 "$COLLECT" "$BROKEN")"
check "collector exits 0 on broken settings" 0 $?
printf '%s' "$OUT3" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['settings']['exists'] is True and d['settings']['parse_ok'] is False, d
"
check "broken settings reported parse_ok=false" 0 $?

echo "checkup-collect-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
