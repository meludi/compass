---
description: Break a PRD into stories — saves to .work/stories/, optionally creates tracker issues
argument-hint: <path to .work/prds/*.prd.md>
---

# /compass:create-stories — Generate Tracker Issues from PRD

> **Model:** `/model sonnet` — balanced model for this command.

Generate user stories from a PRD and create them as issues in your tracker via MCP.

## Input

`/compass:create-stories <path to .work/prds/*.prd.md>`

Or run after `/compass:ideate` when the PRD is already loaded.

## Steps

### 1. Load PRD

Read the PRD file. Extract: user stories, acceptance criteria, technical notes, phases.

### 2. Break into stories

For each user story, create a structured issue:

- **Title**: concise, action-oriented ("Add recently visited to AppHeader")
- **Type**: Feature / Bug / Chore / Spike
- **Priority**: Urgent / High / Medium / Low
- **Description**: user story + context
- **Acceptance criteria**: concrete, testable conditions
- **Technical notes**: patterns to follow, files to change

Aim for stories that take 1–2 days max. Split larger work into phases.

### 3. Save locally

Save all stories to `.work/stories/{prd-name}-stories.md` before creating them in the tracker.

### 4. Create issues in the tracker via MCP

For each story, use `mcp__linear-server__save_issue` to create the issue.

Required fields:

- `title`
- `description` (markdown: user story + acceptance criteria + technical notes)
- `teamId` (get from `mcp__linear-server__get_team` if not known)
- `priority` (1=Urgent, 2=High, 3=Medium, 4=Low)

After creating: report each issue with its tracker ID and URL.

### 5. Output

Summary table:

| Story                | Issue ID | Priority |
| -------------------- | -------- | -------- |
| Add recently visited | PD-42    | Medium   |

Stories are now created — pick one and run `/compass:worktree <name>` to start.
