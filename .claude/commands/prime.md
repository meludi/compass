---
description: Prime agent with project context
argument-hint: [linear-issue-id | path to .work/stories/*.md]
---

# /prime — Load Project Context

Bootstrap your mental model at the start of every session before doing any work.

**Input**: $ARGUMENTS (optional — Linear issue ID e.g. `PROJ-42`, or path to `.work/stories/*.md`)

---

## Steps

### 1. Load spec (if provided)

If a **Linear issue ID** is given:

- Use `mcp__linear-server__get_issue` with the issue ID
- Extract: title, description, acceptance criteria, status
- This becomes the spec for the session

If a **`.work/stories/*.md` path** is given:

- Read the file
- Extract: story title, acceptance criteria, technical notes
- This becomes the spec for the session

### 2. Read project rules

- `.claude/CLAUDE.md` — conventions, stack, patterns
- `.claude/project.yml` — commands, repo, base branch

If additional reference docs exist (e.g. `.claude/reference/DOCUMENTATION.md`, `.claude/reference/DB.md`), read them too.

### 3. Check git state + existing plan

```bash
git branch --show-current
git log --oneline -5
git status --short
ls .work/plans/ 2>/dev/null | tail -1
```

If a plan file exists in `.work/plans/`, read it — it means work is already in progress.

### 4. Output Mental Model

```
## Mental Model

**Branch:** feat/example
**Issue:** PROJ-42 — {title} ({status})
**Spec:** {1-sentence summary of acceptance criteria}
**Plan:** .work/plans/feature-name.plan.md (in progress) — or "none"
**Last commits:** [3 most recent]
**Uncommitted:** [files changed or "clean"]
**Stack:** {from CLAUDE.md}
**Key reminder:** [one non-obvious thing from CLAUDE.md relevant to this issue]
```

If no issue was provided, omit Issue/Spec lines.

Ready to work.
