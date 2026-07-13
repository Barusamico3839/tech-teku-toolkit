#!/usr/bin/env bash
# Deterministic invariants gate.
# P1 scope: planted.json integrity + roots pristine (incl. unexpected additions).
# P4 scope: git-history rules — linear history, append-only growth-log,
#           monotonic index.json (status-only mutations), protected-path trailers.
# Run FROM the seedling's roots/ copy (git-audited), not from the live plugin cache.
# This is the ONLY layer wired to grow's automatic revert; behavior scenarios are advisory.
set -euo pipefail
SEEDLING="${1:?usage: check-invariants.sh <seedling-dir>}"
python3 - "$SEEDLING" <<'PY'
import hashlib, json, os, subprocess, sys
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


def git(*a):
    return subprocess.run(["git", "-C", s, *a], capture_output=True, text=True)


# P4: git-history rules (each skipped gracefully when the history is too short)
if git("rev-parse", "--verify", "-q", "HEAD").returncode == 0:
    if git("rev-list", "--merges", "HEAD").stdout.strip():
        fail.append("seedling history is not linear (merge commits present)")
    if git("rev-parse", "--verify", "-q", "HEAD~1").returncode == 0:
        prev = git("show", "HEAD~1:growth-log.md")
        cur = git("show", "HEAD:growth-log.md")
        if prev.returncode == 0 and (cur.returncode != 0
                                     or not cur.stdout.startswith(prev.stdout)):
            fail.append("growth-log.md is not append-only vs HEAD~1")
        prev_i = git("show", "HEAD~1:trend-stock/index.json")
        cur_i = git("show", "HEAD:trend-stock/index.json")
        if prev_i.returncode == 0:
            try:
                pe = {e["id"]: e for e in json.loads(prev_i.stdout)["entries"]}
                ce = ({e["id"]: e for e in json.loads(cur_i.stdout)["entries"]}
                      if cur_i.returncode == 0 else {})
                deleted = sorted(set(pe) - set(ce))
                if deleted:
                    fail.append(f"index.json entries deleted: {deleted}")
                for eid in set(pe) & set(ce):
                    a, b = dict(pe[eid]), dict(ce[eid])
                    a.pop("status", None), b.pop("status", None)
                    if a != b:
                        fail.append(f"index.json entry {eid!r} mutated beyond status")
            except Exception as e:
                fail.append(f"index.json monotonic check unreadable: {e}")
        changed = git("diff", "--name-only", "HEAD~1", "HEAD").stdout.split("\n")
        if any(c == "planted.json" or c.startswith("roots/") for c in changed if c):
            ev = git("log", "-1",
                     "--format=%(trailers:key=Harnesseed-Event,valueonly)").stdout.strip()
            if ev not in ("germinate", "pull"):
                fail.append("protected paths (planted.json / roots/) changed by a commit "
                            "without a germinate/pull trailer")
if fail:
    print("INVARIANT FAIL:"); [print("  -", f) for f in fail]; sys.exit(1)
print(f"invariants OK (seed_version {planted['seed_version']}, {len(planted['blueprint'])} canon files pristine)")
PY
