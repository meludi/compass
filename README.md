# claude-workflow-starter

A drop-in Claude Code workflow for any project. Brings a structured PIV Loop (Plan → Implement → Validate) with parallel subagent code review, automated E2E testing, and Linear integration — stack-agnostic, configured in one file.

---

## Setup

**1. Copy into your project**

```bash
cp -r claude-workflow-starter/.claude your-project/
```

Or use it as a Git submodule / template.

**2. Configure**

Open your project in Claude Code and run:

```
/init
```

This will ask you a few questions (package manager, commands, repo, branch) and generate:

- `.claude/project.yml` — your project config
- `.claude/CLAUDE.md` — your project conventions (from `CLAUDE-template.md`)

---

## Commands and Workflow

Full reference: `.claude/reference/WORKFLOW.md` → Command Reference

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
```

Commands read this file at runtime — change a value once, all commands pick it up.

---

## What's included

```
.claude/
├── CLAUDE-template.md     # Template for your project conventions
├── agents/                # Subagents: code-reviewer, codebase-explorer, pr-test-analyzer
├── commands/              # All slash commands
├── project.yml            # Project config — commands, repo, branch
├── reference/WORKFLOW.md  # Full workflow guide
└── skills/agent-browser/  # Automated browser testing via Playwright
```
