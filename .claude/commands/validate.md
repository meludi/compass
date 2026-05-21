---
description: Run linter, type checker, and tests — report any failures
---

# /validate

> **Recommended:** `/model haiku` — saves tokens, this command only runs shell checks.

Run all validation checks and report results.

**When to run**: Before `/create-pr`, or anytime you want a quick health check.

---

## Checks to Run

Read `.claude/project.yml` for the commands, then run in order:

1. `lint_cmd && format_cmd`
2. `type_check_cmd` — skip if blank
3. `test_cmd`

---

## Process

1. Run each check, capture output
2. Collect all failures
3. Report results

---

## Output

```
## Validation Results

| Check       | Result | Details                |
|-------------|--------|------------------------|
| Lint        | ✅/❌  | {N errors or "passed"} |
| Type check  | ✅/❌  | {N errors or "passed"} |
| Tests       | ✅/❌  | {N passed, M failed}   |

### Summary
- **Status**: ✅ ALL PASSING / ❌ {N} FAILURES
- **Action needed**: {None / list of things to fix}
```

---

## If Failures Found

List each failure with:

1. File and line number
2. Error message
3. Suggested fix (if obvious)

Fix all failures before proceeding to `/create-pr`.
