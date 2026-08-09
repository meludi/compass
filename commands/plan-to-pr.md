---
description: Run a confirmed plan to an open PR without stopping — implement, validate, review, commit, push
argument-hint: <path to .work/plans/*.plan.md>
---

# /compass:plan-to-pr — a confirmed plan, run to an open PR

> **Model:** `/model sonnet` — the work is `implement.md`'s; this file only sequences it.

Runs Loop 1 end to end without asking: implement, validate, review, commit, push, open the PR. **It never merges.** The open PR is the hard stop.

**The plan is the only human gate.** Run this against a plan you have read. An unreviewed plan executed unattended is the one failure no guard below catches — for that, run `/compass:implement` and stay in the loop.

## When to run

All three must hold. Any one missing → `/compass:implement` instead:

- The plan is reviewed and stable.
- The change is small to medium and follows patterns already in the codebase.
- Nothing risky: no DB migration, no auth or security boundary, no first-time use of a library.

## Pre-flight

Run every check before touching a file. On failure: name the failed check, stop, change nothing.

| Check | Passes when |
|---|---|
| **Plan** | `$ARGUMENTS` resolves to a readable file under `.work/plans/` |
| **Branch** | `git branch --show-current` is **not** the base branch (resolve it as `${CLAUDE_PLUGIN_ROOT}/commands/ship.md` step 4 does) |
| **Clean tree** | `git status --porcelain` is empty, or lists only paths in the plan's *Files to change* table. Anything else → stop and ask the user to clean up |
| **`gh`** | `command -v gh` succeeds. Checked here, not in Phase 3 — a run that implements its way to a missing CLI wasted the whole pass |

**Worktree** — if `git rev-parse --git-common-dir` prints `.git`, this is the main checkout, not a worktree. Say so once and continue; worktrees are optional in compass.

## Phase 1 — Implement

Run steps 1–5 of `${CLAUDE_PLUGIN_ROOT}/commands/implement.md`, per-task gates and all. Two deltas, because nobody is watching:

- **Skip step 6's commit checkpoint** — Phase 3 owns the commit.
- **A tripped 3-fix boundary aborts the run.** Interactively it hands back for a decision; here there is no one to hand to. Report the task, the cause, and what the three attempts were.

Any failure in step 4's full validation is a hard stop: no commit, no push. Report what failed.

## Phase 2 — Review

1. Run `/code-review` on the branch.
2. Apply Critical and Important findings. Skip nits — an unattended run is the wrong place to spend edits on taste.
3. Re-run `/compass:validate`. Those fixes are unproven code, and the PR body is about to claim otherwise.

No findings → say so and continue.

## Phase 3 — Commit, push, PR

Steps 1–4 of `${CLAUDE_PLUGIN_ROOT}/commands/ship.md`, with one waiver: **the confirmation gate in `commit.md` step 2 does not apply to this command.** Show `git status` and `git diff` anyway — as a record, not a gate.

Stage only what the plan's *Files to change* table lists, cross-checked against the implementation report. Never `git add -A`.

## Hard stop

Print the PR URL and the hand-off block from `ship.md` step 5. Then stop — no merge, no auto-merge, no next-step prompt, no follow-up question. The user takes over.

## Rules

- **The only compass command that commits without confirmation.** Everywhere else, `Never auto-commit` still holds.
- **Never merges**, never enables auto-merge, never force-pushes, never pushes to the base branch.
- **Never stages secrets** — a path matching `.env*`, `*.db` or a credential shape aborts the commit; it is not silently skipped.
- **Aborts before the commit on any validation failure.** A half-broken state never reaches the PR.
- **No Co-Authored-By** in the commit or the PR body.
