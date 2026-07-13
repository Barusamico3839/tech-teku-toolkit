#!/usr/bin/env python3
"""Grow Stage 0 integrity gate (extracted so CI can unit-test both branches).

Usage: integrity-gate.py <blueprint-cache-dir> <seedling-dir> <plugin-root>

Exit codes:
  0  integrity OK — blueprint cache matches planted.json, checker is pinned
  3  PULL-FIRST   — installed seed version differs from the absorbed one
                    (legitimate update or rollback; grow must not run — pull first)
  2  TAMPER-STOP  — same version but content mismatch, or the roots checker
                    itself does not match planted.json (do NOT proceed)
"""
import hashlib
import json
import os
import sys


def sha256(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def main():
    bp, s, plug = sys.argv[1], sys.argv[2], sys.argv[3]
    planted = json.load(open(os.path.join(s, "planted.json")))
    cache_ver = json.load(open(os.path.join(plug, ".claude-plugin/plugin.json")))["version"]

    if cache_ver != planted["seed_version"]:
        print(f"PULL-FIRST: installed seed v{cache_ver} != absorbed "
              f"v{planted['seed_version']} — run /harnesseed:pull before growing "
              "(grow must not run against an unabsorbed canon).")
        sys.exit(3)

    walked = {}
    for dp, _, fns in os.walk(bp):
        for fn in sorted(fns):
            rel = os.path.relpath(os.path.join(dp, fn), bp)
            walked[rel] = sha256(os.path.join(dp, fn))
    if walked != planted["blueprint"]:
        print("TAMPER-STOP: plugin cache blueprint differs from planted.json at the "
              "SAME version — tamper suspected. Hard stop; reinstall the plugin. "
              "Do NOT proceed.")
        sys.exit(2)

    rel = "evals/check-invariants.sh"
    checker = os.path.join(s, "roots", rel)
    if not os.path.isfile(checker) or planted["blueprint"].get(rel) != sha256(checker):
        print("TAMPER-STOP: roots checker does not match planted.json — do not run it.")
        sys.exit(2)

    print(f"integrity OK (seed v{cache_ver}; blueprint matches planted; checker pinned)")


main()
