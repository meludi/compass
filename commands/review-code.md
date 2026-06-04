---
description: Deep code review with a tunable effort level. Use for correctness / bugs / direct fixing. Runs the built-in /code-review, then runs /compass:validate when --fix was used (fixes can break lint/types/tests).
argument-hint: "[low|medium|high|max|ultra] [--fix] [--comment] [PR-number]"
---

# /compass:review-code — Deep Code Review

> **Model:** inherits from the built-in `/code-review` (Sonnet for low–high; cloud Opus for `ultra`).

Wraps the built-in `/code-review` with compass-specific follow-up: after `--fix` applies
changes, it always runs `/compass:validate` — because fixes can silently break
lint, types, or tests.

Complementary to `/compass:review-project` (which fans out 3 subagents tuned to *your* project
conventions, patterns, and test coverage — advisory only). Use both, or pick by need:

| Use | Command |
|-----|---------|
| Bugs, correctness, direct fixing | `/compass:review-code [level] [--fix]` |
| Your CLAUDE.md conventions, reuse, test-gap audit | `/compass:review-project` |

---

## Step 0 — Session check

Prompt the user:

> For the sharpest results, run `/clear` first, then re-run `/compass:review-code` — or proceed with current session? (y/n)

- **y** → continue
- **n** → stop

---

## Effort levels

| Level | Cost | Use it for |
|-------|------|-----------|
| `low` / `medium` | cheap, fast | Small diffs, quick pre-ship pass; few but high-confidence findings |
| `high` | moderate | Normal feature work — broader coverage, may include less-certain findings |
| `max` | high | Risky changes where a missed bug is costly; widest local coverage |
| `ultra` | highest (cloud) | High-stakes: DB migrations, auth, payment logic, large refactors |

Pass the level explicitly — don't rely on the default. **Match the level to the risk.**

---

## Usage

```
/compass:review-code low              # quick pass (cheap)
/compass:review-code high --fix       # deep hunt + apply fixes
/compass:review-code ultra 42         # cloud review of PR #42
/compass:review-code high --comment   # post findings as inline PR comments
```

---

## Steps

1. Run: `/<effort-level>` is passed through to the built-in `/code-review` with all
   flags (`--fix`, `--comment`, PR number) as given.

2. When `--fix` was used and findings were applied:

   ```
   /code-review applied fixes. Running /compass:validate to confirm nothing is broken.
   ```

   Run `/compass:validate` automatically. If validation fails, report what broke and
   stop — do **not** commit until clean.

3. When no `--fix` was used (advisory pass): report findings inline. Nothing is applied.
   The author decides on each finding.

---

## Rules

- **Never commits.** Even with `--fix`, the commit is always a deliberate human step
  (via `/compass:commit` or `/compass:ship`).
- **Always validate after `--fix`.** A patch that fixes a bug can break a type or a
  test — do not skip this.
- **Not a replacement for CI review.** In `review-only`/`full` mode, the CI
  `claude-review` already reviewed the PR diff. Use `/compass:fix-ci-review` to act
  on those findings instead of re-reviewing the same diff here.
