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

The plugin **does** ship: the `/clbs` `/en` `/jp` commands and the brainstorm
SessionStart greeting — these activate on `install`. The statusline script
rides along in the plugin too, but plugins can't auto-enable statuslines —
it lights up via the `~/.claude/brainstorm.json` overlay that `setup.sh` writes.

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
