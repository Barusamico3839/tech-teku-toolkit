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
- If `wt.exe` runs but errors because the **Brainstorm** profile doesn't exist, tell the user to run `install/setup.sh` from the repo checkout first — that's the host-side step that installs the profile (a plugin install alone doesn't add it).
Do not do anything else.
