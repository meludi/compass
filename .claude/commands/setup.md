---
description: Set up claude-workflow-starter for a new project
---

# /setup — Project Setup

> **Recommended:** `/model sonnet` — balanced model for this command.

Configure this Claude workflow for your project. Run once after copying the starter into your project. Runs in two phases — same command both times.

**What it does:**
1. Phase 1 — writes `.claude/project.yml` with defaults, asks you to fill it in
2. Phase 2 — validates `.claude/project.yml`, generates `.claude/CLAUDE.md`

---

## Phase Detection

Read `.claude/project.yml`.

- `name: ""` (empty) → **run Phase 1**
- `name` has a value → **run Phase 2**

---

## Phase 1 — Write Template

Write `.claude/project.yml` with the following content (preserve all inline comments):

```yaml
# Project configuration — edit these values, then run /setup again to generate CLAUDE.md
name: ""                # Required — short identifier, e.g. my-app
repo: ""                # Required — GitHub slug, e.g. owner/my-app
base_branch: main       # Branch PRs are opened against

package_manager: npm    # npm | pnpm | yarn | bun

dev_cmd: npm run dev    # Start dev server
dev_port: 3000          # Dev server port (number)

test_cmd: npm test
lint_cmd: npm run lint
format_cmd: npm run format
type_check_cmd: ""      # Optional — e.g. npm run typecheck — leave blank if not used

src_dir: src/           # Source directory
worktree_prefix: ""     # e.g. ../my-app- — placed as sibling of main project dir
db_file: ""             # Optional — e.g. myapp.db — copied per worktree by worktree.sh

autonomy_mode: off      # off | review-only | full — see .claude/reference/AUTONOMY.md

description: ""         # One paragraph — what does this project do?
```

Then output:

```
.claude/project.yml written with defaults.

Open the file, fill in your values, then run /setup again.
```

Stop. Do not proceed to Phase 2.

---

## Phase 2 — Validate + Generate

### Step 1 — Validate

Check the following fields and collect all errors before reporting:

| Field | Rule |
|---|---|
| `name` | Must not be empty |
| `repo` | Must not be empty, must match `owner/repo` format |
| `base_branch` | Must not be empty |
| `package_manager` | Must be one of: `npm`, `pnpm`, `yarn`, `bun` |
| `dev_port` | Must be a number |
| `autonomy_mode` | Must be one of: `off`, `review-only`, `full` (defaults to `off` if missing) |

If any errors exist, output them all at once and stop:

```
Validation failed — fix the following in .claude/project.yml:

  - package_manager: "npmp" is not valid. Must be one of: npm, pnpm, yarn, bun
  - dev_port: "abc" is not a number
```

Do not generate CLAUDE.md until all errors are resolved.

### Step 2 — Warn about unvalidatable fields

After successful validation, always output this notice:

```
Note: dev_cmd, test_cmd, lint_cmd, format_cmd, type_check_cmd cannot be
validated automatically. Please review these manually before continuing.
```

### Step 3 — Generate `.claude/CLAUDE.md`

Read `.claude/CLAUDE-template.md`. Generate `CLAUDE.md` in two phases:

**Fill immediately** (from `project.yml` + codebase scan):
- Project description — from `description` field
- Tech stack — scan existing files (package.json, lock files, config files)
- Commands — from `dev_cmd`, `test_cmd`, `lint_cmd`, `format_cmd`, `type_check_cmd`
- Directory structure, key files — scan existing files (brownfield); leave as placeholder (greenfield)

**Mark as TODO** (not enough context yet):
- Code Patterns (Naming, Error Handling, File Organization)
- Architecture details
- Testing patterns

Mark these sections explicitly as `TODO: update after first feature` — do not invent or leave blank.

Do not modify `CLAUDE-template.md` — it stays as the reusable source.

### Step 4 — Confirm

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

Next: run /ideate — brain dump with the agent; it writes the spec.
```
