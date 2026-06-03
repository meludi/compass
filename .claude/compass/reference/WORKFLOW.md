# Workflow

The map of how work flows through this starter: **one setup, two loops, one axis.**

```
STAGE 0 — Setup (once per initiative)   /setup → [/setup-tracker] → /ideate → [/setup-stack] → /create-stories
LOOP 1 — PIV (per story)                /worktree → /plan-feature → /implement → /ship → /reflect
LOOP 2 — Fix (until the PR is clean)    review → fix → /validate → /commit → push → (repeat) → merge → cleanup
AXIS — autonomy_mode                    off = Loop 2 stays local · review-only = CI re-reviews each push
```

Each step is one command. The *why* behind the structure: `CONCEPTS.md`. Full command table, `.work/` layout, models, glossary, troubleshooting: `HANDBOOK.md`.

---

## Stage 0 — Setup (once per initiative)

Run once when starting a project or a new initiative.

| Step | Command | Does |
|---|---|---|
| 1 | `/setup` | Configures the project — generates `.claude/compass.yml` + `.claude/CLAUDE.md`. Run first. |
| 1b | `/setup-tracker` _(optional)_ | Switch issue tracker. Linear works out of the box — only for Jira / Azure DevOps. |
| 2 | `/ideate "<initiative>"` | Brain dump → PRD (scope check, approaches, self-review) → `.work/prds/`. |
| 3 | `/setup-stack` _(greenfield only)_ | Scaffold framework from the PRD, fill `CLAUDE.md` Code Patterns, drop seed files. Skip for brownfield. |
| 4 | `/create-stories <prd>` | Break the PRD into stories → `.work/stories/` (+ tracker issues if configured). Each story = one PIV iteration. |

---

## Loop 1 — PIV (per story)

Pick a story from `.work/stories/` (or your tracker), then run this loop once per story.

### 1. `/worktree <story-name>`
Creates an isolated worktree on `feat/<name>` and opens a fresh Claude session. Steps 2–4 run in that session. Detail: `WORKTREES.md`.

### 2. `/plan-feature <story>`
Loads project context, then writes an implementation plan to `.work/plans/`. **Plan only — no code.** Ends here on purpose: review the plan before implementing.

### 3. `/implement <plan>`
Executes the plan task by task, type-checking after each, then runs the full validation suite. _Folds in: `/validate` (→ agent-browser)._

### 4. `/ship`
Commits, pushes, opens a PR, then offers the parallel review. _Folds in: `/commit`, `/review`, `/security-review`._

### 5. `/reflect`
Captures learnings and evolves the system (commands, `CLAUDE.md`, `reference/`). Run after a merge — or anytime the workflow itself needs a fix.

> **Auto Path:** when a plan is already reviewed and stable, replace steps 3–4 with `/auto-implement <plan>` — runs implement → commit → push → PR-open with no intermediate confirmation. Hard-stops at PR-open; never merges. The only command that may auto-commit. Not for DB migrations, auth boundaries, or first use of a new pattern.

---

## Loop 2 — Fix (until the PR is clean)

A PR is open. Review surfaces findings; **you** fix them; CI never commits. This loop repeats until clean, then you merge. It is the same loop whether the review is local or in CI — only the entry differs.

```
review  →  fix  →  /validate  →  /commit  →  push  →  (CI re-reviews → repeat)  →  merge  →  cleanup
```

**Step 1 — review** (pick the reviewer for the job):

| Reviewer | What it is | Use when |
|---|---|---|
| `/code-review [level]` | built-in deep bug hunt; effort dial `low`→`ultra`; can `--fix` | correctness/bugs; want fixes applied |
| `/review` | this starter's 3 subagents — *your* CLAUDE.md conventions, reuse, test gaps | convention/reuse/test-coverage check |
| CI `claude-review` | runs on the PR in `review-only`/`full`; posts comments on GitHub | automatic on each push (no API key → does not run) |

**Step 2 — fix** (always a human action; pick the path):

| Path | Command | Use when |
|---|---|---|
| Local fix | `/code-review [level] --fix` | `off` mode / before the PR / want a fresh deep review + fix |
| Apply CI findings | `/apply-ci-review [pr]` | `review-only`/`full` — act on the CI comments already on the PR (no redundant second review) |
| Manual | edit by hand | small, obvious fixes |

**Step 3 — verify & publish:** `/validate` (fixes can break lint/types/tests) → `/commit` → `git push`.

> **`commit` ≠ PR update.** A commit is local. The **push** updates the open PR and (in `review-only`/`full`) triggers an automatic CI re-review. Repeat until clean.

**Step 4 — merge & cleanup:** merge the PR yourself (`gh pr merge --squash`), then remove the worktree with `/worktree <name> rm` (guarded — refuses on unmerged/uncommitted work).

### The same loop, two modes

The shape is identical; what differs is **who triggers the review** and **how you know it's clean**.

**`off` — you drive every round (local):**
```
/code-review [--fix]  →  /validate  →  /commit  →  push  →  CI runs `test` only  →  merge when satisfied
```
You start each review yourself; there is no automatic re-review. The "clean" signal is your own judgement.

**`review-only` — CI reviews every push (CI-assisted):**
```
push  →  CI claude-review posts comments + `## Review Summary`  →  GitHub notifies you
     →  /apply-ci-review  →  /validate  →  /commit  →  push  →  CI re-reviews  →  repeat until clean  →  merge
```
Review is automatic on each push; you consume it with `/apply-ci-review`. The "clean" signal is a `## Review Summary` with no findings — plus an audit trail on the PR.

| | `off` | `review-only` |
|---|---|---|
| Who triggers the review | you, each round | CI, automatically on every push |
| Fix entry | `/code-review --fix` | `/apply-ci-review` |
| Re-review after a fix | manual (run it again) | automatic on push |
| "Clean" signal | your judgement | `## Review Summary` shows no findings |
| Findings live | in chat (ephemeral) | PR comments (audit trail) |

---

## Axis — `autonomy_mode`

A cross-cutting setting (`.claude/compass.yml`), not a step — it decides how Loop 2 runs (see *The same loop, two modes* above): `off` keeps the loop local; `review-only` adds CI review on each push, consumed via `/apply-ci-review`. A third mode, **`full`**, additionally auto-merges on green CI — ⚠️ no human merge gate unless a label gate is configured.

Comparison matrix, cost, and security notes: `AUTONOMY.md`.

---

## Quick Path — trivial changes

For typos, one-line bugfixes, CSS/copy tweaks, config values — a PRD/story/plan is pure ceremony:

```
/worktree <name>  →  make the edit by hand  →  /validate  →  /ship   (answer "no" to the review)
```

**Not for** anything with logic, new files, or acceptance criteria — that goes through Loop 1.

---

## Other commands (folded or on-demand)

- `/context [spec]` — load rules, git state, optional spec, on-demand docs. Auto-runs as step 1 of `/plan-feature` and `/implement`; standalone on resume or stale context.
- `/validate` — lint + types + tests + browser smoke test. Folded into `/implement`; standalone before `/ship` or to debug a failing check.
- `/commit` — stage + commit locally, no push/PR. Folded into `/ship`; standalone for WIP checkpoints.
- `/security-review [path]` — security review of changed files. Auto-runs inside `/ship` on risky diffs; standalone on demand.

---

Reference: `HANDBOOK.md` (command table, `.work/`, models, glossary, troubleshooting) ·
`CONCEPTS.md` (the why) · `WORKTREES.md` (worktree detail) · `AUTONOMY.md` (CI + `autonomy_mode`).
