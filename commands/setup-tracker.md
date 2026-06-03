---
description: Switch the issue tracker (Linear, Jira, Azure DevOps) — updates .mcp.json, compass.yml, settings.local.json
---

# /compass:setup-tracker — Configure Issue Tracker

> **Model:** `/model sonnet` — balanced model for this command.

Switch between issue trackers. The commands (`/compass:context`, `/compass:create-stories`) read the tracker's MCP tool names from `.claude/compass.yml` — they are generic. So switching trackers updates three **project** files, none of them command files: `.mcp.json` (MCP server + auth), `.claude/compass.yml` (the `tracker_*` fields), and `.claude/settings.local.json` (env + enabled server).

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

Before applying, show exactly what will change across the 3 project files:

```
Files to update:
  .mcp.json                     — MCP server config + auth
  .claude/compass.yml           — tracker + tracker_*_tool fields (read by /compass:context, /compass:create-stories)
  .claude/settings.local.json   — env vars + enabledMcpjsonServers
```

Show the key values being set (server URL, tracker name, MCP tool names, env vars).
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

### `.claude/compass.yml` — set the tracker fields

`/compass:context` and `/compass:create-stories` read these fields and call whatever
MCP tools they name — no command file is edited. Set all four per the chosen tracker:

| Tracker | `tracker` | `tracker_get_issue_tool` | `tracker_create_issue_tool` | `tracker_get_team_tool` |
|---------|-----------|--------------------------|-----------------------------|-------------------------|
| Linear | `linear` | `mcp__linear-server__get_issue` | `mcp__linear-server__save_issue` | `mcp__linear-server__get_team` |
| Jira (official) | `jira-official` | `mcp__atlassian__getJiraIssue` | `mcp__atlassian__createJiraIssue` | `mcp__atlassian__getJiraProjects` |
| Jira (community) | `jira-community` | `mcp__jira__jira_get_issue` | `mcp__jira__jira_create_issue` | `mcp__jira__jira_get_projects` |
| Azure DevOps (remote or local) | `azure` | `mcp__azure-devops__wit_work_item` | `mcp__azure-devops__wit_work_item_write` | _(blank — use the project name)_ |

Edit the existing `tracker_*` keys in place (they ship with Linear defaults). Do not
add or remove keys — the schema (`compass.schema.json`) rejects unknown ones.

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

**On success:** "Tracker configured. Run `/compass:context <ISSUE-ID>` (or `/compass:plan-feature <ISSUE-ID>`) to load your first story."
**On error:** Show the exact error message and a concrete troubleshooting hint (wrong URL, missing token, OAuth not completed, etc.).

---

For documentation links and API token setup per tracker, see `README.md` → "Alternative issue trackers".
