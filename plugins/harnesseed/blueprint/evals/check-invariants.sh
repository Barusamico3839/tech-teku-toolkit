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
import hashlib, json, os, re, subprocess, sys
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


# Canon skeleton: stem/philosophy.md must keep every heading of roots/philosophy.md
# (spec gate 1-3; the 3-way merge in pull relies on this skeleton).
def headings(path):
    out, fenced = set(), False
    for line in open(path).read().splitlines():
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced and re.match(r"^#{1,6}\s", line):
            out.add(line.rstrip())
    return out


canon_phi = os.path.join(roots, "philosophy.md")
stem_phi = os.path.join(s, "stem", "philosophy.md")
if os.path.isfile(canon_phi):
    if os.path.isfile(stem_phi):
        missing = headings(canon_phi) - headings(stem_phi)
        if missing:
            fail.append(f"stem/philosophy.md lost canon headings: {sorted(missing)}")
    else:
        # deletion is not a bypass: if it ever existed in history, absence = skeleton loss.
        # (Never-existed is fine — germination runs this checker before the philosophy talk.)
        ever = git("log", "--oneline", "-1", "--", "stem/philosophy.md")
        if ever.returncode == 0 and ever.stdout.strip():
            fail.append("stem/philosophy.md deleted (canon skeleton lost)")

# P4: git-history rules (each skipped gracefully when the history is too short)
if git("rev-parse", "--verify", "-q", "HEAD").returncode == 0:
    if git("rev-list", "--merges", "HEAD").stdout.strip():
        fail.append("seedling history is not linear (merge commits present)")
    # An apply + its exact auto-revert net to zero: tree(HEAD) == tree(HEAD~2).
    # The HEAD~1 delta checks would see the revert "shrink" the ledgers and fail
    # spuriously, so a cancelled pair skips them (state is unchanged by definition).
    net_zero_pair = False
    if git("rev-parse", "--verify", "-q", "HEAD~2").returncode == 0:
        net_zero_pair = (git("rev-parse", "HEAD^{tree}").stdout.strip()
                         == git("rev-parse", "HEAD~2^{tree}").stdout.strip())
    if net_zero_pair:
        pass
    elif git("rev-parse", "--verify", "-q", "HEAD~1").returncode == 0:
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
                    a_status, b_status = a.pop("status", None), b.pop("status", None)
                    if a != b:
                        # Sole exception: resolving deferred -> rejected may ADD the
                        # rejection metadata (never rewrite fields that already existed).
                        if b_status == "rejected" and a_status != "rejected":
                            added = {k: v for k, v in b.items() if k not in a}
                            kept = {k: v for k, v in b.items() if k in a}
                            if (set(added) <= {"reason", "maturity", "evidence", "rejected_at"}
                                    and kept == a):
                                continue
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
        # Past records (checkup reports, scout run details) are add-only files:
        # modifying or deleting them rewrites the evidence trail. --no-renames so
        # a rename cannot masquerade as an allowed change. (A cancelled apply+revert
        # pair skips this whole branch, so auto-reverts stay clean.)
        ns = git("diff", "--no-renames", "--name-status", "HEAD~1", "HEAD").stdout
        for line in ns.splitlines():
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            status, p = parts[0], parts[1]
            is_record = (p.startswith("checkups/")
                         or (p.startswith("trend-stock/") and p.endswith(".md")
                             and "-scout-" in os.path.basename(p)))
            if is_record and status != "A":
                fail.append(f"{p}: past records are add-only (got git status {status!r})")
if fail:
    print("INVARIANT FAIL:"); [print("  -", f) for f in fail]; sys.exit(1)
print(f"invariants OK (seed_version {planted['seed_version']}, {len(planted['blueprint'])} canon files pristine)")
PY
