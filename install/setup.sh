#!/usr/bin/env bash
# setup.sh — idempotently install the brainstorm harness on this machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="${TT_CLAUDE_DIR:-$HOME/.claude}"
BIN_DIR="${TT_BIN_DIR:-$HOME/.local/bin}"
WSL_DISTRO="${TT_WSL_DISTRO:-${WSL_DISTRO_NAME:-Ubuntu}}"
WT_SETTINGS="${TT_WT_SETTINGS:-}"
if [ -z "$WT_SETTINGS" ]; then
  WT_SETTINGS="$(ls /mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json 2>/dev/null | head -n1 || true)"
fi
if [ -z "$WT_SETTINGS" ]; then
  # Windows Terminal Preview installs under a different package id; try it
  # second so a stable-channel install is always preferred when both exist.
  WT_SETTINGS="$(ls /mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_*/LocalState/settings.json 2>/dev/null | head -n1 || true)"
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
  SRC="$SCRIPT_DIR/sunrise-cream.json" WT="$WT_SETTINGS" DISTRO="$WSL_DISTRO" python3 - <<'PY'
import json, os, shutil, sys

wtp = os.environ['WT']

# Windows Terminal settings.json is legally JSONC — `//` comments, trailing
# commas, and often a UTF-8 BOM are all valid there but not in strict JSON.
# Tolerate the BOM; if it still doesn't parse, bail out cleanly (exit 2)
# instead of letting json.JSONDecodeError traceback out of this block. The
# file is left completely untouched in that case (no backup, no rewrite).
try:
    with open(wtp, encoding='utf-8-sig') as f:
        wt = json.loads(f.read())
except json.JSONDecodeError:
    sys.exit(2)

src    = json.load(open(os.environ['SRC']))
distro = os.environ['DISTRO']

scheme  = src['scheme']
profile = dict(src['profile'])
profile['commandline'] = profile['commandline'].replace('__WSL_DISTRO__', distro)

plist = wt.setdefault('profiles', {}).setdefault('list', [])
existing = next((p for p in plist if p.get('name') == 'Brainstorm'), None)
if existing and existing.get('guid'):
    profile['guid'] = existing['guid']
else:
    profile['guid'] = '{' + open('/proc/sys/kernel/random/uuid').read().strip() + '}'

wt.setdefault('schemes', [])
wt['schemes'] = [s for s in wt['schemes'] if s.get('name') != 'Sunrise Cream'] + [scheme]
wt['profiles']['list'] = [p for p in plist if p.get('name') != 'Brainstorm'] + [profile]

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
      echo "  Hint: point TT_WT_SETTINGS at a cleaned (strict-JSON) copy of settings.json to enable it." >&2
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

echo
echo "Done!  Open a brainstorm window with:  clbs"
echo "       (or pick the 'Brainstorm' profile from Windows Terminal's + menu)"
echo "Note:  confirm theme 'light' is accepted via /config; if not, edit $CLAUDE_DIR/brainstorm.json."
