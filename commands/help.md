---
description: Which command fits your situation — a router over compass, Claude Code and mattpocock/skills
argument-hint: "[what you are trying to do]"
---

# /compass:help — What Do I Run?

> **Model:** `/model haiku` — this command routes, it does not think.

You know the eight compass commands. What is easy to forget is the **boundary**: when a job belongs to compass, when to Claude Code, when to a skill, and when to nobody.

`WORKFLOW.md` orders these by flow. This orders them by the situation you are in.

## How to answer

With `$ARGUMENTS`: find the matching row, name the command, say in one sentence why that one and not its neighbour. Stop there — do not run it.

Without arguments: print all three sections below — the situation table, *The pairs people confuse*, and *Nothing to run*. Stop there: no summary, no next-step suggestion.

**Never** invent a command. If nothing fits, say so and name the closest thing.

---

## Situation → command

| You are here | Run | Whose |
|---|---|---|
| Not sure yet what to build | `/mattpocock-skills:grill-with-docs` | mattpocock |
| Know the what, not the where in the code | `/compass:plan-feature <spec>` | compass |
| Plan exists, build it | `/compass:implement <plan>` | compass |
| Is everything still green? | `/compass:validate` | compass |
| Built it, want a look before the PR | `/code-review` | Claude Code |
| Ready to open the PR | `/compass:ship` | compass |
| Just commit, no PR | `/compass:commit [--push]` | compass |
| Review comments are sitting on the PR | `/compass:fix-ci-review` | compass |
| CI is red and you would rather not deal with it | `/autofix-pr` | Claude Code |
| Building two things at once | `/compass:worktree <name>` | compass |
| A bug that survived three attempts | `/mattpocock-skills:diagnosing-bugs` | mattpocock |
| The change touches auth, input handling or secrets | `/security-review` | Claude Code |
| New project, nothing set up | `/compass:setup`, then `/install-github-app` | compass, Claude Code |

Not installed? mattpocock's skills come from `claude plugins install mattpocock-skills` — take the plugin, not the `npx skills` copy, which loads them unprefixed and puts a second `code-review` beside Claude Code's. Everything marked *Claude Code* is already there. For mattpocock's set specifically, `/mattpocock-skills:ask-matt` routes deeper than this file does.

---

## The pairs people confuse

| | |
|---|---|
| `/code-review` **vs** `/compass:fix-ci-review` | Where the findings live. In this session → `/code-review`, fix them directly. On GitHub, outside your context → `fix-ci-review` fetches them. Before a PR exists there is nothing to fetch. |
| `/compass:fix-ci-review` **vs** `/autofix-pr` | Who decides. `fix-ci-review` lists findings, waits for your go, validates locally, and leaves the push to you. `/autofix-pr` watches the PR and pushes its own fixes — `/compass:validate` never sees those commits. Pick one per PR. |
| `/compass:validate` **vs** `/code-review` | Machines vs judgement. `validate` runs your lint, types and tests. `/code-review` reads the diff for the things no command can check. |
| `/compass:commit` **vs** `/compass:ship` | `ship` is commit + push + PR + handoff. Use `commit` when you are not opening a PR yet. |
| `/compass:plan-feature` **vs** `mattpocock-skills:to-spec` | Altitude. `to-spec` decides what to build and deliberately names no files. `plan-feature` names the files, in dependency order. The spec is its input. |
| `/compass:worktree` **vs** just branching | Only worth it in parallel. One feature at a time needs no worktree; nothing downstream depends on it. |

---

## Nothing to run

- **After `/compass:ship`, waiting on review** — the PR is not yours to push on. Merging is manual, always.
- **A finding you disagree with** — flag it for the author with a reason. There is no command for being overruled.
- **Three failed attempts at the same cause** — stop patching. The diagnosis is wrong, not the fix; `/mattpocock-skills:diagnosing-bugs` if you have it.
