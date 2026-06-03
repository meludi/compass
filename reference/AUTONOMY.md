# CI & Autonomy

`/compass:setup-stack` installs `.github/workflows/pr-validation.yml` into your project (copied from the plugin template; self-contained, so it reads `.claude/compass.yml` and runs in CI without the plugin installed). Its behaviour is controlled by a single field in `.claude/compass.yml`:

```yaml
autonomy_mode: off          # off | review-only | full
ci_review_provider: claude  # claude | openai | gemini
```

You can change these at any time, commit, and the next PR run picks up the new behaviour. No reinstall, no second workflow file.

`ci_review_provider` selects which LLM runs the CI review (defaults to `claude` if omitted):

- **`claude`** — uses `anthropics/claude-code-action@v1`. Posts **inline** PR comments plus a `## Review Summary` and a manual-test checklist. Secret: `ANTHROPIC_API_KEY`. Recommended.
- **`openai`** / **`gemini`** — uses a generic API call and posts **one `## Review Summary` PR comment** (no inline comments, no separate checklist — those have no drop-in equivalent outside claude-code-action). Secret: `OPENAI_API_KEY` or `GEMINI_API_KEY`.

`autonomy_mode: off` disables the review regardless of provider.

---

## The three modes

Set by `autonomy_mode`; each mode is a superset of the previous. At-a-glance grid: *Mode comparison* below.

### `off` — the safe baseline

Pure CI: lint, type-check, tests. Same as running `/compass:validate` locally, just on PR open and on each push. No API calls, no surprises. Recommended default for new projects.

### `review-only` — second pair of eyes

Adds two jobs:

1. **`claude-review`** — uses `anthropics/claude-code-action@v1` to review the diff and post **inline comments** on specific lines. Covers code quality, type safety, test coverage gaps, edge cases, and security concerns. Does **not** auto-fix or commit — you decide on each finding.
2. **`claude-checklist`** — generates a manual testing checklist from the diff and posts it as a PR comment under the header `## Manual Verification Before Merge`. Use it as your tick-list before merging.

Mode `review-only` complements `/compass:ship`'s local 3-subagent review:
- **`/compass:ship` review** runs in your chat session, has full conversational context, is fast, and is local.
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

## Mode comparison (at a glance)

|  | `off` | `review-only` | `full` |
|---|---|---|---|
| **— Setup —** | | | |
| API key needed | no | yes | yes |
| Recommended branch protection | require `test` | + `claude-review`, `claude-checklist` | + label `ready-for-merge` |
| **— CI on GitHub —** | | | |
| `test` (lint + types + tests) | ✓ | ✓ | ✓ |
| `claude-review` (inline comments) | ✗ | ✓ | ✓ |
| `claude-checklist` (PR comment) | ✗ | ✓ | ✓ |
| `## Review Summary` (one summary comment) | ✗ | ✓ | ✓ |
| `auto-merge` | ✗ | ✗ | ✓ |
| Claude re-review on each push | ✗ (only `test`) | ✓ | ✓ |
| **— Always present (mode-independent) —** | | | |
| `## Manual Test Plan` in PR body (from `/compass:ship`) | ✓ | ✓ | ✓ |
| `/compass:ship` local 3-subagent review | ✓ optional | ✓ optional | ✓ optional |
| Local `/code-review` / `/compass:review` | ✓ | ✓ | ✓ |
| **— Who does what —** | | | |
| Who reviews | you, locally | you locally **+ CI** | you locally **+ CI** |
| Who fixes | you (local) | you (local) | you (local) |
| Who merges | you | you | **CI automatically** |
| Human merge gate | ✓ | ✓ | ✗ (unless label gate) |
| How you learn of findings | in chat | chat **+ GitHub notification** | chat + GitHub notification |
| **— Practicalities —** | | | |
| Cost / PR | $0 | ~$0.03 | ~$0.03 |
| Review output lives | chat only | chat **+ auditable on GitHub** | chat + GitHub |
| Main risk | no second pair of eyes | findings may be missed (merge stays manual) | **unreviewed merge on green CI** |
| Suitable for | solo, hand-written logic | audit trail, teams, CI second opinion | bot PRs, low-stakes, **only with label gate** |

Notes:
- **Mode set without `ANTHROPIC_API_KEY`** → the Claude jobs fail (red), they do not skip → you effectively get `off` plus red checks that may block branch protection. Keep the key and the mode together.
- **Draft PRs trigger CI in no mode** — the workflow fires only on `opened`, `synchronize`, and `ready_for_review`.

---

## Fixing review findings

The fix loop itself — review → fix → `/compass:validate` → `/compass:commit` → push → re-review → merge, in both `off` and `review-only` modes — lives in `WORKFLOW.md` → **"Loop 2 — Fix"**. In CI modes you consume the findings with `/compass:apply-ci-review`. Two autonomy-specific notes:

- **CI never commits.** `claude-review` only surfaces findings; applying a fix is always a deliberate human step. The single sanctioned auto-commit anywhere is `/compass:auto-implement` (a pre-approved plan on a `feat/*` branch).
- **A new comment per push.** Every push (`synchronize`) re-runs `claude-review`, so a fresh `## Review Summary` comment is posted each iteration — comments are **not** edited in place. This is intentional: it doubles as a per-round record.

---

## Setup

### 1. Required secret

For `review-only` and `full`, set the secret that matches `ci_review_provider`:

```bash
gh secret set ANTHROPIC_API_KEY   # ci_review_provider: claude (default)
gh secret set OPENAI_API_KEY      # ci_review_provider: openai
gh secret set GEMINI_API_KEY      # ci_review_provider: gemini
```

Get a Claude key at <https://console.anthropic.com>. The starter does not need any additional secrets — `GITHUB_TOKEN` is provided by GitHub automatically. If the mode is on but the matching secret is missing, the review job fails (red) rather than skipping.

Verify a secret is present (names only, never values):

```bash
gh secret list
```

`gh secret set <NAME>` is interactive — run it yourself; `/compass:setup-stack` checks for the secret but never sets it (it would have to handle the raw key).

### 2. Branch protection rules

In GitHub → Settings → Branches, add a rule for your `base_branch`:

- **Require a pull request before merging**
- **Require status checks to pass:** `test` (always), `claude-review` and `claude-checklist` (if `review-only` or `full`)
- **Require branches to be up to date before merging**
- For `full` with hard checkbox gate: **Require a label** (`ready-for-merge`)

### 3. Switching modes

Just edit `.claude/compass.yml` and commit:

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

The figures above are for `ci_review_provider: claude`. With `openai`/`gemini` there is a single summary call per PR (no checklist job), and cost depends on that provider's pricing for the model used.

To save budget on draft PRs, the workflow only triggers on `opened`, `synchronize`, and `ready_for_review` — so draft PRs are excluded by default.

---

## Optional: pre-commit hook (review-only style)

If you also want a local pre-commit check, a template hook lives at `${CLAUDE_PLUGIN_ROOT}/templates/husky-pre-commit.sh`. **It is not installed automatically.** To use it:

```bash
npm install --save-dev husky
npx husky init
cp ${CLAUDE_PLUGIN_ROOT}/templates/husky-pre-commit.sh .husky/pre-commit
chmod +x .husky/pre-commit
```

The template runs tests locally and asks Claude for a review — but does **not** auto-fix and does **not** auto-commit. Findings are printed to your terminal; you decide what to fix.

If you run `/compass:auto-implement` (see below) with this hook installed, the hook still fires on the auto-commit: it acts as a final safety net (tests must pass, review findings are printed). It does not turn into an auto-fixer.

---

## Security considerations

- **`full` mode merges code without human code review.** Use it only when (a) you also tick the manual checklist, and (b) ideally with a label gate as described above. For repos with multiple contributors, prefer `review-only`.
- **Secrets in PR diffs.** `claude-review` reads the diff. If you accidentally commit a secret, the API will see it. Use a pre-push secret scanner (e.g. `gitleaks`) as a separate safeguard.
- **API key scope.** The `ANTHROPIC_API_KEY` you store as a GitHub secret should have rate limits or budget caps configured at the Anthropic side.
- **Fork PRs.** GitHub does not expose secrets to PRs from forks by default. The Claude jobs will fail silently on fork PRs unless you explicitly opt-in via `pull_request_target` (which has its own security considerations — research before enabling).

---

## How `autonomy_mode` interacts with the commands

`autonomy_mode` is CI-only — it changes nothing about how the local commands behave (see `HANDBOOK.md` for what each command does). Two interactions worth knowing:

- `/compass:ship` always runs its local 3-subagent review **regardless of `autonomy_mode`**; the CI review (in `review-only`/`full`) is an additional, auditable pass on the PR.
- `/compass:auto-implement` composes with any mode and **never merges** — the PR it opens still gets the CI review jobs when the mode is on.

Security is one of the five focus areas of the CI `claude-review`; for a deeper audit, run `/compass:security-review` locally.
