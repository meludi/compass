---
description: Create an implementation plan for a feature — plan only, no code written
argument-hint: <feature description | path to .work/prds/*.prd.md>
---

# /feature-plan — Create Implementation Plan

Transform a feature description into a concrete implementation plan. **Plan only — no code written.**

Run `/prime` first if you haven't already.

## Input

`/feature-plan <feature description | path to .work/prds/*.prd.md>`

## Steps

### 1. Understand the request

- Parse the feature description, or read the PRD / story file
- Identify: what changes, what is new, what must not break

### 2. Explore the codebase

Use the `codebase-explorer` subagent to find:

- Existing components, hooks, utilities that can be reused
- Naming patterns and file structure conventions
- Existing tests for similar features

If the feature requires an unknown library or pattern: spawn a web-search agent for isolated research. Only the summary returns to main context.

### 3. Design the changes

- List files to CREATE with their purpose
- List files to UPDATE with what changes
- Order tasks by dependency
- Identify risks and edge cases

### 4. Write the plan

Read `project.yml` for `type_check_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`. Save to `.work/plans/{kebab-case-feature-name}.plan.md`:

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
- **Validate**: `type_check_cmd` from project.yml

### Task 2: {Description}

- **File**: `src/...`
- **Action**: CREATE / UPDATE
- **Implement**: {what to do}
- **Mirror**: `src/path/to/example.ts:5-20`
- **Validate**: `type_check_cmd` from project.yml

{...repeat for each task}

## Validation

- `type_check_cmd` — types must pass
- `test_cmd` — all tests pass
- `lint_cmd && format_cmd` — no lint errors

## Acceptance criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
```

### 5. Output

Report: plan saved to `.work/plans/{name}.plan.md` — ready for `/feature-build`.
