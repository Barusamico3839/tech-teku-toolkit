#!/usr/bin/env bash
# Deterministic invariants gate. P1 scope: planted.json integrity + roots pristine check.
# P4 extends this file (append-only ledgers, protected-diff, trailer rules).
# Run FROM the seedling's roots/ copy (git-audited), not from the live plugin cache.
set -euo pipefail
SEEDLING="${1:?usage: check-invariants.sh <seedling-dir>}"
python3 - "$SEEDLING" <<'PY'
import hashlib, json, os, sys
s = sys.argv[1]
fail = []
planted_path = os.path.join(s, "planted.json")
try:
    planted = json.load(open(planted_path))
except Exception as e:
    print(f"INVARIANT FAIL: planted.json unreadable: {e}"); sys.exit(1)
if "seed_version" not in planted or "blueprint" not in planted:
    print("INVARIANT FAIL: planted.json missing seed_version/blueprint"); sys.exit(1)
for rel, want in sorted(planted["blueprint"].items()):
    p = os.path.join(s, "roots", rel)
    if not os.path.isfile(p):
        fail.append(f"roots/{rel} missing"); continue
    got = hashlib.sha256(open(p, "rb").read()).hexdigest()
    if got != want:
        fail.append(f"roots/{rel} hash mismatch (roots must stay pristine; only germination/pull may write it)")
roots = os.path.join(s, "roots")
if os.path.isdir(roots):
    for dp, _, fns in os.walk(roots):
        for fn in sorted(fns):
            rel = os.path.relpath(os.path.join(dp, fn), roots)
            if rel not in planted["blueprint"]:
                fail.append(f"roots/{rel} not in planted.json (unexpected addition)")
if fail:
    print("INVARIANT FAIL:"); [print("  -", f) for f in fail]; sys.exit(1)
print(f"invariants OK (seed_version {planted['seed_version']}, {len(planted['blueprint'])} canon files pristine)")
PY
