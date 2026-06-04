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

> compass is built for **GitHub** (`gh` + GitHub Actions). The local PIV loop (plan → implement → validate → commit) is host-agnostic; only `/compass:ship` (open a PR) and the CI autonomy layer require GitHub. On GitLab/Bitbucket: push works, open the MR/PR yourself.

---

## Install

**Global** (available in every project) — run in a Claude Code session or in your terminal:

```
/plugin marketplace add meludi/compass
```
```
/plugin install compass@compass
```

Or equivalently from your terminal:

```bash
claude plugin marketplace add meludi/compass
```
```bash
claude plugin install compass@compass
```

**Project-only** (`.--scope` is not available in the `/plugin` slash command — use the terminal):

```bash
claude plugin marketplace add meludi/compass --scope local
```
```bash
claude plugin install compass@compass --scope local
```

- `--scope local` — this project only, private to you (`.claude/settings.local.json`, gitignored)
- `--scope project` — this project only, shared with collaborators via git (`.claude/settings.json`)

Restart Claude Code after installing (or run `/reload-plugins`).

**Update to a new version:**

```
/plugin update compass
```

Or from the terminal:

```bash
claude plugin marketplace update compass
```
```bash
claude plugin install compass@compass
```

Then configure your project (run from the project root in Claude Code):

```
/compass:setup
```

`/compass:setup` generates these project files:

- `.claude/compass.yml` — your project config
- `.claude/compass.schema.json` — editor autocomplete + validation
- `.claude/CLAUDE.md` — project conventions (a living document)
- `.mcp.json` — issue-tracker MCP, only if you opt into a tracker

**Greenfield project?** After `/compass:ideate`, run `/compass:setup-stack <prd>` to scaffold the stack.

**Existing project?** Run `/compass:onboard` to scan the codebase and fill `CLAUDE.md` with real patterns (architecture, code style, testing) instead of TODO stubs.

Nothing is copied into your repo — the plugin is installed centrally. (To hack on compass itself: `claude --plugin-dir .` from a clone.)

---

## Workflow

| Stage | When | Command flow |
|-------|------|--------------|
| **Stage 0 — Setup** | once per project / initiative | `/compass:setup` (or `/compass:onboard`) → `/compass:ideate` → `/compass:create-stories` |
| **Loop 1 — PIV** | per story | `/compass:worktree` → `/compass:plan-feature` → `/compass:implement` → `/compass:ship` → `/compass:reflect` |
| **Auto-implement** | plan reviewed + stable | `/compass:auto-implement <plan>` — automates Loop 1 steps 3–4 (implement + ship) (no confirmation at each step). Hard-stops at PR-open; never merges. |
| **Loop 2 — Fix** | until PR is clean | review → fix → `/compass:validate` → `/compass:commit [--push]` → repeat → merge |
| **Quick Path** | tiny fix (typo, 1-liner) | `/compass:worktree` → edit → `/compass:validate` → `/compass:ship` |

- **Single task without an initiative?** — `/compass:plan-feature "description"` → `/compass:implement` → `/compass:ship`. No story file needed.
- **CI review?** — set `autonomy_mode: review-only` in `compass.yml`; CI reviews every push, `/compass:fix-ci-review` applies the findings locally.
- **Full command reference:** [`references/COMMANDS.md`](references/COMMANDS.md)
- **Detailed command flow:** [`references/WORKFLOW.md`](references/WORKFLOW.md)

---

## Working directory — `.work/`

Your specs and outputs live in `.work/` (created on first use) — **no issue tracker required**. This is the default home for everything the workflow produces:

| Path | Holds | Git |
|------|-------|-----|
| `.work/prds/` | PRDs from `/compass:ideate` | committed |
| `.work/stories/` | stories from `/compass:create-stories` | committed |
| `.work/plans/` | plans from `/compass:plan-feature` | committed |
| `.work/reports/`, `.work/screenshots/` | build + validation output | gitignored |
| `.work/BACKLOG.md` | local backlog (when you skip a tracker) | committed |

---

## Configuration

One file drives everything: **`.claude/compass.yml`** (generated by `/compass:setup`) — commands, dev port, branch, tracker settings. Commands read it at runtime and it is schema-validated. Full field reference: [`references/HANDBOOK.md`](references/HANDBOOK.md).

**Optional integrations:**

- **Issue tracker** — **off by default**; specs live locally in `.work/` (above). To sync issues to a tracker, run `/compass:setup-tracker` — Linear is preconfigured, Jira and Azure DevOps are supported. Switching only rewrites project config, never command files.
- **CI & autonomy** — `/compass:setup-stack` installs a self-contained `.github/workflows/pr-validation.yml`: pure CI by default (lint + types + tests), with opt-in Claude PR review, checklists, and auto-merge via `autonomy_mode`. See [`references/AUTONOMY.md`](references/AUTONOMY.md).
- **Deploy** — point Vercel / Coolify / Netlify at the repo to auto-deploy on merge to `base_branch`. See [`references/HANDBOOK.md`](references/HANDBOOK.md).

**Supported trackers:**

| Tracker | Auth | MCP server |
|---------|------|-----------|
| [Linear](https://linear.app) (preconfigured) | API key | [mcp.linear.app](https://mcp.linear.app) |
| [Jira — Atlassian Rovo](https://www.atlassian.com/software/jira) | OAuth (no key) | [mcp.atlassian.com](https://mcp.atlassian.com/v1/mcp) |
| [Jira — community](https://github.com/sooperset/mcp-atlassian) | API token | [mcp-atlassian](https://github.com/sooperset/mcp-atlassian) |
| [Azure DevOps — remote](https://learn.microsoft.com/azure/devops/mcp-server) | OAuth (no key) | mcp.dev.azure.com/{org} |
| [Azure DevOps — local](https://github.com/microsoft/azure-devops-mcp) | PAT | [azure-devops-mcp](https://github.com/microsoft/azure-devops-mcp) |

---

## Documentation

| Doc | What's inside |
|-----|---------------|
| [`references/COMMANDS.md`](references/COMMANDS.md) | Every command — arguments, with/without behavior, when to run standalone |
| [`references/CONCEPTS.md`](references/CONCEPTS.md) | The why — the frameworks and golden rules behind the workflow |
| [`references/WORKFLOW.md`](references/WORKFLOW.md) | The command flow — Level 1, Level 2, Quick Path, fix loop |
| [`references/HANDBOOK.md`](references/HANDBOOK.md) | Models, `.work/` layout, project config, test quality, troubleshooting |
| [`references/WORKTREES.md`](references/WORKTREES.md) | Git worktree mental model, lifecycle, and isolation recipes |
| [`references/AUTONOMY.md`](references/AUTONOMY.md) | CI autonomy — modes, inline review, auto-merge, costs, security |

---

## What's included

- **The plugin** (installed centrally; repo root is the plugin root): `commands/`, `agents/`, `skills/`, `hooks/` (SessionStart orientation), `references/`, `scripts/`, `templates/`, `compass.schema.json`, `.claude-plugin/{plugin.json,marketplace.json}`.
- **Your project** (generated by `/compass:setup` — the only compass files in your repo): `.claude/compass.yml`, `.claude/compass.schema.json`, `.claude/CLAUDE.md`, `.work/` (plans, PRDs, stories), `.github/workflows/pr-validation.yml`, and `.mcp.json`.
