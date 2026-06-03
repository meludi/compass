---
description: Stage and commit changes with a Conventional Commit message. Pass --push to also push immediately after.
argument-hint: "[--push]"
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

Never commit blind. Show what is changed before doing anything.

### 2. Propose a commit message

Based on the changes, propose a Conventional Commit message:

```
feat: <concise summary>
```

Use `feat:`, `fix:`, `refactor:`, `chore:`, or `docs:` as appropriate.

**Wait for explicit confirmation before committing.**

### 3. Commit

```bash
git add <files>
git commit -m "<confirmed message>"
```

### 4. Push?

- **`--push` was passed** → run `git push` immediately. Report the result.
- **No `--push`** → ask: `Push to origin now? (yes / no)`. On yes: `git push`. On no: done.

Pushing updates the open PR (if any) and — in `review-only`/`full` mode — triggers a CI re-review.

## Rules

- **Never auto-commit** — always show state and wait for confirmation. The only sanctioned exception is `/compass:auto-implement`, which runs on a `feat/*` branch with a pre-approved plan and stops at PR-open.
- **No Co-Authored-By** — no AI attribution
