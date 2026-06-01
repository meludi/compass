# CLAUDE.md — claude-workflow-starter

Rules for maintaining this repository.

## Changelog

**Always update `CHANGELOG.md` before committing.** Every commit that adds, changes, or removes a command, script, reference doc, or workflow behavior gets a changelog entry.

- Sections: `### Added`, `### Changed`, `### Fixed`, `### Removed`
- Entries describe user-visible changes — what the user gains, not what files changed

## Commits & Tags

Conventional Commit format — drives versioning:

| Commit type | Version bump | Tag? |
|---|---|---|
| `feat:` | Minor (`1.2.0` → `1.3.0`) | Yes |
| `fix:` | Patch (`1.2.0` → `1.2.1`) | Yes |
| `feat!:` / `BREAKING CHANGE:` | Major (`1.2.0` → `2.0.0`) | Yes |
| `docs:`, `chore:`, `refactor:` | none | No |

- No Co-Authored-By attribution
- Tag on the last commit of the release (after CHANGELOG update), then push:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

## What this repo is

A starter kit — `.claude/` is copied into user projects. Every change here is a change that ships to users.

- Commands live in `.claude/commands/`
- Reference docs live in `.claude/reference/`
- The worktree lifecycle script is `.claude/scripts/worktree.sh`
- `CHANGELOG.md` tracks versions of the starter itself, not user projects
