#!/usr/bin/env bash
# Claude Code pipes a session JSON blob on stdin; we drain and ignore it to
# avoid any parser dependency. Output must be a single line.
cat >/dev/null 2>&1 || true
printf '🌱 brainstorm mode  ·  no wrong ideas — dream big ✨'
