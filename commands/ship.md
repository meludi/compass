---
description: Commit, push, and open a PR, then hand off to review
disable-model-invocation: true
---

# /compass:ship — Commit, PR, and Review

> **Model:** `/model opus` — the PR body must reflect what was actually verified.

Closes the PIV Loop: commits the work, pushes, and opens the PR. Review happens elsewhere — see step 5.

## When to run

After `/compass:implement` completes and all validation passes.

---

## Steps

### 0. Pre-flight — `gh` available?

```bash
command -v gh >/dev/null 2>&1 || echo "MISSING"
```

If `gh` is missing, **stop before committing** and tell the user:

> GitHub CLI (`gh`) is not installed, so `/compass:ship` can't open the PR. Install it
> (`brew install gh` → `gh auth login`), or run `/compass:commit --push` and open the PR
> yourself. The local loop (plan/implement/validate/commit) works without `gh`.

Do not commit or push until `gh` is available or the user chooses the manual path.

### 0b. Pre-flight — is the validation still current?

The report from `/compass:implement` proves the state **at the time it ran**. Anything
edited since — most often fixes for `/code-review` findings — is unproven, and the PR
body must not claim otherwise.

**Resolve the report by branch, not by timestamp.** `/compass:implement` names it after the
feature; the branch is named after the same feature. Two features in one checkout make
"newest file" the wrong answer, and the PR body would then describe someone else's work:

```bash
FEATURE=$(git branch --show-current | sed 's|^feat/||')
REPORT=".work/reports/$FEATURE-report.md"
[ -f "$REPORT" ] || REPORT=$(ls -t .work/reports/*.md 2>/dev/null | head -1)
echo "$REPORT"
```

The `ls -t` line is a fallback, not the rule. When it is what answers, **say so** — the
report you are about to quote may belong to another feature.

Then list source files touched after that report was written (portable — no `stat` flags,
which differ between macOS and Linux):

```bash
[ -n "$REPORT" ] && find . -newer "$REPORT" -type f \
  -not -path './.git/*' -not -path './.work/*' -not -path './node_modules/*' | head
```

Re-run `/compass:validate` if that prints anything, or if there is no report at all.
It is cheap; shipping an unproven claim is not.

### 1. Read the implementation report

Read the `$REPORT` resolved in step 0b — extract what was built and which files changed.

### 2. Commit

Run `/compass:commit` — shows state, proposes message, waits for confirmation, commits.

### 3. Push

```bash
git push -u origin <current-branch>
```

Never push to the base branch directly.

### 4. Open PR

Resolve the base branch, in this order — the first that yields a value wins:

1. The **Base branch** line under `## Commands` in `.claude/CLAUDE.md`, if present
2. `git symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix stripped
3. If that errors, `git remote set-head origin --auto` once, then retry it — a repo created
   with `gh repo create --source=.` has no `origin/HEAD` until something sets it

Never fall back to the current branch here: that is the feature branch, and a PR cannot
open against itself. If all three fail, stop and ask which branch to target.

```bash
gh pr create --base {base branch} \
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

### 5. Hand off to review

Print the PR URL and state who reviews it:

```
PR open: <url>

Review this PR — compass does not:
  - Didn't run /code-review before shipping? Run it now.
  - On GitHub: claude-code-action reviews the PR by itself if installed;
    otherwise comment "@claude review this"

Then apply what comes back:
  /compass:fix-ci-review
```

Print exactly these options — no others. **Stop here**; the user decides when to merge.

---

## Rules

- **Never auto-commit** — always show state and wait for confirmation.
- **Verified state only** — the PR body (Summary, Changes, Manual Test Plan) reflects what validation actually confirmed in `/compass:implement`, not what was intended. See `references/HANDBOOK.md` → *Verification before completion*.
- **No Co-Authored-By** — no AI attribution in commits or PR body
- **Never push to base branch** — feature branch only
- **Never merge the PR** — hand back to the user
- **No secrets** — never stage `.env.local`, `*.db`, or credential files

---

## Note on CI

compass ships no CI workflow. The same checks run locally in `/compass:validate`
before the commit; a workflow that runs your test suite on the PR is generic CI
your stack already has a template for.

PR review comes from `anthropics/claude-code-action`, installed with
`/install-github-app`. It writes and owns its own workflows; compass does not
generate or update them. Findings come back into the loop via
`/compass:fix-ci-review`.
