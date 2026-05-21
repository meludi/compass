# Concepts

The four frameworks behind this workflow. Read once to understand why things are structured the way they are.

---

## 1. The Logical Flow

Every coding session fits into one of four phases:

```
IDEATE → STORY → PIV LOOP → SYSTEM EVOLUTION
```

**Glossary:**
- **IDEATE** — structured brain dump with the agent. Raw ideas, no structure yet. AI asks clarifying questions.
- **STORY** — a scoped unit of work with acceptance criteria. Saved to `.work/stories/`; optionally synced to Linear.
- **PIV** — Plan → Implement → Validate. The three phases of every development iteration.

| Phase | What happens | Commands |
|-------|-------------|---------|
| **IDEATE** | Brain dump with the agent. Raw ideas, no structure. AI asks clarifying questions. | (conversation) |
| **STORY** | Write a PRD, break it into stories. Stories are the spec — tool-agnostic. | `/create-prd`, `/create-stories` |
| **PIV LOOP** | Per story: Plan → Implement → Validate → Merge. | `/prime`, `/feature-plan`, `/feature-build`, `/validate`, `/create-pr`, `/review` |
| **SYSTEM EVOLUTION** | Every bug is an opportunity. Fix the system, not just the symptom. | `/reflect`, update `CLAUDE.md`, commands, `reference/` |

IDEATE and STORY happen once per initiative. The PIV Loop runs for every story.

---

## 2. The Four Golden Rules

| Rule | Principle | How this starter applies it |
|------|-----------|---------------------------|
| **Context Reset** | Plan and execute in separate conversations. Fresh start = sharp focus. | `/worktree` opens a new Claude session per story |
| **Command-ify Everything** | If you do it twice, make it a command. | All repeated actions are slash commands in `.claude/commands/` |
| **Git Log as Memory** | Standardized commits communicate intent to future sessions. | `/commit` enforces Conventional Commits (`feat:`, `fix:`, `refactor:`) |
| **System Evolution** | Every bug → fix the system that allowed it. | `/reflect` guides through updating `CLAUDE.md`, commands, `reference/` docs |

---

## 3. The 10x Reframe

> Bolting AI on = **2x**. Building for parallelism = **10x**.

Same human, same hours — five parallel stories, five worktrees, five fresh-context reviews.

### The 5 Pillars

| # | Pillar | In this starter |
|---|--------|----------------|
| 1 | **Story is the Spec** | `.work/stories/*.md` or Linear issue — any worktree picks it up |
| 2 | **Plan / Build / Validate** | `/feature-plan` → `/feature-build` → `/validate` |
| 3 | **Parallel Worktrees** | `/worktree` → isolated branch + dir + Claude session |
| 4 | **Fresh-Session Review** | `/review` spawns subagents that never saw the writer's chat |
| 5 | **Self-Healing Layer** | System Evolution: bug → `/reflect` → rule → never returns |

### The 5 Blockers (and how this starter handles them)

| Blocker | Fix |
|---------|-----|
| Port `:3000` conflict | Dev server runs from main dir only — never from worktrees |
| `node_modules` × N | Each worktree installs its own (pnpm content store deduplicates) |
| DB races | `worktree.sh` copies `db_file` per worktree — isolated state |
| Token blowouts | Subagents for research; only summaries return to main context |
| PR pile-up | `/review` fans out 3 parallel subagents per PR |

---

## 4. Greenfield Building Blocks

Four patterns that keep context lean and agents effective:

| Pattern | Principle | In this starter |
|---------|-----------|----------------|
| **PRD-First** | Document before you code. PRD (Product Requirements Document) = source of truth for every AI conversation. | `/create-prd` → `.work/prds/` |
| **Modular Rules** | Split rules by concern. Load only what's relevant. | `CLAUDE.md` + `reference/` docs (load on demand) |
| **Prime** | Bootstrap context at session start. Never code before the agent has a mental model. | `/prime` at the start of every session |
| **Subagents for Isolation** | Delegate research to subagents. Only summaries return — main context stays clean. | `/feature-plan` spawns `codebase-explorer`; `/review` fans out 3 agents |
