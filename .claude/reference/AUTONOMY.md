# CI & Autonomy

The starter ships with `.github/workflows/pr-validation.yml`. Its behaviour is controlled by a single field in `.claude/project.yml`:

```yaml
autonomy_mode: off    # off | review-only | full
```

You can change this value at any time, commit, and the next PR run picks up the new behaviour. No reinstall, no second workflow file.

---

## The three modes

| Mode | What runs | API calls | Secrets needed |
|------|-----------|-----------|----------------|
| `off` (default) | `test` (lint + types + tests from `project.yml`) | None | None |
| `review-only` | `+ claude-review` (inline PR comments) `+ claude-checklist` (PR comment) | Per-PR Claude API calls | `ANTHROPIC_API_KEY` |
| `full` | `+ auto-merge` once all required checks pass | Per-PR Claude API calls | `ANTHROPIC_API_KEY` |

### `off` — the safe baseline

Pure CI: lint, type-check, tests. Same as running `/validate` locally, just on PR open and on each push. No API calls, no surprises. Recommended default for new projects.

### `review-only` — second pair of eyes

Adds two jobs:

1. **`claude-review`** — uses `anthropics/claude-code-action@v1` to review the diff and post **inline comments** on specific lines. Covers code quality, type safety, test coverage gaps, edge cases, and security concerns. Does **not** auto-fix or commit — you decide on each finding.
2. **`claude-checklist`** — generates a manual testing checklist from the diff and posts it as a PR comment under the header `## Manual Verification Before Merge`. Use it as your tick-list before merging.

Mode `review-only` complements `/ship`'s local 3-subagent review:
- **`/ship` review** runs in your chat session, has full conversational context, is fast, and is local.
- **`claude-review` in CI** runs against the GitHub PR, posts auditable inline comments visible to anyone with repo access.

Running both gives you a chat-side overview plus an audit trail in GitHub.

### `full` — auto-merge after green

Adds `auto-merge` on top of `review-only`. Triggers `gh pr merge --auto --squash` so the PR auto-merges as soon as all required status checks pass.

**Important caveat:** GitHub branch protection cannot natively enforce manual checkbox completion. The generated checklist is a *prompt*, not a *gate*. If you want hard enforcement:

- Add a required label like `ready-for-merge` to your branch protection rules.
- Tick the checklist, then add the label.
- Only then does auto-merge fire.

Without this gate, `auto-merge` will fire as soon as CI is green, regardless of whether you ticked the checklist. Plan accordingly.

---

## Setup

### 1. Required secret

For `review-only` and `full`, set `ANTHROPIC_API_KEY` in your repo:

```bash
gh secret set ANTHROPIC_API_KEY
```

Get a key at <https://console.anthropic.com>. The starter does not need any additional secrets — `GITHUB_TOKEN` is provided by GitHub automatically.

### 2. Branch protection rules

In GitHub → Settings → Branches, add a rule for your `base_branch`:

- **Require a pull request before merging**
- **Require status checks to pass:** `test` (always), `claude-review` and `claude-checklist` (if `review-only` or `full`)
- **Require branches to be up to date before merging**
- For `full` with hard checkbox gate: **Require a label** (`ready-for-merge`)

### 3. Switching modes

Just edit `.claude/project.yml` and commit:

```yaml
autonomy_mode: review-only
```

The CI workflow reads this field at the start of each run via the `config` job.

---

## Cost estimate

Based on Sonnet 4.6 pricing, per-PR cost is roughly:

| Job | Tokens (approx.) | Cost / PR |
|-----|------------------|-----------|
| `claude-review` | ~8 000 | ~$0.024 |
| `claude-checklist` | ~3 000 | ~$0.009 |
| **Sum** | ~11 000 | **~$0.033** |

A team doing 10 PRs/day on `review-only` mode pays around **$0.33/day** in Claude API costs.

To save budget on draft PRs, the workflow only triggers on `opened`, `synchronize`, and `ready_for_review` — so draft PRs are excluded by default.

---

## Optional: pre-commit hook (review-only style)

If you also want a local pre-commit check, a template hook lives at `.claude/templates/husky-pre-commit.sh`. **It is not installed automatically.** To use it:

```bash
npm install --save-dev husky
npx husky init
cp .claude/templates/husky-pre-commit.sh .husky/pre-commit
chmod +x .husky/pre-commit
```

The template runs tests locally and asks Claude for a review — but does **not** auto-fix and does **not** auto-commit. Findings are printed to your terminal; you decide what to fix.

If you run `/auto-implement` (see below) with this hook installed, the hook still fires on the auto-commit: it acts as a final safety net (tests must pass, review findings are printed). It does not turn into an auto-fixer.

---

## Security considerations

- **`full` mode merges code without human code review.** Use it only when (a) you also tick the manual checklist, and (b) ideally with a label gate as described above. For repos with multiple contributors, prefer `review-only`.
- **Secrets in PR diffs.** `claude-review` reads the diff. If you accidentally commit a secret, the API will see it. Use a pre-push secret scanner (e.g. `gitleaks`) as a separate safeguard.
- **API key scope.** The `ANTHROPIC_API_KEY` you store as a GitHub secret should have rate limits or budget caps configured at the Anthropic side.
- **Fork PRs.** GitHub does not expose secrets to PRs from forks by default. The Claude jobs will fail silently on fork PRs unless you explicitly opt-in via `pull_request_target` (which has its own security considerations — research before enabling).

---

## Relationship to other commands

- `/ship` — local commit + push + PR + 3-subagent chat review. Always runs the chat review regardless of `autonomy_mode`. Commit step is gated by user confirmation.
- `/auto-implement` — runs a pre-approved plan from `.work/plans/` all the way to PR-open without intermediate confirmation. The only local command that may auto-commit. Never merges. Pre-flight checks (feat/* branch, worktree, plan exists) gate it. Works on top of any `autonomy_mode`: if `review-only` is on, the PR it opens still gets the CI review jobs.
- `/validate` — local lint + types + tests + browser smoke test. Mirrors what the `test` CI job runs.
- `/security-review` — local security-focused review. Auto-runs inside `/ship` on risky diffs. The CI `claude-review` includes security as one of five focus areas; for deeper audits, run `/security-review` locally.

The local commands and CI workflow are designed to complement, not replace, each other.
