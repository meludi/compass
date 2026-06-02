# Concepts

The four frameworks behind this workflow. Read once to understand why things are structured the way they are.

---

## 1. The Logical Flow

Every initiative moves through four phases: **ideate → story → build → evolve**. Ideate and story happen once per initiative; the build phase (the PIV loop) repeats per story; evolution feeds learnings back into the system so a mistake never repeats.

The concrete command flow for each phase lives in `WORKFLOW.md` (the canonical map); term definitions (IDEATE, STORY, PIV, PRD) in `HANDBOOK.md`.

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
| 2 | **Plan / Implement / Validate** | `/plan-feature` → `/implement` (validation folded in) → `/ship` |
| 3 | **Parallel Worktrees** | `/worktree` → isolated branch + dir + Claude session |
| 4 | **Fresh-Session Review** | `/ship` spawns subagents that never saw the writer's chat |
| 5 | **Self-Healing Layer** | System Evolution: bug → `/reflect` → rule → never returns |

### The 5 Blockers (and how this starter handles them)

| Blocker | Fix |
|---------|-----|
| Port `:3000` conflict | Dev server runs from main dir only — never from worktrees |
| `node_modules` × N | Each worktree installs its own (pnpm content store deduplicates) |
| DB races | `worktree.sh` copies `db_file` per worktree — isolated state |
| Token blowouts | Subagents for research; only summaries return to main context |
| PR pile-up | `/ship` fans out 3 parallel subagents per PR |

---

## 4. Greenfield Building Blocks

Four patterns that keep context lean and agents effective:

| Pattern | Principle | In this starter |
|---------|-----------|----------------|
| **PRD-First** | Document before you code. PRD (Product Requirements Document) = source of truth for every AI conversation. | `/ideate` → `.work/prds/` |
| **Stack Scaffolding** | Make framework and code-pattern choices once, up front, so every later session writes consistent code. | `/setup-stack` scaffolds framework, fills `CLAUDE.md` Code Patterns, drops seed files |
| **Modular Rules** | Split rules by concern. Load only what's relevant. | `CLAUDE.md` + `reference/` docs (load on demand) |
| **Project Context** | Bootstrap context at session start. Never code before the agent has a mental model. | `/context` loads project rules, git state, spec, and on-demand docs; `/plan-feature` and `/implement` call it as their first step |
| **Subagents for Isolation** | Delegate research to subagents. Only summaries return — main context stays clean. | `/plan-feature` spawns `codebase-explorer`; `/ship` fans out 3 agents |

---

For the day-to-day command flow see `WORKFLOW.md`; for the full command table and troubleshooting see `HANDBOOK.md`.
