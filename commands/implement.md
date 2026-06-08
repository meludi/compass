---
description: Execute an implementation plan step by step, with validation after each task and a full check at the end
argument-hint: <path to .work/plans/*.plan.md>
---

# /compass:implement — Execute Implementation Plan

> **Model:** `/model sonnet` — balanced model for this command.

Execute a plan from `.work/plans/` step by step with validation after each task.

**Golden rule:** If validation fails, fix it before moving on. Never accumulate broken state.

## Input

`/compass:implement <path to .work/plans/*.plan.md>`

## Steps

### 1. Load context

Execute the loading procedure from `${CLAUDE_PLUGIN_ROOT}/commands/context.md` (Steps 1–5). Critical for mid-story resume: project rules and git state are refreshed before continuing on an existing plan.

### 2. Load plan

- Read the plan file
- Read `.claude/compass.yml` for `type_check_cmd`, `test_cmd`, `test_policy`, `lint_cmd`, `format_cmd`, `dev_port`
- Extract: goal, files to change, tasks, acceptance criteria
- Confirm branch is correct (`git branch --show-current`)

### 3. Execute tasks

For each task in the plan:

**Before writing any code:**

1. Read the target file you're about to create or modify
2. Read adjacent files it imports from or that import it
3. Verify the plan's references actually exist — functions, types, component names. If something is wrong, adapt before implementing.

**Implement** — two paths depending on the task:

- **Logic-bearing task** (the task has a `Behavior` line in the plan — domain logic, data transforms, API handlers, hooks/functions with real logic): how the test relates to the code is set by `test_policy` in `.claude/compass.yml` (default `first`):
  - **`first`** (test-first / TDD): write **one** failing test for the behavior (RED), then the **minimal** code to make it pass (GREEN). One behavior → one bit of code → repeat. Do not write the whole task's tests up front (writing all tests first tends to test imagined, not actual, behavior).
  - **`after`** (test-after): write the minimal code first, then **one** unit test that pins the behavior. The test is still required — the task is not done until it exists and passes.
  - **`none`**: implement directly; no forced test for this task.

  When you do write a test (`first` or `after`), follow the test-quality rules in `references/HANDBOOK.md` → *Test quality*.
- **UI / glue / config task** (no `Behavior` line): follow the Mirror pattern from the plan directly; no forced test, regardless of `test_policy`.

For both: after implementing, verify integration — imports resolve, callers/callees still work, data flows correctly across boundaries.

**Validate:** run the task's gate (skip a command if blank in `.claude/compass.yml`):

- Logic task, `test_policy` `first` or `after` → the new **test passes** *and* `type_check_cmd` passes.
- Logic task, `test_policy` `none`, or UI/glue task → `type_check_cmd` passes.

Then:

- **PASS** → mark task `[x]` in the plan file, proceed
- **FAIL** → fix immediately, re-run, confirm PASS before proceeding

Never start the next task while the current task's gate is failing. Save broader cleanup/refactor for after the suite is green — use `/compass:review-code`; see `references/HANDBOOK.md` → *Refactor candidates* for what to scan for (do not refactor while a test is red).

### 4. Full validation

After all tasks complete, run the full validation suite — lint, type check, tests, and the browser smoke test. This is the same suite as `/compass:validate`; follow that command's process.

If any check fails: fix it before continuing. Report what failed and how it was fixed.

### 5. Write report

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
- Browser smoke test: PASS / FAIL / skipped

## Deviations from plan

{Any differences from what was planned}

## Next steps

{What the user needs to do: test manually, open PR, etc.}
```

### 6. Output

- Summarize what was built
- List files changed
- Report validation status
- Next step: run `/compass:ship` to commit, push, open the PR, and review

**Commit checkpoint:** if all checks passed, the working tree is a consistent unit. Before continuing, suggest a commit — `State is consistent ("<one-sentence description>") — run /compass:commit before continuing?` Suggest only; never commit without confirmation.
