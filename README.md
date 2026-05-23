# claude-workflow-starter

A drop-in Claude Code workflow for any project. Brings a structured PIV Loop (Plan → Implement → Validate) with parallel subagent code review, automated E2E testing, and optional issue-tracker sync — stack-agnostic, configured in one file.

---

## Requirements

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| [Claude Code](https://claude.ai/code) | AI coding assistant — runs all slash commands | `npm install -g @anthropic-ai/claude-code` |
| [Git](https://git-scm.com) | Version control + worktrees | pre-installed on most systems |
| [GitHub CLI](https://cli.github.com) (`gh`) | Creating PRs and fetching diffs for `/ship` | `brew install gh` → `gh auth login` |
| [agent-browser](https://agent-browser.dev) | Browser smoke testing via `/validate` | `brew install agent-browser` or `npm install -g agent-browser` → `agent-browser install` |

### Optional

| Tool | Purpose | Setup |
|------|---------|-------|
| [Linear](https://linear.app) | Issue tracker — stories can be synced as Linear issues | See below |
| [pnpm](https://pnpm.io) | Recommended package manager (content store = efficient parallel worktrees) | `npm install -g pnpm` or `brew install pnpm` |

---

### Linear setup (optional)

[Linear](https://linear.app) is not required — stories work fine in `.work/stories/` without it.

The Linear MCP server is already configured in `.mcp.json` (included in this repo) — it starts automatically when Claude Code runs. You only need to provide your API key:

1. Get your Linear API key: [linear.app](https://linear.app) → Settings → API → Personal API keys
2. Add to `.claude/settings.local.json` (gitignored — create if it doesn't exist):

```json
{
  "env": {
    "LINEAR_API_KEY": "lin_api_..."
  },
  "enabledMcpjsonServers": ["linear-server"],
}
```

With this in place:
- `/create-stories` saves stories to `.work/stories/` **and** creates Linear issues
- `/plan-feature PROJ-42` loads the Linear issue as the session spec

---

### Linear + GitHub integration (optional)

Connecting Linear to GitHub is not required for this workflow — PRs are created via `gh` independently. But the integration adds useful automation:

| Without connection | With connection |
|---|---|
| PR and Linear issue exist independently | Branch `feat/PROJ-42-name` auto-links to the issue |
| Manual tracking | PR status visible inside the Linear issue |
| Manual close | Issue moves to "Done" automatically on merge |
| No metrics | Cycle time tracked automatically |

**Setup:** [linear.app](https://linear.app) → Settings → Integrations → GitHub → connect your repo.

---

### Alternative issue trackers (optional)

The workflow is not tied to Linear. Any issue tracker with an MCP server works.
Run `/setup-tracker` to switch — it updates the 3 files that reference Linear.

| Tracker | Auth | MCP server | API keys / tokens |
|---------|------|-----------|-------------------|
| [Linear](https://linear.app) (default) | Bearer Token | [mcp.linear.app](https://mcp.linear.app) | [linear.app → Settings → API](https://linear.app/settings/api) |
| [Jira — Atlassian official Rovo MCP](https://www.atlassian.com/software/jira) | OAuth 2.1 (browser, no key) | [mcp.atlassian.com](https://mcp.atlassian.com/v1/mcp) | — |
| [Jira — community mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | API Token | [github.com/sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | [id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| [Azure DevOps — remote MCP](https://learn.microsoft.com/azure/devops/mcp-server) | OAuth via Entra ID (no key) | [mcp.dev.azure.com/{org}](https://learn.microsoft.com/azure/devops/mcp-server) | — |
| [Azure DevOps — local MCP](https://github.com/microsoft/azure-devops-mcp) | PAT | [github.com/microsoft/azure-devops-mcp](https://github.com/microsoft/azure-devops-mcp) | dev.azure.com → User Settings → Personal Access Tokens |

What `/setup-tracker` changes:
- `.mcp.json` — MCP server config + auth
- `commands/plan-feature.md` — tool name for loading an issue
- `commands/create-stories.md` — tool name for creating issues

---

### agent-browser setup (optional)

[agent-browser.dev](https://agent-browser.dev) — used by `/validate` for browser smoke testing before opening a PR.

Two installs required: the skill (tells Claude how to use the CLI) and the CLI itself (the actual binary).

**1. Install the skill** (already included in this repo — no action needed):

```
.claude/skills/agent-browser/   ← already present
```

**2. Install the CLI + browser:**

```bash
# Homebrew (recommended)
brew install agent-browser
agent-browser install   # downloads Chrome

# npm
npm install -g agent-browser
agent-browser install   # downloads Chrome
```

`/validate` will detect automatically whether the CLI is available and the dev server is running — it skips the browser step silently if either is missing.

---

## Setup

**1. Copy into your project**

```bash
cp -r claude-workflow-starter/.claude your-project/
cp -r claude-workflow-starter/.work your-project/
cp claude-workflow-starter/.gitignore your-project/  # or merge manually
```

**2. Configure**

Open your project in Claude Code and run:

```
/setup
```

This will ask you a few questions (package manager, commands, repo, branch, DB file) and generate:

- `.claude/project.yml` — your project config
- `.claude/CLAUDE.md` — your project conventions (generated from `CLAUDE-template.md`, living document)

`CLAUDE.md` is generated once by `/setup` and updated by you as the project evolves.

**For greenfield projects** — directly after `/ideate`, run:

```
/setup-stack .work/prds/your-prd.prd.md
```

This scaffolds the framework, asks 4 style questions, creates canonical seed files, and fills the Code Patterns section of `CLAUDE.md`. Skip for brownfield projects — existing code already provides the patterns.

---

## How it works

Two-level workflow:

```
LEVEL 1 (once per initiative):  /ideate (brain dump → PRD → self-review) → /setup-stack (greenfield) → /create-stories → stories in .work/stories/
LEVEL 2 (per story):            /worktree → /plan-feature → /implement → /ship
```

- **IDEATE** — brain dump with the agent, no structure yet
- **PIV** — Plan → Implement → Validate, the three phases of every story
- **Linear is optional** — stories live in `.work/stories/`; Linear sync is available but not required
- **Quick Path** — for typos, 1-line fixes, and CSS tweaks, skip PRD/stories/plan: `/worktree → edit → /validate → /ship` (decline the review) — see WORKFLOW.md

Command flow: `.claude/reference/WORKFLOW.md`
Reference (models, command table, troubleshooting): `.claude/reference/HANDBOOK.md`
Concepts (the why): `.claude/reference/CONCEPTS.md`

---

## Working directory: `.work/`

Commands write plans, PRDs, stories, and reports to `.work/` — created automatically on first use.

```
.work/
├── prds/        # specs from /ideate                 → committed
├── stories/     # stories from /create-stories       → committed
├── plans/       # plans from /plan-feature           → committed
├── reports/     # build reports                      → gitignored
├── screenshots/ # browser screenshots                → gitignored
└── BACKLOG.md   # local backlog (no tracker)         → committed
```

---

## Project config

All project-specific values live in `.claude/project.yml`:

```yaml
name: my-project
repo: owner/my-project
base_branch: main
package_manager: pnpm
dev_cmd: pnpm dev
dev_port: 3000
test_cmd: pnpm test
lint_cmd: pnpm lint:fix
format_cmd: pnpm format
type_check_cmd: pnpm tsc --noEmit
src_dir: src/
worktree_prefix: ../my-project-
db_file: myapp.db          # optional — copied per worktree for isolation
```

Commands read this file at runtime — change a value once, all commands pick it up.

---

## What's included

```
.claude/
├── CLAUDE-template.md     # Template for your project conventions — /setup generates CLAUDE.md from this
├── agents/                # Subagents: code-reviewer, codebase-explorer, pr-test-analyzer
├── commands/              # All slash commands
├── project.yml            # Project config — commands, repo, branch
├── reference/
│   ├── CONCEPTS.md        # The four frameworks behind this workflow
│   ├── WORKFLOW.md        # The command flow — Level 1, Level 2, Quick Path
│   ├── HANDBOOK.md        # Reference — models, command table, troubleshooting
│   └── WORKTREES.md       # Git worktree mental model and lifecycle
├── scripts/
│   └── worktree.sh        # Worktree lifecycle script (create, open, remove)
└── skills/agent-browser/  # Skill definition for automated browser testing (agent-browser CLI)
```
