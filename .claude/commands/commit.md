---
description: Stage and commit changes with a Conventional Commit message
---

# /commit — Stage and Commit

Create a commit for current changes. No push.

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

## Rules

- **Never auto-commit** — always show state and wait for confirmation
- **No Co-Authored-By** — no AI attribution
