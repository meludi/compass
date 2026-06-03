---
description: Run parallel code review on a PR or local branch diff (3 subagents + security check)
argument-hint: [PR-number]
---

# /compass:review — Parallel Code Review

> **Model:** `/model opus` — deep analysis needed.
> **Before running:** `/clear` — gives all three subagents a clean context window.

Runs a 3-agent parallel review. Works with or without an open PR.

Can be triggered from `/compass:ship` (step 5) or run standalone at any time.

**Input**: `$ARGUMENTS` — PR number (optional).

## Diff source — how it's resolved

| Situation | Diff source |
|---|---|
| `$ARGUMENTS` is a PR number | `gh pr diff <number>` |
| No argument, PR exists for current branch | `gh pr diff` (inferred) |
| No argument, no PR found | `git diff {base_branch}...HEAD` |

Read `base_branch` from `.claude/compass.yml` for the local fallback.

> **Note (local diff):** Without a PR, the agents have no PR title or description as context — they only see the raw diff. Results are still accurate, but slightly less contextualized.

## When to run

- After `/compass:ship` opens a PR and you answer "yes" to the review prompt
- Before `/compass:ship`: review local changes early, before pushing
- Standalone: after a manual push + PR open, before merge
- Re-review: after addressing feedback from a previous run
- External PR: reviewing a contributed PR or a branch you did not write

## Steps

### 1. Resolve the diff source

Follow the table above. Read `repo`, `src_dir`, and `base_branch` from `.claude/compass.yml`.

For PR mode:
```bash
gh pr view <PR-number> --repo {repo}   # fetch title + description
gh pr diff <PR-number> --repo {repo}   # fetch diff
```

For local mode:
```bash
git diff {base_branch}...HEAD
```

Filter to files inside `src_dir`. Ignore config, docs, and lock files unless they introduce security risks.

### 2. Fan out subagents in parallel

Launch all three agents simultaneously with the diff as context:

**Agent 1 — code-reviewer**
Review for: CLAUDE.md compliance, security, performance, naming conventions.

**Agent 2 — pr-test-analyzer**
Review for: missing tests, uncovered edge cases, missing failure cases.

**Agent 3 — codebase-explorer** (if the diff adds new patterns)
Verify: does the new code follow existing conventions? Are there utilities that should have been reused?

### 3. Aggregate findings

Combine all findings into a single report:

---

**Summary**
Brief description of what the diff does.

**Critical** — Must fix before merge
| Agent | File | Line | Finding |
|-------|------|------|---------|

**Important** — Should fix
| Agent | File | Line | Finding |
|-------|------|------|---------|

**Suggestions** — Nice to fix
| Agent | File | Line | Finding |
|-------|------|------|---------|

**Test gaps**
| File | Rating | Missing |
|------|--------|---------|

---

### 4. Security check (automatic)

If the diff touches any of the following — run `/compass:security-review` on those files:

- API route handlers
- Database queries or ORM calls
- Forms with user input
- Authentication / token handling

Skip if none of the above are affected.

### 5. Overall verdict

- **REJECT** — Critical security or data loss issues.
- **REQUEST CHANGES** — Important issues that must be addressed.
- **APPROVE WITH NITS** — Minor issues only, safe to merge.
- **APPROVE** — Clean.

One-sentence overall code health summary.

**Note:** Output is inline in the conversation. Do NOT post to GitHub unless explicitly asked.

## Rules

- Never merge — hand back to the user after the verdict
- No secrets — never log `.env.local`, `*.db`, or credential files
- For a trivial change (typo, 1-line fix), skip this command — the 3-subagent review is overkill for a one-line diff
