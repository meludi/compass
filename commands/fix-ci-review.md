---
description: Fetch the review comments on the PR and apply the fixes locally, then validate
argument-hint: [PR-number]
---

# /compass:fix-ci-review — Apply PR Review Findings

> **Model:** `/model opus` — applying review feedback needs careful editing.

Consumes whatever review is on the PR — claude-code-action, Codex, a human, any bot that comments — and applies the fixes **locally**, so each one passes `/compass:validate` before it goes back up. This is the bridge back from a review that ran elsewhere; it does not re-review the diff.

**Input**: `$ARGUMENTS` — PR number (optional).

Before the PR exists, use Claude Code's built-in `/code-review` instead.

## PR source — how it's resolved

| Situation | PR |
|---|---|
| `$ARGUMENTS` is a PR number | that PR |
| No argument, PR exists for current branch | inferred via `gh pr view` |
| No argument, no PR found | stop — nothing to apply (suggest `/code-review`) |

Resolve the repo with `gh repo view --json nameWithOwner -q .nameWithOwner` — it reads the remote, so it stays right in worktrees and forks.

## Pre-flight — `gh` available?

```bash
command -v gh >/dev/null 2>&1 || echo "MISSING"
```

This command reads PR comments via `gh`, so it can't run without it. If missing, stop:
tell the user to install it (`brew install gh` → `gh auth login`), or use the built-in
`/code-review` for a fresh local review instead.

## Steps

### 1. Fetch the review comments

```bash
gh pr view <PR-number> --repo {repo} --comments              # conversation incl. ## Review Summary
gh api repos/{repo}/pulls/<PR-number>/comments               # inline review comments (file + line)
```

If there are no review comments, stop and report it — there is nothing to apply.

### 2. Present the findings

List the findings concisely (file · line · what to change), grouped by severity if the comments indicate it. Confirm the set before editing.

### 3. Apply the fixes locally

Edit the files to address each finding. Skip or flag any comment you disagree with (state why) rather than forcing a change — the author decides on contested points. Do not invent fixes for comments you cannot map to code.

**3-fix boundary:** if the same finding resists three distinct fix attempts, stop patching it — switch to root-cause mode (reproduce, isolate, one hypothesis at a time; the `diagnosing-bugs` skill if available) or hand it back to the author. Three misses means the diagnosis is wrong, not the patch; more variations just churn the PR.

### 4. Validate

Run `/compass:validate` (lint + types + tests + browser smoke). Fixes can break lint/types/tests — this is the gate. If validation fails, fix and re-run before finishing.

### 5. Hand back

Report what was fixed and what was left (with reasons). If a finding revealed something non-obvious (a wrong assumption, a landmine, a deliberate decision), append one delta line to the `## Loop log` of the plan file (`.work/plans/{feature}.plan.md`) — skip this when there is no plan (Quick-Path change). **Stop here** — the human commits, pushes, and decides when to merge. The push re-triggers the CI review.

## Rules

- **Never auto-commit** — stop after `/compass:validate`; the author commits and pushes.
- **Never merge** — hand back after the fixes are validated.
- **No secrets** — never log `.env.local`, `*.db`, or credential files.
- **No AI attribution** — no `Co-Authored-By` trailers.
- Don't force a change for a finding you disagree with — flag it for the author instead.
- **Stop at three** — after three failed attempts on the same finding, re-investigate the cause instead of patching again.
