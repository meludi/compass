---
description: Report where the current feature stands — phase, PR, CI, findings — derived live from git + gh
argument-hint: [PR-number]
---

# /compass:status — Where Does This Feature Stand?

> **Model:** `/model haiku` — read-only shell + `gh`, no editing.

Reports the current phase of the feature on this branch. **Derived, never stored** — there is no state file. Everything below is computed fresh from `git` and the PR, so it cannot drift or lie. This replaces the idea of a hand-maintained status file.

**Input**: `$ARGUMENTS` — PR number (optional; inferred from the branch when omitted).

## Pre-flight — `gh` available?

```bash
command -v gh >/dev/null 2>&1 || echo "MISSING"
```

If missing, report only the local part (branch + `git status`) and tell the user that PR-derived status needs `gh` (`brew install gh` → `gh auth login`).

Read `repo` and `autofix_max_pushes` from `.claude/compass.yml`.

## Steps

### 1. Gather ground truth

```bash
git branch --show-current
git rev-parse --short HEAD
git status --porcelain
git log --oneline {base_branch}..HEAD          # local commits ahead of base

# PR for this branch (empty output = no PR yet):
gh pr view --repo {repo} \
  --json number,url,state,mergeStateStatus,reviewDecision,statusCheckRollup,commits 2>/dev/null

# Comments (for findings, checklist, escalation):
gh pr view <number> --repo {repo} --comments      # conversation: ## Review Summary, ## Manual Verification, ## Auto-fix stopped
gh api repos/{repo}/pulls/<number>/comments        # inline review comments (file + line)
```

### 2. Derive the phase

Pick the **first** row that matches:

| Condition | Phase |
|---|---|
| No PR, no local commits ahead of base | `not-started` |
| No PR, local commits/uncommitted changes present | `local — no PR yet` |
| `## Auto-fix stopped` comment exists | `escalated` — needs a human (structural problem or push cap hit) |
| PR `state = MERGED` | `merged` |
| `statusCheckRollup` has a failing/error check | `ci-failing` — auto-fix territory |
| `statusCheckRollup` still pending | `ci-running` |
| Checks green, `reviewDecision = CHANGES_REQUESTED` or unresolved inline comments | `awaiting-fixes` |
| Checks green, `## Manual Verification Before Merge` exists with unticked `- [ ]` | `awaiting-checklist` |
| Checks green, no blocking review, checklist clear (or absent) | `ready-to-merge` |

### 3. Report

Print a compact block — phase first, then the facts behind it:

```
Phase:        <phase>
PR:           <url or —>
Last commit:  <short-hash>
Checks:       <n passed / n failed / n pending>
Findings:     <n unresolved review comments>
Auto-fix:     <commits-on-PR> / autofix_max_pushes   (proxy for push count; the autofix-guard CI job is authoritative)
```

End with a one-line **next step** matching the phase, e.g.:

- `local — no PR yet` → `/compass:ship` to open the PR
- `ci-failing` → enable the `auto-fix` toggle, or `/compass:fix-ci-review`
- `awaiting-fixes` → `/compass:fix-ci-review`
- `escalated` → read the `## Auto-fix stopped` comment; fix by hand or close the PR
- `awaiting-checklist` → tick the items in `## Manual Verification Before Merge`, then merge
- `ready-to-merge` → `gh pr merge --squash`, then `/compass:worktree <name> rm`

## Rules

- **Read-only.** This command never edits, commits, or pushes — it only reports.
- **Never trust a cached value.** Always re-derive from `git` + `gh`; do not read a status from any file.
- **No secrets** — never echo `.env.local`, `*.db`, or credential files.
