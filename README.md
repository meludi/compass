# compass

A Claude Code **plugin** that brings a structured PIV loop (Plan → Implement → Validate) to any project — parallel subagent code review, browser smoke testing, and optional issue-tracker sync. Stack-agnostic, configured in one file. Commands are namespaced `/compass:<name>`.

---

## Requirements

| Tool | Required? | If missing | Install |
|------|-----------|------------|---------|
| [Claude Code](https://claude.ai/code) | **Required** | Nothing runs — it executes every command | `npm install -g @anthropic-ai/claude-code` |
| [Git](https://git-scm.com) | **Required** | No version control, worktrees, or commits | pre-installed on most systems |
| [GitHub CLI](https://cli.github.com) (`gh`) | For PRs | Local PIV loop still works; `/compass:ship` can't push or open a PR | `brew install gh` → `gh auth login` |
| [agent-browser](https://agent-browser.dev) | Optional | `/compass:validate` skips the browser smoke test | `brew install agent-browser` → `agent-browser install` |

> compass is built for **GitHub** (`gh` + GitHub Actions). The local PIV loop is host-agnostic; only `/compass:ship` and the CI autonomy layer need GitHub. On GitLab/Bitbucket: push works, open the MR/PR yourself.

---

## Install

Run in a Claude Code session (or prefix each with `claude` in your terminal):

```
/plugin marketplace add meludi/compass
/plugin install compass@compass
```

Restart Claude Code afterwards (or `/reload-plugins`).

- **Project-only install** (terminal): add `--scope local` (private, gitignored) or `--scope project` (shared via git) to `claude plugin install compass@compass`.
- **Update:** `/plugin update compass`, then run `/compass:update` in each project to sync new config keys.

The plugin installs centrally — nothing is copied into your repo. (To hack on compass itself: `claude --plugin-dir .` from a clone.)

---

## Configure

From your project root:

```
/compass:setup
```

Generates `.claude/compass.yml` (config), `.claude/compass.schema.json` (editor autocomplete + validation), `.claude/CLAUDE.md` (project conventions), and `.mcp.json` (only with a tracker).

- **Greenfield?** After `/compass:ideate`, run `/compass:setup-stack <prd>` to scaffold the stack.
- **Existing project?** Run `/compass:onboard` to fill `CLAUDE.md` from the real codebase.

`compass.yml` is the single, schema-validated source of config, documented inline. The fields you'll most likely touch:

| Field | Default | Controls |
|---|---|---|
| `test_policy` | `first` | tests for logic tasks: `first` (TDD) · `after` · `none` |
| `autonomy_mode` | `off` | CI depth: `off` · `review-only` · `full` |
| `ci_review_provider` / `ci_review_model` | `claude` / default | who reviews in CI, and an optional pinned model |
| `autofix_max_pushes` | `0` | brake for the native auto-fix loop (`0` = off) |

**Optional integrations** — **issue tracker** (off by default; `/compass:setup-tracker` — see [`references/HANDBOOK.md`](references/HANDBOOK.md)), **CI & autonomy** (`/compass:setup-stack` installs the PR workflow — see [`references/AUTONOMY.md`](references/AUTONOMY.md)), **deploy** (Vercel / Coolify / Netlify on merge — see [`references/HANDBOOK.md`](references/HANDBOOK.md)).

---

## Workflow

| Stage | When | Commands |
|-------|------|----------|
| **Setup** | once per project / initiative | `/compass:setup` (or `/compass:onboard`) → `/compass:ideate` → `/compass:create-stories` |
| **Loop 1 — PIV** | per story | `/compass:worktree` → `/compass:plan-feature` → `/compass:implement` → `/compass:ship` _(commit, PR, then optional review)_ → `/compass:reflect` |
| **Loop 2 — Fix** | until PR is clean | `/compass:review-code` → fix → `/compass:validate` → `/compass:commit [--push]` → merge |
| **Quick Path** | tiny fix (typo, 1-liner) | `/compass:worktree` → edit → `/compass:validate` → `/compass:ship` |

**Review** runs in two places: after opening the PR, `/compass:ship` offers a parallel-subagent review of the diff with fresh context (skip it for trivial changes); then Loop 2 re-reviews each round — locally (`/compass:review-code` / `/compass:review-project`) or in CI (`ci-review`, when `autonomy_mode` is on).

Single task, no initiative: `/compass:plan-feature "description"` → `/compass:implement` → `/compass:ship`. A reviewed, stable plan can run hands-off via `/compass:auto-implement` (stops at PR-open, never merges). Where does a feature stand? `/compass:status`. Full flow + diagrams: [`references/WORKFLOW.md`](references/WORKFLOW.md).

---

## Auto-fix the PR

Once a PR is open, Claude can drive it to green — watching CI and review comments and pushing fixes until checks pass. This is a **built-in Claude Code feature**: run `/autofix-pr` (terminal) or flip the **auto-fix** toggle in the PR's CI status bar (Desktop / web). compass adds a brake — `autofix_max_pushes` stops it if the PR keeps pushing without going green. Details: [`references/AUTONOMY.md`](references/AUTONOMY.md) → *Auto-fix the PR loop*.

---

## Documentation

Specs and outputs live in `.work/` (created on first use, **no tracker required**): `prds/`, `stories/`, `plans/` committed; `reports/`, `screenshots/` gitignored.

| Doc | What's inside |
|-----|---------------|
| [`references/COMMANDS.md`](references/COMMANDS.md) | Every command — arguments, behavior, when to run standalone |
| [`references/CONCEPTS.md`](references/CONCEPTS.md) | The why — frameworks and golden rules behind the workflow |
| [`references/WORKFLOW.md`](references/WORKFLOW.md) | The command flow — Loop 1, Loop 2, Quick Path, with diagrams |
| [`references/HANDBOOK.md`](references/HANDBOOK.md) | Models, `.work/` layout, config, trackers, test quality, troubleshooting |
| [`references/WORKTREES.md`](references/WORKTREES.md) | Git worktree mental model, lifecycle, isolation recipes |
| [`references/AUTONOMY.md`](references/AUTONOMY.md) | CI autonomy — modes, inline review, the auto-fix loop, auto-merge, costs, security |

---

## What's included

- **The plugin** (installed centrally; repo root is the plugin root): `commands/`, `agents/`, `skills/`, `hooks/`, `references/`, `scripts/`, `templates/`, `compass.schema.json`, `.claude-plugin/`.
- **In your repo** (generated by `/compass:setup`): `.claude/compass.yml`, `.claude/compass.schema.json`, `.claude/CLAUDE.md`, `.work/`, `.github/workflows/pr-validation.yml`, and `.mcp.json`.
