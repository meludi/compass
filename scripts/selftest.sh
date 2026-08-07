#!/usr/bin/env bash
# selftest.sh — read-only static dry-run of the compass plugin.
#
# Validates everything that does NOT need a human, GitHub, or an external AI:
# manifests, templates, config-vs-schema, scripts, doc links, inventory. It is the
# "lint" to TESTING.md's "E2E" — the behavioural workflow (slash commands, CI,
# native auto-fix / Codex) is covered there.
#
#   bash scripts/selftest.sh                  # static checks, stdout only
#   bash scripts/selftest.sh --full           # + functional worktree.sh test (temp repo)
#   bash scripts/selftest.sh --report         # + write reports/selftest-report-<date>.md (gitignored)
#   bash scripts/selftest.sh --report FILE     # write the report to FILE
#
# Exits non-zero if any check FAILs. The static checks mutate nothing; --full
# creates and removes a throwaway git repo under the system temp dir only.
# Requires: ruby + bash. Uses actionlint / shellcheck only if on PATH.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPORT=""
FULL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --full) FULL=1; shift ;;
    --report)
      shift
      if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then REPORT="$1"; shift
      else REPORT="$ROOT/reports/selftest-report-$(date +%Y-%m-%d-%H%M%S).md"; fi ;;
    -h|--help) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "selftest: unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v ruby >/dev/null 2>&1 || { echo "selftest: ruby is required"; exit 2; }

PASS=0
FAIL=0
log()  { [ -n "$REPORT" ] && printf '%s\n' "$1" >> "$REPORT"; return 0; }
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; log "- PASS — $1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; log "- FAIL — $1"; FAIL=$((FAIL + 1)); }
sec()  { printf '\n== %s ==\n' "$1"; log ""; log "### $1"; }

if [ -n "$REPORT" ]; then
  mkdir -p "$(dirname "$REPORT")"
  {
    echo "# compass selftest report"
    echo
    echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "- Repo: $ROOT"
    echo "- Mode: $([ "$FULL" -eq 1 ] && echo 'full (static + functional worktree)' || echo 'static')"
  } > "$REPORT"
fi

# 1. JSON manifests parse
sec "JSON manifests"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if ruby -rjson -e "JSON.parse(File.read(ARGV[0]))" "$f" 2>/dev/null; then pass "$f"; else fail "$f — invalid JSON"; fi
done

# 2. compass has no config file of its own. Project config is the ## Commands table
#    in the generated CLAUDE.md — nothing else, or the truth has two copies again.
sec "No config file"
stale=$(grep -rl 'compass\.yml\|compass\.schema\.json' commands references skills templates scripts hooks README.md TESTING.md 2>/dev/null \
        | grep -v '^scripts/selftest.sh$' || true)
if [ -e templates/compass.yml ] || [ -e compass.schema.json ]; then
  fail "compass.yml/compass.schema.json are back — config lives in CLAUDE.md"
elif [ -n "$stale" ]; then
  fail "stale config references: $(echo "$stale" | tr '\n' ' ')"
else
  pass "no config file, no stale references"
fi

# 3. The row labels ARE the interface: commands look them up by name in the
#    generated CLAUDE.md. Renaming one here silently disables its gate.
sec "CLAUDE template carries the config table"
missing=""
for label in Dev Build Lint Format "Type check" Test; do
  grep -qE "^\| *$label *\|" templates/CLAUDE-template.md || missing="$missing $label"
done
for line in "Test policy" "Dev port" "Base branch"; do
  grep -q "\*\*$line:\*\*" templates/CLAUDE-template.md || missing="$missing $line"
done
if [ -z "$missing" ]; then pass "all config rows present"; else fail "missing from template:$missing"; fi

# 6. Shell scripts: syntax (+ shellcheck if present)
sec "Shell scripts"
for f in scripts/*.sh; do
  if bash -n "$f" 2>/dev/null; then pass "bash -n $f"; else fail "bash -n $f"; fi
done
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error scripts/*.sh >/dev/null 2>&1; then pass "shellcheck (errors) clean"; else fail "shellcheck reported errors"; fi
fi

# 7. Mermaid / code fences balanced in docs
sec "Doc code fences balanced"
bad=0
for f in references/*.md README.md TESTING.md; do
  n=$(grep -c '```' "$f")
  [ $((n % 2)) -eq 0 ] || { fail "$f — unbalanced fences ($n)"; bad=1; }
done
[ $bad -eq 0 ] && pass "all fences balanced"

# 8. ${CLAUDE_PLUGIN_ROOT}/… references resolve to real files
sec "Plugin-root references"
bad=0
while read -r ref; do
  rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  [ -e "$rel" ] || { fail "missing: $ref"; bad=1; }
done < <(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' commands references hooks 2>/dev/null | sort -u)
[ $bad -eq 0 ] && pass "all plugin-root references resolve"

# 9. Relative *.md links resolve
sec "Relative doc links"
bad=0
for f in references/*.md README.md; do
  while read -r link; do
    [ -z "$link" ] && continue
    d=$(dirname "$f")
    [ -e "$d/$link" ] || { fail "$f -> $link"; bad=1; }
  done < <(grep -oE '\]\(([A-Za-z0-9_./-]+\.md)(#[^)]*)?\)' "$f" | sed -E 's/\]\(([^)#]+).*/\1/')
done
[ $bad -eq 0 ] && pass "all relative .md links resolve"

# 10. Command frontmatter present
sec "Command frontmatter"
bad=0
for f in commands/*.md; do
  head -1 "$f" | grep -q '^---$' || { fail "$f — no frontmatter"; bad=1; }
done
[ $bad -eq 0 ] && pass "all commands start with frontmatter"

# 11. Component inventory
sec "Inventory"
c=$(find commands -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
s=$(find skills -maxdepth 2 -name 'SKILL.md' | wc -l | tr -d ' ')
echo "  commands=$c skills=$s"; log "- commands=$c skills=$s"
[ -f hooks/hooks.json ] && pass "SessionStart hook present" || fail "hooks/hooks.json missing"

# The PIV core is the plugin's reason to exist — assert it by name, not by count.
# help is the ninth: a router, not workflow. Everything else is a regression.
bad=0
for cmd in setup plan-feature implement validate commit ship fix-ci-review worktree help; do
  [ -f "commands/$cmd.md" ] || { fail "commands/$cmd.md missing"; bad=1; }
done
[ $bad -eq 0 ] && pass "all 8 workflow commands + help present"
[ "$c" -eq 9 ] && pass "no stray commands ($c)" || fail "expected 9 commands, found $c"

# Review belongs to /code-review and claude-code-action — compass must not grow
# its own review command or reviewer agents back.
[ -d agents ] && fail "agents/ is back — review agents were dropped deliberately" \
              || pass "no agents/ directory"

# 12. Functional worktree.sh test (--full) — throwaway temp repo, removed after
if [ "$FULL" -eq 1 ]; then
  sec "worktree.sh functional (temp repo)"
  WT="$(mktemp -d)/wt"; mkdir -p "$WT"
  ( # No compass.yml and no lockfile: worktree.sh must work off the repo alone.
    # No origin either — the base-branch lookup has to survive that.
    cd "$WT" && git init -q repo && cd repo \
      && git config user.email t@t.dev && git config user.name tester && git branch -M main \
      && mkdir -p .claude \
      && printf '#!/usr/bin/env bash\necho "hook:$WT_NAME:$WT_PORT" > .hook-ran\n' > .claude/worktree-setup.sh \
      && echo SECRET > .env.local && echo "# repo" > README.md \
      && git add -A && git commit -qm init
  )
  TARGET="$WT/repo-test"
  ( cd "$WT/repo" && bash "$ROOT/scripts/worktree.sh" test ) >/dev/null 2>&1 || true
  [ -d "$TARGET" ] && pass "worktree created (no config, no origin)" || fail "worktree not created"
  ( cd "$WT/repo" && git show-ref --verify --quiet refs/heads/feat/test ) && pass "branch feat/test exists" || fail "branch missing"
  port=$(cat "$TARGET/.worktree-port" 2>/dev/null || echo "")
  case "$port" in [0-9]*) pass ".worktree-port reserved ($port)";; *) fail ".worktree-port missing or not numeric";; esac
  [ -L "$TARGET/.env.local" ] && pass ".env.local symlinked" || fail ".env.local not symlinked"
  grep -q "^hook:test:$port$" "$TARGET/.hook-ran" 2>/dev/null \
    && pass "setup hook ran with WT_NAME/WT_PORT" || fail "setup hook did not run correctly"
  echo dirty > "$TARGET/x.txt"
  ( cd "$WT/repo" && bash "$ROOT/scripts/worktree.sh" test rm ) >/dev/null 2>&1 && rc=0 || rc=1
  { [ "$rc" -ne 0 ] && [ -d "$TARGET" ]; } && pass "rm refuses on uncommitted changes" || fail "rm did not guard uncommitted"
  ( cd "$TARGET" && git add -A && git commit -qm work ) >/dev/null 2>&1
  ( cd "$WT/repo" && bash "$ROOT/scripts/worktree.sh" test rm ) >/dev/null 2>&1 && rc=0 || rc=1
  [ "$rc" -ne 0 ] && pass "rm refuses on unmerged commits" || fail "rm did not guard unmerged"
  ( cd "$WT/repo" && bash "$ROOT/scripts/worktree.sh" test rm --force ) >/dev/null 2>&1 && rc=0 || rc=1
  { [ "$rc" -eq 0 ] && [ ! -d "$TARGET" ]; } && pass "rm --force removes dir + branch" || fail "rm --force failed"
  rm -rf "$(dirname "$WT")"
fi

# Summary
sec "Summary"
printf 'PASS=%d  FAIL=%d\n' "$PASS" "$FAIL"
log ""; log "**PASS=$PASS  FAIL=$FAIL**"
[ -n "$REPORT" ] && echo "report: $REPORT"
[ "$FAIL" -eq 0 ] || { echo "selftest: FAILED"; exit 1; }
echo "selftest: OK"
