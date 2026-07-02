#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."           # repo root
WORK="$(mktemp -d)"
WORK2="$(mktemp -d)"
WORK3="$(mktemp -d)"
trap 'rm -rf "$WORK" "$WORK2" "$WORK3"' EXIT

# Fake a minimal Windows Terminal settings.json
cat > "$WORK/wt.json" <<'JSON'
{ "profiles": { "list": [ { "name": "Ubuntu", "guid": "{25abb833-a701-5cc1-9dc2-cf33e62fd10b}" } ] }, "schemes": [] }
JSON
# Pristine snapshot taken BEFORE any run touches the file, to verify the
# one-time backup is an exact, unmodified copy of the original settings.
cp "$WORK/wt.json" "$WORK/wt.json.orig"

run() {
  TT_CLAUDE_DIR="$WORK/claude" TT_BIN_DIR="$WORK/bin" \
  TT_WT_SETTINGS="$WORK/wt.json" TT_WSL_DISTRO="Ubuntu" \
  bash install/setup.sh >/dev/null
}

run   # first install

# Capture the Brainstorm profile GUID minted by the first run so we can
# assert it is preserved (not regenerated) by the second, idempotent run.
FIRST_GUID="$(python3 -c "import json; wt=json.load(open('$WORK/wt.json')); print(next(p['guid'] for p in wt['profiles']['list'] if p['name']=='Brainstorm'))")"

run   # second install (must stay idempotent)

FIRST_GUID="$FIRST_GUID" python3 - "$WORK" <<'PY'
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
# GUID identity preserved across the idempotent re-run (not regenerated)
first_guid = os.environ["FIRST_GUID"]
assert profs[0]["guid"] == first_guid, \
    "profile GUID changed across runs: %s -> %s" % (first_guid, profs[0]["guid"])
# original Ubuntu profile preserved
assert any(p["name"]=="Ubuntu" for p in wt["profiles"]["list"])
# pristine backup exists and is byte-for-byte the untouched original
# (taken before the first run, never overwritten by the second)
backup_path = os.path.join(w,"wt.json.tt-backup")
assert os.path.exists(backup_path), "backup missing"
orig = open(os.path.join(w,"wt.json.orig")).read()
backup = open(backup_path).read()
assert backup == orig, "backup is not a pristine copy of the original settings"
print("setup integration OK")
PY

# --- Scenario 2: WT settings not found -> graceful skip -----------------
# Spec: when WT settings can't be located, setup.sh must still exit 0,
# warn that the light-window setup is being skipped, and still install
# the overlay/launchers/statusline.
run_skip() {
  TT_CLAUDE_DIR="$WORK2/claude" TT_BIN_DIR="$WORK2/bin" \
  TT_WT_SETTINGS="$WORK2/does-not-exist/settings.json" TT_WSL_DISTRO="Ubuntu" \
  bash install/setup.sh
}

set +e
SKIP_OUT="$(run_skip 2>&1)"
SKIP_RC=$?
set -e

if [ "$SKIP_RC" -ne 0 ]; then
  echo "expected exit 0 when WT settings are missing, got $SKIP_RC" >&2
  echo "$SKIP_OUT" >&2
  exit 1
fi

if ! grep -q "skipping the light-window setup" <<<"$SKIP_OUT"; then
  echo "missing graceful-skip warning in output:" >&2
  echo "$SKIP_OUT" >&2
  exit 1
fi

python3 - "$WORK2" <<'PY'
import json, os, sys, stat
w=sys.argv[1]
# claude-dir / bin-dir artifacts still installed despite the missing WT settings
for p in ["bin/clbs","bin/clbs-run","claude/brainstorm-statusline.sh"]:
    fp=os.path.join(w,p); assert os.path.exists(fp), p
    assert os.stat(fp).st_mode & stat.S_IXUSR, "not executable: "+p
o=json.load(open(os.path.join(w,"claude/brainstorm.json")))
assert "__STATUSLINE_CMD__" not in json.dumps(o)
# no WT settings file should have been created out of thin air
assert not os.path.exists(os.path.join(w,"does-not-exist","settings.json"))
print("setup skip-scenario OK")
PY

# --- Scenario 3: WT settings is JSONC (comments / trailing commas) ------
# Spec: real Windows Terminal settings.json legally contains `//` comments
# and trailing commas (JSONC), which strict json.load() rejects. setup.sh
# must not traceback on this — it should warn and skip the light-window
# setup gracefully (exit 0), leaving the JSONC file byte-for-byte untouched
# (no backup, no rewrite), while still installing the claude/bin artifacts.
cat > "$WORK3/wt.json" <<'JSONC'
{
  // this comment line is legal JSONC but not strict JSON
  "profiles": { "list": [ { "name": "Ubuntu", "guid": "{25abb833-a701-5cc1-9dc2-cf33e62fd10b}" } ] },
  "schemes": [],
}
JSONC
cp "$WORK3/wt.json" "$WORK3/wt.json.orig"

run_jsonc() {
  TT_CLAUDE_DIR="$WORK3/claude" TT_BIN_DIR="$WORK3/bin" \
  TT_WT_SETTINGS="$WORK3/wt.json" TT_WSL_DISTRO="Ubuntu" \
  bash install/setup.sh
}

set +e
JSONC_OUT="$(run_jsonc 2>&1)"
JSONC_RC=$?
set -e

if [ "$JSONC_RC" -ne 0 ]; then
  echo "expected exit 0 for JSONC WT settings, got $JSONC_RC" >&2
  echo "$JSONC_OUT" >&2
  exit 1
fi

if ! grep -q "not strict JSON" <<<"$JSONC_OUT"; then
  echo "missing JSONC warning in output:" >&2
  echo "$JSONC_OUT" >&2
  exit 1
fi

python3 - "$WORK3" <<'PY'
import os, sys, stat
w = sys.argv[1]
# claude-dir / bin-dir artifacts still installed despite the JSONC WT settings
for p in ["bin/clbs", "bin/clbs-run", "claude/brainstorm-statusline.sh"]:
    fp = os.path.join(w, p); assert os.path.exists(fp), p
    assert os.stat(fp).st_mode & stat.S_IXUSR, "not executable: " + p
# the JSONC file itself must be byte-for-byte unchanged
orig = open(os.path.join(w, "wt.json.orig"), "rb").read()
after = open(os.path.join(w, "wt.json"), "rb").read()
assert after == orig, "JSONC WT settings file was modified"
# no backup should have been created for a file setup.sh never actually touched
assert not os.path.exists(os.path.join(w, "wt.json.tt-backup")), "unexpected .tt-backup for JSONC file"
print("setup jsonc-scenario OK")
PY
