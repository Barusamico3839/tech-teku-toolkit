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

# 3) overlay (resolve statusline path placeholder)
sed "s|__STATUSLINE_CMD__|$CLAUDE_DIR/brainstorm-statusline.sh|g" \
    "$SCRIPT_DIR/brainstorm.json" > "$CLAUDE_DIR/brainstorm.json"
python3 -c "import json; json.load(open('$CLAUDE_DIR/brainstorm.json'))"
echo "✓ overlay -> $CLAUDE_DIR/brainstorm.json"

# 4) Windows Terminal scheme + profile (idempotent)
if [ -z "$WT_SETTINGS" ] || [ ! -f "$WT_SETTINGS" ]; then
  echo "⚠ Windows Terminal settings not found — skipping the light-window setup."
  echo "  (Claude overlay, skills, and banner still work in any terminal.)"
else
  [ -f "$WT_SETTINGS.tt-backup" ] || cp "$WT_SETTINGS" "$WT_SETTINGS.tt-backup"
  SRC="$SCRIPT_DIR/sunrise-cream.json" WT="$WT_SETTINGS" DISTRO="$WSL_DISTRO" python3 - <<'PY'
import json, os
src    = json.load(open(os.environ['SRC']))
wtp    = os.environ['WT']
distro = os.environ['DISTRO']
wt     = json.load(open(wtp))

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

tmp = wtp + '.tt-tmp'
json.dump(wt, open(tmp, 'w'), indent=4, ensure_ascii=False)
json.load(open(tmp))          # validate before swap
os.replace(tmp, wtp)
PY
  echo "✓ Windows Terminal: 'Sunrise Cream' scheme + 'Brainstorm' profile (distro=$WSL_DISTRO)"
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
