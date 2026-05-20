---
description: Commit, push, and open a PR — bridges feature-build and review
---

# /create-pr — Commit, Push, and Open PR

Closes the PIV Loop: bridges `/feature-build` (Build session) and `/review` (Review session).

## When to run

After `/feature-build` completes and all validation passes (`/validate`).

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

### 5. Output

Print the PR URL and tell the user:

```
PR open: <url>

Next:
1. Test manually using the checklist above
2. Run /review <PR_NUMBER> once ready for code review
```

---

## Rules

- **Never auto-commit** — always show state and wait for confirmation
- **No Co-Authored-By** — no AI attribution in commits or PR body
- **Never push to base branch** — feature branch only
- **Never merge the PR** — hand back to the user after PR is open
- **No secrets** — never stage `.env.local`, `*.db`, or credential files
