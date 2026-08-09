# compass

A Claude Code **plugin** that brings a structured PIV loop (Plan → Implement → Validate → Ship) to any project — file-level plans, per-task validation gates, browser smoke testing, and worktree isolation. Stack-agnostic, configured in one file. Commands are namespaced `/compass:<name>`.

Nine workflow commands, no more — plus `/compass:help`, which tells you which one you want. Specs, tickets and code review are left to tools that are maintained for you — [`references/WORKFLOW.md`](references/WORKFLOW.md) names which.

---

## Requirements

| Tool | Required? | If missing | Install |
|------|-----------|------------|---------|
| [Claude Code](https://claude.ai/code) | **Required** | Nothing runs — it executes every command | `npm install -g @anthropic-ai/claude-code` |
| [Git](https://git-scm.com) | **Required** | No version control, worktrees, or commits | pre-installed on most systems |
| [GitHub CLI](https://cli.github.com) (`gh`) | For PRs | Local PIV loop still works; `/compass:ship` can't push or open a PR | `brew install gh` → `gh auth login` |
| [agent-browser](https://agent-browser.dev) | Optional | `/compass:validate` skips the browser smoke test | `brew install agent-browser` → `agent-browser install` |

> compass is built for **GitHub** (`gh` + GitHub Actions). The local PIV loop is host-agnostic; only `/compass:ship` and `/compass:fix-ci-review` need GitHub. On GitLab/Bitbucket: push works, open the MR/PR yourself.

---

## Install

Run in a Claude Code session (or prefix each with `claude` in your terminal):

```
/plugin marketplace add meludi/compass
/plugin install compass@compass
```

Restart Claude Code afterwards (or `/reload-plugins`).

- **Project-only install** (terminal): add `--scope local` (private, gitignored) or `--scope project` (shared via git) to `claude plugin install compass@compass`.
- **Update:** `/plugin update compass`. Nothing to re-run in your projects — the `## Commands` table is yours, and a plugin update never touches it.

The plugin installs centrally — nothing is copied into your repo. (To hack on compass itself: `claude --plugin-dir .` from a clone.)

---

## Configure

From your project root:

```
/compass:setup
```

Generates one file: `.claude/CLAUDE.md` — project conventions, the review conventions, and the `## Commands` table. **compass has no config file of its own**; that table is the configuration, and you edit it directly.

| Row | Default | Controls |
|---|---|---|
| `Lint` · `Format` · `Type check` · `Test` | from `package.json` | what `/compass:validate` runs; a blank row is skipped, never guessed |
| **Test policy** | `first` | tests for logic tasks: `first` (TDD) · `after` · `none` |
| **Dev port** | `3000` | dev server port; blank disables the browser smoke test |
| **Base branch** | `origin/HEAD` | what PRs open against; delete the line to derive it |

Keep the row labels as generated — commands look them up by name. Nothing validates the table, so a typo fails quietly; the trade is no schema to refresh after a plugin update.

No CI workflow — that's not compass' job. For review on the PR, pick a reviewer once per repo — claude-code-action via `/install-github-app`, or Codex code review: [`references/WORKFLOW.md`](references/WORKFLOW.md) → *Automated PR review*.

Deployment is not compass' business — point Vercel, Netlify or your own host at your base branch and keep secrets in the host's env vars.

---

## Workflow

```
LOOP 1  worktree → plan-feature → implement → /code-review → ship    → PR open
LOOP 2  review lands → fix-ci-review → push → repeat                 → merge
```

Both loops in full — steps, diagrams, what runs before Loop 1, and where compass stops: [`references/WORKFLOW.md`](references/WORKFLOW.md).

---

## Documentation

Plans and outputs live in `.work/` (created on first use): `plans/` committed; `reports/`, `screenshots/` gitignored.

| Doc | What's inside |
|-----|---------------|
| [`references/WORKFLOW.md`](references/WORKFLOW.md) | The loops, with diagrams — and where compass stops |
| [`references/COMMANDS.md`](references/COMMANDS.md) | Every command in detail — arguments, behaviour, when to run them standalone |
| [`references/HANDBOOK.md`](references/HANDBOOK.md) | What "done" has to prove, why there is no config file, troubleshooting |
