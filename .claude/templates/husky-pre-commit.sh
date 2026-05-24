#!/usr/bin/env sh
# Optional pre-commit hook for review-only autonomy.
#
# This file is NOT installed automatically. To use it:
#
#   npm install --save-dev husky
#   npx husky init
#   cp .claude/templates/husky-pre-commit.sh .husky/pre-commit
#   chmod +x .husky/pre-commit
#
# Behaviour: runs tests locally, then asks Claude to review the staged diff.
# Findings are PRINTED — never auto-fixed, never auto-committed. You decide.

set -e

# 1. Run tests
echo ">> Running tests..."
if ! npm test --silent --passWithNoTests; then
  echo ">> Tests failed. Fix them, then re-stage and commit again."
  exit 1
fi

# 2. Ask Claude to review the staged diff (read-only — no Edit, no Bash writes)
if command -v claude >/dev/null 2>&1; then
  DIFF=$(git diff --cached)
  if [ -n "$DIFF" ]; then
    echo ""
    echo ">> Claude review (read-only — findings are printed, not applied):"
    echo ""
    printf '%s' "$DIFF" | claude --print "Review this staged diff for code quality, type safety, and test coverage. List concrete findings — do not propose patches or rewrites." || true
  fi
else
  echo ">> Skipping Claude review (claude CLI not installed)."
fi

echo ""
echo ">> Pre-commit checks complete."
