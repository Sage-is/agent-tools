#!/usr/bin/env bash
# check-skills.sh: the review gate for the sage-agent-tools bundle.
#
# 1. Every skills/*/SKILL.md has frontmatter whose `name` equals its folder
#    and a non-empty `description`.
# 2. No absolute personal paths (/Users/ or a tilde Documents folder) in
#    skills, rules, bin. The pattern is spelt so it never matches this file.
# 3. No denylisted word (one extended regex per line in $DENYLIST) in skills,
#    rules, bin or README.md. A missing denylist is a warning, not a failure.
# 4. No bare "Claude" self-reference. Tool and path names stay allowed:
#    `claude plugin`, `claude -p`, `claude mcp`, `CLAUDE.md`, `Claude Code`.
#
# Exit 1 on any hit, with the offending lines printed. Exit 0 when clean.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

DENYLIST="${DENYLIST:-$HOME/.config/sage-agent-tools/denylist.txt}"
SELF="scripts/check-skills.sh"
fail=0

# Shipped directories that exist right now (an empty repo must not error).
present() {
  local d
  for d in "$@"; do [ -e "$d" ] && printf '%s\n' "$d"; done
  return 0
}

say_fail() { printf 'FAIL: %s\n' "$1"; fail=1; }

# 1. Frontmatter -------------------------------------------------------------
shopt -s nullglob
for f in skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  if [ "$(head -n 1 "$f")" != "---" ]; then
    say_fail "$f: no frontmatter (first line is not ---)"
    continue
  fi
  fm=$(awk 'NR==1 {next} /^---$/ {exit} {print}' "$f")
  name=$(printf '%s\n' "$fm" | sed -nE 's/^name:[[:space:]]*"?([^"]*[^" ])"?[[:space:]]*$/\1/p' | head -n 1)
  if [ -z "$name" ]; then
    say_fail "$f: frontmatter has no name"
  elif [ "$name" != "$dir" ]; then
    say_fail "$f: frontmatter name '$name' differs from folder '$dir'"
  fi
  if ! printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*[^[:space:]]'; then
    say_fail "$f: frontmatter has no description"
  fi
done
shopt -u nullglob

# 2. Absolute paths ----------------------------------------------------------
dirs=$(present skills rules bin)
if [ -n "$dirs" ]; then
  # shellcheck disable=SC2086
  hits=$(grep -rnE '/Users/|~/Doc[u]ments' $dirs --exclude="$(basename "$SELF")" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    say_fail "absolute personal paths in the shipped tree (above)"
  fi
fi

# 3. Denylist ----------------------------------------------------------------
targets=$(present skills rules bin README.md)
if [ ! -f "$DENYLIST" ]; then
  printf 'warning: denylist %s is absent, denylist check skipped\n' "$DENYLIST"
elif [ -n "$targets" ]; then
  pat=$(mktemp)
  # Blank lines and comments would match every line; drop them.
  grep -v -e '^#' -e '^[[:space:]]*$' "$DENYLIST" > "$pat" || true
  if [ -s "$pat" ]; then
    # shellcheck disable=SC2086
    hits=$(grep -rnIE -f "$pat" $targets 2>/dev/null || true)
    if [ -n "$hits" ]; then
      printf '%s\n' "$hits"
      say_fail "denylisted words in the shipped tree (above; list: $DENYLIST)"
    fi
  else
    printf 'warning: denylist %s has no patterns\n' "$DENYLIST"
  fi
  rm -f "$pat"
fi

# 4. Self-reference ----------------------------------------------------------
# Strip the allowed tool and path names from each matching line first, then
# look again: a line that pairs "Claude Code" with a bare "Claude" still fails.
word='(^|[^A-Za-z0-9_])Claude($|[^A-Za-z0-9_])'
targets=$(present skills rules bin README.md NOTICE.md TODO.md)
if [ -n "$targets" ]; then
  # shellcheck disable=SC2086
  hits=$(grep -rnE "$word" $targets 2>/dev/null \
    | sed -E 's/claude (plugin|-p|mcp)|CLAUDE\.md|Claude Code//g' \
    | grep -E "$word" || true)
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    say_fail "bare self-reference in the shipped tree (above); the assistant is Sage.is AI"
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "check-skills: clean"
fi
exit "$fail"
