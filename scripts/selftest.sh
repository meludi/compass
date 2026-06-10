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
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json compass.schema.json templates/mcp.json; do
  if ruby -rjson -e "JSON.parse(File.read(ARGV[0]))" "$f" 2>/dev/null; then pass "$f"; else fail "$f — invalid JSON"; fi
done

# 2. Template YAML parses
sec "Template YAML"
for f in templates/compass.yml templates/pr-validation.yml; do
  if ruby -ryaml -e "YAML.load_file(ARGV[0])" "$f" 2>/dev/null; then pass "$f"; else fail "$f — invalid YAML"; fi
done

# 3. Every compass.yml key is declared in the schema (additionalProperties:false)
sec "compass.yml keys declared in schema"
missing=$(ruby -ryaml -rjson -e '
  y = YAML.load_file("templates/compass.yml").keys
  s = JSON.parse(File.read("compass.schema.json"))["properties"].keys
  puts (y - s).join(",")' 2>/dev/null)
if [ -z "$missing" ]; then pass "all keys declared"; else fail "keys missing from schema: $missing"; fi

# 4. read-config.sh parser sanity (a few representative keys)
sec "read-config.sh parser"
chk_cfg() {
  local k="$1" exp="$2" got
  got=$(bash scripts/read-config.sh "$k" templates/compass.yml)
  if [ "$got" = "$exp" ]; then pass "read $k=$got"; else fail "read $k => '$got' (expected '$exp')"; fi
}
chk_cfg autonomy_mode off
chk_cfg ci_review_provider claude
chk_cfg autofix_max_pushes 0
chk_cfg ci_review_guidelines .github/review-guidelines.md

# 5. CI workflow: lint if possible, and assert the expected jobs exist
sec "CI workflow"
if command -v actionlint >/dev/null 2>&1; then
  if actionlint templates/pr-validation.yml >/dev/null 2>&1; then pass "actionlint clean"; else fail "actionlint reported issues"; fi
fi
jobs=$(ruby -ryaml -e 'puts YAML.load_file("templates/pr-validation.yml")["jobs"].keys.join(",")' 2>/dev/null)
for j in config test ci-review ci-checklist autofix-guard auto-merge; do
  case ",$jobs," in *",$j,"*) pass "job $j";; *) fail "job $j missing";; esac
done

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
a=$(find agents -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
s=$(find skills -maxdepth 2 -name 'SKILL.md' | wc -l | tr -d ' ')
echo "  commands=$c agents=$a skills=$s"; log "- commands=$c agents=$a skills=$s"
[ -f hooks/hooks.json ] && pass "SessionStart hook present" || fail "hooks/hooks.json missing"
{ [ "$c" -ge 1 ] && [ "$a" -ge 1 ]; } && pass "components present ($c cmds, $a agents, $s skills)" || fail "inventory looks empty"

# 12. Functional worktree.sh test (--full) — throwaway temp repo, removed after
if [ "$FULL" -eq 1 ]; then
  sec "worktree.sh functional (temp repo)"
  WT="$(mktemp -d)/wt"; mkdir -p "$WT"
  ( # build a minimal repo (install_cmd:true avoids a real install)
    cd "$WT" && git init -q repo && cd repo \
      && git config user.email t@t.dev && git config user.name tester && git branch -M main \
      && mkdir -p .claude \
      && printf 'base_branch: main\npackage_manager: npm\ninstall_cmd: "true"\ndev_port: 3000\ndev_cmd: echo dev\n' > .claude/compass.yml \
      && echo SECRET > .env.local && echo "# repo" > README.md \
      && git add -A && git commit -qm init
  )
  TARGET="$WT/repo-test"
  ( cd "$WT/repo" && bash "$ROOT/scripts/worktree.sh" test ) >/dev/null 2>&1 || true
  [ -d "$TARGET" ] && pass "worktree created" || fail "worktree not created"
  ( cd "$WT/repo" && git show-ref --verify --quiet refs/heads/feat/test ) && pass "branch feat/test exists" || fail "branch missing"
  [ "$(cat "$TARGET/.worktree-port" 2>/dev/null)" = "3001" ] && pass ".worktree-port = dev_port+1 (3001)" || fail ".worktree-port wrong"
  [ -L "$TARGET/.env.local" ] && pass ".env.local symlinked" || fail ".env.local not symlinked"
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
