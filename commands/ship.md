---
description: Commit, push, open a PR, then optionally run parallel code review
---

# /compass:ship — Commit, PR, and Review

> **Model:** `/model opus` — the review step needs deep analysis.

Closes the PIV Loop: commits the work, opens a PR, and runs the parallel code review — all in one command.

## When to run

After `/compass:implement` completes and all validation passes.

---

## Steps

### 1. Read the implementation report

Find the most recent report in `.work/reports/` — extract what was built and which files changed.

```bash
ls -t .work/reports/*.md | head -1
```

### 2. Commit

Run `/compass:commit` — shows state, proposes message, waits for confirmation, commits.

### 3. Push

```bash
git push -u origin <current-branch>
```

Never push to `base_branch` (from `.claude/compass.yml`) directly.

### 4. Open PR

Read `base_branch` from `.claude/compass.yml`, then:

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
  no  — stop here; you can run /compass:ship's review later, or test manually first

Note: for yes — run /clear first so the subagents start with a clean context.
```

**If "no":** stop. Remind the user to test manually using the PR checklist, and that `/compass:reflect` is available after merge.

**If "yes":** run `/compass:review <PR-number>` — it handles the full 3-subagent fan-out, aggregation, security check, and verdict.

> For a trivial change (Quick Path — typo, 1-line fix), answer **no**: the 3-subagent review is overkill for a one-line diff.

---

## Rules

- **Never auto-commit** — always show state and wait for confirmation. The only sanctioned exception is `/compass:auto-implement`, which runs on a `feat/*` branch with a pre-approved plan and stops at PR-open.
- **No Co-Authored-By** — no AI attribution in commits or PR body
- **Never push to base branch** — feature branch only
- **Never merge the PR** — hand back to the user after the review
- **No secrets** — never stage `.env.local`, `*.db`, or credential files

---

## Note on CI / auto-merge

If `autonomy_mode` in `.claude/compass.yml` is `review-only` or `full`, the CI
workflow `.github/workflows/pr-validation.yml` adds inline PR comments and a
dynamic test checklist on PR open. In `full` mode, the PR auto-merges once all
required checks pass.

See `${CLAUDE_PLUGIN_ROOT}/reference/AUTONOMY.md` for full details.
