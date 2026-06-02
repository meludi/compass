# Changelog

## v1.8.0 — 2026-06-02

### Added
- `.claude/project.schema.json` — JSON Schema for `project.yml` (required keys, enums, types, `owner/repo` pattern, `dev_port` integer). A `# yaml-language-server: $schema=` line in `project.yml` enables editor autocomplete + inline validation; `/setup` validates against it so a mistyped key or bad value is reported instead of silently defaulting.
- `.claude/scripts/read-config.sh` — single shared reader (`read_config <key>`) for `project.yml`, used by both `scripts/worktree.sh` (sourced) and CI (executed). Zero runtime dependencies (flat `key: value` only).

### Changed
- `scripts/worktree.sh` and `.github/workflows/pr-validation.yml` now use the shared reader instead of two separate hand-rolled `grep|cut|sed` parsers.
- `/setup` no longer embeds a duplicate `project.yml` template (which had drifted from the shipped file) — it edits the canonical shipped file in place, pre-fills command fields from `package.json`, and validates against the schema.
- `project.yml` fields grouped under comment headers (Identity / Commands / Worktrees / CI) for readability; format stays flat YAML (no nesting, no new dependency).

## v1.7.0 — 2026-06-02

### Added
- **Refactor candidates** catalogue in `reference/HANDBOOK.md` — structural smells with remediations (duplication, long method, shallow/deep modules, feature envy, primitive obsession, plus code the new change reveals as awkward). Scanned post-green by `/implement`, and referenced by the `code-reviewer` agent and `/code-review`. Surfaced in the On-Demand Context table (`CLAUDE-template.md`).

## v1.6.0 — 2026-06-02

### Added
- Test-quality guidance — new **Test quality** section in `reference/HANDBOOK.md` (behavior over implementation, public interface only, survives refactor, integration over heavy mocking), surfaced in the On-Demand Context table (`CLAUDE-template.md`) and referenced by `/plan-feature`, `/implement`, `/validate`.
- `/plan-feature` task template — optional `Behavior` line (the observable behavior to verify). Present for logic tasks, omitted for pure UI/glue/config.

### Changed
- `/implement` Step 3 now branches by task type: **logic-bearing tasks** (those with a `Behavior` line) are built **test-first** (RED → GREEN, one behavior at a time, the test is the per-task gate alongside the type check); **UI/glue/config tasks** keep the type-check-only gate. Post-green cleanup cross-links the built-in `/code-review` rather than refactoring while red.

## v1.5.0 — 2026-06-02

### Added
- `/setup-stack` now leaves a **runnable app**: it scaffolds a visible welcome screen (project name + `Button`) wired into the app entry point, adds a first smoke test for it, and ends with a **boot check** (build or briefly start the dev server) plus exact instructions to open the app in the browser.
- `ci_review_provider` (`project.yml`) — choose which LLM runs the CI PR review: `claude` (default, inline comments + checklist via `claude-code-action`, `ANTHROPIC_API_KEY`), or `openai` / `gemini` (a single `## Review Summary` comment via the provider API, `OPENAI_API_KEY` / `GEMINI_API_KEY`). New `external-review` job in `pr-validation.yml`; `auto-merge` tolerates whichever review path is skipped. The field is now a visible default in the `project.yml` template (`commands/setup.md`) next to `autonomy_mode`, which is also surfaced in the committed `project.yml`.
- `/setup-stack` Step 11 now **verifies** the matching CI secret is present (`gh secret list`) when enabling `review-only`/`full`, and warns if it's missing — instead of silently producing red checks. It still never sets the secret (interactive, handles the raw key); the user runs `gh secret set` themselves.
- Commit checkpoints — `/implement`, `/validate`, and `/setup-stack` now suggest a `/commit` when the working tree is a consistent, one-sentence-describable unit. Suggestion only; nothing auto-commits. Documented as a convention in `reference/HANDBOOK.md`.
- `.claude/VERSION` — plaintext starter version that ships with the copied `.claude/`, so a project can tell which starter version it is on (CHANGELOG and git tags don't travel with the copy). Release process (`CLAUDE.md`) now bumps it alongside the CHANGELOG and tag.

### Changed
- Model recommendation in every command normalized to a single `> **Model:** /model <alias>` callout right under the title, using stable aliases (no version numbers) so it never goes stale; `reference/HANDBOOK.md` model table updated to Opus 4.8.
- `reference/AUTONOMY.md`, `reference/HANDBOOK.md`, `TESTING.md`, `commands/setup-stack.md`, `README.md` — document the review-provider choice and the matching GitHub secret per provider (incl. the README "CI & autonomy" note that an LLM-backed CI review requires the key as a GitHub secret).

## v1.4.0 — 2026-06-02

### Added
- `install_cmd` (`project.yml`) — custom install command for any stack (e.g. `uv sync`, `poetry install`, `go mod download`); overrides the package-manager install in `worktree.sh`. JS projects leave it blank.
- `worktree_setup_cmd` / `worktree_teardown_cmd` (`project.yml`) — per-worktree isolation hooks run by `worktree.sh` on create (after install) / before removal, with `WT_NAME` / `WT_DIR` / `WT_BRANCH` / `WT_PORT` exported. Enables server-DB isolation (Postgres/MySQL) that the `db_file` copy can't cover.
- `reference/WORKTREES.md` — "Isolation scope" section: what worktrees isolate automatically (dir/branch/port, file DB) vs what needs hooks (server DB, non-JS), with a security note; plus copy-paste **Recipes** for Payload CMS + MongoDB, Python + Postgres, Docker Compose, and a non-JS install-only stack.
- `TESTING.md` (repo root) — maintainer self-test covering all four workflow flows (Stage 0 Setup, Loop 1 PIV, Loop 2 Fix in both `off` and `review-only` modes, Quick Path) plus the guarded worktree lifecycle, run against a throwaway sandbox repo. Stack-agnostic; not shipped via `.claude/`.

### Changed
- `scripts/worktree.sh` — `read_yml` now strips only a trailing ` # comment` and one surrounding quote pair, **preserving internal quotes** so command values (`install_cmd`, hooks) survive intact (also a more robust fix for the earlier comment-pollution issue).
- `commands/setup.md`, `project.yml` — document the new fields (with a commented Postgres example).
- `reference/CONCEPTS.md` — the "DB races" blocker now notes the setup hook for server DBs.

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
