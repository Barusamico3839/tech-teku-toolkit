---
name: pull
description: Use when the user wants to absorb upstream canon updates (/harnesseed:pull), when the SessionStart hook reports a newer seed than the seedling absorbed, or after a plugin update. Updates the installed seed, verifies the new blueprint against the upstream repo, then does a staged 3-way merge that preserves the user's personalization.
---

# /harnesseed:pull — absorb upstream canon (roots=base / stem=mine / new blueprint=theirs)

Requires a germinated seedling. `roots/` and `planted.json` are written ONLY here (and at
germination) — the invariants checker enforces this via the pull trailer.

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SM="${CLAUDE_PLUGIN_ROOT}/skills/pull/stage-merge.sh"
```

**Leftover staging?** If `$SEEDLING/.pull-staging` exists, an earlier pull was interrupted.
Ask the user: 「破棄して最初から / 解決済み分を引き継いで再開」— discard = `rm -rf`, resume =
continue at Step 3's conflict resolution. The seedling's tracked files are guaranteed intact.

## Step 0 — update the seed (the installed cache does not update itself)

Derive our own identity from the running plugin's cache path (layout:
`…/cache/<marketplace>/<plugin>/<version>`) — never hardcode the marketplace name, which
differs between the GitHub install and a dev/directory install:

```bash
read -r MKT_NAME PLUGIN_NAME <<<"$(python3 - "${CLAUDE_PLUGIN_ROOT}" <<'PY'
import os, sys
parts = os.path.normpath(sys.argv[1]).split(os.sep)
if "cache" in parts[:-2]:
    i = len(parts) - 1 - parts[::-1].index("cache")
    if len(parts) >= i + 3:
        print(parts[i + 1], parts[i + 2]); raise SystemExit
print("", "")
PY
)"
```

If that prints empty (non-cache layout), fall back to scanning
`installed_plugins.json` for keys matching `harnesseed@*` and ask the user which one.

```bash
PLUGIN_ID="$PLUGIN_NAME@$MKT_NAME"
claude plugin marketplace update "$MKT_NAME"
claude plugin update "$PLUGIN_ID"
```

Then resolve where the NEW blueprint landed — do NOT use `${CLAUDE_PLUGIN_ROOT}` for theirs
(it still points at the old version in this session; this is the documented exception).
Pick the newest registry entry and cross-check it against its own plugin.json:

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
NEW_ROOT="$(python3 - "$CFG" "$PLUGIN_ID" <<'PY'
import json, os, sys
cfg, pid = sys.argv[1], sys.argv[2]
d = json.load(open(os.path.join(cfg, "plugins", "installed_plugins.json")))
e = max(d["plugins"][pid], key=lambda x: x.get("lastUpdated", ""))
ip = e["installPath"]
ver = json.load(open(os.path.join(ip, ".claude-plugin", "plugin.json")))["version"]
if ver != e.get("version"):
    sys.exit(f"REFUSE PULL: installPath plugin version {ver} != registry {e.get('version')}")
print(ip)
PY
)" || exit 1
NEWBP="$NEW_ROOT/blueprint"
NEW_SHA="$(python3 - "$CFG" "$PLUGIN_ID" <<'PY'
import json, os, sys
cfg, pid = sys.argv[1], sys.argv[2]
d = json.load(open(os.path.join(cfg, "plugins", "installed_plugins.json")))
e = max(d["plugins"][pid], key=lambda x: x.get("lastUpdated", ""))
print(e.get("gitCommitSha", ""))
PY
)"
```

If the new cache version equals the seedling's `planted.json` seed_version, report 「既に最新の
正典を吸収済み」 and stop. (If it is OLDER — a rollback — say so and stop; pulling backwards is
not supported.)

## Step 1 — upstream verification (tamper gate)

The marketplace cache is a git clone. Verify the new blueprint's manifest against the SAME
commit in the upstream history — a cache edited after install will not match. Resolve the
marketplace directory from the registry (the conventional `plugins/marketplaces/<name>` path
only holds for git sources; directory sources record an installLocation):

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MKT="$(python3 - "$CFG" "$MKT_NAME" <<'PY'
import json, os, sys
cfg, name = sys.argv[1], sys.argv[2]
for reg in ("known_marketplaces.json", "marketplaces.json"):
    p = os.path.join(cfg, "plugins", reg)
    if os.path.isfile(p):
        try:
            m = json.load(open(p)).get(name) or {}
            loc = m.get("installLocation") or m.get("path")
            if loc:
                print(loc); raise SystemExit
        except SystemExit:
            raise
        except Exception:
            pass
print(os.path.join(cfg, "plugins", "marketplaces", name))
PY
)"
if [ -n "$NEW_SHA" ] && git -C "$MKT" cat-file -e "$NEW_SHA" 2>/dev/null; then
  git -C "$MKT" show "$NEW_SHA:plugins/harnesseed/blueprint/manifest.json" \
    | diff -q - "$NEWBP/manifest.json" \
    || { echo "REFUSE PULL: new cache manifest differs from upstream commit $NEW_SHA"; exit 1; }
else
  echo "REFUSE PULL: cannot verify upstream (offline / no commit sha) — retry when verifiable"
  exit 1
fi
```

Both refusal branches **exit 1** — the stop is machine-enforced, not just prose. The decisive
files-vs-manifest gate (the same bidirectional walk as germination) runs deterministically
inside `stage-merge.sh` at both `stage` and `finalize` — a files-only tamper that leaves the
manifest intact is caught there even if this upstream check passes.

## Step 2 — precondition

`stage-merge.sh stage` verifies the seedling working tree is clean and no staging exists; if
dirty, show `git -C "$SEEDLING" status` and let the user decide before retrying.

## Step 3 — staged merge + conversational conflict resolution

```bash
bash "$SM" stage "$SEEDLING" "$NEWBP"
```

- exit 0: no conflicts → Step 4.
- exit 2: for each reported conflict, show the marked region from
  `$SEEDLING/.pull-staging/merged/<file>` and resolve it WITH the user (their personalization
  vs the upstream change — never decide silently). Edit the staging copy until no
  `<<<<<<<` markers remain.
- New items in the upstream `blueprint/trend-stock/index-seed.json` are NOT merged: offer them
  as bundled-candidates **in conversation only at this point** — the ledger registration
  happens AFTER finalize (Step 4), so an interrupted pull leaves the seedling's tracked
  files untouched, as guaranteed.

## Step 4 — all-or-nothing finalize

```bash
bash "$SM" finalize "$SEEDLING" "$NEWBP"
```

One commit: new roots + merged stem + regenerated planted.json, trailer
`Harnesseed-Event: pull` / `Seed-Version`. Then run the (freshly absorbed) checker as a
self-check: `bash "$SEEDLING/roots/evals/check-invariants.sh" "$SEEDLING"`.

**Only now** register the accepted bundled-candidates from Step 3 (use the NEW plugin's
ledger helper — `$NEW_ROOT/skills/scout/ledger.py`, not `${CLAUDE_PLUGIN_ROOT}` which still
points at the old version), one `append` per accepted item (status "bundled"), then a single
follow-up commit:

```bash
git -C "$SEEDLING" add trend-stock && git -C "$SEEDLING" commit -q \
  -m "pull: register upstream stock additions" \
  -m "Harnesseed-Event: pull-bundled"
```

(The trend-stock ledger is an append-only surface, not a protected path, so this commit
passes the invariants gate without a pull trailer.)

Finish by advising a Claude Code **restart** so the updated skills/hooks themselves take
effect, and show a short diff summary of what the canon gained.
