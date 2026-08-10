---
description: Load context, then create an implementation plan for a feature — plan only, no code written
argument-hint: <spec file | issue-id | feature description>
---

# /compass:plan-feature — Create Implementation Plan

> **Model:** `/model opus` + Plan Mode (`/plan`) — deep thinking for architecture decisions, no accidental execution.

Transform a story (or feature description) into a concrete implementation plan. **Plan only — no code written.**

This command loads project context itself, so it is the first thing you run in a fresh worktree session — and the command you re-run to resume a story later.

## Input

`/compass:plan-feature <spec file | issue-id | feature description>`

## Steps

### 1. Load context

Build the mental model before planning:

- `.claude/CLAUDE.md` — conventions, stack, patterns, review conventions, and `## Commands`: the gate commands, test policy, base branch
- Git state: `git branch --show-current`, `git log --oneline -5`, `git status --short`
- `ls .work/plans/ .work/reports/ 2>/dev/null` — existing plan or report for this story

**If a complete plan for this story already exists in `.work/plans/`:** do not re-plan. Report the current status — the plan, git state, what looks done vs. open — and recommend `/compass:implement` to continue. Proceed to step 2 only if the user explicitly asks for a new or revised plan.

### 2. Understand the request

- Read the spec. A **file path** is read as given — that is the ordinary case, and no `gh` is involved. An **issue-id** is fetched (`gh issue view <id>`) and its title printed back before planning: an id resolved against the wrong list is the most expensive silent error in this command. Anything else is taken as the description you typed.
- Identify: what changes, what is new, what must not break

### 3. Explore the codebase

Use the built-in `Explore` subagent to find:

- Existing components, hooks, utilities that can be reused
- Naming patterns and file structure conventions
- Existing tests for similar features — note the patterns so planned behaviors are stated as observable behavior through the public interface, not implementation

If the feature requires an unknown library or pattern: spawn a web-search agent for isolated research. Only the summary returns to main context.

**Done when every file the plan will touch has a real `Mirror:` target** — a `file:line` you have opened, not a path you assume exists. A task with no mirror means the exploration stopped early: go find the closest existing example, or state in the plan that none exists and why.

### 4. Design the changes

- List files to CREATE with their purpose
- List files to UPDATE with what changes
- Order tasks by dependency
- Identify risks and edge cases

### 5. Write the plan

Read the `## Commands` table in `.claude/CLAUDE.md` for the gate commands. Save to `.work/plans/{kebab-case-feature-name}.plan.md`:

```markdown
# Plan: {Feature Name}

## Goal

One sentence: what this plan achieves.

## Source

{`owner/repo#42` · path to the spec file · `conversation` — where this plan came from.
Do not restate its contents; the sections below are what this plan adds.}

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
- **Behavior**: {observable behavior to verify with a test — include for logic-bearing tasks; omit for pure UI/glue/config}
- **Mirror**: `src/path/to/example.tsx:10-30` — follow this pattern
- **Validate**: the `Type check` command from `.claude/CLAUDE.md`

### Task 2: {Description}

- **File**: `src/...`
- **Action**: CREATE / UPDATE
- **Implement**: {what to do}
- **Mirror**: `src/path/to/example.ts:5-20`
- **Validate**: the `Type check` command from `.claude/CLAUDE.md`

{...repeat for each task}

The `Behavior` line marks a logic-bearing task and describes the observable behavior to verify. Add it only for tasks with real logic; leave it off for pure UI/glue/config tasks. Whether and when `/compass:implement` writes a test against it is set by the **Test policy** line in `.claude/CLAUDE.md` — `first` (test-first, RED→GREEN), `after` (test-after), or `none` (no forced test).

## Validation

- `Type check` — types must pass
- `Test` — all tests pass
- `Lint` + `Format` — no lint errors

## Acceptance criteria

- [ ] {criterion 1}
- [ ] {criterion 2}

## Loop log

<!-- Filled in during implementation/fix, not now. Capture only what the plan
     above does NOT already say: decisions made while coding, snags hit,
     "tried X — failed because Y" landmines, and any handover note. Deltas only,
     never a restatement of the plan. This is the feature's only durable scratch
     space — live status (PR/CI/findings) comes from git and gh, not a file. -->
```

### 6. Output

Report: plan saved to `.work/plans/{name}.plan.md` — ready for `/compass:implement`.
