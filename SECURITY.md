# Security

## Reporting

Found a vulnerability? Open a GitHub issue on this repository (or contact the
owner privately for sensitive reports).

## What the harnesseed plugin does on your machine

- **SessionStart hook** (`plugins/harnesseed/hooks/harnesseed-nudge.sh`):
  read-only detect-and-inject. It checks for `.harnesseed/` marker files by
  walking up from the working directory (stopping at a `.git` boundary), and
  on harnessed projects reads two small JSON files to compare seed versions.
  It makes **no network calls, runs no git commands, and writes nothing** —
  it only prints context text for the session.
- **`/harnesseed:harness` skill**: runs only after you explicitly agree. It
  creates a git repository at `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/`
  (your seedling) and a `.harnesseed/leaf.json` marker in the project. It
  offers — but never applies without your consent — a `.gitignore` entry and
  an optional permission rule protecting the plugin's `blueprint/` cache.
- **No bypass modes**: harnesseed never enables `bypassPermissions` or any
  other permission-skipping configuration, and it does not modify
  `~/.claude/settings.json`.
- **No telemetry**: nothing is collected or sent anywhere.
