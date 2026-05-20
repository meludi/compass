---
description: Set up claude-workflow-starter for a new project
---

# /init — Project Setup

Configure this Claude workflow for your project by filling in `project.yml` and `.claude/CLAUDE.md`.

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
11. **Worktree prefix** — [../my-app-]
12. **Source directory** — [src/]

### 2. Write `project.yml`

Fill in all values in `project.yml` at the project root.

### 3. Generate `.claude/CLAUDE.md` from template

Read `.claude/CLAUDE-template.md`, fill in all `{placeholder}` values, write to `.claude/CLAUDE.md`:

- `{Project description and purpose}` — ask the user for a one-paragraph description
- `{tech}` / `{why it's used}` — Tech Stack from what the user tells you
- `{dev-command}`, `{build-command}`, `{test-command}`, `{lint-command}` — from step 1
- `{root}/`, `{dir}/` — ask the user or scan existing files for the directory tree
- Code Patterns, Key Files — ask the user or leave as `{fill in}` for later

Do not modify `CLAUDE-template.md` — it stays as the reusable source.

### 4. Confirm

```
Project configured:
  Name:     {name}
  Repo:     {repo}
  Branch:   {base_branch}
  Test:     {test_cmd}
  Dev:      {dev_cmd} on :{dev_port}

Next: run /prime to load context and start working.
```
