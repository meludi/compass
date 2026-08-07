---
description: Set up compass for a new project
---

# /compass:setup — Project Setup

> **Model:** `/model sonnet` — balanced model for this command.

Generates `.claude/CLAUDE.md` from the plugin template: project conventions, the commands compass runs, and the review conventions every reviewer reads. Run once per project after installing the plugin. One phase, one file — compass has no config file of its own.

---

## Steps

### 1. Scan the project

Gather what the template needs. Never guess — a value you cannot detect stays a placeholder.

- **Commands** — from `package.json` scripts when they exist: set `npm run lint` only if a `lint` script is present, and leave the row **blank** otherwise. A blank command is a gate that does not run, which is correct for a project that has no such gate. For non-JS projects (no `package.json`), leave the rows for the user.
- **Dev port** — from the dev script when it names one; else `3000`.
- **Base branch** — `git symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix stripped; fall back to the current branch.
- **Tech stack, directory structure, key files** — scan the repo (brownfield); leave placeholders on an empty one.

### 2. Generate `.claude/CLAUDE.md`

Read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-template.md` and write the filled result to `.claude/CLAUDE.md` (create `.claude/` if needed).

**Never overwrite an existing `.claude/CLAUDE.md`.** If one is there, report what a fresh scan would have put in the `## Commands` table, and let the user merge. Their file may carry weeks of hand-written conventions.

**Do not** inline the compass workflow guidance or the framework doc index — the SessionStart hook injects both. The only on-demand table in `CLAUDE.md` is the project-specific *Project Context* one.

**Fill immediately:** project description, tech stack, the `## Commands` table, directory structure, key files.

**Mark as `TODO: update after first feature`:** code patterns (naming, error handling, file organization), architecture details, testing patterns. Do not invent them and do not leave them blank.

Keep the `## Commands` table's row labels exactly as the template spells them — `Dev`, `Build`, `Lint`, `Format`, `Type check`, `Test`. `/compass:validate` and `/compass:implement` look them up by name.

Do not modify `CLAUDE-template.md` — it stays the reusable source.

**No CI workflow and no `.mcp.json`.** compass ships neither. The checks run locally in `/compass:validate` before every ship, and a workflow that runs your test suite on the PR is generic CI your stack already has a template for. PR *review* comes from claude-code-action — mention `/install-github-app` in the closing output, but do not set it up here.

### 3. Confirm

```
Generated: .claude/CLAUDE.md
  Branch:   {base branch}
  Test:     {test command}
  Dev port: {dev port}

  ✓ Filled:  description, tech stack, commands, directory structure
  ~ TODO:    code patterns, architecture details, testing patterns
             → update after your first feature

Everything compass reads lives in that file. Edit it directly — the ## Commands
table is the configuration.

Next: /compass:plan-feature <your spec> — describe the feature, get a plan.

Optional, once per repo:
  /install-github-app   PR review (anthropics/claude-code-action). It offers two
                        workflows: "Claude Code Review" reviews every PR by itself,
                        "Claude PR Assistant" answers @claude mentions.
```
