---
description: Fetch the CI review comments on the PR and apply the fixes locally, then validate
argument-hint: [PR-number]
---

# /compass:apply-ci-review — Apply CI review findings

> **Model:** `/model opus` — applying review feedback needs careful editing.

Consumes the comments the CI `claude-review` job posted on the PR and applies the fixes **locally**. This is the non-redundant fix path in `review-only` / `full` mode: act on the review that already ran, instead of re-reviewing the same diff with `/code-review`.

**Input**: `$ARGUMENTS` — PR number (optional).

Use `/code-review --fix` instead when there is **no** CI review (mode `off`, or before the PR exists).

## PR source — how it's resolved

| Situation | PR |
|---|---|
| `$ARGUMENTS` is a PR number | that PR |
| No argument, PR exists for current branch | inferred via `gh pr view` |
| No argument, no PR found | stop — nothing to apply (suggest `/code-review --fix`) |

Read `repo` from `.claude/compass.yml`.

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

### 4. Validate

Run `/compass:validate` (lint + types + tests + browser smoke). Fixes can break lint/types/tests — this is the gate. If validation fails, fix and re-run before finishing.

### 5. Hand back

Report what was fixed and what was left (with reasons). **Stop here** — the human commits and pushes. The push re-triggers the CI review.

## Rules

- **Never auto-commit** — stop after `/compass:validate`; the author commits and pushes. (`/compass:auto-implement` is the only sanctioned auto-commit exception.)
- **Never merge** — hand back after the fixes are validated.
- **No secrets** — never log `.env.local`, `*.db`, or credential files.
- **No AI attribution** — no `Co-Authored-By` trailers.
- Don't force a change for a finding you disagree with — flag it for the author instead.
