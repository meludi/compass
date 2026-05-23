---
description: Load context, then create an implementation plan for a feature — plan only, no code written
argument-hint: <path to .work/stories/*.md | issue-id | feature description>
---

# /plan-feature — Create Implementation Plan

> **Recommended:** `/model opus` + Plan Mode (`/plan`) — deep thinking for architecture decisions, no accidental execution.

Transform a story (or feature description) into a concrete implementation plan. **Plan only — no code written.**

This command loads project context itself, so it is the first thing you run in a fresh worktree session — and the command you re-run to resume a story later.

## Input

`/plan-feature <path to .work/stories/*.md | issue-id | feature description>`

## Steps

### 1. Load context

Build the mental model before planning.

**Spec** — if an argument was given:

- An **issue ID** (e.g. `PROJ-42`) → fetch it with `mcp__linear-server__get_issue`. Extract title, description, acceptance criteria, status.
- A **`.work/stories/*.md` path** → read the file. Extract title, acceptance criteria, technical notes.
- This becomes the spec for the session. With a plain feature description and no tracker, the description itself is the spec.

**Project rules:**

- `.claude/CLAUDE.md` — conventions, stack, patterns
- `.claude/project.yml` — commands, repo, base branch
- Any relevant reference docs from the CLAUDE.md On-Demand Context table

**Git state + existing plan:**

```bash
git branch --show-current
git log --oneline -5
git status --short
ls .work/plans/ 2>/dev/null
```

Recap in one or two lines: branch, spec, and whether a plan already exists.

**If a complete plan for this story already exists in `.work/plans/`:** do not re-plan. Report the current status — the plan, git state, what looks done vs. open — and recommend `/build` to continue. Proceed to step 2 only if the user explicitly asks for a new or revised plan.

### 2. Understand the request

- Read the story file from `.work/stories/` (or the issue, or parse the feature description)
- Identify: what changes, what is new, what must not break

### 3. Explore the codebase

Use the `codebase-explorer` subagent to find:

- Existing components, hooks, utilities that can be reused
- Naming patterns and file structure conventions
- Existing tests for similar features

If the feature requires an unknown library or pattern: spawn a web-search agent for isolated research. Only the summary returns to main context.

### 4. Design the changes

- List files to CREATE with their purpose
- List files to UPDATE with what changes
- Order tasks by dependency
- Identify risks and edge cases

### 5. Write the plan

Read `.claude/project.yml` for `type_check_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`. Save to `.work/plans/{kebab-case-feature-name}.plan.md`:

```markdown
# Plan: {Feature Name}

## Goal

One sentence: what this plan achieves.

## Patterns to follow

- {file:line} — example of naming/structure to mirror

## Optimization Strategy (optional)

- {performance consideration — only if relevant}

## Files to change

| Action | File    | Purpose |
| ------ | ------- | ------- |
| CREATE | src/... | ...     |
| UPDATE | src/... | ...     |

## Tasks

### Task 1: {Description}

- **File**: `src/...`
- **Action**: CREATE / UPDATE
- **Implement**: {what to do}
- **Mirror**: `src/path/to/example.tsx:10-30` — follow this pattern
- **Validate**: `type_check_cmd` from `.claude/project.yml`

### Task 2: {Description}

- **File**: `src/...`
- **Action**: CREATE / UPDATE
- **Implement**: {what to do}
- **Mirror**: `src/path/to/example.ts:5-20`
- **Validate**: `type_check_cmd` from `.claude/project.yml`

{...repeat for each task}

## Validation

- `type_check_cmd` — types must pass
- `test_cmd` — all tests pass
- `lint_cmd && format_cmd` — no lint errors

## Acceptance criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
```

### 6. Output

Report: plan saved to `.work/plans/{name}.plan.md` — ready for `/build`.
