---
description: Switch the issue tracker (Linear, Jira, Azure DevOps) — updates .mcp.json, context.md, create-stories.md
---

# /setup-tracker — Configure Issue Tracker

> **Recommended:** `/model sonnet` — balanced model for this command.

Switch between issue trackers. Updates the 3 files that reference Linear so the whole workflow points to the new tracker.

---

## Step 1 — Choose tracker

Ask the user:

```
Which issue tracker do you want to use?

1. Linear (default — cloud MCP, Bearer Token)
2. Jira — Atlassian official Rovo MCP (cloud, OAuth 2.1)
3. Jira — community mcp-atlassian (self-hosted or cloud, API Token)
4. Azure DevOps — remote MCP (cloud, OAuth via Entra ID)
5. Azure DevOps — local MCP (npm package, PAT)
```

Wait for selection before continuing.

---

## Step 2 — Collect credentials

Based on selection:

**1 — Linear**
- Ask: Linear API key (`lin_api_...`)
- Source: [linear.app](https://linear.app) → Settings → API → Personal API keys

**2 — Jira (Atlassian official Rovo MCP)**
- No API key needed — uses OAuth 2.1 browser flow on first MCP call
- Ask: Jira base URL (e.g. `https://yourcompany.atlassian.net`)
- Docs: https://support.atlassian.com/atlassian-rovo-mcp-server

**3 — Jira (community mcp-atlassian)**
- Ask: Jira base URL (e.g. `https://yourcompany.atlassian.net`)
- Ask: Jira API token (Atlassian account token, not password)
- Source: id.atlassian.com → Security → API tokens
- Optionally: Confluence URL (leave blank to skip)
- Docs: https://github.com/sooperset/mcp-atlassian

**4 — Azure DevOps (remote MCP)**
- No API key needed — uses OAuth via Entra ID on first MCP call
- Ask: Azure DevOps organization name (e.g. `myorg` from `dev.azure.com/myorg`)
- Docs: https://learn.microsoft.com/azure/devops/mcp-server

**5 — Azure DevOps (local MCP)**
- Ask: Azure DevOps organization name
- Ask: Personal Access Token (PAT)
- Source: dev.azure.com → User Settings → Personal Access Tokens
- Docs: https://github.com/microsoft/azure-devops-mcp

---

## Step 3 — Show planned changes (diff-style)

Before applying, show exactly what will change across the 3 files:

```
Files to update:
  .mcp.json                        — MCP server config + auth
  .claude/commands/context.md      — tool name for loading an issue (called by /plan-feature, /implement)
  .claude/commands/create-stories.md — tool name for creating issues
```

Show the key values being set (server URL, tool names, env vars).
Ask: "Apply these changes? (yes/no)"

---

## Step 4 — Apply changes

After confirmation, update all 3 files:

### `.mcp.json`

**Linear:**
```json
{
  "mcpServers": {
    "linear-server": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/mcp"],
      "env": {
        "MCP_REMOTE_HEADER_Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    }
  }
}
```

**Jira (Atlassian official):**
```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

**Jira (community mcp-atlassian):**
```json
{
  "mcpServers": {
    "jira": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "<jira-base-url>",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    }
  }
}
```
(If Confluence URL was provided, add `CONFLUENCE_URL` env var.)

**Azure DevOps (remote):**
```json
{
  "mcpServers": {
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.dev.azure.com/<org>"]
    }
  }
}
```

**Azure DevOps (local):**
```json
{
  "mcpServers": {
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp"],
      "env": {
        "ADO_ORG": "<org>",
        "ADO_PAT": "${ADO_PAT}"
      }
    }
  }
}
```

---

### `.claude/commands/context.md` — update the spec-loading step

Description texts in `context.md` are already tracker-neutral ("issue ID", not "Linear issue ID") — do not change them.

Update these three things:

**1. MCP tool name** (Step 3, the issue-ID branch):

| Tracker | Tool |
|---------|------|
| Linear | `mcp__linear-server__get_issue` |
| Jira (official) | `mcp__atlassian__getJiraIssue` |
| Jira (community) | `mcp__jira__jira_get_issue` |
| Azure DevOps (remote or local) | `mcp__azure-devops__wit_work_item` |

**2. `argument-hint` frontmatter** — set per tracker:

| Tracker | argument-hint |
|---------|--------------|
| Linear / Jira | `<path to .work/stories/*.md \| issue-id \| feature description>` |
| Jira (with Confluence URL configured) | `<path to .work/stories/*.md \| issue-id \| confluence-page-url \| feature description>` |
| Azure DevOps | `<path to .work/stories/*.md \| work-item-id \| feature description>` |

**3. For Jira + Confluence only** — add a Confluence option to the Spec list in Step 1:

```
A **Confluence page URL** → fetch with `mcp__atlassian__getConfluencePage` (official)
or `mcp__jira__confluence_get_page` (community). Extract page title and body — use as
additional session context.
```

---

### `.claude/commands/create-stories.md` — update "Create in tracker" step

Replace the Linear MCP tools with the correct tracker tools:

| Tracker | Create issue | Get team/project |
|---------|-------------|-----------------|
| Linear | `mcp__linear-server__save_issue` | `mcp__linear-server__get_team` |
| Jira (official) | `mcp__atlassian__createJiraIssue` | `mcp__atlassian__getJiraProjects` |
| Jira (community) | `mcp__jira__jira_create_issue` | `mcp__jira__jira_get_projects` |
| Azure DevOps | `mcp__azure-devops__wit_work_item_write` | (use project name from config) |

Update required fields section to match the tracker's schema.

---

### `settings.local.json` — add env vars and enable the MCP server

Add to `.claude/settings.local.json` (gitignored). `enabledMcpjsonServers` must match the key in `.mcp.json`.

**Linear:**
```json
{
  "env": { "LINEAR_API_KEY": "lin_api_..." },
  "enabledMcpjsonServers": ["linear-server"]
}
```

**Jira (official — OAuth, no token needed):**
```json
{
  "enabledMcpjsonServers": ["atlassian"]
}
```

**Jira (community):**
```json
{
  "env": { "JIRA_API_TOKEN": "..." },
  "enabledMcpjsonServers": ["jira"]
}
```

**Azure DevOps (remote — OAuth, no token needed):**
```json
{
  "enabledMcpjsonServers": ["azure-devops"]
}
```

**Azure DevOps (local):**
```json
{
  "env": { "ADO_PAT": "..." },
  "enabledMcpjsonServers": ["azure-devops"]
}
```

---

## Step 5 — Test the connection

After applying, call the "get issue" tool with a real or test issue ID:

- **Linear**: `mcp__linear-server__get_issue` with a known issue ID
- **Jira (official)**: `mcp__atlassian__getJiraIssue` (triggers OAuth browser flow if first time)
- **Jira (community)**: `mcp__jira__jira_get_issue`
- **Azure DevOps (remote)**: `mcp__azure-devops__wit_work_item` (triggers OAuth if first time)
- **Azure DevOps (local)**: `mcp__azure-devops__wit_work_item`

Ask the user for an issue/work-item ID to test with. If they don't have one handy, skip the test.

**On success:** "Tracker configured. Run `/context <ISSUE-ID>` (or `/plan-feature <ISSUE-ID>`) to load your first story."
**On error:** Show the exact error message and a concrete troubleshooting hint (wrong URL, missing token, OAuth not completed, etc.).

---

For documentation links and API token setup per tracker, see `README.md` → "Alternative issue trackers".
