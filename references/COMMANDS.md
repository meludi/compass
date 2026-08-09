# Commands

Nine workflow commands and a router — what each one takes, what it writes, and
when to reach for it. The flow they form is in `WORKFLOW.md`.

**This file answers *whether* to run a command, never *how* it runs.** The files
in `commands/` are the instruction set the agent executes and the only place a
rule lives; restating one here would give it a second copy to drift from.

| | Command | Argument | Model |
|---|---|---|---|
| Help | [`/compass:help`](#compasshelp) | `[situation]` | haiku |
| Setup | [`/compass:setup`](#compasssetup) | — | sonnet |
| PIV | [`/compass:worktree`](#compassworktree) | `<name> [rm]` | haiku |
| PIV | [`/compass:plan-feature`](#compassplan-feature) | `<spec \| issue-id \| description>` | opus |
| PIV | [`/compass:implement`](#compassimplement) | `<plan path>` | sonnet |
| PIV | [`/compass:plan-to-pr`](#compassplan-to-pr) | `<plan path>` | sonnet |
| PIV | [`/compass:validate`](#compassvalidate) | — | sonnet |
| Ship | [`/compass:commit`](#compasscommit) | `[--push]` | haiku |
| Ship | [`/compass:ship`](#compassship) | — | opus |
| Fix | [`/compass:fix-ci-review`](#compassfix-ci-review) | `[PR-number]` | opus |

---

## Help

### /compass:help

Routes a situation to the command that fits — across compass, Claude Code's built-ins and mattpocock/skills.

| | |
|---|---|
| **Argument** | `[what you are trying to do]` — optional; without one it prints the whole table |
| **Trigger** | User |
| **Writes** | nothing |

It **names** a command and stops; it never runs one. Where `WORKFLOW.md` orders commands by flow and this file by ownership, `help` orders them by the question you actually have.

Two sections carry most of the value: *The pairs people confuse* (`/code-review` vs `fix-ci-review` vs `/autofix-pr`, `validate` vs `code-review`, `plan-feature` vs `to-spec`) and *Nothing to run* — the situations whose correct answer is no command at all.

---

## Setup

### /compass:setup

Scaffolds `.claude/CLAUDE.md` — project conventions, the *Review conventions* section, and the `## Commands` table that **is** compass' configuration.

| | |
|---|---|
| **Argument** | none |
| **Trigger** | User — once per project |
| **Writes** | `.claude/CLAUDE.md`, `.work/.gitignore` |

One phase, one file to edit — rows it cannot detect stay blank rather than guessed. The second file is two lines that keep generated reports and screenshots out of git; it is written once and never read by compass.

**It never overwrites an existing `CLAUDE.md`** — it reports what a fresh scan would have written and lets you merge, so re-running it is safe. There is nothing to refresh after a plugin update.

No CI workflow is written. For review on the PR, pick a reviewer once per repo — `WORKFLOW.md` → *Automated PR review* covers both options.

---

## PIV loop

### /compass:worktree

Creates an isolated worktree on `feat/<name>`, installs dependencies, and opens a fresh Claude session inside it. Also removes one, guarded.

| | |
|---|---|
| **Argument** | `<feature-name>` — required. Append `rm` to remove, `rm --force` to override the guards |
| **Trigger** | User |
| **Reads** | nothing — base branch, package manager and port come from the repo |

The script reserves a free port in `.worktree-port` and symlinks `.env.local` plus `.claude/settings.local.json` from main. Per-worktree **state** is yours: drop a `.claude/worktree-setup.sh` (and `-teardown.sh`) into the project and it runs with `WT_NAME`, `WT_DIR`, `WT_BRANCH`, `WT_PORT` exported. The command file carries recipes for Postgres, Mongo, Docker Compose, SQLite and non-JS stacks.

**Removal is guarded** — it refuses on uncommitted changes, on commits not merged into the base branch, and if you are standing inside the worktree, so `rm` cannot lose work by accident.

**Skip it** if you work one feature at a time. Nothing downstream depends on it.

### /compass:plan-feature

Loads context, explores the codebase, and writes a file-level implementation plan to `.work/plans/`. **Plan only — no code.**

| | |
|---|---|
| **Argument** | `<spec file \| issue-id \| "description">` — required |
| **Trigger** | User |
| **Uses** | the built-in `Explore` subagent |
| **Writes** | `.work/plans/<feature>.plan.md` |

The spec is whatever you have. A markdown file, an issue id fetched via `gh`, or a sentence typed on the spot — compass does not produce specs and does not care where yours comes from.

The plan lists files to create and update, tasks in dependency order, and a `Behavior` line per logic-bearing task. That line is what makes `/compass:implement` write a test for it.

**If a complete plan already exists** for this feature, it reports status and recommends `/compass:implement` instead of re-planning. Ask explicitly for a revision to override.

Run it in a fresh session to re-orient — step 1 reloads `CLAUDE.md` and git state before anything else.

### /compass:implement

Executes a plan task by task. Each task passes its own gate before the next starts.

| | |
|---|---|
| **Argument** | `<path to .work/plans/*.plan.md>` — required |
| **Trigger** | User |
| **Calls** | `/compass:validate` at the end |
| **Writes** | `.work/reports/<feature>-report.md`, plus `## Loop log` entries in the plan |

Because every task is gated before the next starts, this is **safe to interrupt** — stop after any task and the tree is consistent. Resume by re-running it against the same plan; completed tasks are ticked off in the file.

Whether a logic-bearing task gets a test, and whether the test comes first, is the **Test policy** line in `.claude/CLAUDE.md` (README → *Configure*).

### /compass:plan-to-pr

Runs `implement` → `/code-review` → `ship` as one unattended pass, from a confirmed plan to an open PR.

| | |
|---|---|
| **Argument** | `<path to .work/plans/*.plan.md>` — required |
| **Trigger** | User |
| **Calls** | `/compass:implement`, `/code-review`, `/compass:validate`, `/compass:ship` |
| **Writes** | what `implement` writes, plus a commit, a pushed branch and a PR |
| **Needs** | `gh` — checked up front, before any code is written |

**Reach for it when all three hold:** the plan is reviewed and stable, the change is small to medium, and it follows patterns already in the codebase. **Not** for migrations, auth or security boundaries, or the first use of a library here — those want the per-task look that `/compass:implement` gives you.

The plan is the only human gate, which is why `plan-feature` stays outside the chain. Everything downstream is guarded automatically: a failed validation aborts before the commit, and it never merges.

It is the **one** compass command that commits without asking. That exception is the reason to pick it deliberately rather than by default.

### /compass:validate

Runs the full check suite and reports failures with file and line.

| | |
|---|---|
| **Argument** | none |
| **Trigger** | Auto (end of `implement`, end of `fix-ci-review`) or User |
| **Reads** | the `## Commands` table in `.claude/CLAUDE.md` |

Order: lint + format → type check → tests → browser smoke test. **A blank command is skipped**, so a project without a type checker simply has one fewer gate.

The browser step only runs when the **Dev port** line is set *and* the dev server answers; otherwise it skips cleanly. It uses `agent-browser` to load the app, check that interactive elements render, and save a screenshot to `.work/screenshots/`.

**Run it standalone** anytime you want a health check without touching a plan.

---

## Ship

### /compass:commit

Stages, shows you the state, proposes a Conventional Commit message, and waits.

| | |
|---|---|
| **Argument** | `[--push]` — also push after committing |
| **Trigger** | Auto (from `ship`) or User |

**Never commits without confirmation** — safe to run just to see the proposed message.

### /compass:ship

Closes the loop: commit → push → open the PR → hand off to review.

Run `/code-review` on the branch **before** this — findings are cheaper to fix while no PR exists. `ship` does not check whether you did.

| | |
|---|---|
| **Argument** | none |
| **Trigger** | User |
| **Calls** | `/compass:commit` |
| **Needs** | `gh` — it stops before committing if the CLI is missing |
| **Reads** | the `Base branch` line in `.claude/CLAUDE.md`, else `origin/HEAD` |

The PR body is built from the implementation report: Summary, Changes, Manual Test Plan, Notes. It reflects **what validation actually confirmed**, not what was intended.

It does not review the diff and posts no review comment. It prints where review comes from — `/code-review` now, or claude-code-action on the PR — and stops. It never pushes to the base branch and never merges.

---

## Fix

### /compass:fix-ci-review

Reads the review comments on a PR and applies the fixes **locally**.

| | |
|---|---|
| **Argument** | `[PR-number]` — optional; inferred from the current branch via `gh pr view` |
| **Trigger** | User |
| **Calls** | `/compass:validate` |
| **Needs** | `gh` |

**Run it when both are true:** a PR exists, and there are review comments on it you haven't applied. It fetches the conversation *and* the line-level comments, lists the findings, and **waits for confirmation** before editing. No comments, no work — it stops and says so.

| Situation | Command |
|---|---|
| claude-code-action reviewed the PR | `/compass:fix-ci-review` |
| A human reviewed the PR | `/compass:fix-ci-review` |
| You came back in a fresh session — the PR comments are the only record | `/compass:fix-ci-review` |
| `/code-review` just ran in this session | none — the findings are in the chat, fix them directly |
| No PR yet | `/code-review` |

The point is the bridge: pulling in findings that were produced **outside your context window**. When the finding is already in the chat, the detour through GitHub is pure friction.

Fixes land locally and go through `/compass:validate` before anything is pushed, so a fix that breaks the type check never reaches the PR. The command **stops there**: you commit and push, and that push re-triggers the review.

**Before the PR exists**, use the built-in `/code-review` instead.

---

## Not compass' commands

You will type these in the same sessions, but they belong to tools compass does not maintain — documented where they are used, not here, so this file never describes someone else's behaviour incorrectly.

| Command | Owner | Where |
|---|---|---|
| `/install-github-app` | Claude Code | `WORKFLOW.md` → *Automated PR review* |
| `/code-review` | Claude Code | `WORKFLOW.md` → Loop 1, step 4 |
| `/autofix-pr` | Claude Code | `WORKFLOW.md` → Loop 2, *Autofix* |
| `/security-review` | Claude Code | not part of either loop — run it when the change touches auth, input handling or secrets |
| `@codex review` | OpenAI Codex | `WORKFLOW.md` → *Automated PR review* — typed in a PR comment, not a session |
| `mattpocock-skills:to-spec`, `…:to-tickets`, `…:tdd`, … | [mattpocock/skills](https://github.com/mattpocock/skills) | `WORKFLOW.md` → Loop 0 |
