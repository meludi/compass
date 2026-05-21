---
description: Execute an implementation plan step by step with validation after each task
argument-hint: <path to .work/plans/*.plan.md>
---

# /feature-build — Execute Implementation Plan

> **Recommended:** `/model sonnet` — balanced model for this command.

Execute a plan from `.work/plans/` step by step with validation after each task.

**Golden rule:** If validation fails, fix it before moving on. Never accumulate broken state.

## Input

`/feature-build <path to .work/plans/*.plan.md>`

## Steps

### 1. Load plan

- Read the plan file
- Read `.claude/project.yml` for `type_check_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`, `dev_port`
- Extract: goal, files to change, tasks, acceptance criteria
- Confirm branch is correct (`git branch --show-current`)

### 2. Execute tasks

For each task in the plan:

**Before writing any code:**

1. Read the target file you're about to create or modify
2. Read adjacent files it imports from or that import it
3. Verify the plan's references actually exist — functions, types, component names. If something is wrong, adapt before implementing.

**Implement:**
4. Follow the Mirror pattern from the plan
5. After implementing, verify integration: imports resolve, callers/callees still work, data flows correctly across boundaries

**Validate:**
6. Run `type_check_cmd` from `.claude/project.yml` (skip if blank):

- **PASS** → mark task `[x]` in the plan file, proceed
- **FAIL** → fix immediately, re-run, confirm PASS before proceeding

7. Never start the next task while the current task's type check is failing

### 3. Validate

After all tasks complete, run in order (from `.claude/project.yml`):

1. `lint_cmd && format_cmd`
2. `type_check_cmd` (skip if blank)
3. `test_cmd`

If any check fails: fix it before continuing. Report what failed and how it was fixed.

### 4. Write report

Save to `.work/reports/{feature-name}-report.md`:

```markdown
# Implementation Report: {Feature Name}

## Status: COMPLETE / PARTIAL / BLOCKED

## Tasks completed

- [x] Task 1
- [x] Task 2

## Validation results

- Type check: PASS / FAIL
- Tests: PASS / FAIL (N passing, N failing)
- Lint: PASS / FAIL

## Deviations from plan

{Any differences from what was planned}

## Next steps

{What the user needs to do: test manually, open PR, etc.}
```

### 5. Output

- Summarize what was built
- List files changed
- Report validation status
- Next step: run `/create-pr` to commit, push, and open the PR
