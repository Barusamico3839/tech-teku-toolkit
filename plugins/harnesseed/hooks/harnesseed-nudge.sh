#!/usr/bin/env bash
# harnesseed SessionStart hook: detect-and-inject ONLY.
# Hard constraints: no network, no git commands, no jq. Cheap file reads, then exit.
set -u

INPUT="$(cat 2>/dev/null || true)"
SOURCE="$(printf '%s' "$INPUT" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$SOURCE" ] || SOURCE="startup"

# Upward marker search from cwd; stop at repo boundary (.git) or filesystem root.
dir="$PWD"; STATE="none"
while :; do
  if [ -e "$dir/.harnesseed/declined" ]; then STATE="declined"; break; fi
  if [ -e "$dir/.harnesseed/leaf.json" ]; then STATE="leaf"; break; fi
  if [ -e "$dir/.git" ] || [ "$dir" = "/" ]; then break; fi
  dir="$(dirname "$dir")"
done

json_field() { # file, key -> first string value
  sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -n1
}

case "$STATE" in
  declined)
    exit 0
    ;;
  leaf)
    SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
    HINT=""
    PLANTED="$SEEDLING/planted.json"
    PLUGJSON="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
    if [ -f "$PLANTED" ] && [ -f "$PLUGJSON" ]; then
      pv="$(json_field "$PLANTED" seed_version)"
      cv="$(json_field "$PLUGJSON" version)"
      if [ -n "$pv" ] && [ -n "$cv" ] && [ "$pv" != "$cv" ]; then
        HINT=" A newer seed (v$cv) is installed than this seedling absorbed (v$pv) — suggest running /harnesseed:pull."
      fi
    fi
    printf '%s\n' "[harnesseed] This project is harnessed. Seedling: $SEEDLING — read stem/philosophy.md (personal overlay) and trend-stock/summary.md if you need harness context; do NOT load the whole seedling.$HINT"
    exit 0
    ;;
esac

# Unharnessed: nudge only on startup/clear, never in non-interactive runs.
case "$SOURCE" in resume|compact) exit 0 ;; esac
case "${CLAUDE_CODE_ENTRYPOINT:-}" in sdk-*) exit 0 ;; esac
cat <<'NUDGE'
[harnesseed] This project is not harnessed. Suggest /harnesseed:harness to the user and ASK FIRST — never proceed on your own. Ask exactly once, in the user's language, e.g.: "🌱 このプロジェクトを Harnesseed でハーネスしますか？" If the user seems busy with another task, mention it briefly instead of interrupting. If this appears to be a non-interactive run, skip the question entirely and proceed with the task.
NUDGE
exit 0
