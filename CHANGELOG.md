# Changelog

## v1.1.0 — 2026-05-30

### Added
- `/auto-implement` — runs a confirmed plan from `.work/plans/` to PR-open without intermediate confirmation. Implements, validates, commits, pushes, opens PR — then hard-stops. Never merges. The only sanctioned exception to the `Never auto-commit` rule, gated by `feat/*` branch + worktree pre-flight checks.

### Changed
- `commands/commit.md` and `commands/ship.md` Rules — note that `/auto-implement` is the sanctioned exception to `Never auto-commit`.
- `reference/WORKFLOW.md` — new "Auto Path" entry in the top diagram and a section explaining when `/auto-implement` is the right tool and when to stay on `/implement` → `/ship`.
- `reference/HANDBOOK.md` — Command Reference table and Models table extended with `/auto-implement`.
- `reference/AUTONOMY.md` — `/auto-implement` added to the "Relationship to other commands" section; husky pre-commit interaction documented.

## v1.0.0 — 2026-05-27

Initial stable release.

### Commands
- `/setup` — project configuration + CLAUDE.md generation
- `/setup-tracker` — switch issue tracker (Linear / Jira / Azure DevOps)
- `/ideate` — brain dump → PRD with incremental design approval
- `/setup-stack` — greenfield tech stack scaffolding
- `/create-stories` — PRD → stories + tracker issues
- `/worktree` — create isolated Git worktree + open Claude session
- `/context` — load rules, git state, optional spec
- `/plan-feature` — implementation plan (plan only, no code)
- `/implement` — execute plan task-by-task with type-check loop
- `/validate` — lint + type check + tests + browser smoke test
- `/commit` — stage and commit with Conventional Commit message
- `/ship` — commit → push → PR → 3-agent parallel review
- `/security-review` — security-focused code review
- `/reflect` — system evolution after merge

### Agents
- `code-reviewer` — CLAUDE.md compliance, security, performance
- `codebase-explorer` — find existing patterns before planning
- `pr-test-analyzer` — test coverage gaps and missing edge cases

### Skills
- `agent-browser` — browser automation for UI smoke tests

### Structure
- `.claude/project.yml` — single source of truth for all commands
- `.claude/scripts/worktree.sh` — full worktree lifecycle script
- `.claude/reference/` — WORKFLOW, CONCEPTS, HANDBOOK, WORKTREES, AUTONOMY
- `.work/` — PIV Loop artifacts (prds, stories, plans, reports, screenshots)
