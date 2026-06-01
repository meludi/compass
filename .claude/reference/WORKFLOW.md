# Workflow

The day-to-day command flow — two levels plus a quick path. Each step below is one
command: what it does, how to call it, what it hands off.

```
LEVEL 1 — Initiative Setup   /setup → /setup-tracker → /ideate → /setup-stack → /create-stories   (once per initiative)
LEVEL 2 — PIV Loop           /worktree → /plan-feature → /implement → /ship → /reflect                (per story)
QUICK PATH — trivial changes /worktree → edit → /validate → /ship
AUTO PATH — confirmed plan   /worktree → /plan-feature → /auto-implement                              (no HITL after plan approval)
```

Reference (models, full command table, troubleshooting, `.work/` layout): `HANDBOOK.md`.
The *why* behind this structure: `CONCEPTS.md`.

---

## Level 1 — Initiative Setup

Run once when starting a project or a new initiative.

### 1. `/setup`

Configures the project — generates `.claude/project.yml` and `.claude/CLAUDE.md`. Run once per project, before anything else.

```
/setup
```

### 1b. `/setup-tracker` _(optional)_

Switches the issue tracker. Linear is the default and works out of the box — run this only to use Jira or Azure DevOps instead.

```
/setup-tracker
```

### 2. `/ideate`

Structured brain dump → PRD: scope check, research, approaches, incremental design approval, self-review — all in one session. Skips the brain dump if the initiative is already well understood from the conversation.

```
/ideate "Dividend tracking feature set"
→ .work/prds/dividend-tracking.prd.md
```

### 3. `/setup-stack` _(greenfield only)_

Scaffolds the framework from the PRD's tech notes, fills the CLAUDE.md Code Patterns section, and creates canonical seed files. Skip for brownfield — existing code already provides the patterns.

```
/setup-stack .work/prds/dividend-tracking.prd.md
```

### 4. `/create-stories`

Breaks the PRD into individual, actionable stories with acceptance criteria. Each story becomes the spec for one PIV Loop iteration.

```
/create-stories .work/prds/dividend-tracking.prd.md
→ .work/stories/   (+ tracker issues if configured)
```

---

## Level 2 — PIV Loop

Run once per story. Pick a story from `.work/stories/` (or your tracker), then:

### 1. `/worktree`

Creates an isolated worktree on `feat/<name>` and opens a fresh Claude session inside it. Steps 2–4 run in that session.

```
/worktree <story-name>
```

### 2. `/plan-feature`

Loads project context, then writes an implementation plan to `.work/plans/`. Plan only — no code. Ends here on purpose: review the plan before implementing.

```
/plan-feature .work/stories/dividend-display.md
→ .work/plans/dividend-display.plan.md
```

### 3. `/implement`

Executes the plan task by task, type-checking after each. After all tasks pass, runs the full validation suite — lint, types, tests, browser smoke test — and writes a report to `.work/reports/`.

_Includes: /validate (→ agent-browser)_

```
/implement .work/plans/dividend-display.plan.md
```

### 4. `/ship`

Commits, pushes, opens a PR, then asks whether to run the parallel code review.

_Includes: /commit, /review, /security-review_

```
/ship
```

After the review passes: merge the PR, then remove the worktree —
`bash .claude/scripts/worktree.sh <story-name> rm`.

### 4b. `/review` (standalone)

Runs the 3-subagent parallel review — without going through `/ship`. Works with or without an open PR.

```
/clear          ← clean context for the subagents
/review         ← PR if one exists, otherwise local branch diff
/review 42      ← explicit PR number
```

Use before `/ship` for early feedback on local changes, or after for re-reviews and external PRs.

_Includes: /security-review_

### 5. `/reflect`

Captures learnings and evolves the system — updates commands, `CLAUDE.md`, or `reference/` docs so a mistake never repeats. Run it right after a merge; also useful anytime the workflow itself needs a fix.

```
/reflect
```

---

## Quick Path — trivial changes

For typos, single-line bugfixes, CSS/copy tweaks, and config-value changes, a PRD, a story, and a plan are pure ceremony. Skip them:

```
/worktree <name>  →  make the edit by hand  →  /validate  →  /ship
```

- Skips `/ideate`, `/setup-stack`, `/create-stories`, `/plan-feature`, and `/implement` — no spec artifacts are produced.
- When `/ship` asks whether to run the review, answer **no** — the 3-subagent review is overkill for a one-line diff.
- `/worktree` still applies: it keeps work off the base branch and isolated.

**Do not use it for** anything with logic, new files, or acceptance criteria — that goes through the full Level 2 PIV Loop.

---

## Auto Path — confirmed plan to PR without HITL

When the plan is already reviewed and stable, `/auto-implement` runs the entire pipeline from the plan to an open PR in one go — no commit confirmation, no review prompt. Merge stays manual.

```
/worktree <name>  →  /plan-feature <story>  →  (review & approve the plan)  →  /auto-implement .work/plans/<name>.plan.md
```

- Plan freezes after approval — `/auto-implement` reads `.work/plans/<name>.plan.md` as immutable input.
- Implementation runs the same per-task type-check loop as `/implement`, then the full validation suite.
- Commit, push, and `gh pr create` all run without asking. Hard stop at PR-open. Never merges.
- The only command in the workflow that may auto-commit. The standard `Never auto-commit` rule in `commit.md` and `ship.md` still holds everywhere else.

**Use it for:** small to medium stories that follow existing patterns. Plans you would have approved via `/implement` → `/ship` anyway, where the in-between confirmations add no value.

**Do not use it for:** DB migrations, auth/security boundaries, first-time use of a new library or pattern, or anything where you want to inspect intermediate state. There: stay on `/implement` → `/ship` with all the gates intact.

**Pre-conditions enforced inside `/auto-implement`:**

- Current branch matches `feat/*` — refuses on the base branch.
- Running inside a worktree (matches `worktree_prefix` from `project.yml`).
- Plan file exists at the given path.
- Working tree is clean or only contains plan-scoped changes.

If any check fails, `/auto-implement` aborts before touching anything.

---

## Other commands

Not flow steps — they run inside the steps above (folded in) or on demand:

- `/context [issue-id | story-path | feature description]` — load project rules, git state, optional spec, and on-demand docs. Auto-runs as Step 1 of `/plan-feature` and `/implement`. Standalone for mid-story resume, debugging, or before `/reflect`.
- `/validate` — run lint, types, tests, and the browser smoke test on their own. No argument. Folded into `/implement`.
- `/commit` — stage and commit locally, no push or PR. No argument. Folded into `/ship`.
- `/security-review [file-or-directory]` — security review of changed files; defaults to staged changes if no path is given. Auto-runs inside `/ship` on a risky diff; also runnable on demand.

---

Reference: `HANDBOOK.md` (models, command table, troubleshooting, `.work/` layout) ·
`CONCEPTS.md` (the why) · `WORKTREES.md` (worktree detail) ·
`AUTONOMY.md` (CI workflow + `autonomy_mode` opt-in).
