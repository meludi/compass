---
description: Load project context — rules, git state, spec, and on-demand docs
argument-hint: [path to .work/stories/*.md | issue-id | feature description]
---

# /context — Build the Project Mental Model

> **Recommended:** `/model sonnet` — light, just reading and summarizing.

Build the project mental model: read project rules, capture git state, optionally load a spec (issue, story, or feature description), and surface any existing plan or report for the current story.

`/plan-feature` and `/implement` call this loading procedure as their first step — you do not need to run `/context` separately before them.

**When to run on its own:**

- **Mid-story resume** — coming back to a worktree after time away; refresh rules and git state before continuing with `/implement`.
- **Stale session** — long conversation, context feels confused; reload to get oriented.
- **Before `/reflect`** — refresh project state before analyzing what to evolve.

## Input

`/context [<path to .work/stories/*.md | issue-id | feature description>]`

Argument is **optional** — bare `/context` just reloads rules + git state.

## Steps

### 1. Project rules

- `.claude/CLAUDE.md` — conventions, stack, patterns
- `.claude/project.yml` — commands, repo, base branch
- Reference docs from the CLAUDE.md "On-Demand Context" table — pull selectively based on the task at hand

### 2. Git state

```bash
git branch --show-current
git log --oneline -5
git status --short
```

### 3. Spec — if an argument was given

- An **issue ID** (e.g. `PROJ-42`) → fetch with `mcp__linear-server__get_issue`. Extract title, description, acceptance criteria, status.
- A **`.work/stories/*.md` path** → read the file. Extract title, acceptance criteria, technical notes.
- A **plain feature description** (and no tracker configured) → the description itself is the spec.

This becomes the spec for the session.

### 4. Existing plan and report

```bash
ls .work/plans/ .work/reports/ 2>/dev/null
```

If a plan or report for the current spec exists, read it.

### 5. Recap

Recap in 2–3 lines: branch, spec (if loaded), plan/report status, recommended next step (e.g. "ready for `/plan-feature`" or "plan exists, ready for `/implement`").

If a complete plan already exists and code looks done: report status and suggest `/ship` instead.
