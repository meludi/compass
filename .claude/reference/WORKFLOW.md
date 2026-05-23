# Workflow

The day-to-day command flow — two levels plus a quick path. Each step below is one
command: what it does, how to call it, what it hands off.

```
LEVEL 1 — Initiative Setup   /setup → /setup-tracker → /ideate → /setup-stack → /create-stories   (once per initiative)
LEVEL 2 — PIV Loop           /worktree → /plan-feature → /implement → /ship → /reflect                (per story)
QUICK PATH — trivial changes /worktree → edit → /validate → /ship
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

Commits, pushes, opens a PR, then asks whether to run the parallel code review (3 subagents + security check).

_Includes: /commit, /security-review_

```
/ship
```

After the review passes: merge the PR, then remove the worktree —
`bash .claude/scripts/worktree.sh <story-name> rm`.

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

## Other commands

Not flow steps — they run inside the steps above (folded in) or on demand:

- `/validate` — run lint, types, tests, and the browser smoke test on their own. No argument. Folded into `/implement`.
- `/commit` — stage and commit locally, no push or PR. No argument. Folded into `/ship`.
- `/security-review [file-or-directory]` — security review of changed files; defaults to staged changes if no path is given. Auto-runs inside `/ship` on a risky diff; also runnable on demand.

---

Reference: `HANDBOOK.md` (models, command table, troubleshooting, `.work/` layout) ·
`CONCEPTS.md` (the why) · `WORKTREES.md` (worktree detail).
