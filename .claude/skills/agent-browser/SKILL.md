---
name: agent-browser
description: Automates browser interactions for UI testing after feature implementation. Use to test golden paths, take screenshots, and verify UI changes. Requires the dev server to be running.
allowed-tools: Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Used by `/validate` to verify UI before opening a PR. The dev server must be running (see `dev_cmd` and `dev_port` in `.claude/project.yml`).

**Screenshot path convention:** always save to `.work/screenshots/{name}.png` — this directory is gitignored.

## Quick start

```bash
agent-browser open http://localhost:{dev_port}   # Open app (dev_port from `.claude/project.yml`)
agent-browser snapshot -i                  # Get interactive elements
agent-browser screenshot                   # Take screenshot
agent-browser close                        # Close browser
```

## Core workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns refs like `@e1`, `@e2`)
3. Interact using refs
4. Re-snapshot after navigation or DOM changes

## Commands

### Navigation

```bash
agent-browser open <url>
agent-browser back / forward / reload / close
```

### Snapshot

```bash
agent-browser snapshot -i         # Interactive elements (recommended)
agent-browser snapshot -c         # Compact output
agent-browser snapshot -s "#main" # Scope to selector
```

### Interactions

```bash
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser press Enter
agent-browser hover @e1
agent-browser scroll down 500
```

### Get information

```bash
agent-browser get text @e1
agent-browser get url
agent-browser get title
```

### Screenshots

```bash
agent-browser screenshot                              # To stdout
agent-browser screenshot .work/screenshots/{name}.png # Save to file (use this path)
agent-browser screenshot --full                       # Full page
```

### Wait

```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait ms
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --load networkidle      # Wait for network idle
```

### Semantic locators

```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
```

## Debugging

```bash
agent-browser open <url> --headed  # Show browser window
agent-browser console              # View console messages
agent-browser errors               # View page errors
```
