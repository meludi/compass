#!/usr/bin/env bash
# read-config.sh — the single source for reading flat `key: value` fields from
# .claude/compass.yml. Used by scripts/worktree.sh (sourced) and CI (executed),
# so the parsing rules live in exactly one place.
#
#   Sourced:   PROJECT_YML=path/to/compass.yml; source read-config.sh
#              val=$(read_config dev_port)
#   Executed:  val=$(bash read-config.sh dev_port [path/to/compass.yml])
#
# Flat keys only — by design. Pure grep/sed keeps this dependency-free (no yq),
# matching the flat YAML the starter ships. read_config strips a trailing
# " # comment", trims surrounding whitespace, and removes one surrounding quote
# pair (internal quotes are preserved so command/hook values survive intact).

read_config() {
  local key="$1" yml="${2:-${PROJECT_YML:-${CLAUDE_PROJECT_DIR:-$PWD}/.claude/compass.yml}}"
  grep -m1 "^${key}:" "$yml" 2>/dev/null \
    | cut -d: -f2- \
    | sed -E 's/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/' \
    || true
}

# When executed directly (not sourced), print the requested key's value.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  [ $# -ge 1 ] || { echo "usage: read-config.sh <key> [compass.yml]" >&2; exit 2; }
  read_config "$@"
fi
