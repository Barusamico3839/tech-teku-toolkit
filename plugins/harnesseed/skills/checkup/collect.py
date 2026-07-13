#!/usr/bin/env python3
"""Read-only fact collector for /harnesseed:checkup.

Usage: collect.py <config-dir> [project-dir]

Prints a JSON summary of the harness environment: key NAMES, counts and
booleans only — never configuration values (no env vars, no tokens, no
command strings). Missing or broken files are reported, never crash.
"""
import json
import os
import sys


def load_json(path):
    """-> (exists, parse_ok, data|None)"""
    if not os.path.isfile(path):
        return False, False, None
    try:
        with open(path) as f:
            return True, True, json.load(f)
    except Exception:
        return True, False, None


def collect(cfg, proj):
    out = {}

    exists, ok, settings = load_json(os.path.join(cfg, "settings.json"))
    s = {"exists": exists, "parse_ok": ok,
         "permission_rules": {"allow": 0, "deny": 0, "ask": 0},
         "enabled_plugins": 0, "disabled_plugins": 0,
         "hooks_events": [], "output_style": None, "model": None}
    if ok and isinstance(settings, dict):
        perms = settings.get("permissions")
        perms = perms if isinstance(perms, dict) else {}
        for k in ("allow", "deny", "ask"):
            v = perms.get(k)
            s["permission_rules"][k] = len(v) if isinstance(v, list) else 0
        ep = settings.get("enabledPlugins") or {}
        if isinstance(ep, dict):
            s["enabled_plugins"] = sum(1 for v in ep.values() if v)
            s["disabled_plugins"] = sum(1 for v in ep.values() if not v)
        hooks = settings.get("hooks") or {}
        if isinstance(hooks, dict):
            s["hooks_events"] = sorted(hooks.keys())
        s["output_style"] = settings.get("outputStyle")
        s["model"] = settings.get("model") if isinstance(settings.get("model"), str) else None
    out["settings"] = s

    _, ok, installed = load_json(os.path.join(cfg, "plugins", "installed_plugins.json"))
    n_installed = len(installed.get("plugins", {})) if ok and isinstance(installed, dict) else 0
    mkt_dir = os.path.join(cfg, "plugins", "marketplaces")
    markets = sorted(d for d in os.listdir(mkt_dir)
                     if os.path.isdir(os.path.join(mkt_dir, d))) if os.path.isdir(mkt_dir) else []
    out["plugins"] = {"installed": n_installed, "marketplaces": markets}

    out["mcp"] = {"user_file": os.path.isfile(os.path.join(cfg, ".mcp.json")),
                  "project_file": bool(proj) and os.path.isfile(os.path.join(proj, ".mcp.json"))}
    out["claude_md"] = {"global": os.path.isfile(os.path.join(cfg, "CLAUDE.md")),
                        "project": bool(proj) and os.path.isfile(os.path.join(proj, "CLAUDE.md"))}

    skills_dir = os.path.join(cfg, "skills")
    out["skills_dirs"] = (sum(1 for d in os.listdir(skills_dir)
                              if os.path.isdir(os.path.join(skills_dir, d)))
                          if os.path.isdir(skills_dir) else 0)
    out["workflows"] = {"dir_exists": os.path.isdir(os.path.join(cfg, "workflows"))}
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cfg = sys.argv[1]
    proj = sys.argv[2] if len(sys.argv) > 2 else None
    print(json.dumps(collect(cfg, proj), ensure_ascii=False, indent=1))


main()
