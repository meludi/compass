# Workflow

The map of how work flows through this starter: **one setup, two loops, one axis.**

```
STAGE 0 — Setup (once per initiative)   /compass:setup → [/compass:setup-tracker] → /compass:ideate → [/compass:setup-stack] → /compass:create-stories
LOOP 1 — PIV (per story)                /compass:worktree → /compass:plan-feature → /compass:implement → /compass:ship → /compass:reflect
LOOP 2 — Fix (until the PR is clean)    review → fix → /compass:validate → /compass:commit [--push] → (repeat) → merge → cleanup
AXIS — autonomy_mode                    off = Loop 2 stays local · review-only = CI re-reviews each push
```

Each step is one command. The *why* behind the structure: `CONCEPTS.md`. Full command table, `.work/` layout, models, glossary, troubleshooting: `HANDBOOK.md`.

---

## Stage 0 — Setup (once per initiative)

Run once when starting a project or a new initiative.

| Step | Command | Does |
|---|---|---|
| 1 | `/compass:setup` | Configures the project — generates `.claude/compass.yml` + `.claude/CLAUDE.md`. Run first. |
| 1b | `/compass:onboard` _(brownfield)_ | Scans the existing codebase and fills `CLAUDE.md` with real patterns (architecture, code style, testing). Skip for greenfield. |
| 1c | `/compass:setup-stack` _(greenfield only)_ | Scaffold framework from the PRD, fill `CLAUDE.md` Code Patterns, drop seed files. Skip for brownfield. |
| 1d | `/compass:setup-tracker` _(optional)_ | Switch issue tracker. Linear works out of the box — only for Jira / Azure DevOps. |
| 2 | `/compass:ideate "<initiative>"` | Brain dump → PRD (scope check, approaches, self-review) → `.work/prds/`. |
| 3 | `/compass:create-stories <prd>` | Break the PRD into stories → `.work/stories/` (+ tracker issues if configured). Each story = one PIV iteration. |

---

## Loop 1 — PIV (per story)

Pick a story from `.work/stories/` (or your tracker), then run this loop once per story.

| Step | Command | Does |
|---|---|---|
| 1 | `/compass:worktree <story-name>` | Isolated worktree on `feat/<name>` + a fresh Claude session; steps 2–4 run there. Detail: `WORKTREES.md`. |
| 2 | `/compass:plan-feature <story>` | Loads context, writes a plan to `.work/plans/`. **Plan only — no code.** Stops here on purpose: review the plan first. |
| 3 | `/compass:implement <plan>` | Executes the plan task by task (type-check after each), then the full validation suite. _Folds in `/compass:validate` (→ agent-browser)._ |
| 4 | `/compass:ship` | Commit → push → open PR, then offers the parallel review. _Folds in `/compass:commit`, `/compass:review`, `/compass:security-review`._ |
| 5 | `/compass:reflect` | Captures learnings, evolves the system (commands, `CLAUDE.md`, `references/`). After a merge — or anytime the workflow needs a fix. |

**Shortcuts:**

| Situation | Command | Replaces |
|---|---|---|
| Single task, no initiative (bug, small addition) | `/compass:plan-feature "description"` | Steps 2 with a free-text description — no story file, no Ideate needed |
| Plan already reviewed and stable | `/compass:auto-implement <plan>` | Steps 3–4 — implement → commit → push → PR-open without confirmation. Hard-stops at PR-open; never merges. Not for DB migrations, auth changes, or first use of a new pattern. |

---

## Loop 2 — Fix (until the PR is clean)

A PR is open. The reviewer points, **you** fix, CI never commits — repeat until clean, then merge. Same loop whether the review is local or in CI; only the trigger differs.

**Step 1 — review** (pick one):

| Command | What it does | Use when |
|---|---|---|
| `/compass:code-review [low→ultra]` | Deep bug hunt; tunable effort; verify stage to filter false positives | Correctness / bugs; want to apply fixes directly |
| `/compass:review` | 3 subagents in parallel: your CLAUDE.md conventions, pattern reuse, test-coverage gaps — advisory, no edits | Convention compliance, reuse check, coverage audit |
| CI `claude-review` | Runs automatically on each push in `review-only`/`full`; posts inline comments + `## Review Summary` on the PR | Already running — nothing to invoke |

**Step 2 — fix** (pick one):

| Command | What it does | Use when |
|---|---|---|
| `/compass:code-review --fix` | Re-reviews the diff and applies fixes directly in your working tree | `off` mode, or before the PR exists — fresh local review + fix |
| `/compass:apply-ci-review` | Pulls the CI `claude-review` comments from the open PR and applies them locally | `review-only`/`full` — act on the review that already ran, no redundant re-review |
| Edit by hand | — | Small, obvious fixes |

**Step 3 — verify:** `/compass:validate` — re-run lint/types/tests (a fix can break them).

**Step 4 — publish:** `/compass:commit [--push]` — commit, then push (asked automatically, or pass `--push` to skip). The push updates the open PR and triggers CI re-review in `review-only`/`full`.

**Step 5 — merge:** `gh pr merge --squash`, then `/compass:worktree <name> rm` (guarded — refuses on unmerged/uncommitted work).

**Two modes** (set by `autonomy_mode` — see Axis below):

| | `off` | `review-only` |
|---|---|---|
| Who triggers the review | you, each round | CI, automatically on every push |
| Fix entry | `/compass:code-review --fix` | `/compass:apply-ci-review` |
| Re-review after a fix | manual (run it again) | automatic on push |
| "Clean" signal | your judgement | `## Review Summary` with no findings |
| Findings live | in chat (ephemeral) | PR comments (audit trail) |

---

## Axis — `autonomy_mode`

A cross-cutting setting (`.claude/compass.yml`), not a step — it decides how Loop 2 runs (see the **Two modes** table above): `off` keeps the loop local; `review-only` adds CI review on each push, consumed via `/compass:apply-ci-review`. A third mode, **`full`**, additionally auto-merges on green CI — ⚠️ no human merge gate unless a label gate is configured.

Comparison matrix, cost, and security notes: `AUTONOMY.md`.

---

## Quick Path — trivial changes

For typos, one-line bugfixes, CSS/copy tweaks, config values — a PRD/story/plan is pure ceremony:

```
/compass:worktree <name>  →  make the edit by hand  →  /compass:validate  →  /compass:ship   (answer "no" to the review)
```

**Not for** anything with logic, new files, or acceptance criteria — that goes through Loop 1.

---

## Other commands (folded or on-demand)

| Command | Does | Auto-runs in | Standalone when |
|---|---|---|---|
| `/compass:context [story \| issue-id \| description]` | Loads project rules, git state, and optional spec into context | step 1 of `plan-feature` + `implement` | Resuming, stale session, before `reflect` |
| `/compass:validate` | Runs lint, type-check, tests, browser smoke | end of `implement` | Before `ship`, or to debug a failing check |
| `/compass:commit [--push]` | Stages + commits; asks whether to push | `ship` | WIP checkpoint, Fix-Loop publish step |
| `/compass:security-review [file-or-directory]` | Security-focused review: injection, auth, data exposure, secrets — advisory, never edits | `ship` on risky diffs | Targeted audit of a specific file or directory |

---

Reference: `HANDBOOK.md` (command table, `.work/`, models, glossary, troubleshooting) ·
`CONCEPTS.md` (the why) · `WORKTREES.md` (worktree detail) · `AUTONOMY.md` (CI + `autonomy_mode`).
