# Command Reference

Single source for every `/compass:*` command. For the flow (in what order to run them)
see `WORKFLOW.md`. For the full operational spec Claude reads, see `commands/<name>.md`.

---

## Setup & onboarding

### /compass:setup

Configures the project — generates `.claude/compass.yml`, `compass.schema.json`, and
`.claude/CLAUDE.md` from the plugin templates. Runs in two phases; same command both times.

| | |
|---|---|
| **Level** | Once |
| **Recommended model** | Sonnet |
| **Trigger** | User |
|---|---|

**Phase 1** (when `compass.yml` is missing or `name` is blank): generates config, pre-fills detected commands from `package.json`. Stops — fill in `name` and other blanks, then re-run.

**Phase 2** (when `name` has a value): validates `compass.yml` against the schema, generates `.claude/CLAUDE.md`.

---

### /compass:onboard

Self-contained brownfield onboarding — bootstraps `compass.yml` if missing, then scans
the codebase and fills `CLAUDE.md` with real patterns (Architecture, Code Patterns,
Testing, Key Files). No prior `/compass:setup` needed.

| | |
|---|---|
| **Level** | Once (brownfield) |
| **Recommended model** | Opus |
| **Argument** | `[--refresh]` — optional |
| **Trigger** | User |
|---|---|

**Phase 1** (when `compass.yml` missing or `name` blank): copies template, auto-detects commands/repo/branch. Stops — fill in `name` and other blanks, then re-run.

**Phase 2** (when `name` set): validates `compass.yml`, generates `CLAUDE.md` if absent.

**Phase 3** (scan): reads the codebase and fills Architecture, Code Patterns, Testing, Key Files.

**With `--refresh`:** skips Phases 1–2, re-runs the scan and overwrites the scanned sections — use when `CLAUDE.md` has drifted.

**When to run:** on any existing project with source code. Not for greenfield — use `/compass:setup-stack` instead.

---

### /compass:setup-stack

Scaffolds the tech stack for a blank project — framework, tooling, seed files, a
visible welcome screen, a first smoke test, the CI workflow, and CLAUDE.md Code Patterns.

| | |
|---|---|
| **Level** | Once (greenfield only) |
| **Recommended model** | Sonnet |
| **Argument** | `[path to .work/prds/*.prd.md]` — optional |
| **Trigger** | User |
|---|---|

**Without argument:** asks for framework and package manager interactively.

**With argument:** extracts tech hints from the PRD's `## Technical notes` section to pre-select the framework.

Has a brownfield guard — warns and stops if `src/` already has more than 3 entries.

---

### /compass:setup-tracker

Switches the issue tracker. Rewrites `.mcp.json`, the `tracker_*_tool` fields in
`compass.yml`, and `settings.local.json`. No command files are touched.

| | |
|---|---|
| **Level** | Once (optional) |
| **Recommended model** | Sonnet |
| **Trigger** | User |
|---|---|

Supported: Linear (preconfigured), Jira (Atlassian official), Jira (community),
Azure DevOps (remote), Azure DevOps (local). See `README.md` for the full table.

---

## Initiative

### /compass:ideate

Structured brain dump → PRD. Asks clarifying questions one at a time, proposes 2–3
approaches, writes a self-reviewed PRD to `.work/prds/`. No code written.

| | |
|---|---|
| **Level** | Initiative |
| **Recommended model** | Opus |
| **Plan Mode** | Yes |
| **Argument** | `<initiative name>` — required |
| **Trigger** | User |
|---|---|

---

### /compass:create-stories

Breaks a PRD into user stories → `.work/stories/`. Optionally creates tracker issues
if a tracker is configured (`tracker ≠ none` in `compass.yml`).

| | |
|---|---|
| **Level** | Initiative |
| **Recommended model** | Sonnet |
| **Argument** | `[path to .work/prds/*.prd.md]` — optional |
| **Trigger** | User |
|---|---|

**Without argument:** uses the most recent PRD in `.work/prds/`, or the one already loaded in session.

**With argument:** reads that specific PRD file.

If no tracker is configured, stories are saved locally only — the command ends cleanly without prompting for credentials.

---

## PIV loop

### /compass:worktree

Creates an isolated worktree on `feat/<name>`, installs dependencies, and opens a
fresh Claude session inside it. All PIV steps run in that session.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Haiku |
| **Argument** | `<feature-name>` — required |
| **Trigger** | User |
|---|---|

The feature name becomes the branch: `feat/<name>`. Use a short slug (e.g. `add-auth`). Detail on isolation, hooks, recipes: `WORKTREES.md`.

---

### /compass:context

Loads the project mental model — rules, git state, existing plan/report — and
optionally a spec.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet |
| **Argument** | `[story \| issue-id \| "description"]` — optional |
| **Trigger** | Auto (step 1 of `plan-feature` + `implement`) or User |
| **Used in** | `/compass:plan-feature` (inline), `/compass:implement` (inline) |
|---|---|

**Without argument:** reloads project rules + git state only. No spec loaded.

**With argument:**
- `.work/stories/story.md` → reads the story file
- `PROJ-42` → fetches from tracker via `tracker_get_issue_tool` from `compass.yml`
- `"description"` → uses the text directly as spec

**When to run standalone:** mid-story resume, stale session, before `/compass:reflect`, or to debug missing context.

---

### /compass:plan-feature

Loads context, then writes a concrete implementation plan to `.work/plans/`.
**Plan only — no code written.**

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Plan Mode** | Yes |
| **Argument** | `<story \| issue-id \| "description">` — required |
| **Trigger** | User |
| **Uses** | `/compass:context` (inline) |
|---|---|

If a complete plan already exists for this story, reports status and recommends `/compass:implement` instead of re-planning.

Pass a free-text description to skip the story file entirely (useful for single tasks without an initiative).

---

### /compass:implement

Executes the plan task by task — type-check gate after each task, then the full
validation suite. Folds in `/compass:validate` (including browser smoke test).

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet |
| **Argument** | `<path to .work/plans/*.plan.md>` — required |
| **Trigger** | User |
| **Uses** | `/compass:context` (inline), `/compass:validate` (inline) |
|---|---|

For logic-bearing tasks: writes a test per `test_policy` in `.claude/compass.yml` — `first` (test-first, RED → GREEN, default), `after` (test-after), or `none` (no forced test). For UI/glue/config tasks: type-check gate only.

---

### /compass:auto-implement

Runs the full pipeline without confirmation — implement → validate → commit → push →
open PR. Hard-stops at PR-open; **never merges**.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet |
| **Argument** | `<path to .work/plans/*.plan.md>` — required |
| **Trigger** | User |
| **Uses** | `/compass:context` (inline), `/compass:validate` (inline), `/compass:commit` (inline) |
|---|---|

Pre-flight checks gate it: `feat/*` branch, inside a worktree, `gh` installed, clean working tree, plan exists.

**Not for:** DB migrations, auth changes, or first use of a new pattern. Use `/compass:implement` → `/compass:ship` instead.

---

### /compass:validate

Runs lint → type-check → tests → browser smoke test. Mirrors the CI `test` job.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet |
| **Trigger** | Auto (end of `implement`) or User |
| **Used in** | `/compass:implement` (inline), `/compass:auto-implement` (inline), `/compass:review-code` (after `--fix`), `/compass:review-project` (after `--fix`), `/compass:review-security` (after `--fix`), `/compass:fix-ci-review` |
|---|---|

**When to run standalone:** before `/compass:ship`, to debug a failing check, after a manual fix, or mid-implementation to confirm a previous task didn't break anything.

---

### /compass:commit

Stages and commits with a Conventional Commit message. Always shows state and draft message, waits for confirmation. After committing, asks whether to push.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Haiku |
| **Argument** | `[--push]` — optional |
| **Trigger** | Auto (inside `ship`) or User |
| **Used in** | `/compass:auto-implement` (inline), `/compass:ship` |
|---|---|

**Without `--push`:** commits, then asks "Push to origin now?".

**With `--push`:** commits and pushes without the question.

**When to run standalone:** WIP checkpoint, multiple commits per story, or Fix-Loop publish step.

---

### /compass:ship

Closes the PIV loop — reads the implementation report, commits, pushes, opens a PR,
and offers the parallel code review. Pre-flight: checks `gh` is installed before committing.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Trigger** | User |
| **Uses** | `/compass:commit`, `/compass:review-project` |
|---|---|

Folds in: `/compass:commit`, `/compass:review-project`, `/compass:review-security` (on risky diffs).

---

## Review & fix

### /compass:review-project

3-subagent parallel review — your `CLAUDE.md` conventions, pattern reuse,
test-coverage gaps. Advisory by default; `--fix` applies findings.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Argument** | `[--fix] [PR-number]` — optional |
| **Trigger** | Auto (inside `ship`) or User |
| **Uses** | `/compass:review-security` (conditional — risky diffs only) |
| **Used in** | `/compass:ship` |
|---|---|

**Without argument:** uses the current branch's PR (inferred) or falls back to `git diff {base_branch}...HEAD`.

**With argument:** reviews that specific PR number.

**With `--fix`:** applies Critical and Important findings — if any were applied, runs `/compass:validate`. Never auto-commits.

**When to run standalone:** before shipping, for re-reviews after addressing feedback, for external/contributed PRs, or after a manual push.

**vs. `/compass:review-code`:** this command checks your project conventions and test coverage. `/compass:review-code` is a deep generic bug hunt with tunable effort.

---

### /compass:review-code

Deep bug hunt with a tunable effort dial. Wraps the built-in `/code-review` with
compass-specific follow-up: after `--fix`, automatically runs `/compass:validate`.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet (low–high) / Opus cloud (ultra) |
| **Argument** | `[low\|medium\|high\|max\|ultra] [--fix] [--comment] [PR-number]` — optional |
| **Trigger** | User |
| **Uses** | `/code-review` (built-in), `/compass:validate` (after `--fix`) |
|---|---|

**Without flags:** advisory — findings shown inline, nothing applied.

**With `--fix`:** applies fixes in the working tree — if any were applied, runs `/compass:validate`. Never auto-commits.

**With `--comment`:** posts findings as inline PR comments on GitHub instead of showing them in chat.

| Level | Cost | Use for |
|---|---|---|
| `low` / `medium` | cheap | Small diffs, quick pre-ship pass |
| `high` | moderate | Normal feature work |
| `max` | high | Risky changes |
| `ultra` | highest (cloud) | DB migrations, auth, large refactors |

**Default level:** inherits the session's current effort — set it with `/effort low|medium|high|xhigh`. Pass a level explicitly to override for a single run.

---

### /compass:fix-ci-review

Pulls the CI `claude-review` inline comments from the open PR and applies the fixes
locally, then runs `/compass:validate`. Stops before commit.

| | |
|---|---|
| **Level** | PIV (Fix) |
| **Recommended model** | Opus |
| **Argument** | `[PR-number]` — optional |
| **Trigger** | User |
| **Uses** | `/compass:validate` |
|---|---|

**Without argument:** infers the PR from the current branch.

**With argument:** uses that specific PR number.

**When to use:** in `review-only`/`full` mode — the CI already reviewed the diff, so re-reviewing with `/compass:review-code` would be redundant. In `off` mode or before the PR exists, use `/compass:review-code --fix` instead.

---

### /compass:review-security

Security-focused review — injection, auth, data exposure, secrets. Advisory by default;
`--fix` applies findings. Defaults to staged changes if no argument given.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Argument** | `[--fix] [file-or-directory]` — optional |
| **Trigger** | Auto (inside `ship` on risky diffs) or User |
| **Used in** | `/compass:review-project` (conditional) |
|---|---|

**Without argument:** reviews staged `git diff --cached`, or unstaged `git diff` if nothing is staged.

**With argument:** reviews those paths specifically (e.g. `src/api/auth.ts`).

**With `--fix`:** applies Critical and High findings — if any were applied, runs `/compass:validate`. Never auto-commits.

**When to run standalone:** before shipping when you touched sensitive code, for a targeted file/directory audit, or to review external/vendored code.

---

## System

### /compass:reflect

Captures learnings and evolves the system — updates `CLAUDE.md` rules, command files,
and reference docs based on what went wrong or right.

| | |
|---|---|
| **Level** | Anytime |
| **Recommended model** | Sonnet |
| **Trigger** | User |
|---|---|

**When to run:** after a merge, after a frustrating session, after a bug, or periodically to keep `CLAUDE.md` and commands aligned with how the project has evolved.
