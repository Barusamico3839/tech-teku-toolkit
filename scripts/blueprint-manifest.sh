#!/usr/bin/env bash
# generate|verify plugins/harnesseed/blueprint/manifest.json
# manifest = { "seed_version": <plugin.json version>, "files": { relpath: sha256 } }
set -euo pipefail
MODE="${1:-verify}"
ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
python3 - "$MODE" "$ROOT" <<'PY'
import hashlib, json, os, sys
mode, root = sys.argv[1], sys.argv[2]
plug = os.path.join(root, "plugins/harnesseed")
bp = os.path.join(plug, "blueprint")
mf = os.path.join(bp, "manifest.json")
ver = json.load(open(os.path.join(plug, ".claude-plugin/plugin.json")))["version"]
files = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        p = os.path.join(dp, fn)
        rel = os.path.relpath(p, bp)
        if rel == "manifest.json":
            continue
        files[rel] = hashlib.sha256(open(p, "rb").read()).hexdigest()
current = {"seed_version": ver, "files": dict(sorted(files.items()))}
if mode == "generate":
    json.dump(current, open(mf, "w"), indent=2, ensure_ascii=False)
    open(mf, "a").write("\n")
    print(f"manifest.json written ({len(files)} files, seed_version {ver})")
elif mode == "verify":
    recorded = json.load(open(mf))
    if recorded != current:
        for k in sorted(set(recorded.get("files", {})) | set(current["files"])):
            a, b = recorded.get("files", {}).get(k), current["files"].get(k)
            if a != b:
                print(f"MISMATCH {k}: recorded={a} actual={b}")
        if recorded.get("seed_version") != current["seed_version"]:
            print(f"MISMATCH seed_version: recorded={recorded.get('seed_version')} actual={current['seed_version']}")
        sys.exit(1)
    print("manifest verify: OK")
else:
    sys.exit(f"unknown mode {mode}")
PY
