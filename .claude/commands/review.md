---
description: Run parallel subagent code review on an open PR
argument-hint: <PR number>
---

# /review — Chief Code Review Officer

> **Recommended:** `/model opus` — deep analysis for code review.

Performs a thorough PR review by fanning out 3 specialized subagents in parallel, then aggregates their findings.

## Input

`/review <PR number>`

## Steps

### 1. Fetch the PR

Read `repo` and `src_dir` from `.claude/project.yml`, then:

```bash
gh pr view $ARGUMENTS --repo {repo}
gh pr diff $ARGUMENTS --repo {repo}
```

Filter to files inside `src_dir`. Ignore config, docs, and lock files unless they introduce security risks.

### 2. Fan out subagents in parallel

Launch all three agents simultaneously with the PR diff as context:

**Agent 1 — code-reviewer**
Review for: CLAUDE.md compliance, security, performance, naming conventions.

**Agent 2 — pr-test-analyzer**
Review for: missing tests, uncovered edge cases, missing failure cases.

**Agent 3 — codebase-explorer** (if the PR adds new patterns)
Verify: does the new code follow existing conventions? Are there utilities that should have been reused?

### 3. Aggregate findings

Combine all findings into a single report:

---

**PR Summary**
Brief description of what the PR does.

**Critical** — Must fix before merge
| Agent | File | Line | Finding |
|-------|------|------|---------|

**Important** — Should fix
| Agent | File | Line | Finding |
|-------|------|------|---------|

**Suggestions** — Nice to fix
| Agent | File | Line | Finding |

**Test gaps**
| File | Rating | Missing |
|------|--------|---------|

---

### 4. Security check (automatic)

If the diff touches any of the following — run `/security-review` on those files before the verdict:

- API route handlers
- Database queries or ORM calls
- Forms with user input
- Authentication / token handling

Skip if none of the above are affected.

### 5. Overall Verdict

- **REJECT** — Critical security or data loss issues.
- **REQUEST CHANGES** — Important issues that must be addressed.
- **APPROVE WITH NITS** — Minor issues only, safe to merge.
- **APPROVE** — Clean.

One-sentence overall code health summary.

**Note:** Output is inline in the conversation. Do NOT post to GitHub unless explicitly asked.
