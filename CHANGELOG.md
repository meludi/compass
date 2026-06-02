# Changelog

## v1.3.0 — 2026-06-02

### Added
- `/apply-ci-review` — new Fix-loop command: pulls the CI `claude-review` comments from the PR and applies the fixes **locally**, then runs `/validate`. Stops before commit (no auto-commit); the human commits and pushes. The non-redundant fix path in `review-only` / `full`.
- CI `claude-review` now posts a single `## Review Summary` comment on the PR alongside its inline comments — finding count plus a verbatim reminder that findings are fixed locally, never by CI.
- `reference/AUTONOMY.md` — at-a-glance mode-comparison matrix (off / review-only / full) covering CI jobs, who reviews/fixes/merges, cost, risk, and suitability; plus notes on no-API-key behaviour and draft-PR exclusion. New "Fixing review findings (the Fix Loop)" section covering both fix entry paths (local pre-PR, CI post-PR).
- `reference/HANDBOOK.md` — "`/review` vs `/code-review` — and choosing an effort level" section (effort recommendation table); `/apply-ci-review` added to the command table with standalone guidance.

### Changed
- `scripts/worktree.sh` — `rm` is now **guarded**: it refuses (and changes nothing) on uncommitted changes, on commits not merged into `base_branch` (with a pushed-vs-local-only note), or when run from inside the target worktree. `-f`/`--force` overrides; deletion uses safe `git branch -d` unless forced. Documented as `/worktree <name> rm` in `commands/worktree.md`.
- `reference/WORKFLOW.md` — rewritten as the canonical map around four phases: **Setup** (once) · **PIV Loop** · **Fix Loop** · **autonomy axis**. The Fix Loop (review → fix → validate → commit → push → repeat) is now a first-class section with a reviewer / fix-path decision tree and an `off` vs `review-only` side-by-side.
- `reference/` docs de-duplicated to single-source each concept: glossary + logical flow → HANDBOOK; 10x / parallel development → CONCEPTS; command flow → WORKFLOW; autonomy modes → AUTONOMY. Removed duplicated representations — AUTONOMY's intro mode-table (the matrix covers it), WORKFLOW's autonomy re-explanation (folded into the Fix-loop mode contrast), the CONCEPTS logical-flow stub, the HANDBOOK parallel-dev block, and the WORKTREES VS Code + repeated port explanations.

### Fixed
- `scripts/worktree.sh` — `project.yml` field parsing now strips inline comments. Previously a commented field (e.g. `package_manager: pnpm  # ...`) was read with the comment attached, silently falling back to `npm` and mis-reading `dev_port` / `db_file` / `dev_cmd`.

## v1.2.0 — 2026-06-01

### Added
- `/review` — standalone parallel code review command (3 subagents: code-reviewer, pr-test-analyzer, codebase-explorer). Works with or without an open PR: falls back to `git diff {base_branch}...HEAD` when no PR exists. `/ship` now delegates to `/review` instead of duplicating the logic.
- `CLAUDE.md` — maintainer rules for this repo (changelog discipline, commit format, project context).
- Per-worktree dev server ports: `worktree.sh` now assigns each worktree a unique port (`dev_port + N`), writes it to `.worktree-port`, and prints the ready-to-use start command after setup.
- `.worktree-port` added to `.gitignore`.

### Changed
- `README.md` — Setup section now includes `git clone` step and `.mcp.json` copy; directory tree updated with `AUTONOMY.md`, `templates/`, `.github/workflows/`, and `.mcp.json`.
- `commands/ship.md` — steps 6–9 (subagent fan-out, aggregation, security check, verdict) removed; step 5 now delegates to `/review`. `/clear` hint added to the review prompt.
- `commands/worktree.md` — updated Notes and "After the session opens" to reflect per-worktree port and editor hint.
- `reference/WORKTREES.md` — corrected "Dev server runs from main only" rule; added "Dev Server per Worktree" section and port table.
- `reference/WORKFLOW.md` — `/review` added as standalone step 4b; `/ship` includes entry updated.
- `reference/HANDBOOK.md` — `/review` added to command table and Models table; "When to run `/review` standalone" section added; troubleshooting entry updated.
- `scripts/worktree.sh` — reads `dev_port` and `dev_cmd` from `project.yml`; port assignment and `.worktree-port` write added.

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
