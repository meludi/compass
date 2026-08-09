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

Refresh the mental model before touching an existing plan — critical for mid-story resume:

- `.claude/CLAUDE.md` — conventions, stack, patterns, review conventions
- Git state: `git branch --show-current`, `git log --oneline -5`, `git status --short`
- Any existing report in `.work/reports/` for this feature

### 2. Load plan

- Read the plan file
- Read the `## Commands` table in `.claude/CLAUDE.md` — the gate commands, plus the **Test policy** and **Dev port** lines below it
- Extract: goal, files to change, tasks, acceptance criteria
- Confirm branch is correct (`git branch --show-current`)

**Say what you found before you rely on it.** Nothing validates that table, so a silent
fallback is indistinguishable from a deliberate choice. Print one line before Task 1, and
only when something is off:

- **Test policy** present but not one of `first` / `after` / `none` → `Test policy "<value>" is not first/after/none — using first.` A typo must not look like a decision.
- No **Type check** or **Test** *label* at all (as opposed to a label with a blank command) → name it, and note the gate will not run.

One line, then continue. Neither case stops the run.

### 3. Execute tasks

For each task in the plan:

**Before writing any code:**

1. Read the target file you're about to create or modify
2. Read adjacent files it imports from or that import it
3. Verify the plan's references actually exist — functions, types, component names. If something is wrong, adapt before implementing.

**Implement** — two paths depending on the task:

- **Logic-bearing task** (the task has a `Behavior` line in the plan — domain logic, data transforms, API handlers, hooks/functions with real logic): how the test relates to the code is set by the **Test policy** line in `.claude/CLAUDE.md` (default `first` when absent):
  - **`first`** (test-first / TDD): write **one** failing test for the behavior, **run it, and watch it fail for the expected reason** — the missing behavior, not a typo or an unresolved import. A test that errors out, or passes before the code exists, proves nothing — fix it until it fails for the right reason. That is RED. Then write the **minimal** code to make it pass and re-run to confirm GREEN. One behavior → one bit of code → repeat. Do not write the whole task's tests up front (writing all tests first tends to test imagined, not actual, behavior). If you catch yourself writing the code before its test, stop — the test can no longer prove the behavior; write the test first.
  - **`after`** (test-after): write the minimal code first, then **one** unit test that pins the behavior. The test is still required — the task is not done until it exists and passes.
  - **`none`**: implement directly; no forced test for this task.

  **A blank `Test` row overrides all three** — a project with no test command cannot watch a test go RED, so treat the policy as `none` and say so once rather than failing the gate.

  When you do write a test (`first` or `after`), test observable behaviour through the public interface, never implementation details. If the `tdd` skill is available, follow it — it is the fuller reference on seams, anti-patterns, and the rules of the loop.
- **UI / glue / config task** (no `Behavior` line): follow the Mirror pattern from the plan directly; no forced test, regardless of the policy.

For both: after implementing, verify integration — imports resolve, callers/callees still work, data flows correctly across boundaries.

**Validate:** run the task's gate (skip a command whose row is blank):

- Logic task, policy `first` or `after` → the new **test passes** *and* **Type check** passes.
- Logic task, policy `none`, or UI/glue task → **Type check** passes.

Then:

- **PASS** → mark task `[x]` in the plan file, proceed
- **FAIL** → fix immediately, re-run, confirm PASS before proceeding

Never start the next task while the current task's gate is failing.

**3-fix boundary (binding):** if the gate still fails after **three** distinct attempts at the same cause, stop patching — you may not make a fourth blind change. Switch to root-cause mode: reproduce, isolate, form one hypothesis, test it. Three misses mean the diagnosis is wrong, not the fix. If the `diagnosing-bugs` skill is available, use it. Save broader cleanup for after the suite is green — never refactor while a test is red.

**Loop log:** whenever you hit something the plan does not already say — a decision made while coding, a snag, a "tried X — failed because Y" landmine — append one line to the `## Loop log` section of the plan file (`.work/plans/{feature}.plan.md`). Deltas only; do not restate the plan. This is the feature's durable scratch space for the next session or developer; live status comes from `git` and `gh`, not from a file.

### 4. Full validation

After all tasks complete, run the full validation suite — lint, type check, tests, and the browser smoke test. This is the same suite as `/compass:validate`; follow that command's process.

If any check fails: fix it before continuing. Report what failed and how it was fixed.

Report the suite as passing only from the **fresh output you just ran** — never from memory, a stale run, or a hedge ("should pass"). See `references/HANDBOOK.md` → *Verification before completion*.

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
- Report validation status — from the actual run in Step 4, with no hedged claims
- Next step: **`/code-review`** on the branch, then `/compass:ship`. Reviewing before the PR exists is the cheapest place to fix anything — a finding costs one edit instead of a push, a CI run and a review round. For a trivial diff, go straight to `/compass:ship`.

**Commit checkpoint:** if all checks passed, the working tree is a consistent unit. Before continuing, suggest a commit — `State is consistent ("<one-sentence description>") — run /compass:commit before continuing?` Suggest only; never commit without confirmation.
