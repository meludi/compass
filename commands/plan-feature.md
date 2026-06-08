---
description: Load context, then create an implementation plan for a feature — plan only, no code written
argument-hint: <path to .work/stories/*.md | issue-id | feature description>
---

# /compass:plan-feature — Create Implementation Plan

> **Model:** `/model opus` + Plan Mode (`/plan`) — deep thinking for architecture decisions, no accidental execution.

Transform a story (or feature description) into a concrete implementation plan. **Plan only — no code written.**

This command loads project context itself, so it is the first thing you run in a fresh worktree session — and the command you re-run to resume a story later.

## Input

`/compass:plan-feature <path to .work/stories/*.md | issue-id | feature description>`

## Steps

### 1. Load context

Execute the loading procedure from `${CLAUDE_PLUGIN_ROOT}/commands/context.md` (Steps 1–5). That file is the canonical home of loading logic — keeping it here would cause drift with `/compass:context` and `/compass:implement`.

**If the recap from `/compass:context` shows a complete plan for this story already exists in `.work/plans/`:** do not re-plan. Report the current status — the plan, git state, what looks done vs. open — and recommend `/compass:implement` to continue. Proceed to step 2 only if the user explicitly asks for a new or revised plan.

### 2. Understand the request

- Read the story file from `.work/stories/` (or the issue, or parse the feature description)
- Identify: what changes, what is new, what must not break

### 3. Explore the codebase

Use the `codebase-explorer` subagent to find:

- Existing components, hooks, utilities that can be reused
- Naming patterns and file structure conventions
- Existing tests for similar features — note the patterns so planned behaviors follow `references/HANDBOOK.md` → *Test quality* (behavior over implementation, public interface)

If the feature requires an unknown library or pattern: spawn a web-search agent for isolated research. Only the summary returns to main context.

### 4. Design the changes

- List files to CREATE with their purpose
- List files to UPDATE with what changes
- Order tasks by dependency
- Identify risks and edge cases

### 5. Write the plan

Read `.claude/compass.yml` for `type_check_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`. Save to `.work/plans/{kebab-case-feature-name}.plan.md`:

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
- **Behavior**: {observable behavior to verify with a test — include for logic-bearing tasks; omit for pure UI/glue/config}
- **Mirror**: `src/path/to/example.tsx:10-30` — follow this pattern
- **Validate**: `type_check_cmd` from `.claude/compass.yml`

### Task 2: {Description}

- **File**: `src/...`
- **Action**: CREATE / UPDATE
- **Implement**: {what to do}
- **Mirror**: `src/path/to/example.ts:5-20`
- **Validate**: `type_check_cmd` from `.claude/compass.yml`

{...repeat for each task}

The `Behavior` line marks a logic-bearing task and describes the observable behavior to verify. Add it only for tasks with real logic; leave it off for pure UI/glue/config tasks. Whether and when `/compass:implement` writes a test against it is set by `test_policy` in `.claude/compass.yml` — `first` (test-first, RED→GREEN), `after` (test-after), or `none` (no forced test).

## Validation

- `type_check_cmd` — types must pass
- `test_cmd` — all tests pass
- `lint_cmd && format_cmd` — no lint errors

## Acceptance criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
```

### 6. Output

Report: plan saved to `.work/plans/{name}.plan.md` — ready for `/compass:implement`.
