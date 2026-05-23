---
description: Commit, push, open a PR, then optionally run parallel code review
---

# /ship — Commit, PR, and Review

> **Recommended:** `/model opus` — the review step needs deep analysis.

Closes the PIV Loop: commits the work, opens a PR, and runs the parallel code review — all in one command.

## When to run

After `/implement` completes and all validation passes.

---

## Steps

### 1. Read the implementation report

Find the most recent report in `.work/reports/` — extract what was built and which files changed.

```bash
ls -t .work/reports/*.md | head -1
```

### 2. Commit

Run `/commit` — shows state, proposes message, waits for confirmation, commits.

### 3. Push

```bash
git push -u origin <current-branch>
```

Never push to `base_branch` (from `.claude/project.yml`) directly.

### 4. Open PR

Read `base_branch` from `.claude/project.yml`, then:

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

Print the PR URL.

### 5. Offer the review

Ask the user:

```
PR open: <url>

Run code review now? (yes/no)
  yes — fan out 3 parallel review subagents on the diff
  no  — stop here; you can run /ship's review later, or test manually first
```

**If "no":** stop. Remind the user to test manually using the PR checklist, and that `/reflect` is available after merge.

**If "yes":** continue with steps 6–9.

> For a trivial change (Quick Path — typo, 1-line fix), answer **no**: the 3-subagent review is overkill for a one-line diff.

### 6. Fan out subagents in parallel

Read `repo` and `src_dir` from `.claude/project.yml`, then fetch the diff:

```bash
gh pr view <PR number> --repo {repo}
gh pr diff <PR number> --repo {repo}
```

Filter to files inside `src_dir`. Ignore config, docs, and lock files unless they introduce security risks. Launch all three agents simultaneously with the PR diff as context:

**Agent 1 — code-reviewer**
Review for: CLAUDE.md compliance, security, performance, naming conventions.

**Agent 2 — pr-test-analyzer**
Review for: missing tests, uncovered edge cases, missing failure cases.

**Agent 3 — codebase-explorer** (if the PR adds new patterns)
Verify: does the new code follow existing conventions? Are there utilities that should have been reused?

### 7. Aggregate findings

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

### 8. Security check (automatic)

If the diff touches any of the following — run `/security-review` on those files before the verdict:

- API route handlers
- Database queries or ORM calls
- Forms with user input
- Authentication / token handling

Skip if none of the above are affected.

### 9. Overall verdict

- **REJECT** — Critical security or data loss issues.
- **REQUEST CHANGES** — Important issues that must be addressed.
- **APPROVE WITH NITS** — Minor issues only, safe to merge.
- **APPROVE** — Clean.

One-sentence overall code health summary.

**Note:** Output is inline in the conversation. Do NOT post to GitHub unless explicitly asked.

---

## Rules

- **Never auto-commit** — always show state and wait for confirmation
- **No Co-Authored-By** — no AI attribution in commits or PR body
- **Never push to base branch** — feature branch only
- **Never merge the PR** — hand back to the user after the review
- **No secrets** — never stage `.env.local`, `*.db`, or credential files
