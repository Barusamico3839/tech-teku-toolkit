#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."           # repo root
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Fake a minimal Windows Terminal settings.json
cat > "$WORK/wt.json" <<'JSON'
{ "profiles": { "list": [ { "name": "Ubuntu", "guid": "{25abb833-a701-5cc1-9dc2-cf33e62fd10b}" } ] }, "schemes": [] }
JSON

run() {
  TT_CLAUDE_DIR="$WORK/claude" TT_BIN_DIR="$WORK/bin" \
  TT_WT_SETTINGS="$WORK/wt.json" TT_WSL_DISTRO="Ubuntu" \
  bash install/setup.sh >/dev/null
}

run   # first install
run   # second install (must stay idempotent)

python3 - "$WORK" <<'PY'
import json, os, sys, stat
w=sys.argv[1]
# scripts installed + executable
for p in ["bin/clbs","bin/clbs-run","claude/brainstorm-statusline.sh"]:
    fp=os.path.join(w,p); assert os.path.exists(fp), p
    assert os.stat(fp).st_mode & stat.S_IXUSR, "not executable: "+p
# overlay statusline path resolved (no placeholder left)
o=json.load(open(os.path.join(w,"claude/brainstorm.json")))
assert o["statusLine"]["command"]==os.path.join(w,"claude/brainstorm-statusline.sh")
assert "__STATUSLINE_CMD__" not in json.dumps(o)
# WT merged: exactly one scheme + one profile, distro substituted, guid present
wt=json.load(open(os.path.join(w,"wt.json")))
schemes=[s for s in wt["schemes"] if s["name"]=="Sunrise Cream"]
profs=[p for p in wt["profiles"]["list"] if p["name"]=="Brainstorm"]
assert len(schemes)==1, "scheme not idempotent: %d"%len(schemes)
assert len(profs)==1, "profile not idempotent: %d"%len(profs)
assert "__WSL_DISTRO__" not in profs[0]["commandline"]
assert "wsl.exe -d Ubuntu" in profs[0]["commandline"]
assert profs[0]["guid"].startswith("{") and profs[0]["guid"].endswith("}")
# original Ubuntu profile preserved
assert any(p["name"]=="Ubuntu" for p in wt["profiles"]["list"])
# pristine backup exists
assert os.path.exists(os.path.join(w,"wt.json.tt-backup"))
print("setup integration OK")
PY
