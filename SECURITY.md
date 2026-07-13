# Security

Harnesseed runs on users' machines — its germination hook and grow command can propose
changes to settings and project structure. Harnesseed is **tamper-evident, not tamper-proof**:
the canon ships inside a writable plugin cache, so integrity is enforced by hash checks against
your seedling's records, not by filesystem isolation. v1 never edits your host settings directly;
proposals touching `settings.json` or `CLAUDE.md` are emitted as diffs for you to apply by hand.

If you find a vulnerability, please report it privately via GitHub's
**Report a vulnerability** button (Security tab of this repository) instead of
opening a public issue. Fixes ship as new plugin versions.
