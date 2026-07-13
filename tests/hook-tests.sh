#!/usr/bin/env bash
# harnesseed-nudge.sh unit tests: 3 states x sources x subdir x entrypoint x version-skew
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/plugins/harnesseed/hooks/harnesseed-nudge.sh"
PASS=0; FAIL=0
run_hook() { # cwd, source, entrypoint -> stdout
  ( cd "$1" && printf '{"source":"%s"}' "$2" | \
    CLAUDE_CODE_ENTRYPOINT="$3" CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PLUGIN_ROOT="$PLUGROOT" bash "$HOOK" )
}
expect() { # name, needle-or-EMPTY, output
  local out="$3"
  if [ "$2" = "EMPTY" ]; then
    [ -z "$out" ] && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: $1 (expected empty, got: $out)"; }
  else
    case "$out" in *"$2"*) PASS=$((PASS+1));; *) FAIL=$((FAIL+1)); echo "FAIL: $1 (missing '$2' in: $out)";; esac
  fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CFG="$TMP/claude"; PLUGROOT="$TMP/plug"
mkdir -p "$CFG/harnesseed" "$PLUGROOT/.claude-plugin"
printf '{"name":"harnesseed","version":"0.1.0"}' > "$PLUGROOT/.claude-plugin/plugin.json"

# unharnessed project (git repo)
P1="$TMP/proj1"; mkdir -p "$P1/sub/dir" "$P1/.git"
expect "unharnessed startup nudges"      "/harnesseed:harness" "$(run_hook "$P1" startup cli)"
expect "unharnessed clear nudges"        "/harnesseed:harness" "$(run_hook "$P1" clear cli)"
expect "unharnessed resume silent"       EMPTY                 "$(run_hook "$P1" resume cli)"
expect "unharnessed compact silent"      EMPTY                 "$(run_hook "$P1" compact cli)"
expect "headless sdk silent"             EMPTY                 "$(run_hook "$P1" startup sdk-cli)"
expect "subdir stops at .git boundary"   "/harnesseed:harness" "$(run_hook "$P1/sub/dir" startup cli)"

# declined project
P2="$TMP/proj2"; mkdir -p "$P2/.harnesseed" "$P2/.git"; touch "$P2/.harnesseed/declined"
expect "declined startup silent"         EMPTY                 "$(run_hook "$P2" startup cli)"
expect "declined resume silent"          EMPTY                 "$(run_hook "$P2" resume cli)"

# harnessed project, matching versions
P3="$TMP/proj3"; mkdir -p "$P3/.harnesseed" "$P3/sub" "$P3/.git"
printf '{"harnesseed":true,"seed_version":"0.1.0"}' > "$P3/.harnesseed/leaf.json"
printf '{"seed_version":"0.1.0","planted_at":"2026-07-13"}' > "$CFG/harnesseed/planted.json"
expect "leaf startup pointer"            "harnessed"           "$(run_hook "$P3" startup cli)"
expect "leaf resume pointer (compact rebuild)" "harnessed"     "$(run_hook "$P3" resume cli)"
expect "leaf from subdir finds root"     "harnessed"           "$(run_hook "$P3/sub" startup cli)"
expect "no pull hint when versions match" EMPTY "$(run_hook "$P3" startup cli | grep -o 'harnesseed:pull' || true)"

# version skew -> pull hint
printf '{"seed_version":"0.0.9","planted_at":"2026-07-13"}' > "$CFG/harnesseed/planted.json"
expect "version skew suggests pull"      "/harnesseed:pull"    "$(run_hook "$P3" startup cli)"

echo "hook-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
