# Brainstorm Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `brainstorm-harness` plugin + a one-time `install/setup.sh` that opens an independent, light-themed Windows Terminal window running a cheerful "brainstorm mode" Claude Code, all distributed from the `tech-teku-toolkit` umbrella marketplace.

**Architecture:** A Claude Code plugin carries the *portable* parts (slash commands `/clbs` `/en` `/jp`, a SessionStart greeting hook, a statusline). The *host-specific* parts (Windows Terminal light color scheme + profile, the `clbs`/`clbs-run` launcher scripts, and a `~/.claude/brainstorm.json` settings overlay) can't ride a plugin, so an idempotent `setup.sh` applies them per machine. The brainstorm window launches Claude Code with `--settings ~/.claude/brainstorm.json`, which (key-level) overrides theme→light, permissions→bypass, statusLine→our script, and enabledPlugins→a curated ideation set.

**Tech Stack:** Bash scripts, JSON config, Python 3 (for the idempotent Windows Terminal settings merge — no `jq` dependency), Windows Terminal (`wt.exe`) on WSL2 Ubuntu, Claude Code v2.1.198 plugin/marketplace system.

## Global Constraints

- Target host: **WSL2 Ubuntu + Windows Terminal** (`wt.exe` present). Non-WT hosts: `setup.sh` skips the window setup gracefully; the overlay + plugin still work.
- **No `jq`, no `shellcheck`** in the environment — use **`python3`** for JSON manipulation and **`bash -n`** for script syntax checks.
- Launcher uses **`cux` if present, else `claude`** (fallback for shareability).
- **bypassPermissions is scoped to the brainstorm window only** (via the `--settings` overlay). **Never modify the global `~/.claude/settings.json`.**
- `setup.sh` must be **idempotent** (safe to re-run; no duplicate WT scheme/profile; keeps a one-time pristine backup `settings.json.tt-backup`).
- Windows Terminal profile name is **`Brainstorm`** (ASCII, for reliable `wt.exe -p` matching); the 🌱 goes in `tabTitle`/`icon`.
- Marketplace `name` = **`tech-teku-toolkit`**; plugin id in overlays = **`brainstorm-harness@tech-teku-toolkit`**.
- Startup language default = **English**; `/jp` and `/en` toggle mid-session.
- `theme: "light"` is not documented — after install, **verify via `/config`**; fallback `light-daltonized` or `auto` (harmless since the window itself is light).
- Color scheme **Sunrise Cream**: bg `#FFF8F0`, fg `#4A4137`, accent `#E8871E`, green `#5E9E4A`, blue `#3A8FB7`, red `#D6564B`, purple `#9A6FB0`, cyan `#2FA6A6`.
- Repo root: `~/projects/personal/tech-teku-toolkit`. All paths below are relative to it. Commit after every task.

---

## File Structure

| Path | Responsibility |
|---|---|
| `.claude-plugin/marketplace.json` | Umbrella catalog; lists `brainstorm-harness`. |
| `plugins/brainstorm-harness/.claude-plugin/plugin.json` | Plugin manifest. |
| `plugins/brainstorm-harness/commands/clbs.md` | `/clbs` — open a new Brainstorm window from inside Claude Code. |
| `plugins/brainstorm-harness/commands/en.md` | `/en` — respond in English henceforth. |
| `plugins/brainstorm-harness/commands/jp.md` | `/jp` — respond in Japanese henceforth. |
| `plugins/brainstorm-harness/hooks/hooks.json` | Registers the SessionStart greeting hook. |
| `plugins/brainstorm-harness/hooks/brainstorm-greeting.sh` | Emits brainstorm framing (English default) **only when `BRAINSTORM_MODE=1`**. |
| `plugins/brainstorm-harness/statusline/brainstorm-statusline.sh` | Cheerful 🌱 statusline line (dependency-free). |
| `install/brainstorm.json` | Claude settings overlay (theme/bypass/statusLine placeholder/curated plugins). |
| `install/sunrise-cream.json` | Source of truth for the WT scheme + profile (with `__WSL_DISTRO__` placeholder). |
| `install/clbs` | WSL command: opens a new Brainstorm WT window. |
| `install/clbs-run` | Runs *inside* the window: prints the banner, then `exec`s the launcher with the overlay. |
| `install/setup.sh` | Idempotent installer: places scripts/overlay/statusline, merges WT scheme+profile. |
| `README.md` | Install steps, friend flow, and the plugin-vs-setup tradeoff. |

**Dependency order:** manifests → commands → hook → statusline → overlay → WT source → launchers → `setup.sh` (integrates everything) → README.

---

### Task 1: Marketplace + plugin manifests

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/brainstorm-harness/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: marketplace `name: "tech-teku-toolkit"` with a plugin entry `{name:"brainstorm-harness", source:"./plugins/brainstorm-harness"}`; plugin `name: "brainstorm-harness"`. Later tasks and the overlay reference the id `brainstorm-harness@tech-teku-toolkit`.

- [ ] **Step 1: Write the failing validation**

Run (expected to FAIL — files don't exist yet):
```bash
cd ~/projects/personal/tech-teku-toolkit
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert m['name']=='tech-teku-toolkit'; assert any(p['name']=='brainstorm-harness' for p in m['plugins']); print('marketplace OK')"
python3 -c "import json; p=json.load(open('plugins/brainstorm-harness/.claude-plugin/plugin.json')); assert p['name']=='brainstorm-harness' and p['version'] and p['description']; print('plugin OK')"
```
Expected: `FileNotFoundError`.

- [ ] **Step 2: Create `.claude-plugin/marketplace.json`**

```json
{
  "name": "tech-teku-toolkit",
  "owner": { "name": "hikaru" },
  "metadata": {
    "description": "Hikaru's toolkit of Claude Code harness plugins."
  },
  "plugins": [
    {
      "name": "brainstorm-harness",
      "source": "./plugins/brainstorm-harness",
      "description": "Open an independent, light-themed terminal for cheerful brainstorming."
    }
  ]
}
```

- [ ] **Step 3: Create `plugins/brainstorm-harness/.claude-plugin/plugin.json`**

```json
{
  "name": "brainstorm-harness",
  "version": "0.1.0",
  "description": "Open an independent, light-themed terminal for cheerful brainstorming with Claude Code — light theme, bypass, curated ideation skills, cheerful banner, EN/JP toggle.",
  "author": { "name": "hikaru" },
  "keywords": ["brainstorming", "harness", "theme", "ideation"]
}
```

- [ ] **Step 4: Run validation to verify it passes**

Run:
```bash
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert m['name']=='tech-teku-toolkit'; assert any(p['name']=='brainstorm-harness' for p in m['plugins']); print('marketplace OK')"
python3 -c "import json; p=json.load(open('plugins/brainstorm-harness/.claude-plugin/plugin.json')); assert p['name']=='brainstorm-harness' and p['version'] and p['description']; print('plugin OK')"
```
Expected: `marketplace OK` then `plugin OK`.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin plugins/brainstorm-harness/.claude-plugin
git commit -m "feat: add tech-teku-toolkit marketplace + brainstorm-harness manifest"
```

---

### Task 2: Slash commands `/clbs`, `/en`, `/jp`

**Files:**
- Create: `plugins/brainstorm-harness/commands/clbs.md`
- Create: `plugins/brainstorm-harness/commands/en.md`
- Create: `plugins/brainstorm-harness/commands/jp.md`

**Interfaces:**
- Consumes: the `clbs` WSL command (Task 7) / `wt.exe` for `/clbs`.
- Produces: three user-invocable commands. `/clbs` shells out to open a window; `/en` and `/jp` set the response language.

- [ ] **Step 1: Write the failing validation**

Run (expected FAIL — files missing):
```bash
test -f plugins/brainstorm-harness/commands/clbs.md \
 && test -f plugins/brainstorm-harness/commands/en.md \
 && test -f plugins/brainstorm-harness/commands/jp.md \
 && grep -q "wt.exe -w new -p Brainstorm" plugins/brainstorm-harness/commands/clbs.md \
 && echo "commands OK"
```
Expected: no output / non-zero exit.

- [ ] **Step 2: Create `commands/clbs.md`**

```markdown
---
description: Open a fresh light-themed Brainstorm window (Windows Terminal)
---

Open a new brainstorming window for the user.

Run this with the Bash tool:

```
wt.exe -w new -p Brainstorm
```

- On success, tell the user a new light 🌱 Brainstorm window is opening.
- If `wt.exe` is not found (not on WSL / no Windows Terminal), tell the user to run `clbs` in their terminal instead, and that this feature needs WSL + Windows Terminal.
Do not do anything else.
```

- [ ] **Step 3: Create `commands/en.md`**

```markdown
---
description: Switch responses to English
---

From now on, respond in **English** for the rest of this conversation, regardless of the language the user writes in — until they run `/jp`. Reply with a short, upbeat one-line confirmation and nothing else.
```

- [ ] **Step 4: Create `commands/jp.md`**

```markdown
---
description: 応答を日本語に切り替える
---

これ以降、ユーザーが `/en` を実行するまで、この会話では**日本語**で応答してください（ユーザーが何語で書いても）。明るい一言で確認だけ返し、他には何もしないでください。
```

- [ ] **Step 5: Run validation to verify it passes**

Run the Step 1 command. Expected: `commands OK`.

- [ ] **Step 6: Commit**

```bash
git add plugins/brainstorm-harness/commands
git commit -m "feat: add /clbs, /en, /jp brainstorm commands"
```

---

### Task 3: SessionStart greeting hook

**Files:**
- Create: `plugins/brainstorm-harness/hooks/brainstorm-greeting.sh`
- Create: `plugins/brainstorm-harness/hooks/hooks.json`

**Interfaces:**
- Consumes: env var `BRAINSTORM_MODE` (exported by `clbs-run`, Task 7).
- Produces: SessionStart context text that frames brainstorm mode + English default. **Emits nothing unless `BRAINSTORM_MODE=1`** so it never leaks into normal sessions where the plugin is also enabled.

- [ ] **Step 1: Write the failing test**

Run (expected FAIL — file missing):
```bash
S=plugins/brainstorm-harness/hooks/brainstorm-greeting.sh
BRAINSTORM_MODE=  bash "$S" | wc -c   # expect 0
BRAINSTORM_MODE=1 bash "$S" | grep -qi "no wrong ideas" && echo "greeting OK"
```
Expected: error (no such file).

- [ ] **Step 2: Create `hooks/brainstorm-greeting.sh`**

```bash
#!/usr/bin/env bash
# SessionStart hook. Stdout is injected into Claude's context (not shown to the
# user). Only speak up inside a brainstorm window (BRAINSTORM_MODE=1) so this
# never affects normal sessions where the plugin may also be enabled.
[ "${BRAINSTORM_MODE:-}" = "1" ] || exit 0

cat <<'EOF'
[Brainstorm mode active] You are in a dedicated brainstorming space.
- Default to responding in ENGLISH. The user can switch to Japanese anytime with /jp (and back with /en).
- Keep an upbeat, encouraging, generative tone: defer judgment, build on ideas, offer many options. There are no wrong ideas here.
- Favor divergent exploration first, then help converge when the user is ready.
EOF
```

- [ ] **Step 3: Make it executable**

```bash
chmod +x plugins/brainstorm-harness/hooks/brainstorm-greeting.sh
```

- [ ] **Step 4: Create `hooks/hooks.json`**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/brainstorm-greeting.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
S=plugins/brainstorm-harness/hooks/brainstorm-greeting.sh
echo "empty-case bytes: $(BRAINSTORM_MODE= bash "$S" | wc -c)"   # expect 0
BRAINSTORM_MODE=1 bash "$S" | grep -qi "no wrong ideas" && echo "greeting OK"
python3 -c "import json; json.load(open('plugins/brainstorm-harness/hooks/hooks.json')); print('hooks.json OK')"
```
Expected: `empty-case bytes: 0`, `greeting OK`, `hooks.json OK`.

- [ ] **Step 6: Commit**

```bash
git add plugins/brainstorm-harness/hooks
git commit -m "feat: add BRAINSTORM_MODE-gated SessionStart greeting hook"
```

---

### Task 4: Brainstorm statusline

**Files:**
- Create: `plugins/brainstorm-harness/statusline/brainstorm-statusline.sh`

**Interfaces:**
- Consumes: Claude Code passes a session JSON blob on stdin (ignored here to stay dependency-free).
- Produces: a single cheerful status line containing `🌱` and `brainstorm`. Referenced by the overlay's `statusLine.command` (installed path resolved by `setup.sh`).

- [ ] **Step 1: Write the failing test**

Run (expected FAIL — file missing):
```bash
echo '{}' | bash plugins/brainstorm-harness/statusline/brainstorm-statusline.sh | grep -q "🌱" && echo "statusline OK"
```
Expected: error (no such file).

- [ ] **Step 2: Create `statusline/brainstorm-statusline.sh`**

```bash
#!/usr/bin/env bash
# Claude Code pipes a session JSON blob on stdin; we drain and ignore it to
# avoid any parser dependency. Output must be a single line.
cat >/dev/null 2>&1 || true
printf '🌱 brainstorm mode  ·  no wrong ideas — dream big ✨'
```

- [ ] **Step 3: Make it executable**

```bash
chmod +x plugins/brainstorm-harness/statusline/brainstorm-statusline.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
echo '{"model":{"display_name":"Opus"}}' | bash plugins/brainstorm-harness/statusline/brainstorm-statusline.sh | grep -q "🌱 brainstorm mode" && echo "statusline OK"
```
Expected: `statusline OK`.

- [ ] **Step 5: Commit**

```bash
git add plugins/brainstorm-harness/statusline
git commit -m "feat: add cheerful 🌱 brainstorm statusline (dependency-free)"
```

---

### Task 5: Claude settings overlay

**Files:**
- Create: `install/brainstorm.json`

**Interfaces:**
- Consumes: `__STATUSLINE_CMD__` placeholder (replaced by `setup.sh` with the installed statusline path).
- Produces: the overlay loaded via `claude --settings`. Because `--settings` is key-level override, listing `enabledPlugins` here means ONLY these plugins are active in the window; everything else is off.

- [ ] **Step 1: Write the failing test**

Run (expected FAIL — file missing):
```bash
python3 - <<'PY'
import json
d=json.load(open('install/brainstorm.json'))
assert d['theme']=='light'
assert d['permissions']['defaultMode']=='bypassPermissions'
assert d['enabledPlugins']['brainstorm-harness@tech-teku-toolkit'] is True
assert d['enabledPlugins']['superpowers@claude-plugins-official'] is True
assert d['statusLine']['command']=='__STATUSLINE_CMD__'
print('overlay OK')
PY
```
Expected: `FileNotFoundError`.

- [ ] **Step 2: Create `install/brainstorm.json`**

```json
{
  "theme": "light",
  "permissions": { "defaultMode": "bypassPermissions" },
  "enabledPlugins": {
    "brainstorm-harness@tech-teku-toolkit": true,
    "superpowers@claude-plugins-official": true,
    "everything-claude-code@everything-claude-code": true,
    "frontend-design@claude-plugins-official": true,
    "firecrawl@claude-plugins-official": true,
    "notion@claude-plugins-official": true
  },
  "statusLine": {
    "type": "command",
    "command": "__STATUSLINE_CMD__",
    "padding": 0
  }
}
```

- [ ] **Step 3: Run test to verify it passes**

Run the Step 1 Python block. Expected: `overlay OK`.

- [ ] **Step 4: Commit**

```bash
git add install/brainstorm.json
git commit -m "feat: add brainstorm settings overlay (light/bypass/curated plugins)"
```

---

### Task 6: Windows Terminal scheme + profile source

**Files:**
- Create: `install/sunrise-cream.json`

**Interfaces:**
- Consumes: `__WSL_DISTRO__` placeholder in `profile.commandline` (replaced by `setup.sh` with the live distro name).
- Produces: `{ "scheme": {...}, "profile": {...} }` read by `setup.sh` and merged into Windows Terminal `settings.json`. Profile `name` must be `Brainstorm`; scheme `name` must be `Sunrise Cream`.

- [ ] **Step 1: Write the failing test**

Run (expected FAIL — file missing):
```bash
python3 - <<'PY'
import json
d=json.load(open('install/sunrise-cream.json'))
assert d['scheme']['name']=='Sunrise Cream'
assert d['scheme']['background']=='#FFF8F0'
assert d['profile']['name']=='Brainstorm'
assert d['profile']['colorScheme']=='Sunrise Cream'
assert '__WSL_DISTRO__' in d['profile']['commandline']
assert 'clbs-run' in d['profile']['commandline']
print('wt-source OK')
PY
```
Expected: `FileNotFoundError`.

- [ ] **Step 2: Create `install/sunrise-cream.json`**

```json
{
  "scheme": {
    "name": "Sunrise Cream",
    "background": "#FFF8F0",
    "foreground": "#4A4137",
    "cursorColor": "#E8871E",
    "selectionBackground": "#F3E1C7",
    "black": "#4A4137",
    "red": "#D6564B",
    "green": "#5E9E4A",
    "yellow": "#E8871E",
    "blue": "#3A8FB7",
    "purple": "#9A6FB0",
    "cyan": "#2FA6A6",
    "white": "#EDE4D6",
    "brightBlack": "#8A7F70",
    "brightRed": "#E4756B",
    "brightGreen": "#77B85F",
    "brightYellow": "#F2A24A",
    "brightBlue": "#57A6C9",
    "brightPurple": "#B588C6",
    "brightCyan": "#4FBDBD",
    "brightWhite": "#FFF8F0"
  },
  "profile": {
    "name": "Brainstorm",
    "commandline": "wsl.exe -d __WSL_DISTRO__ -- bash -lc ~/.local/bin/clbs-run",
    "colorScheme": "Sunrise Cream",
    "tabTitle": "🌱 Brainstorm",
    "icon": "🌱",
    "font": { "size": 13 },
    "useAcrylic": false
  }
}
```

- [ ] **Step 3: Run test to verify it passes**

Run the Step 1 Python block. Expected: `wt-source OK`.

- [ ] **Step 4: Commit**

```bash
git add install/sunrise-cream.json
git commit -m "feat: add Sunrise Cream WT scheme + Brainstorm profile source"
```

---

### Task 7: Launcher scripts `clbs` and `clbs-run`

**Files:**
- Create: `install/clbs`
- Create: `install/clbs-run`

**Interfaces:**
- Consumes: `wt.exe` (for `clbs`); `cux` or `claude` + `~/.claude/brainstorm.json` (for `clbs-run`).
- Produces: `clbs` opens the window; `clbs-run` (invoked by the WT profile) prints the banner, exports `BRAINSTORM_MODE=1`, and `exec`s the launcher. Both honor `CLBS_DRY_RUN=1` to print instead of exec (for tests).

- [ ] **Step 1: Write the failing test**

Run (expected FAIL — files missing):
```bash
CLBS_DRY_RUN=1 bash install/clbs | grep -q "wt.exe -w new -p Brainstorm" \
 && CLBS_DRY_RUN=1 bash install/clbs-run | grep -q "brainstorm.json" \
 && echo "launchers OK"
```
Expected: error (no such file).

- [ ] **Step 2: Create `install/clbs`**

```bash
#!/usr/bin/env bash
# clbs — open a fresh light-themed Brainstorm window (Windows Terminal).
set -euo pipefail

CMD=(wt.exe -w new -p Brainstorm)

if [ "${CLBS_DRY_RUN:-}" = "1" ]; then
  echo "${CMD[*]}"
  exit 0
fi

if ! command -v wt.exe >/dev/null 2>&1; then
  echo "clbs: wt.exe not found (need WSL + Windows Terminal). Launching brainstorm mode in this terminal instead." >&2
  exec "$(dirname "$0")/clbs-run"
fi

exec "${CMD[@]}"
```

- [ ] **Step 3: Create `install/clbs-run`**

```bash
#!/usr/bin/env bash
# clbs-run — runs INSIDE the Brainstorm window. Prints the banner, then execs
# Claude Code with the brainstorm overlay. cux if present, else claude.
set -euo pipefail

cd "$HOME" 2>/dev/null || true
OVERLAY="$HOME/.claude/brainstorm.json"

if command -v cux >/dev/null 2>&1; then
  LAUNCH=(cux --settings "$OVERLAY")
else
  LAUNCH=(claude --settings "$OVERLAY" --permission-mode bypassPermissions)
fi

print_banner() {
  cat <<'EOF'

    🌱  B R A I N S T O R M   S P A C E
    ────────────────────────────────────────────
    no wrong ideas here — what shall we dream up today?
    (switch language anytime:  /jp  ·  /en )

EOF
}

if [ "${CLBS_DRY_RUN:-}" = "1" ]; then
  print_banner
  echo "would exec: BRAINSTORM_MODE=1 ${LAUNCH[*]}"
  exit 0
fi

print_banner
export BRAINSTORM_MODE=1
exec "${LAUNCH[@]}"
```

- [ ] **Step 4: Make them executable**

```bash
chmod +x install/clbs install/clbs-run
```

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
bash -n install/clbs && bash -n install/clbs-run && echo "syntax OK"
CLBS_DRY_RUN=1 bash install/clbs | grep -q "wt.exe -w new -p Brainstorm" && echo "clbs OK"
CLBS_DRY_RUN=1 bash install/clbs-run | grep -q "brainstorm.json" && echo "clbs-run OK"
CLBS_DRY_RUN=1 bash install/clbs-run | grep -q "no wrong ideas" && echo "banner OK"
```
Expected: `syntax OK`, `clbs OK`, `clbs-run OK`, `banner OK`.

- [ ] **Step 6: Commit**

```bash
git add install/clbs install/clbs-run
git commit -m "feat: add clbs + clbs-run launcher scripts (dry-run testable)"
```

---

### Task 8: Idempotent installer `setup.sh`

**Files:**
- Create: `install/setup.sh`

**Interfaces:**
- Consumes: all `install/*` files + `plugins/brainstorm-harness/statusline/brainstorm-statusline.sh`. Env overrides for testing: `TT_CLAUDE_DIR`, `TT_BIN_DIR`, `TT_WT_SETTINGS`, `TT_WSL_DISTRO`.
- Produces: installs `clbs`/`clbs-run` to `$BIN_DIR`, `brainstorm-statusline.sh` + resolved `brainstorm.json` to `$CLAUDE_DIR`, and merges the Sunrise Cream scheme + Brainstorm profile into Windows Terminal `settings.json` (idempotently). Never touches `~/.claude/settings.json`.

- [ ] **Step 1: Write the failing integration test**

Create `install/test-setup.sh` (a throwaway harness we keep for regression):
```bash
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
```
Run (expected FAIL — `setup.sh` missing):
```bash
chmod +x install/test-setup.sh && bash install/test-setup.sh
```
Expected: failure referencing missing `install/setup.sh`.

- [ ] **Step 2: Create `install/setup.sh`**

```bash
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
```

- [ ] **Step 3: Make it executable**

```bash
chmod +x install/setup.sh
```

- [ ] **Step 4: Run the integration test to verify it passes**

Run:
```bash
bash -n install/setup.sh && echo "syntax OK"
bash install/test-setup.sh
```
Expected: `syntax OK` then `setup integration OK`.

- [ ] **Step 5: Commit**

```bash
git add install/setup.sh install/test-setup.sh
git commit -m "feat: add idempotent setup.sh + integration test (python3 merge)"
```

---

### Task 9: README + final verification

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: nothing (docs).
- Produces: install steps, friend flow, and the explicit plugin-vs-setup tradeoff.

- [ ] **Step 1: Write the failing check**

Run (expected FAIL — file missing):
```bash
grep -q "plugin marketplace add" README.md \
 && grep -q "setup.sh" README.md \
 && grep -qi "does NOT" README.md \
 && echo "readme OK"
```
Expected: error (no such file).

- [ ] **Step 2: Create `README.md`**

````markdown
# tech-teku-toolkit 🌱

Hikaru's toolkit of Claude Code **harness** plugins, distributed as one marketplace.

## Plugins

### brainstorm-harness
Opens an independent, **light-themed** Windows Terminal window running a cheerful
"brainstorm mode" Claude Code: light theme, bypass permissions, a curated set of
ideation skills, a warm startup banner, and an EN/JP language toggle.

**Three ways to open it**
- Type `clbs` in any terminal
- Pick the **Brainstorm** profile from Windows Terminal's `+` menu
- Run `/clbs` from inside Claude Code

## Install (your machine or a friend's)

```
/plugin marketplace add <owner>/tech-teku-toolkit
/plugin install brainstorm-harness@tech-teku-toolkit
```

Then clone this repo (or use the marketplace cache) and run the one-time setup:

```
git clone https://github.com/<owner>/tech-teku-toolkit
cd tech-teku-toolkit
bash install/setup.sh
```

## What the plugin can and can't carry

The plugin **does** ship: the `/clbs` `/en` `/jp` commands, the brainstorm
SessionStart greeting, and the statusline — these activate on `install`.

The plugin **does NOT** ship (a plugin can't): the terminal window color, the
light theme, bypass permissions, or the `clbs` launcher. Those are host/user
settings, so **`install/setup.sh` applies them once per machine**:
- adds the *Sunrise Cream* scheme + *Brainstorm* profile to Windows Terminal
- installs `clbs` / `clbs-run` into `~/.local/bin`
- writes the `~/.claude/brainstorm.json` overlay (it never edits your global settings)

## Requirements

- WSL2 + Windows Terminal (for the independent light window). On other hosts,
  `setup.sh` skips the window step; the overlay + skills still work.
- `python3` (used by `setup.sh`; no `jq` needed).
- `cux` optional — falls back to `claude`.

## Notes

- `theme: "light"` isn't officially documented; if `/config` rejects it, edit
  `~/.claude/brainstorm.json` (`light-daltonized` or `auto` also work — the
  window itself is already light).
- bypass permissions applies **only** to the brainstorm window.

_Design + rationale: `plugins/brainstorm-harness/docs/superpowers/`._
````

- [ ] **Step 3: Run the check to verify it passes**

Run the Step 1 command. Expected: `readme OK`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add README (install, friend flow, plugin-vs-setup tradeoff)"
```

- [ ] **Step 5: Final end-to-end verification (manual, real machine)**

This can't be scripted — do it once after the tasks above:
```bash
bash install/setup.sh
clbs
```
Confirm, in the new window:
1. A new **light** (Sunrise Cream) Windows Terminal window opened.
2. The 🌱 banner printed before Claude Code started.
3. `/config` shows theme is light (if it rejected `light`, edit the overlay per Notes).
4. `/status` (or the statusline) shows the 🌱 brainstorm line.
5. Bypass is active (no permission prompts); Claude greets in English; `/jp` switches to Japanese, `/en` back.
6. Re-run `bash install/setup.sh` — Windows Terminal still has exactly one Brainstorm profile / Sunrise Cream scheme (idempotent).

---

## Self-Review

**1. Spec coverage:**
- 3 entry points → `/clbs` (Task 2), `clbs` + WT profile (Tasks 6/7/8). ✅
- Light appearance: WT scheme (Task 6/8), theme light (Task 5), banner via `clbs-run` (Task 7), statusline (Task 4). ✅
- EN default + `/en` `/jp` → greeting hook (Task 3) + commands (Task 2). ✅
- Curated skills → overlay `enabledPlugins` (Task 5). ✅
- Umbrella marketplace + friend flow → Task 1 + README (Task 9). ✅
- Idempotent setup + graceful non-WT + no global-settings edits + backup → Task 8. ✅
- Verify theme light / final e2e → Task 9 Step 5. ✅

**2. Placeholder scan:** Intentional, resolved-at-runtime tokens only (`__STATUSLINE_CMD__`, `__WSL_DISTRO__`, `<owner>`), each with an explicit resolver. No "TODO"/"handle edge cases"/unshown code. ✅

**3. Type/name consistency:** `Brainstorm` (profile), `Sunrise Cream` (scheme), `brainstorm-harness@tech-teku-toolkit` (plugin id), `BRAINSTORM_MODE`, `CLBS_DRY_RUN`, `TT_CLAUDE_DIR`/`TT_BIN_DIR`/`TT_WT_SETTINGS`/`TT_WSL_DISTRO`, `~/.claude/brainstorm.json`, `~/.claude/brainstorm-statusline.sh` — used identically across tasks and the integration test. ✅
