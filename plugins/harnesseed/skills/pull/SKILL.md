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

```bash
claude plugin marketplace update tech-teku-toolkit
claude plugin update harnesseed@tech-teku-toolkit
```

Then resolve where the NEW blueprint landed — do NOT use `${CLAUDE_PLUGIN_ROOT}` for theirs
(it still points at the old version in this session; this is the documented exception):

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
NEW_ROOT="$(python3 -c "
import json, os
d = json.load(open(os.path.join('$CFG', 'plugins', 'installed_plugins.json')))
print(d['plugins']['harnesseed@tech-teku-toolkit'][0]['installPath'])")"
NEWBP="$NEW_ROOT/blueprint"
NEW_SHA="$(python3 -c "
import json, os
d = json.load(open(os.path.join('$CFG', 'plugins', 'installed_plugins.json')))
print(d['plugins']['harnesseed@tech-teku-toolkit'][0].get('gitCommitSha', ''))")"
```

If the new cache version equals the seedling's `planted.json` seed_version, report 「既に最新の
正典を吸収済み」 and stop. (If it is OLDER — a rollback — say so and stop; pulling backwards is
not supported.)

## Step 1 — upstream verification (tamper gate)

The marketplace cache is a git clone. Verify the new blueprint's manifest against the SAME
commit in the upstream history — a cache edited after install will not match:

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MKT="$CFG/plugins/marketplaces/tech-teku-toolkit"
if [ -n "$NEW_SHA" ] && git -C "$MKT" cat-file -e "$NEW_SHA" 2>/dev/null; then
  git -C "$MKT" show "$NEW_SHA:plugins/harnesseed/blueprint/manifest.json" > /tmp/upstream-manifest.json
  diff -q /tmp/upstream-manifest.json "$NEWBP/manifest.json" \
    || { echo "REFUSE PULL: new cache manifest differs from upstream commit $NEW_SHA"; }
else
  echo "REFUSE PULL: cannot verify upstream (offline / no commit sha) — retry when verifiable"
fi
```

On refusal: stop, tell the user why, suggest reinstall. Also verify the new blueprint's files
against its own manifest (same bidirectional walk as germination) before merging.

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
  as bundled-candidates and register accepted ones via
  `python3 "${CLAUDE_PLUGIN_ROOT}/skills/scout/ledger.py" append …` (status "bundled").

## Step 4 — all-or-nothing finalize

```bash
bash "$SM" finalize "$SEEDLING" "$NEWBP"
```

One commit: new roots + merged stem + regenerated planted.json, trailer
`Harnesseed-Event: pull` / `Seed-Version`. Then run the (freshly absorbed) checker as a
self-check: `bash "$SEEDLING/roots/evals/check-invariants.sh" "$SEEDLING"`.

Finish by advising a Claude Code **restart** so the updated skills/hooks themselves take
effect, and show a short diff summary of what the canon gained.
