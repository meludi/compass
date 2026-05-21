---
description: Run linter, type checker, tests, and browser smoke test — report any failures
---

# /validate

> **Recommended:** `/model sonnet` — needed for browser interaction step.

Run all validation checks and report results.

**When to run**: Before `/create-pr`, or anytime you want a full health check.

---

## Checks to Run

Read `.claude/project.yml` for the commands, then run in order:

1. `lint_cmd && format_cmd`
2. `type_check_cmd` — skip if blank
3. `test_cmd`
4. Browser smoke test — only if `dev_port` is set and dev server is reachable

---

## Process

1. Run checks 1–3, capture output
2. Check 4 — browser smoke test (see below)
3. Collect all failures
4. Report results

---

## Browser Smoke Test

Only run if `dev_port` is set in `project.yml`. Check if the dev server is reachable:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:{dev_port}
```

**If server responds (2xx/3xx):** use the `agent-browser` skill to verify the UI:

```bash
agent-browser open http://localhost:{dev_port}
agent-browser snapshot -i                                         # check interactive elements load
agent-browser screenshot .work/screenshots/validate-{timestamp}.png
agent-browser close
```

Report: screenshot path + any console errors found (`agent-browser errors`).

**If server is not running:** skip silently — add note "Browser: skipped (dev server not running)" to output.

**If `dev_port` is blank:** skip entirely — project has no UI.

---

## Output

```
## Validation Results

| Check       | Result | Details                                        |
|-------------|--------|------------------------------------------------|
| Lint        | ✅/❌  | {N errors or "passed"}                         |
| Type check  | ✅/❌  | {N errors or "passed"}                         |
| Tests       | ✅/❌  | {N passed, M failed}                           |
| Browser     | ✅/❌/⏭ | {screenshot path / errors / skipped reason}  |

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
