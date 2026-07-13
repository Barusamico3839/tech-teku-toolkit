#!/usr/bin/env python3
"""Deterministic guardian of the seedling's trend-stock ledger (index.json).

Commands:
  known <index.json>                  print JSON array of known entries (dedup view)
  append <index.json> <entry.json>    validate + append a NEW entry
  set-status <index.json> <id> <st>   update ONLY the status field of an entry

Rules (spec: docs/specs/2026-07-13-harnesseed-v1-design.md section 5/7):
entry set only grows; existing entries are immutable except `status`;
`rejected` requires reason/maturity/evidence; `supersedes` must reference an
existing id; statuses are exactly bundled|adopted|rejected|deferred.
"""
import json
import sys

STATUSES = {"bundled", "adopted", "rejected", "deferred"}
REQUIRED = {"id", "title", "status", "source", "registered_at"}
REJECTED_REQUIRED = {"reason", "maturity", "evidence"}


def load(path):
    with open(path) as f:
        return json.load(f)


def save(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def cmd_known(path):
    view = []
    for e in load(path)["entries"]:
        item = {"id": e["id"], "status": e["status"]}
        for k in ("maturity", "registered_at", "supersedes"):
            if k in e:
                item[k] = e[k]
        view.append(item)
    print(json.dumps(view, ensure_ascii=False))


def cmd_append(path, entry_path):
    data = load(path)
    entry = load(entry_path)
    missing = REQUIRED - set(entry)
    if missing:
        sys.exit(f"append rejected: missing fields {sorted(missing)}")
    if entry["status"] not in STATUSES:
        sys.exit(f"append rejected: bad status {entry['status']!r}")
    if entry["status"] == "rejected":
        rmissing = REJECTED_REQUIRED - set(entry)
        if rmissing:
            sys.exit(f"append rejected: rejected entry missing {sorted(rmissing)}")
    ids = {e["id"] for e in data["entries"]}
    if entry["id"] in ids:
        sys.exit(f"append rejected: id {entry['id']!r} already exists "
                 "(existing entries are immutable; supersede with a new id)")
    if "supersedes" in entry and entry["supersedes"] not in ids:
        sys.exit(f"append rejected: supersedes unknown id {entry['supersedes']!r}")
    data["entries"].append(entry)
    save(path, data)
    print(f"appended {entry['id']} ({entry['status']})")


def cmd_set_status(path, eid, status):
    if status not in STATUSES:
        sys.exit(f"set-status rejected: bad status {status!r}")
    data = load(path)
    for e in data["entries"]:
        if e["id"] == eid:
            old = e["status"]
            e["status"] = status
            save(path, data)
            print(f"{eid}: {old} -> {status}")
            return
    sys.exit(f"set-status rejected: unknown id {eid!r}")


def main():
    argv = sys.argv
    if len(argv) == 3 and argv[1] == "known":
        cmd_known(argv[2])
    elif len(argv) == 4 and argv[1] == "append":
        cmd_append(argv[2], argv[3])
    elif len(argv) == 5 and argv[1] == "set-status":
        cmd_set_status(argv[2], argv[3], argv[4])
    else:
        sys.exit(__doc__)


main()
