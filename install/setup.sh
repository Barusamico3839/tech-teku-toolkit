#!/usr/bin/env bash
# setup.sh — idempotently install the brainstorm harness on this machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="${TT_CLAUDE_DIR:-$HOME/.claude}"
BIN_DIR="${TT_BIN_DIR:-$HOME/.local/bin}"
WSL_DISTRO="${TT_WSL_DISTRO:-${WSL_DISTRO_NAME:-Ubuntu}}"
# TT_WT_SETTINGS distinguishes "unset" from "set but empty": unset means
# auto-detect (below); explicitly set to "" means the caller wants the WT
# section skipped outright, so it must NOT fall through to auto-detection.
if [ "${TT_WT_SETTINGS+x}" = "x" ]; then
  WT_SETTINGS="$TT_WT_SETTINGS"
else
  WT_SETTINGS="$(ls /mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json 2>/dev/null | head -n1 || true)"
  if [ -z "$WT_SETTINGS" ]; then
    # Windows Terminal Preview installs under a different package id; try it
    # second so a stable-channel install is always preferred when both exist.
    WT_SETTINGS="$(ls /mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_*/LocalState/settings.json 2>/dev/null | head -n1 || true)"
  fi
fi

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required." >&2; exit 1; }

mkdir -p "$CLAUDE_DIR" "$BIN_DIR"

# 1) launcher scripts
install -m 0755 "$SCRIPT_DIR/clbs"     "$BIN_DIR/clbs"
install -m 0755 "$SCRIPT_DIR/clbs-run" "$BIN_DIR/clbs-run"
echo "✓ launcher scripts -> $BIN_DIR (clbs, clbs-run)"

# 2) statusline
install -m 0755 "$REPO_ROOT/plugins/brainstorm-harness/statusline/brainstorm-statusline.sh" \
                "$CLAUDE_DIR/brainstorm-statusline.sh"
echo "✓ statusline -> $CLAUDE_DIR/brainstorm-statusline.sh"

# 3) overlay (resolve statusline path placeholder) — python-only substitution;
#    paths travel via env vars, never interpolated into the python source text.
STATUSLINE_CMD="$CLAUDE_DIR/brainstorm-statusline.sh" \
SRC_OVERLAY="$SCRIPT_DIR/brainstorm.json" \
DST_OVERLAY="$CLAUDE_DIR/brainstorm.json" \
python3 - <<'PY'
import json, os

src = os.environ['SRC_OVERLAY']
dst = os.environ['DST_OVERLAY']
cmd = os.environ['STATUSLINE_CMD']

with open(src, encoding='utf-8') as f:
    text = f.read()
text = text.replace('__STATUSLINE_CMD__', cmd)

json.loads(text)  # validate before writing

with open(dst, 'w', encoding='utf-8') as f:
    f.write(text)
PY
echo "✓ overlay -> $CLAUDE_DIR/brainstorm.json"

# 4) Windows Terminal scheme + profile (idempotent)
if [ -z "$WT_SETTINGS" ] || [ ! -f "$WT_SETTINGS" ]; then
  echo "⚠ Windows Terminal settings not found — skipping the light-window setup." >&2
  echo "  (Claude overlay, skills, and banner still work in any terminal.)" >&2
else
  set +e
  SRC="$SCRIPT_DIR/sunrise-cream.json" WT="$WT_SETTINGS" DISTRO="$WSL_DISTRO" BIN_DIR="$BIN_DIR" python3 - <<'PY'
import json, os, shutil, sys

wtp = os.environ['WT']

# Windows Terminal settings.json is legally JSONC — `//` comments, trailing
# commas, and often a UTF-8 BOM are all valid there but not in strict JSON.
# Tolerate the BOM; if it still doesn't parse — malformed JSON, non-UTF-8
# bytes, or a root that isn't a JSON object (e.g. a top-level array) — bail
# out cleanly (exit 2) instead of letting an exception traceback out of this
# block. The file is left completely untouched in that case (no backup, no
# rewrite). Genuine I/O errors (missing/unreadable file) are left to
# propagate and stay fatal.
try:
    with open(wtp, encoding='utf-8-sig') as f:
        wt = json.loads(f.read())
except (json.JSONDecodeError, UnicodeDecodeError):
    sys.exit(2)

if not isinstance(wt, dict):
    sys.exit(2)

src    = json.load(open(os.environ['SRC'], encoding='utf-8'))
distro = os.environ['DISTRO']
bin_dir = os.environ['BIN_DIR']

scheme  = src['scheme']
profile = dict(src['profile'])
profile['commandline'] = profile['commandline'] \
    .replace('__WSL_DISTRO__', distro) \
    .replace('__CLBS_RUN__', os.path.join(bin_dir, 'clbs-run'))

# Windows Terminal legally allows "profiles" to be either the object form
# {"list": [...], ...} or a flat array [...]. Detect which shape this file
# uses and write back the *same* shape — never convert the user's structure.
profiles_val = wt.get('profiles')
if isinstance(profiles_val, list):
    flat_profiles = True
    plist = profiles_val
else:
    flat_profiles = False
    plist = wt.setdefault('profiles', {}).setdefault('list', [])

existing = next((p for p in plist if p.get('name') == 'Brainstorm'), None)
if existing and existing.get('guid'):
    profile['guid'] = existing['guid']
else:
    profile['guid'] = '{' + open('/proc/sys/kernel/random/uuid').read().strip() + '}'

wt.setdefault('schemes', [])
wt['schemes'] = [s for s in wt['schemes'] if s.get('name') != 'Sunrise Cream'] + [scheme]

new_list = [p for p in plist if p.get('name') != 'Brainstorm'] + [profile]
if flat_profiles:
    wt['profiles'] = new_list
else:
    wt['profiles']['list'] = new_list

# Only now that we know the file round-trips as valid JSON do we take the
# one-time pristine backup (skipped if a prior run already made one).
backup = wtp + '.tt-backup'
if not os.path.exists(backup):
    shutil.copyfile(wtp, backup)

tmp = wtp + '.tt-tmp'
with open(tmp, 'w', encoding='utf-8') as f:
    json.dump(wt, f, indent=4, ensure_ascii=False)
with open(tmp, encoding='utf-8') as f:
    json.load(f)          # validate before swap
os.replace(tmp, wtp)
PY
  WT_RC=$?
  set -e
  case "$WT_RC" in
    0)
      echo "✓ Windows Terminal: 'Sunrise Cream' scheme + 'Brainstorm' profile (distro=$WSL_DISTRO)"
      ;;
    2)
      echo "⚠ Windows Terminal settings is not strict JSON (comments/trailing commas?) — skipping the light-window setup." >&2
      echo "  Hint: change any setting once in Windows Terminal's settings UI and retry — WT rewrites" >&2
      echo "  settings.json as strict JSON when it saves. Or add the 'Brainstorm' profile manually." >&2
      ;;
    *)
      exit "$WT_RC"
      ;;
  esac
fi

# 5) launcher backend note
if command -v cux >/dev/null 2>&1; then
  echo "✓ cux detected — the Brainstorm window will launch via cux"
else
  echo "ℹ cux not found — the Brainstorm window will launch via 'claude' (fallback)"
fi

# 6) PATH sanity check — the WT profile itself uses an absolute path to
#    clbs-run (see item E), so this only affects invoking `clbs` directly.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "⚠ $BIN_DIR is not on your PATH — 'clbs' won't work until it is." >&2
    echo "  Add to ~/.bashrc:  export PATH=\"$BIN_DIR:\$PATH\"" >&2
    ;;
esac

echo
echo "Done!  Open a brainstorm window with:  clbs"
echo "       (or pick the 'Brainstorm' profile from Windows Terminal's + menu)"
echo "Note:  confirm theme 'light' is accepted via /config; if not, edit $CLAUDE_DIR/brainstorm.json."
echo
echo "Also install the plugin itself inside Claude Code:"
echo "  /plugin marketplace add <owner>/tech-teku-toolkit"
echo "  /plugin install brainstorm-harness@tech-teku-toolkit"
