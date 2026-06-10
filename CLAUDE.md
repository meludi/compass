# CLAUDE.md — compass

Rules for maintaining this repository.

## Changelog

**Always update `CHANGELOG.md` before committing.** Every commit that adds, changes, or removes a command, script, reference doc, or workflow behavior gets a changelog entry.

- Sections: `### Added`, `### Changed`, `### Fixed`, `### Removed`
- Entries describe user-visible changes — what the user gains, not what files changed

## Commits & Tags

Conventional Commit format — drives versioning:

| Commit type | Version bump | Tag? |
|---|---|---|
| `feat:` | Minor (`0.2.0` → `0.3.0`) | Yes |
| `fix:` | Patch (`0.2.0` → `0.2.1`) | Yes |
| `feat!:` / `BREAKING CHANGE:` | Minor while pre-1.0 (`0.x`) | Yes |
| `docs:`, `chore:`, `refactor:` | none | No |

We restarted at `0.x` for the plugin migration; `1.0.0` is the first stable release. While on `0.x`, breaking changes bump the minor.

- Before a release commit, run `bash scripts/selftest.sh` — a read-only static dry-run (manifests, template YAML, config-vs-schema, doc links, shell syntax, inventory). It must exit 0. It does not replace the manual `TESTING.md` run; it catches the breakage that doesn't need a human.
- No Co-Authored-By attribution
- The version lives in **`.claude-plugin/plugin.json`** (`version` field) — that is what `/plugin` and the marketplace show. On a release (`feat:`/`fix:`/breaking), bump `plugin.json` `version` **together with** the CHANGELOG entry, in the same commit. There is no standalone `VERSION` file.
- Tag on the last commit of the release (after CHANGELOG + `plugin.json` bump), then push:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

## What this repo is

A **Claude Code plugin** — the repo root *is* the plugin root, installed (not copied) into user projects via the marketplace. Every change here ships to users on plugin update.

- Manifest: `.claude-plugin/plugin.json`; catalog: `.claude-plugin/marketplace.json`
- Commands live in `commands/` → invoked as `/compass:<name>`
- Agents in `agents/`, skills in `skills/`
- Reference docs in `references/`
- The worktree lifecycle script is `scripts/worktree.sh`; the shared config reader is `scripts/read-config.sh`; the static dry-run/self-test is `scripts/selftest.sh`
- Always-on guidance is the `SessionStart` hook (`hooks/hooks.json` → `hooks/session-start.sh`) — a plugin `CLAUDE.md` is **not** loaded by Claude Code, so guidance must come via the hook
- Bundled files referenced from commands/scripts use `${CLAUDE_PLUGIN_ROOT}/…`; user-project files use `${CLAUDE_PROJECT_DIR}/…` (or stay relative in command prose, where CWD is the project)
- `CHANGELOG.md` tracks versions of the plugin itself, not user projects
