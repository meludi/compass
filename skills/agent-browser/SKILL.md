---
name: agent-browser
description: Automates browser interactions for UI testing after feature implementation. Use to test golden paths, take screenshots, and verify UI changes. Requires the dev server to be running.
allowed-tools: Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Used by `/compass:validate` to verify UI before opening a PR.

`agent-browser --help` is the command reference — read it there rather than from memory. What follows is what the CLI does not tell you.

## Before you start

The dev server must already be running. Start it with the `Dev` command from `.claude/CLAUDE.md` → `## Commands`, on the port named in the **Dev port** line beneath that table. That port is also the one to open.

## The loop

```bash
agent-browser open http://localhost:{dev port}
agent-browser snapshot -i     # interactive elements, returns refs: @e1, @e2, …
agent-browser click @e1       # interact by ref, never by selector
agent-browser close
```

**Re-snapshot after every navigation or DOM change.** Refs are bound to the snapshot that produced them — acting on a stale `@e1` hits whatever now occupies that slot, which fails silently rather than erroring.

## Screenshots

Always save to `.work/screenshots/{name}.png` — that directory is gitignored. A screenshot written anywhere else lands in the user's commit.

## When something looks wrong

`--headed` shows the browser window, `console` prints console messages, `errors` prints page errors. Read the console before concluding the UI is broken — a failed request explains more than a screenshot does.
