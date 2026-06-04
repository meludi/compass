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

**Phase 1** (when `compass.yml` is missing or `name` is blank): generates config, pre-fills detected commands from `package.json`. Stops — fill in `name` and other blanks, then re-run.

**Phase 2** (when `name` has a value): validates `compass.yml` against the schema, generates `.claude/CLAUDE.md`.

---

### /compass:onboard

Scans an existing codebase and fills the sections `/compass:setup` leaves as TODO —
Architecture, Code Patterns, Testing, Key Files.

| | |
|---|---|
| **Level** | Once (brownfield) |
| **Recommended model** | Opus |
| **Argument** | `[--refresh]` — optional |
| **Trigger** | User |

**Without argument:** fills empty/TODO sections for the first time.

**With `--refresh`:** re-runs the scan and overwrites the scanned sections — use when `CLAUDE.md` has drifted.

**When to run:** after `setup`, when the project already has source code. Not for greenfield — use `/compass:setup-stack` instead.

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

For logic-bearing tasks: builds test-first (RED → GREEN). For UI/glue/config tasks: type-check gate only.

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

Folds in: `/compass:commit`, `/compass:review`, `/compass:security-review` (on risky diffs).

---

## Review & fix

### /compass:review

3-subagent parallel review — your `CLAUDE.md` conventions, pattern reuse,
test-coverage gaps. Advisory only; never edits or commits.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Argument** | `[PR-number]` — optional |
| **Trigger** | Auto (inside `ship`) or User |

**Without argument:** uses the current branch's PR (inferred) or falls back to `git diff {base_branch}...HEAD`.

**With argument:** reviews that specific PR number.

**When to run standalone:** before shipping, for re-reviews after addressing feedback, for external/contributed PRs, or after a manual push. Run `/clear` first for the sharpest results.

**vs. `/compass:code-review`:** this command checks your project conventions and test coverage (advisory). `/compass:code-review` is a deep generic bug hunt with tunable effort and `--fix`.

---

### /compass:code-review

Deep bug hunt with a tunable effort dial. Wraps the built-in `/code-review` with
compass-specific follow-up: after `--fix`, automatically runs `/compass:validate`.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Sonnet (low–high) / Opus cloud (ultra) |
| **Argument** | `[low\|medium\|high\|max\|ultra] [--fix] [--comment] [PR-number]` — optional |
| **Trigger** | User |

**Without `--fix`:** advisory — findings shown, nothing applied.

**With `--fix`:** applies fixes in the working tree, then runs `/compass:validate`. Never auto-commits.

| Level | Cost | Use for |
|---|---|---|
| `low` / `medium` | cheap | Small diffs, quick pre-ship pass |
| `high` | moderate | Normal feature work |
| `max` | high | Risky changes |
| `ultra` | highest (cloud) | DB migrations, auth, large refactors |

Match the level to the risk — don't rely on the default.

---

### /compass:apply-ci-review

Pulls the CI `claude-review` inline comments from the open PR and applies the fixes
locally, then runs `/compass:validate`. Stops before commit.

| | |
|---|---|
| **Level** | PIV (Fix) |
| **Recommended model** | Opus |
| **Argument** | `[PR-number]` — optional |
| **Trigger** | User |

**Without argument:** infers the PR from the current branch.

**With argument:** uses that specific PR number.

**When to use:** in `review-only`/`full` mode — the CI already reviewed the diff, so re-reviewing with `/compass:code-review` would be redundant. In `off` mode or before the PR exists, use `/compass:code-review --fix` instead.

---

### /compass:security-review

Security-focused review — injection, auth, data exposure, secrets. Advisory; never
edits. Defaults to staged changes if no argument given.

| | |
|---|---|
| **Level** | PIV |
| **Recommended model** | Opus |
| **Argument** | `[file-or-directory]` — optional |
| **Trigger** | Auto (inside `ship` on risky diffs) or User |

**Without argument:** reviews staged `git diff --cached`, or unstaged `git diff` if nothing is staged.

**With argument:** reviews those paths specifically (e.g. `src/api/auth.ts`).

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

**When to run:** after a merge, after a frustrating session, after a bug, or periodically to keep `CLAUDE.md` and commands aligned with how the project has evolved.
