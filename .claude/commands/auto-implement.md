---
description: Execute a confirmed plan all the way to PR-open without intermediate confirmation
argument-hint: <path to .work/plans/*.plan.md>
---

# /auto-implement — Plan to PR without confirmation

> **Model:** `/model sonnet` — use only when the plan in `.work/plans/` has already been reviewed and approved.

This is the **explicit, sanctioned exception** to the `Never auto-commit` rule. It runs the entire pipeline from a confirmed plan to an open PR without asking — implement, validate, commit, push, open PR. It **never** merges. The PR-open is the hard stop.

If you have not reviewed the plan yet, use `/implement` followed by `/ship` instead. Auto-implementing an unreviewed plan is dangerous.

## When to run

- The plan in `.work/plans/<feature>.plan.md` is reviewed and stable.
- The story is small to medium and follows existing patterns.
- No risky changes (DB migrations, auth/security boundaries, first-time use of a new library).

For everything else, stay with `/implement` → `/ship`.

## Input

`/auto-implement <path to .work/plans/*.plan.md>`

## Pre-flight checks (any failure → abort, no commit, no push)

1. **Branch guard** — `git branch --show-current` must match `feat/*`. Refuse on `base_branch` (from `.claude/compass.yml`), `main`, or any non-`feat/*` branch.
2. **Worktree guard** — the working directory must match the `worktree_prefix` pattern from `.claude/compass.yml`. Refuse if running in the main project directory.
3. **Plan exists** — the path argument resolves to a readable file under `.work/plans/`.
4. **Working tree** — `git status --porcelain` either empty, or only contains files within this plan's declared scope. If unrelated changes exist: abort and ask the user to clean up first.

Report which check failed and stop. Do not proceed to Phase 1.

## Phase 1 — Implement

Execute Steps 1–5 from `commands/implement.md`:

1. Load context (`commands/context.md` Steps 1–5).
2. Load plan, read `.claude/compass.yml` for `type_check_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`, `dev_port`, `base_branch`, `worktree_prefix`, `repo`, `src_dir`.
3. Execute tasks one by one with per-task `type_check_cmd` after each. On type-check failure: fix, re-run, confirm PASS before continuing.
4. After all tasks: full validation suite — lint, type check, tests, browser smoke test (same suite as `/validate`).
5. Write the implementation report to `.work/reports/<feature>-report.md`.

**Hard stop on any validation failure.** Do NOT proceed to commit. Report what failed.

## Phase 2 — Commit (no confirmation)

1. Show `git status` and `git diff` for visibility — this is **logging, not a gate**.
2. Derive a Conventional Commit message from the plan title and report summary. Use `feat:`, `fix:`, `refactor:`, `chore:`, or `docs:` as appropriate.
3. Stage **only** files declared in the plan's "Files to change" table (cross-checked against the implementation report). Never `git add -A` or `git add .`.
4. **Secret guard** — refuse to stage any path matching `.env*`, `*.db`, credential-shaped files, or any project-specific blocklist in `commit.md`/`ship.md`. On match: abort before committing.
5. `git commit -m "<message>"` — no AI attribution, no `Co-Authored-By` trailer.

## Phase 3 — Push + open PR

1. `git push -u origin <current-branch>`. Never `--force`.
2. Read `base_branch` and `repo` from `.claude/compass.yml`, then:

```bash
gh pr create --base {base_branch} \
  --title "<meaningful PR title>" \
  --body "$(cat <<'EOF'
## Summary
<1–3 bullets: what was built and why>

## Changes
<key changes from the implementation report>

## Manual Test Plan
- [ ] <golden path step>
- [ ] <edge case>
- [ ] <regression check>

## Notes
<risks, follow-ups, or leave empty>
EOF
)"
```

3. Print the PR URL.

## HARD STOP

After the PR URL is printed:

- Do **not** run code review (no 3-subagent fan-out, no `/security-review` prompt).
- Do **not** merge or enable auto-merge.
- Do **not** prompt for follow-up actions.

Hand back to the user. The user takes over for manual testing and the merge decision.

## Rules

- **Only runs on `feat/*` branches inside a worktree.** Refuse otherwise.
- **Never merges.** Merge is always a human action.
- **Never force-pushes.**
- **Never stages secrets** — see Phase 2 step 4.
- **Aborts before commit on any validation failure** — never push a half-broken state.
- **No Co-Authored-By** — no AI attribution in commit message or PR body.
- This is the **only** command in the workflow that may auto-commit. The standard rule in `commit.md` and `ship.md` still holds everywhere else.

## Note on CI

If `autonomy_mode` in `.claude/compass.yml` is `review-only` or `full`, the CI workflow `.github/workflows/pr-validation.yml` will add inline review comments and a checklist on the PR. `/auto-implement` itself does not interact with CI — it just opens the PR.

See `.claude/compass/reference/AUTONOMY.md` for details.

## Note on husky pre-commit hook

If `.claude/compass/templates/husky-pre-commit.sh` has been installed as `.husky/pre-commit`, it runs on the auto-commit in Phase 2:

- The hook runs `npm test` first. If tests fail, the hook exits non-zero and the auto-commit aborts before push — a useful safety net even though Phase 1 already ran the full validation suite.
- The hook then asks Claude to review the staged diff in `--print` mode. Findings are printed to the terminal; they do **not** block the commit.
- Net effect: `/auto-implement` and the husky hook compose cleanly — the hook acts as a final, non-blocking sanity check on top of Phase 1 validation.
