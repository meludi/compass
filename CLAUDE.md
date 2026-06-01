# CLAUDE.md — claude-workflow-starter

Rules for maintaining this repository.

## Changelog

**Always update `CHANGELOG.md` before committing.** Every commit that adds, changes, or removes a command, script, reference doc, or workflow behavior gets a changelog entry.

- Use `## vX.Y.Z — YYYY-MM-DD` headers (bump minor for new features, patch for fixes/docs)
- Sections: `### Added`, `### Changed`, `### Fixed`, `### Removed`
- Entries describe user-visible changes — what the user gains, not what files changed

## Commits

- Conventional Commit format: `feat:`, `fix:`, `docs:`, `chore:`
- No Co-Authored-By attribution

## What this repo is

A starter kit — `.claude/` is copied into user projects. Every change here is a change that ships to users.

- Commands live in `.claude/commands/`
- Reference docs live in `.claude/reference/`
- The worktree lifecycle script is `.claude/scripts/worktree.sh`
- `CHANGELOG.md` tracks versions of the starter itself, not user projects
