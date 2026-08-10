---
description: Stage and commit changes with a Conventional Commit message. Pass --push to also push immediately after.
argument-hint: "[--push]"
disable-model-invocation: true
---

# /compass:commit — Stage and Commit

> **Model:** `/model haiku` — saves tokens, this command only runs git operations.

Create a commit for current changes. Stays local by default; after committing always asks whether to push.

`--push` — skip the question and push immediately after the commit.

## Steps

### 1. Show current state

```bash
git status
git diff
```

### 2. Propose a commit message

Based on the changes, propose a Conventional Commit message:

```
feat: <concise summary>
```

Use `feat:`, `fix:`, `refactor:`, `chore:`, or `docs:` as appropriate.

**Wait for explicit confirmation before committing.**

### 3. Commit

Stage the files by name — never `git add -A`, which sweeps in whatever else the tree
happens to carry.

```bash
git add <files>
git commit -m "<confirmed message>"
```

**A path matching `.env*`, `*.db`, `*.pem`, `*id_rsa*` or a credential shape aborts the
commit.** Say which path and why; do not stage it silently and do not stage the rest
as if nothing happened. The user decides whether it really belongs in the commit.

### 4. Push?

- **`--push` was passed** → push immediately. Report the result.
- **No `--push`** → ask: `Push to origin now? (yes / no)`. On yes: `git push`. On no: done.

**On the base branch, `--push` asks anyway.** Resolve the base branch as
`${CLAUDE_PLUGIN_ROOT}/commands/ship.md` step 4 does. If the current branch is it,
`--push` loses its waiver — a direct push to `main` is not a commit convenience:

```
You are on <base branch>. --push would push straight to it, with no PR and no review.
Push anyway? (yes / no)
```

Pushing updates the open PR, if one exists — claude-code-action re-reviews it when installed.

## Rules

- **Never auto-commit** — always show state and wait for confirmation.
- **No secrets** — never stage `.env.local`, `*.db`, or credential files.
- **Never push to the base branch unasked** — `--push` skips the question everywhere else, not there.
- **No Co-Authored-By** — no AI attribution
