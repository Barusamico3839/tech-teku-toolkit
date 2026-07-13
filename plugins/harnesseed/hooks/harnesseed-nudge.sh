#!/usr/bin/env bash
# harnesseed SessionStart hook: detect-and-inject ONLY.
# Hard constraints: no network, no git commands, no jq. Cheap file reads, then exit.
set -u

INPUT="$(cat 2>/dev/null || true)"
SOURCE="$(printf '%s' "$INPUT" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

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
    # Declined always wins when both markers are present in the same directory
    # (the marker search above checks declined before leaf.json, so a stale
    # leaf.json left over from a prior attempt never overrides an explicit
    # decline). This ordering is intentional.
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
        # Directional skew: only recommend /harnesseed:pull when the INSTALLED
        # seed (cv) is newer than what the seedling absorbed (pv). If pv is
        # newer (a rollback / older plugin install), give neutral wording with
        # no pull suggestion — pulling would not help in that direction.
        newest="$(printf '%s\n%s\n' "$pv" "$cv" | sort -V | tail -n1)"
        if [ "$newest" = "$cv" ]; then
          HINT=" A newer seed (v$cv) is installed than this seedling absorbed (v$pv) — suggest running /harnesseed:pull."
        else
          HINT=" Seed version mismatch: installed v$cv, seedling absorbed v$pv."
        fi
      fi
    fi
    printf '%s\n' "[harnesseed] This project is harnessed. Seedling: $SEEDLING — read stem/philosophy.md (personal overlay) and trend-stock/summary.md (if present, else trend-stock/index.json) if you need harness context; do NOT load the whole seedling.$HINT"
    exit 0
    ;;
esac

# Unharnessed: nudge only on startup/clear (fail closed — empty/missing/unknown
# source values, and anything else, stay silent), never in non-interactive runs.
case "$SOURCE" in
  startup|clear) ;;
  *) exit 0 ;;
esac
ENTRYPOINT="$(printf '%s' "${CLAUDE_CODE_ENTRYPOINT:-}" | tr '[:upper:]' '[:lower:]')"
case "$ENTRYPOINT" in sdk-*) exit 0 ;; esac
cat <<'NUDGE'
[harnesseed] This project is not harnessed. Suggest /harnesseed:harness to the user and ASK FIRST — never proceed on your own. Ask exactly once, in the user's language, e.g.: "🌱 このプロジェクトを Harnesseed でハーネスしますか？" If the user seems busy with another task, mention it briefly instead of interrupting. If this appears to be a non-interactive run, skip the question entirely and proceed with the task.
NUDGE
exit 0
