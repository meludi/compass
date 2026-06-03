# compass

A Claude Code **plugin** that brings a structured PIV Loop (Plan → Implement → Validate) to any project — with parallel subagent code review, automated E2E testing, and optional issue-tracker sync. Stack-agnostic, configured in one file. Commands are namespaced `/compass:<name>`.

---

## Requirements

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| [Claude Code](https://claude.ai/code) | AI coding assistant — runs all slash commands | `npm install -g @anthropic-ai/claude-code` |
| [Git](https://git-scm.com) | Version control + worktrees | pre-installed on most systems |
| [GitHub CLI](https://cli.github.com) (`gh`) | Creating PRs and fetching diffs for `/compass:ship` | `brew install gh` → `gh auth login` |
| [agent-browser](https://agent-browser.dev) | Browser smoke testing via `/compass:validate` | `brew install agent-browser` or `npm install -g agent-browser` → `agent-browser install` |

### Optional

| Tool | Purpose | Setup |
|------|---------|-------|
| [Linear](https://linear.app) | Issue tracker — stories can be synced as Linear issues | See below |
| [pnpm](https://pnpm.io) | Recommended package manager (content store = efficient parallel worktrees) | `npm install -g pnpm` or `brew install pnpm` |

---

### Linear setup (optional)

[Linear](https://linear.app) is not required — stories work fine in `.work/stories/` without it.

The Linear MCP server is configured in your project's `.mcp.json` — it starts automatically when Claude Code runs. You only need to provide your API key:

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
- `/compass:create-stories` saves stories to `.work/stories/` **and** creates Linear issues
- `/compass:plan-feature PROJ-42` loads the Linear issue as the session spec

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
Run `/compass:setup-tracker` to switch — it updates the 3 files that reference Linear.

| Tracker | Auth | MCP server | API keys / tokens |
|---------|------|-----------|-------------------|
| [Linear](https://linear.app) (default) | Bearer Token | [mcp.linear.app](https://mcp.linear.app) | [linear.app → Settings → API](https://linear.app/settings/api) |
| [Jira — Atlassian official Rovo MCP](https://www.atlassian.com/software/jira) | OAuth 2.1 (browser, no key) | [mcp.atlassian.com](https://mcp.atlassian.com/v1/mcp) | — |
| [Jira — community mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | API Token | [github.com/sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | [id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| [Azure DevOps — remote MCP](https://learn.microsoft.com/azure/devops/mcp-server) | OAuth via Entra ID (no key) | [mcp.dev.azure.com/{org}](https://learn.microsoft.com/azure/devops/mcp-server) | — |
| [Azure DevOps — local MCP](https://github.com/microsoft/azure-devops-mcp) | PAT | [github.com/microsoft/azure-devops-mcp](https://github.com/microsoft/azure-devops-mcp) | dev.azure.com → User Settings → Personal Access Tokens |

What `/compass:setup-tracker` changes:
- `.mcp.json` — MCP server config + auth
- `commands/context.md` — tool name for loading an issue (called by `/compass:plan-feature` and `/compass:implement`)
- `commands/create-stories.md` — tool name for creating issues

---

### agent-browser setup (optional)

[agent-browser.dev](https://agent-browser.dev) — used by `/compass:validate` for browser smoke testing before opening a PR.

Two installs required: the skill (tells Claude how to use the CLI) and the CLI itself (the actual binary).

**1. Install the skill** — ships with the compass plugin (no action needed); available as `/compass:agent-browser`.

**2. Install the CLI + browser:**

```bash
# Homebrew (recommended)
brew install agent-browser
agent-browser install   # downloads Chrome

# npm
npm install -g agent-browser
agent-browser install   # downloads Chrome
```

`/compass:validate` will detect automatically whether the CLI is available and the dev server is running — it skips the browser step silently if either is missing.

---

### CI & autonomy (optional)

The starter ships `.github/workflows/pr-validation.yml`. Default mode is
`off` — pure CI (lint + types + tests), no API calls. Opt in to inline Claude
PR reviews, auto-generated test checklists, and auto-merge by setting
`autonomy_mode` in `.claude/compass.yml`.

**Using an LLM for CI review needs an API key as a GitHub secret.** Whenever
`autonomy_mode` is `review-only` or `full`, the review runs in GitHub Actions —
so the key lives as a **repository secret**, not in `compass.yml` or a local
`.env`. Pick the provider with `ci_review_provider`, then set the matching
secret:

```bash
gh secret set ANTHROPIC_API_KEY   # ci_review_provider: claude (default)
gh secret set OPENAI_API_KEY      # ci_review_provider: openai
gh secret set GEMINI_API_KEY      # ci_review_provider: gemini
```

If the mode is on but the secret is missing, the review job fails (red) instead
of skipping. `/compass:setup-stack` checks for the secret and warns; it never sets it.

Full details, secrets, costs, and security notes: `${CLAUDE_PLUGIN_ROOT}/reference/AUTONOMY.md`.

---

### Deploying (optional)

Connect the repo to one of:

- **Vercel** — <https://vercel.com/new>, pick `base_branch` as production.
- **Coolify** (self-hosted) — create service, set branch, add Coolify webhook to GitHub.
- **Netlify** — <https://app.netlify.com>, pick `base_branch`, set build + publish dir.

Once configured, every merge to `base_branch` auto-deploys. The starter is
deploy-target-agnostic on purpose.

---

## Setup

**1. Install the plugin**

```
/plugin marketplace add meludi/compass
/plugin install compass@compass
```

The `/compass:*` commands, agents, skills, and the SessionStart orientation hook are now available in every project — nothing is copied into your repo. (For local development of compass itself: `claude --plugin-dir .` from a clone.)

**2. Configure**

Open your project in Claude Code and run:

```
/compass:setup
```

This will ask you a few questions (package manager, commands, repo, branch, DB file) and generate:

- `.claude/compass.yml` — your project config
- `.claude/CLAUDE.md` — your project conventions (generated from `CLAUDE-template.md`, living document)

`CLAUDE.md` is generated once by `/compass:setup` and updated by you as the project evolves.

**For greenfield projects** — directly after `/compass:ideate`, run:

```
/compass:setup-stack .work/prds/your-prd.prd.md
```

This scaffolds the framework, asks 4 style questions, creates canonical seed files, and fills the Code Patterns section of `CLAUDE.md`. Skip for brownfield projects — existing code already provides the patterns.

---

## How it works

Two-level workflow:

```
LEVEL 1 (once per initiative):  /compass:ideate (brain dump → PRD → self-review) → /compass:setup-stack (greenfield) → /compass:create-stories → stories in .work/stories/
LEVEL 2 (per story):            /compass:worktree → /compass:plan-feature → /compass:implement → /compass:ship
```

- **IDEATE** — brain dump with the agent, no structure yet
- **PIV** — Plan → Implement → Validate, the three phases of every story
- **Linear is optional** — stories live in `.work/stories/`; Linear sync is available but not required
- **Quick Path** — for typos, 1-line fixes, and CSS tweaks, skip PRD/stories/plan: `/compass:worktree → edit → /compass:validate → /compass:ship` (decline the review) — see WORKFLOW.md

Command flow: `${CLAUDE_PLUGIN_ROOT}/reference/WORKFLOW.md`
Reference (models, command table, troubleshooting): `${CLAUDE_PLUGIN_ROOT}/reference/HANDBOOK.md`
Concepts (the why): `${CLAUDE_PLUGIN_ROOT}/reference/CONCEPTS.md`

---

## Working directory: `.work/`

Commands write plans, PRDs, stories, and reports to `.work/` — created automatically on first use.

```
.work/
├── prds/        # specs from /compass:ideate                 → committed
├── stories/     # stories from /compass:create-stories       → committed
├── plans/       # plans from /compass:plan-feature           → committed
├── reports/     # build reports                      → gitignored
├── screenshots/ # browser screenshots                → gitignored
└── BACKLOG.md   # local backlog (no tracker)         → committed
```

---

## Project config

All project-specific values live in `.claude/compass.yml`:

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

It is schema-backed: `${CLAUDE_PLUGIN_ROOT}/project.schema.json` drives editor autocomplete + inline
validation (via the `# yaml-language-server: $schema=` line at the top of the file),
and `/compass:setup` validates against it — a mistyped key or bad value is reported, not
silently ignored. A single reader (`${CLAUDE_PLUGIN_ROOT}/scripts/read-config.sh`) parses it for
both `worktree.sh` and CI. Keep fields flat (no nesting).

---

## What's included

**The plugin** (installed centrally, never copied into your repo — repo root is the plugin root):

```
.claude-plugin/
├── plugin.json           # Plugin manifest — name, version, description
└── marketplace.json      # Marketplace catalog entry
commands/                 # All slash commands → invoked as /compass:<name>
agents/                   # Subagents: code-reviewer, codebase-explorer, pr-test-analyzer
skills/agent-browser/     # Skill for automated browser testing → /compass:agent-browser
hooks/
├── hooks.json            # SessionStart hook registration
└── session-start.sh      # Always-on orientation (PIV loop + on-demand doc index)
reference/
├── AUTONOMY.md           # CI autonomy layer — inline reviews, auto-merge, costs, security
├── CONCEPTS.md           # The four frameworks behind this workflow
├── WORKFLOW.md           # The command flow — Level 1, Level 2, Quick Path
├── HANDBOOK.md           # Reference — models, command table, troubleshooting
└── WORKTREES.md          # Git worktree mental model and lifecycle
scripts/
├── worktree.sh           # Worktree lifecycle script (create, open, remove)
└── read-config.sh        # Single reader for compass.yml (used by worktree.sh + CI)
templates/
├── CLAUDE-template.md    # /compass:setup generates your CLAUDE.md from this
└── husky-pre-commit.sh   # Pre-commit hook template — installed by /compass:setup if Husky is detected
project.schema.json       # JSON Schema for compass.yml — editor + /compass:setup validation
```

**Your project** (generated by `/compass:setup` / `/compass:setup-stack` — the only compass files in your repo):

```
.claude/
├── compass.yml           # Your project config — commands, repo, branch (edit this)
├── compass.schema.json   # Copy of the schema so the $schema line resolves in your editor
└── CLAUDE.md             # Your project conventions — generated, then a living document
.work/                    # Plans, PRDs, stories, reports (see "Working directory")
.github/workflows/
└── pr-validation.yml     # CI workflow — lint, types, tests; opt-in Claude PR review + auto-merge
.mcp.json                 # MCP server config (Linear by default; swap via /compass:setup-tracker)
```
