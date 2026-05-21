---
description: Set up claude-workflow-starter for a new project
---

# /setup — Project Setup

Configure this Claude workflow for your project. Run once after copying the starter into your project.

**What it does:**
1. Fills in `.claude/project.yml` with your project values
2. Generates `.claude/CLAUDE.md` from `.claude/CLAUDE-template.md`

---

## Steps

### 1. Ask the user

Collect the following values (show defaults in brackets):

1. **Project name** — short identifier, e.g. `my-app`
2. **GitHub repo** — `owner/repo` format
3. **Package manager** — npm / pnpm / yarn / bun [npm]
4. **Dev command** — [npm run dev]
5. **Dev port** — [3000]
6. **Test command** — [npm test]
7. **Lint command** — [npm run lint]
8. **Format command** — [npm run format]
9. **Type check command** — [npm run typecheck] (leave blank to skip)
10. **Base branch** — [main]
11. **Worktree prefix** — e.g. `../my-app-` (parent dir + project name + dash)
12. **Source directory** — [src/]
13. **DB file** — e.g. `myapp.db` (leave blank if no DB to copy per worktree)
14. **Project description** — one paragraph, what this project does

### 2. Write `.claude/project.yml`

Fill in all values.

### 3. Generate `.claude/CLAUDE.md` from template

Read `.claude/CLAUDE-template.md`. Generate `CLAUDE.md` in two phases:

**Phase 1 — fill immediately** (from answers + codebase scan):
- Project description, tech stack, commands — from step 1
- Directory structure, key files — scan existing files if this is a brownfield project; leave as placeholder for greenfield

**Phase 2 — mark as TODO** (not enough context yet):
- Code Patterns (Naming, Error Handling, File Organization)
- Architecture details
- Testing patterns

Mark these sections explicitly as `TODO: update after first feature` — do not invent or leave blank.

Do not modify `CLAUDE-template.md` — it stays as the reusable source. `CLAUDE.md` is the living document.

### 4. Confirm

```
Project configured:
  Name:     {name}
  Repo:     {repo}
  Branch:   {base_branch}
  Test:     {test_cmd}
  Dev:      {dev_cmd} on :{dev_port}

Generated: .claude/CLAUDE.md
  ✓ Filled:  description, tech stack, commands, directory structure
  ~ TODO:    code patterns, architecture details, testing patterns
             → update after your first feature

Next: run /prime to load context and start working.
```
