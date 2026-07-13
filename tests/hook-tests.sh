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
run_hook_nostdin() { # cwd, entrypoint -> stdout (no JSON on stdin at all)
  ( cd "$1" && CLAUDE_CODE_ENTRYPOINT="$2" CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PLUGIN_ROOT="$PLUGROOT" bash "$HOOK" < /dev/null )
}
expect() { # name, needle-or-EMPTY, output
  local out="$3"
  if [ "$2" = "EMPTY" ]; then
    [ -z "$out" ] && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: $1 (expected empty, got: $out)"; }
  else
    case "$out" in *"$2"*) PASS=$((PASS+1));; *) FAIL=$((FAIL+1)); echo "FAIL: $1 (missing '$2' in: $out)";; esac
  fi
}
refute() { # name, needle, output -> fails if needle IS present
  local out="$3"
  case "$out" in *"$2"*) FAIL=$((FAIL+1)); echo "FAIL: $1 (unexpected '$2' present in: $out)";; *) PASS=$((PASS+1));; esac
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
expect "leaf compact pointer"            "harnessed"           "$(run_hook "$P3" compact cli)"

# downgrade skew (planted/seedling absorbed a NEWER version than what's installed now)
# -> neutral mismatch wording, no pull suggestion
printf '{"seed_version":"0.2.0","planted_at":"2026-07-13"}' > "$CFG/harnesseed/planted.json"
DOWNGRADE_OUT="$(run_hook "$P3" startup cli)"
expect "downgrade skew shows neutral mismatch wording" "Seed version mismatch: installed v0.1.0, seedling absorbed v0.2.0." "$DOWNGRADE_OUT"
refute "downgrade skew has no pull suggestion" "/harnesseed:pull" "$DOWNGRADE_OUT"

# ancestor leaf above a .git boundary must not bleed into a nested repo
P4="$TMP/proj4"; mkdir -p "$P4/.harnesseed" "$P4/child/.git"
printf '{"harnesseed":true,"seed_version":"0.1.0"}' > "$P4/.harnesseed/leaf.json"
expect "nested repo below ancestor leaf still nudges" "/harnesseed:harness" "$(run_hook "$P4/child" startup cli)"

# fail-closed source handling: empty stdin, and unknown source values
expect "empty stdin unharnessed silent"  EMPTY                 "$(run_hook_nostdin "$P1" cli)"
expect "unknown source value silent"     EMPTY                 "$(run_hook "$P1" mystery cli)"

# entrypoint matching is case-insensitive
expect "case-variant sdk entrypoint silent" EMPTY              "$(run_hook "$P1" startup SDK-CLI)"

# declined + leaf both present: declined wins (see comment in hook)
P5="$TMP/proj5"; mkdir -p "$P5/.harnesseed" "$P5/.git"
touch "$P5/.harnesseed/declined"
printf '{"harnesseed":true,"seed_version":"0.1.0"}' > "$P5/.harnesseed/leaf.json"
expect "declined wins over leaf when both present" EMPTY       "$(run_hook "$P5" startup cli)"

# declined stays silent on clear/compact too
expect "declined clear silent"           EMPTY                 "$(run_hook "$P2" clear cli)"
expect "declined compact silent"         EMPTY                 "$(run_hook "$P2" compact cli)"

echo "hook-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
