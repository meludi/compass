# Workflow

The map of how work flows through this starter: **one setup, two loops, one axis.**

```
STAGE 0 — Setup (once per initiative)   /compass:setup → [/compass:setup-tracker] → /compass:ideate → [/compass:setup-stack] → /compass:create-stories
LOOP 1 — PIV (per story)                /compass:worktree → /compass:plan-feature → /compass:implement → /compass:ship → /compass:reflect
LOOP 2 — Fix (until the PR is clean)    review → fix → /compass:validate → /compass:commit → push → (repeat) → merge → cleanup
AXIS — autonomy_mode                    off = Loop 2 stays local · review-only = CI re-reviews each push
```

Each step is one command. The *why* behind the structure: `CONCEPTS.md`. Full command table, `.work/` layout, models, glossary, troubleshooting: `HANDBOOK.md`.

---

## Stage 0 — Setup (once per initiative)

Run once when starting a project or a new initiative.

| Step | Command | Does |
|---|---|---|
| 1 | `/compass:setup` | Configures the project — generates `.claude/compass.yml` + `.claude/CLAUDE.md`. Run first. |
| 1b | `/compass:setup-tracker` _(optional)_ | Switch issue tracker. Linear works out of the box — only for Jira / Azure DevOps. |
| 2 | `/compass:ideate "<initiative>"` | Brain dump → PRD (scope check, approaches, self-review) → `.work/prds/`. |
| 3 | `/compass:setup-stack` _(greenfield only)_ | Scaffold framework from the PRD, fill `CLAUDE.md` Code Patterns, drop seed files. Skip for brownfield. |
| 4 | `/compass:create-stories <prd>` | Break the PRD into stories → `.work/stories/` (+ tracker issues if configured). Each story = one PIV iteration. |

---

## Loop 1 — PIV (per story)

Pick a story from `.work/stories/` (or your tracker), then run this loop once per story.

| Step | Command | Does |
|---|---|---|
| 1 | `/compass:worktree <story-name>` | Isolated worktree on `feat/<name>` + a fresh Claude session; steps 2–4 run there. Detail: `WORKTREES.md`. |
| 2 | `/compass:plan-feature <story>` | Loads context, writes a plan to `.work/plans/`. **Plan only — no code.** Stops here on purpose: review the plan first. |
| 3 | `/compass:implement <plan>` | Executes the plan task by task (type-check after each), then the full validation suite. _Folds in `/compass:validate` (→ agent-browser)._ |
| 4 | `/compass:ship` | Commit → push → open PR, then offers the parallel review. _Folds in `/compass:commit`, `/compass:review`, `/compass:security-review`._ |
| 5 | `/compass:reflect` | Captures learnings, evolves the system (commands, `CLAUDE.md`, `reference/`). After a merge — or anytime the workflow needs a fix. |

> **Auto Path:** when a plan is already reviewed and stable, replace steps 3–4 with `/compass:auto-implement <plan>` — runs implement → commit → push → PR-open with no intermediate confirmation. Hard-stops at PR-open; never merges. The only command that may auto-commit. Not for DB migrations, auth boundaries, or first use of a new pattern.

---

## Loop 2 — Fix (until the PR is clean)

A PR is open. The reviewer points, **you** fix, CI never commits — repeat until clean, then merge. Same loop whether the review is local or in CI; only the trigger differs.

| Step | Command | Does |
|---|---|---|
| 1 — review | `/code-review` · `/compass:review` · or CI `claude-review` | Surface findings (bugs / conventions / coverage). Pick the reviewer below. |
| 2 — fix | `/code-review --fix` · `/compass:apply-ci-review` · or by hand | Apply the fixes — always a deliberate human step. |
| 3 — verify | `/compass:validate` | Re-run lint/types/tests (a fix can break them). |
| 4 — publish | `/compass:commit` → `git push` | Commit is **local**; the **push** updates the PR and (in `review-only`/`full`) triggers an automatic CI re-review. |
| 5 — merge | `gh pr merge --squash` → `/compass:worktree <name> rm` | Merge it yourself, then remove the worktree (guarded — refuses on unmerged/uncommitted work). |

**Which reviewer?**

| Reviewer | Best for |
|---|---|
| `/code-review [low→ultra]` _(can `--fix`)_ | correctness / bugs; want fixes applied |
| `/compass:review` _(3 subagents)_ | your `CLAUDE.md` conventions, reuse, test-coverage gaps |
| CI `claude-review` | automatic on each push (`review-only`/`full`; needs an API key) |

**Two modes** (set by `autonomy_mode` — see Axis below):

| | `off` | `review-only` |
|---|---|---|
| Who triggers the review | you, each round | CI, automatically on every push |
| Fix entry | `/code-review --fix` | `/compass:apply-ci-review` |
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

- `/compass:context [spec]` — load rules, git state, optional spec, on-demand docs. Auto-runs as step 1 of `/compass:plan-feature` and `/compass:implement`; standalone on resume or stale context.
- `/compass:validate` — lint + types + tests + browser smoke test. Folded into `/compass:implement`; standalone before `/compass:ship` or to debug a failing check.
- `/compass:commit` — stage + commit locally, no push/PR. Folded into `/compass:ship`; standalone for WIP checkpoints.
- `/compass:security-review [path]` — security review of changed files. Auto-runs inside `/compass:ship` on risky diffs; standalone on demand.

---

Reference: `HANDBOOK.md` (command table, `.work/`, models, glossary, troubleshooting) ·
`CONCEPTS.md` (the why) · `WORKTREES.md` (worktree detail) · `AUTONOMY.md` (CI + `autonomy_mode`).
