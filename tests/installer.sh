#!/usr/bin/env bash
# tests/installer.sh: temp-HOME tests for bin/sage-agent-tools. Plain bash, no bats.
#
# Builds a throwaway HOME, a PREFIX with two fake bundles, a fake "claude" and
# a fake "opencode" on PATH, then runs the installer through its commands and
# asserts on the filesystem. Exit 0 when every assertion passes.
#
# Run: bash tests/installer.sh        (also fine under /bin/bash 3.2)

set -eu
set -o pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../bin/sage-agent-tools"
BASH_BIN="${BASH:-bash}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sage-agent-tools-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }

# assert DESC CMD...: passes when CMD exits 0
assert() {
  local d="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else fail "$d"; fi
}
# assert_not DESC CMD...: passes when CMD exits non-zero
assert_not() {
  local d="$1"
  shift
  if "$@" >/dev/null 2>&1; then fail "$d"; else ok "$d"; fi
}
# assert_eq DESC EXPECTED ACTUAL
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected [$2], got [$3])"; fi
}
# assert_exit DESC CODE CMD...: runs CMD, keeps its output in $TMP/last.out
assert_exit() {
  local d="$1" want="$2" rc=0
  shift 2
  "$@" >"$TMP/last.out" 2>&1 || rc=$?
  if [ "$rc" = "$want" ]; then
    ok "$d"
  else
    fail "$d (exit $rc, want $want): $(tail -n 3 "$TMP/last.out" | tr '\n' ' ')"
  fi
}
sat() { "$BASH_BIN" "$BIN" "$@"; }

# snapshot: every path under HOME plus every symlink's target
snapshot() {
  {
    find "$HOME" -print
    find "$HOME" -type l -exec sh -c 'printf "%s -> %s\n" "$1" "$(readlink "$1")"' _ {} \;
  } | LC_ALL=C sort
}

# line_of TEXT FILE: first line number holding TEXT, or empty
line_of() {
  local n
  n="$(grep -n -F -- "$1" "$2" || true)"
  printf '%s' "${n%%:*}"
}

# in_order N1 N2 ...: every argument is a number and they ascend
in_order() {
  local prev="" n
  for n in "$@"; do
    [ -n "$n" ] || return 1
    if [ -n "$prev" ] && [ "$prev" -ge "$n" ]; then return 1; fi
    prev="$n"
  done
  return 0
}

# newest_file GLOB...: the last matching path, or empty
newest_file() {
  local found="" f
  for f in "$@"; do
    [ -e "$f" ] && found="$f"
  done
  printf '%s' "$found"
}

# ---------------------------------------------------------------- fixture

export HOME="$TMP/home"
export CLAUDE_HOME="$HOME/.claude"
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
export SAGE_AGENT_TOOLS_PREFIX="$TMP/prefix"
export SAGE_SOUNDS_SETTLE=1
export SAGE_SOUNDS_TIMEOUT=20
unset FAKE_PLUGIN FAKE_SILENT HOMEBREW_PREFIX || true
PUB="$SAGE_AGENT_TOOLS_PREFIX/share/sage-agent-tools"
PRIV="$SAGE_AGENT_TOOLS_PREFIX/share/sage-agent-tools-private"
export PATH="$TMP/bin:$PATH"

mkdir -p "$TMP/bin" "$TMP/empty" "$HOME" \
  "$PUB/skills/alpha" "$PUB/skills/beta" "$PUB/rules" \
  "$PRIV/skills/beta" "$PRIV/skills/gamma" "$PRIV/rules" "$PRIV/sounds" \
  "$CLAUDE_HOME/skills/alpha" "$OPENCODE_CONFIG_DIR"

for s in "$PUB/skills/alpha" "$PUB/skills/beta" "$PRIV/skills/beta" "$PRIV/skills/gamma"; do
  n="$(basename "$s")"
  printf -- '---\nname: %s\ndescription: fake %s skill\n---\n# %s\n' "$n" "$n" "$n" > "$s/SKILL.md"
done
printf '# rule x (public 20)\n' > "$PUB/rules/20-x.md"
printf '# rule y (private 10)\n' > "$PRIV/rules/10-y.md"

printf '#!/bin/bash\n# fake play-sound.sh\nafplay "$HOME/.claude/sounds/$1" &\n' > "$PRIV/sounds/play-sound.sh"
chmod +x "$PRIV/sounds/play-sound.sh"
printf 'export const SoundsPlugin = async () => ({});\n' > "$PRIV/sounds/sounds.js"
for m in bubbles veil moon; do printf 'ID3 fake mp3' > "$PRIV/sounds/patatap-$m.mp3"; done
cat > "$PRIV/sounds/claude-hooks.json" <<'EOF'
{"hooks": {
  "SessionStart": [{"hooks": [{"type": "command", "command": "~/.claude/play-sound.sh patatap-bubbles.mp3"}]}],
  "SessionEnd": [{"hooks": [{"type": "command", "command": "~/.claude/play-sound.sh patatap-moon.mp3"}]}],
  "Stop": [{"hooks": [{"type": "command", "command": "~/.claude/play-sound.sh patatap-veil.mp3"}]}]
}}
EOF

# a real, pre-existing skill directory that install must move aside
printf 'local alpha\n' > "$CLAUDE_HOME/skills/alpha/SKILL.md"

cat > "$OPENCODE_CONFIG_DIR/opencode.json" <<'EOF'
{"$schema": "https://opencode.ai/config.json", "plugin": ["x@beta"], "skills": {"paths": ["/existing/path"]}}
EOF

# fake claude: "plugin list" shows sage@ only with FAKE_PLUGIN=1; "-p" plays
# bubbles then moon (nothing with FAKE_SILENT=1, only bubbles with FAKE_PARTIAL=1)
cat > "$TMP/bin/claude" <<'EOF'
#!/bin/sh
case "$1" in
  plugin)
    echo "Installed plugins:"
    [ "${FAKE_PLUGIN:-0}" = 1 ] && echo "  > sage@sage-agent-tools"
    exit 0 ;;
  -p)
    if [ "${FAKE_SILENT:-0}" != 1 ]; then
      "$HOME/.claude/play-sound.sh" patatap-bubbles.mp3
      [ "${FAKE_PARTIAL:-0}" = 1 ] || "$HOME/.claude/play-sound.sh" patatap-moon.mp3
    fi
    echo ok ;;
esac
EOF
# fake opencode: "run" plays bubbles then veil, with the same two switches
cat > "$TMP/bin/opencode" <<'EOF'
#!/bin/sh
case "$1" in
  run)
    if [ "${FAKE_SILENT:-0}" != 1 ]; then
      "$HOME/.claude/play-sound.sh" patatap-bubbles.mp3
      [ "${FAKE_PARTIAL:-0}" = 1 ] || "$HOME/.claude/play-sound.sh" patatap-veil.mp3
    fi
    echo ok ;;
esac
EOF
# fake brew: the prefix is the test's; no private tap, so doctor never reaches
# the real machine's tap or its keychain credential
cat > "$TMP/bin/brew" <<'EOF'
#!/bin/sh
case "$1" in
  --prefix) echo "${SAGE_AGENT_TOOLS_PREFIX:-/nonexistent}" ;;
  --repo)   exit 1 ;;
  *)        exit 1 ;;
esac
EOF
chmod +x "$TMP/bin/claude" "$TMP/bin/opencode" "$TMP/bin/brew"

# ---------------------------------------------------------------- basics

printf '== basics\n'
assert_eq "version prints v0.1.0" "sage-agent-tools v0.1.0" "$(sat version)"
assert_eq "version works with HOME unset" "sage-agent-tools v0.1.0" "$(env -u HOME "$BASH_BIN" "$BIN" version 2>&1)"
assert_exit "no command exits 2" 2 sat
assert_exit "unknown command exits 2" 2 sat frobnicate
assert_exit "unknown option exits 2" 2 sat install --bogus
assert_exit "no bundle exits 3" 3 env SAGE_AGENT_TOOLS_PREFIX="$TMP/empty" "$BASH_BIN" "$BIN" install
assert_exit "missing jq exits 5" 5 env PATH="$TMP/empty" "$BASH_BIN" "$BIN" install
assert_exit "plugin route active exits 4" 4 env FAKE_PLUGIN=1 "$BASH_BIN" "$BIN" install

# ---------------------------------------------------------------- install

printf '== install with a broken opencode.json\n'
oc="$OPENCODE_CONFIG_DIR/opencode.json"
cp "$oc" "$TMP/opencode.valid"
printf '{"skills": {"paths": [],},}\n' > "$oc"
before="$(snapshot)"
assert_exit "install stops with exit 1" 1 sat install
assert "the broken file is named" grep -q 'not a plain JSON object' "$TMP/last.out"
assert_eq "nothing linked before the stop" "$before" "$(snapshot)"
cp "$TMP/opencode.valid" "$oc"

printf '== install --dry-run\n'
before="$(snapshot)"
assert_exit "install --dry-run exits 0" 0 sat install --dry-run
assert "dry-run prints the ln commands" grep -q 'ln -s' "$TMP/last.out"
assert_eq "dry-run writes nothing" "$before" "$(snapshot)"

printf '== install\n'
assert_exit "install exits 0" 0 sat install
assert_eq "claude alpha -> public" "$PUB/skills/alpha" "$(readlink "$CLAUDE_HOME/skills/alpha")"
assert_eq "claude beta -> public (clash: public wins)" "$PUB/skills/beta" "$(readlink "$CLAUDE_HOME/skills/beta")"
assert_eq "claude gamma -> private" "$PRIV/skills/gamma" "$(readlink "$CLAUDE_HOME/skills/gamma")"
assert_eq "agents alpha -> public" "$PUB/skills/alpha" "$(readlink "$HOME/.agents/skills/alpha")"
assert_eq "agents beta -> public" "$PUB/skills/beta" "$(readlink "$HOME/.agents/skills/beta")"
assert_eq "agents gamma -> private" "$PRIV/skills/gamma" "$(readlink "$HOME/.agents/skills/gamma")"
assert "clash reported as a skip" grep -q 'skip   beta' "$TMP/last.out"
backup_alpha="$(newest_file "$CLAUDE_HOME"/backups/*/skills/alpha)"
assert "real alpha moved to the backup" test -n "$backup_alpha"
assert_eq "backup alpha keeps its content" "local alpha" "$(cat "$backup_alpha/SKILL.md" 2>/dev/null || true)"
assert_not "no alpha/alpha under the link" test -e "$CLAUDE_HOME/skills/alpha/alpha"
assert_not "no alpha/alpha inside the bundle" test -e "$PUB/skills/alpha/alpha"
assert_not "no links.txt without foreign links" test -e "$(newest_file "$CLAUDE_HOME"/backups/*/links.txt)"

printf '== install again\n'
before="$(snapshot)"
assert_exit "second install exits 0" 0 sat install
assert_eq "second install changes nothing" "$before" "$(snapshot)"
paths="$(jq -r '.skills.paths[]' "$OPENCODE_CONFIG_DIR/opencode.json" | grep "^$SAGE_AGENT_TOOLS_PREFIX" | LC_ALL=C sort | tr '\n' ' ')"
want="$(printf '%s\n' "$PUB/skills" "$PRIV/skills" | LC_ALL=C sort | tr '\n' ' ')"
assert_eq "skills.paths has exactly the two bundle paths" "$want" "$paths"
assert "pre-existing skills.paths entry kept" jq -e 'any(.skills.paths[]; . == "/existing/path")' "$OPENCODE_CONFIG_DIR/opencode.json"
assert "other opencode.json keys kept" jq -e '.plugin == ["x@beta"]' "$OPENCODE_CONFIG_DIR/opencode.json"
assert_eq "opencode.json backed up once" 1 "$(ls "$CLAUDE_HOME"/backups/*/opencode/opencode.json 2>/dev/null | wc -l | tr -d ' ')"

printf '== status / doctor\n'
assert_exit "status exits 0" 0 sat status
assert "status shows alpha linked" grep -q 'alpha.*linked' "$TMP/last.out"
assert "status reports the clash" grep -q 'beta.*skipped' "$TMP/last.out"
assert_exit "doctor exits 0 on a healthy install" 0 sat doctor
ln -s "$TMP/nowhere" "$CLAUDE_HOME/skills/dangling"
assert_exit "doctor exits 1 with a dangling link" 1 sat doctor
assert "doctor names the dangling link" grep -q 'dangling link' "$TMP/last.out"
rm -f "$CLAUDE_HOME/skills/dangling"

printf '== foreign link\n'
rm -f "$CLAUDE_HOME/skills/gamma"
mkdir -p "$TMP/other"
ln -s "$TMP/other" "$CLAUDE_HOME/skills/gamma"
# the Codex layout: ~/.agents/skills/<x> -> ~/.claude/skills/<x>
rm -f "$HOME/.agents/skills/beta"
ln -s "$CLAUDE_HOME/skills/beta" "$HOME/.agents/skills/beta"
assert_exit "install over a foreign link exits 0" 0 sat install
assert_eq "foreign link replaced" "$PRIV/skills/gamma" "$(readlink "$CLAUDE_HOME/skills/gamma")"
assert_eq "agents beta foreign link replaced" "$PUB/skills/beta" "$(readlink "$HOME/.agents/skills/beta")"
links_txt="$(newest_file "$CLAUDE_HOME"/backups/*/links.txt)"
assert "foreign link recorded in links.txt" grep -q "skills/gamma -> $TMP/other" "${links_txt:-/dev/null}"
assert "agents beta link recorded in links.txt" grep -q "agents/skills/beta -> $CLAUDE_HOME/skills/beta" "${links_txt:-/dev/null}"

# ---------------------------------------------------------------- uninstall

printf '== uninstall\n'
before="$(snapshot)"
assert_exit "uninstall --dry-run exits 0" 0 sat uninstall --dry-run
assert_eq "uninstall --dry-run writes nothing" "$before" "$(snapshot)"
# a broken opencode.json stops uninstall before any link is touched
printf '{"skills": {"paths": [],},}\n' > "$oc"
assert_exit "uninstall with a broken opencode.json exits 1" 1 sat uninstall
assert_eq "broken opencode.json: nothing unlinked" "$before" "$(snapshot)"
# no opencode.json at all: uninstall must not create one
rm -f "$oc"
assert_exit "uninstall without opencode.json exits 0" 0 sat uninstall
assert_not "uninstall creates no opencode.json" test -e "$oc"
cp "$TMP/opencode.valid" "$oc"
assert_exit "reinstall after that exits 0" 0 sat install
assert_exit "uninstall exits 0" 0 sat uninstall
assert "alpha is a real dir again" test -d "$CLAUDE_HOME/skills/alpha"
assert_not "alpha is not a link" test -L "$CLAUDE_HOME/skills/alpha"
assert_eq "alpha content restored" "local alpha" "$(cat "$CLAUDE_HOME/skills/alpha/SKILL.md" 2>/dev/null || true)"
assert_not "claude beta link removed" test -L "$CLAUDE_HOME/skills/beta"
assert_eq "claude gamma foreign link put back" "$TMP/other" "$(readlink "$CLAUDE_HOME/skills/gamma")"
assert_not "agents alpha link removed" test -L "$HOME/.agents/skills/alpha"
assert_eq "agents beta foreign link put back" "$CLAUDE_HOME/skills/beta" "$(readlink "$HOME/.agents/skills/beta")"
assert_not "agents gamma link removed" test -L "$HOME/.agents/skills/gamma"
assert_eq "skills.paths has no bundle paths" "" "$(jq -r '.skills.paths[]' "$OPENCODE_CONFIG_DIR/opencode.json" | grep "^$SAGE_AGENT_TOOLS_PREFIX" || true)"
assert "pre-existing path survives uninstall" jq -e 'any(.skills.paths[]; . == "/existing/path")' "$OPENCODE_CONFIG_DIR/opencode.json"

# ---------------------------------------------------------------- rules

printf '== rules install\n'
md="$CLAUDE_HOME/CLAUDE.md"
printf '# Personal notes\nkeep me\n' > "$md"
printf 'opencode only line\n' > "$OPENCODE_CONFIG_DIR/AGENTS.md"
before="$(snapshot)"
assert_exit "rules install --dry-run exits 0" 0 sat rules install --dry-run
assert_eq "rules dry-run writes nothing" "$before" "$(snapshot)"
assert_exit "rules install exits 0" 0 sat rules install
assert "block order: begin, 10-y, 20-x, end, then the personal text" in_order \
  "$(line_of '<!-- sage-agent-tools rules: begin v0.1.0 -->' "$md")" \
  "$(line_of 'rule y (private 10)' "$md")" \
  "$(line_of 'rule x (public 20)' "$md")" \
  "$(line_of '<!-- sage-agent-tools rules: end -->' "$md")" \
  "$(line_of 'keep me' "$md")"
assert "CLAUDE.md without markers backed up" test -n "$(newest_file "$CLAUDE_HOME"/backups/*/CLAUDE.md)"
assert "AGENTS.md text merged below the block" grep -q 'opencode only line' "$md"
assert "AGENTS.md backed up" test -n "$(newest_file "$CLAUDE_HOME"/backups/*/opencode/AGENTS.md)"
assert_eq "AGENTS.md is a symlink to CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md" "$(readlink "$OPENCODE_CONFIG_DIR/AGENTS.md")"
first="$(cat "$md")"
assert_exit "second rules install exits 0" 0 sat rules install
assert_eq "second run leaves identical content" "$first" "$(cat "$md")"
assert_eq "one begin marker" 1 "$(grep -c 'rules: begin' "$md")"
assert_eq "one end marker" 1 "$(grep -c 'rules: end' "$md")"
assert_eq "personal text once" 1 "$(grep -c 'keep me' "$md")"
assert_eq "merged AGENTS text once" 1 "$(grep -c 'opencode only line' "$md")"
printf '# rule y v2\n' > "$PRIV/rules/10-y.md"
assert_exit "rules install after a fragment change exits 0" 0 sat rules install
assert "changed fragment in the block" grep -q 'rule y v2' "$md"
assert_not "old fragment text gone" grep -q 'rule y (private 10)' "$md"
assert_eq "personal text still once" 1 "$(grep -c 'keep me' "$md")"
mkdir -p "$TMP/norules/share/sage-agent-tools/skills/x"
assert_exit "no fragments exits 6" 6 env SAGE_AGENT_TOOLS_PREFIX="$TMP/norules" "$BASH_BIN" "$BIN" rules install

printf '== rules install with a fragment that quotes the end marker\n'
printf '# rule q\nThe block ends at `<!-- sage-agent-tools rules: end -->` on its own line.\n' > "$PUB/rules/30-q.md"
assert_exit "rules install with the quoting fragment exits 0" 0 sat rules install
lines="$(wc -l < "$md" | tr -d ' ')"
assert_exit "second run exits 0" 0 sat rules install
assert_exit "third run exits 0" 0 sat rules install
assert_eq "line count stable across runs" "$lines" "$(wc -l < "$md" | tr -d ' ')"
assert_eq "one end marker line" 1 "$(grep -c -x -F -- '<!-- sage-agent-tools rules: end -->' "$md")"
assert_eq "personal text still once after the quoting fragment" 1 "$(grep -c 'keep me' "$md")"
rm -f "$PUB/rules/30-q.md"

printf '== rules install over a reverse link (CLAUDE.md -> AGENTS.md)\n'
agents_md="$OPENCODE_CONFIG_DIR/AGENTS.md"
rm -f "$md" "$agents_md"
printf '# Personal notes\nkeep me\n' > "$agents_md"
ln -s "$agents_md" "$md"
assert_exit "rules install over a reverse link exits 0" 0 sat rules install
assert "AGENTS.md stays a regular file (no loop)" test ! -L "$agents_md"
assert_eq "CLAUDE.md still points at AGENTS.md" "$agents_md" "$(readlink "$md")"
assert "CLAUDE.md is readable through the link" grep -q 'rules: begin' "$md"
assert "personal text kept" grep -q 'keep me' "$md"
assert_eq "one personal line in the shared file" 1 "$(grep -c 'keep me' "$agents_md")"
first="$(cat "$agents_md")"
assert_exit "second run over the reverse link exits 0" 0 sat rules install
assert_eq "second run leaves the shared file identical" "$first" "$(cat "$agents_md")"
rm -f "$md" "$agents_md"
printf '# Personal notes\nkeep me\n' > "$md"
assert_exit "rules install restores the forward layout" 0 sat rules install
assert_eq "AGENTS.md -> CLAUDE.md again" "$md" "$(readlink "$agents_md")"

# ---------------------------------------------------------------- sounds

printf '== sounds install\n'
# a SessionStart group that already holds the bubbles command next to another one
cat > "$CLAUDE_HOME/settings.json" <<'EOF'
{"model": "opus", "hooks": {"SessionStart": [{"hooks": [
  {"type": "command", "command": "~/.claude/play-sound.sh patatap-bubbles.mp3"},
  {"type": "command", "command": "echo andon"}]}]}}
EOF
cp "$CLAUDE_HOME/settings.json" "$TMP/settings.before"
bubbles_count() { jq '[.hooks.SessionStart[].hooks[].command | select(. == "~/.claude/play-sound.sh patatap-bubbles.mp3")] | length' "$CLAUDE_HOME/settings.json"; }
mkdir -p "$OPENCODE_CONFIG_DIR/plugins"
printf 'legacy\n' > "$OPENCODE_CONFIG_DIR/plugins/sounds.js"
before="$(snapshot)"
assert_exit "sounds install --dry-run exits 0" 0 sat sounds install --dry-run
assert_eq "sounds dry-run writes nothing" "$before" "$(snapshot)"
assert_exit "sounds install exits 0" 0 sat sounds install
assert_eq "mp3 linked into sounds/" "$PRIV/sounds/patatap-bubbles.mp3" "$(readlink "$CLAUDE_HOME/sounds/patatap-bubbles.mp3")"
assert_eq "three mp3 links" 3 "$(ls "$CLAUDE_HOME/sounds" | wc -l | tr -d ' ')"
assert "play-sound.sh installed and executable" test -x "$CLAUDE_HOME/play-sound.sh"
assert "play-sound.sh matches the bundle" cmp -s "$PRIV/sounds/play-sound.sh" "$CLAUDE_HOME/play-sound.sh"
assert "sounds.js installed under plugin/" cmp -s "$PRIV/sounds/sounds.js" "$OPENCODE_CONFIG_DIR/plugin/sounds.js"
assert_not "legacy plugins/sounds.js moved away" test -e "$OPENCODE_CONFIG_DIR/plugins/sounds.js"
assert "legacy plugins/sounds.js kept in the backup" test -n "$(newest_file "$CLAUDE_HOME"/backups/*/opencode/plugins/sounds.js)"
assert "settings.json untouched without --claude-hooks" cmp -s "$TMP/settings.before" "$CLAUDE_HOME/settings.json"
assert "hook snippet printed instead" grep -q 'SessionStart' "$TMP/last.out"
assert_exit "sounds install --claude-hooks exits 0" 0 sat sounds install --claude-hooks
assert_eq "SessionStart keeps one group" 1 "$(jq '.hooks.SessionStart | length' "$CLAUDE_HOME/settings.json")"
assert_eq "bubbles command present once, not twice" 1 "$(bubbles_count)"
assert "the other command in that group kept" jq -e 'any(.hooks.SessionStart[].hooks[].command; . == "echo andon")' "$CLAUDE_HOME/settings.json"
assert_eq "SessionEnd hook merged" 1 "$(jq '.hooks.SessionEnd | length' "$CLAUDE_HOME/settings.json")"
assert_eq "Stop hook merged" 1 "$(jq '.hooks.Stop | length' "$CLAUDE_HOME/settings.json")"
assert_eq "model key kept" opus "$(jq -r .model "$CLAUDE_HOME/settings.json")"
assert "settings.json backed up" test -n "$(newest_file "$CLAUDE_HOME"/backups/*/settings.json)"
assert_exit "second --claude-hooks exits 0" 0 sat sounds install --claude-hooks
assert "second --claude-hooks reports nothing to add" grep -q 'already has the hook entries' "$TMP/last.out"
assert_eq "hook groups not duplicated" 1 "$(jq '.hooks.SessionStart | length' "$CLAUDE_HOME/settings.json")"
assert_eq "bubbles command still once" 1 "$(bubbles_count)"
assert_eq "Stop still one group" 1 "$(jq '.hooks.Stop | length' "$CLAUDE_HOME/settings.json")"

printf '== sounds test\n'
assert_exit "sounds test --dry-run exits 0" 0 sat sounds test --dry-run
assert "sounds test --dry-run prints the commands" grep -q "opencode run" "$TMP/last.out"
assert_exit "sounds test exits 0 with the fake tools" 0 sat sounds test
# play-sound.sh backgrounds afplay, so the two names can land in either order
grep '^opencode: ok, played ' "$TMP/last.out" > "$TMP/oc.line" || true
grep '^claude: ok, played ' "$TMP/last.out" > "$TMP/cl.line" || true
assert "opencode ok line names bubbles" grep -q patatap-bubbles.mp3 "$TMP/oc.line"
assert "opencode ok line names veil" grep -q patatap-veil.mp3 "$TMP/oc.line"
assert "claude ok line names bubbles" grep -q patatap-bubbles.mp3 "$TMP/cl.line"
assert "claude ok line names moon" grep -q patatap-moon.mp3 "$TMP/cl.line"
assert_not "claude ok line does not name veil" grep -q patatap-veil.mp3 "$TMP/cl.line"
assert_exit "sounds test exits 1 when a tool plays nothing" 1 env FAKE_SILENT=1 "$BASH_BIN" "$BIN" sounds test
assert "silent tool: both expected names reported missing" grep -q 'missing patatap-bubbles.mp3 patatap-veil.mp3' "$TMP/last.out"
assert_exit "sounds test exits 1 when the second sound is missing" 1 env FAKE_PARTIAL=1 "$BASH_BIN" "$BIN" sounds test
assert "partial opencode: veil reported missing" grep -q '^opencode: FAIL, played patatap-bubbles.mp3; missing patatap-veil.mp3' "$TMP/last.out"
assert "partial claude: moon reported missing" grep -q '^claude: FAIL, played patatap-bubbles.mp3; missing patatap-moon.mp3' "$TMP/last.out"

printf '== uninstall after sounds\n'
assert_exit "uninstall exits 0" 0 sat uninstall
assert_not "mp3 link removed" test -L "$CLAUDE_HOME/sounds/patatap-bubbles.mp3"
assert "play-sound.sh stays" test -x "$CLAUDE_HOME/play-sound.sh"

# ---------------------------------------------------------------- agents-md

g() { git -c user.name=t -c user.email=t@example.com -c init.defaultBranch=main -c commit.gpgsign=false "$@"; }
nlinks() { stat -c %h "$1" 2>/dev/null || stat -f %l "$1"; }
# tree_sum DIR: every file outside .git with its checksum, and every symlink
tree_sum() {
  { find "$1" -path '*/.git' -prune -o -type f -exec cksum {} + ; find "$1" -type l -print; } | LC_ALL=C sort
}
# normalised: a TMPDIR ending in "/" leaves "//" in $TMP, and the report prints pwd's form
P="$(cd "$TMP" && pwd)/projects"
SHIM='@AGENTS.md'
STOCK='This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.'

mkdir -p "$P/own/sub" "$P/own/docs/tpl" "$P/own/vendor/lib" "$P/own/node_modules/x" "$P/own/inner" "$P/own/.claude" \
  "$P/done" "$P/half" "$P/both" "$P/twin" "$P/agentsonly" "$P/hard" "$P/extra" "$P/linked" "$TMP/lone/broken"
printf '# CLAUDE.md\n\n%s\n\n- rule one\n' "$STOCK" > "$P/own/CLAUDE.md"
printf '# sub rules\n' > "$P/own/sub/CLAUDE.md"
printf 'template, not rules\n' > "$P/own/docs/tpl/AGENTS.md"
printf 'vendored\n' > "$P/own/vendor/lib/AGENTS.md"
printf 'dependency\n' > "$P/own/node_modules/x/CLAUDE.md"
printf 'claude-only folder\n' > "$P/own/.claude/CLAUDE.md"
mkdir -p "$P/own/forensics/skill" "$P/forensics/kit"
printf '# evidence\n' > "$P/own/forensics/skill/CLAUDE.md"
printf '# evidence\n' > "$P/forensics/kit/CLAUDE.md"
g -C "$P/own" init -q && g -C "$P/own" add CLAUDE.md && g -C "$P/own" commit -qm init
g -C "$P/own/inner" init -q && printf '# inner repo\n' > "$P/own/inner/CLAUDE.md"
printf '%s\n' "$SHIM" > "$P/done/CLAUDE.md"; printf '# done\n' > "$P/done/AGENTS.md"
g -C "$P/half" init -q && printf '%s\n' "$SHIM" > "$P/half/CLAUDE.md" && g -C "$P/half" add CLAUDE.md && g -C "$P/half" commit -qm init
printf '# half\n' > "$P/half/AGENTS.md"
printf '# both claude\n' > "$P/both/CLAUDE.md"; printf '# both agents\n' > "$P/both/AGENTS.md"
printf '# twin\n' > "$P/twin/CLAUDE.md"; printf '# twin\n' > "$P/twin/AGENTS.md"
printf '# agents only\n' > "$P/agentsonly/AGENTS.md"
printf '# shared\n' > "$TMP/shared.md"; ln "$TMP/shared.md" "$P/hard/CLAUDE.md"
printf '%s\n\n## Claude-only\n- extra\n' "$SHIM" > "$P/extra/CLAUDE.md"; printf '# extra\n' > "$P/extra/AGENTS.md"
printf '# linked\n' > "$P/linked/AGENTS.md"; ln -s AGENTS.md "$P/linked/CLAUDE.md"
printf '%s\n' "$SHIM" > "$TMP/lone/broken/CLAUDE.md"
# fork: upstream ships CLAUDE.md; fork2: upstream does not, the fork added one
mkdir -p "$TMP/up1" "$TMP/up2"
g -C "$TMP/up1" init -q && printf '# upstream rules\n' > "$TMP/up1/CLAUDE.md" && g -C "$TMP/up1" add . && g -C "$TMP/up1" commit -qm up
g -C "$TMP/up2" init -q && printf 'readme\n' > "$TMP/up2/README" && g -C "$TMP/up2" add . && g -C "$TMP/up2" commit -qm up
g clone -q -o upstream "$TMP/up1" "$P/fork"
g clone -q -o upstream "$TMP/up2" "$P/fork2" && printf '# fork rules\n' > "$P/fork2/CLAUDE.md"

printf '== agents-md --dry-run\n'
before="$(tree_sum "$P")"
assert_exit "agents-md --all --dry-run exits 0" 0 sat agents-md --all --dry-run "$P"
assert_eq "dry run changes nothing" "$before" "$(tree_sum "$P")"
assert "dry run prints the AGENTS.md write" grep -q "write $P/own/AGENTS.md" "$TMP/last.out"

printf '== agents-md --all\n'
assert_exit "agents-md --all exits 0" 0 sat agents-md --all "$P"
cp "$TMP/last.out" "$TMP/am.out"
assert_eq "own: first line renamed" "# AGENTS.md" "$(head -n 1 "$P/own/AGENTS.md")"
assert "own: stock header made agent-neutral" grep -qx 'This file provides guidance to AI coding agents when working with code in this repository.' "$P/own/AGENTS.md"
assert "own: rules carried over" grep -qx -- '- rule one' "$P/own/AGENTS.md"
assert_eq "own: CLAUDE.md is the shim" "$SHIM" "$(cat "$P/own/CLAUDE.md")"
assert "own: nothing staged" g -C "$P/own" diff --cached --quiet
assert_eq "own/sub: left alone without --nested" "# sub rules" "$(cat "$P/own/sub/CLAUDE.md")"
assert_not "own/sub: no AGENTS.md without --nested" test -e "$P/own/sub/AGENTS.md"
assert "own/sub: reported" grep -q 'info    sub/CLAUDE.md is below the project root; left alone' "$TMP/am.out"
assert "summary points at --nested" grep -q '^1 CLAUDE.md file(s) below a project root left alone' "$TMP/am.out"
assert_not "nested AGENTS.md alone gets no shim" test -e "$P/own/docs/tpl/CLAUDE.md"
assert "nested AGENTS.md alone reported" grep -q 'docs/tpl/AGENTS.md has no CLAUDE.md beside it' "$TMP/am.out"
assert_not "vendor/ skipped" test -e "$P/own/vendor/lib/CLAUDE.md"
assert_not "node_modules/ skipped" test -e "$P/own/node_modules/x/AGENTS.md"
assert_not "nested repo skipped" test -e "$P/own/inner/AGENTS.md"
assert_not ".claude/CLAUDE.md not converted" test -e "$P/own/.claude/AGENTS.md"
assert_eq "forensics/ inside a project untouched" "# evidence" "$(cat "$P/own/forensics/skill/CLAUDE.md")"
assert_not "forensics/ inside a project: no AGENTS.md" test -e "$P/own/forensics/skill/AGENTS.md"
assert_not "forensics/ under --all ROOT not walked" test -e "$P/forensics/kit/AGENTS.md"
assert_not "forensics/ never named in the report" grep -q forensics "$TMP/am.out"
assert "done: reported ok" grep -q 'ok      CLAUDE.md imports AGENTS.md$' "$TMP/am.out"
assert "half: untracked AGENTS.md reported" grep -q 'git does not track AGENTS.md' "$TMP/am.out"
assert "half: listed to commit" grep -qx "  $P/half" "$TMP/am.out"
assert_eq "both: CLAUDE.md untouched" "# both claude" "$(cat "$P/both/CLAUDE.md")"
assert "both: listed for a hand merge" grep -qx "  $P/both/CLAUDE.md" "$TMP/am.out"
assert_eq "twin: copy becomes the shim" "$SHIM" "$(cat "$P/twin/CLAUDE.md")"
assert_eq "agentsonly: shim created" "$SHIM" "$(cat "$P/agentsonly/CLAUDE.md")"
assert_eq "hard: CLAUDE.md untouched" "# shared" "$(cat "$P/hard/CLAUDE.md")"
assert_eq "hard: link count held" 2 "$(nlinks "$TMP/shared.md")"
assert_not "hard: no AGENTS.md" test -e "$P/hard/AGENTS.md"
assert "linked: symlink kept" test -L "$P/linked/CLAUDE.md"
assert_eq "fork: upstream-shipped CLAUDE.md untouched" "# upstream rules" "$(cat "$P/fork/CLAUDE.md")"
assert "fork: reported as upstream's" grep -q 'upstream ships it' "$TMP/am.out"
assert_eq "fork2: own CLAUDE.md converted" "# fork rules" "$(cat "$P/fork2/AGENTS.md")"

printf '== agents-md --nested\n'
assert_exit "--nested exits 0" 0 sat agents-md --all --nested "$P"
assert_eq "own/sub: converted" "# sub rules" "$(cat "$P/own/sub/AGENTS.md")"
assert_eq "own/sub: CLAUDE.md is the shim" "$SHIM" "$(cat "$P/own/sub/CLAUDE.md")"
assert_not "--nested still skips forensics/" test -e "$P/own/forensics/skill/AGENTS.md"
assert_not "--nested still skips the nested repo" test -e "$P/own/inner/AGENTS.md"

printf '== agents-md again\n'
assert_exit "second run exits 0" 0 sat agents-md --all "$P"
assert "second run changes nothing" grep -q '^summary: 0 changed' "$TMP/last.out"
assert "a nested import is still checked" grep -q 'ok      sub/CLAUDE.md imports AGENTS.md' "$TMP/last.out"
assert_exit "--nested with another command exits 2" 2 sat status --nested
assert_exit "a shim without AGENTS.md exits 1" 1 sat agents-md "$TMP/lone/broken"
assert "broken shim reported" grep -q 'FAIL    CLAUDE.md imports a missing AGENTS.md' "$TMP/last.out"
assert_exit "a subdirectory resolves to its repo" 0 sat agents-md "$P/own/sub"
assert "header names the repo root" grep -q '^project .*/own$' "$TMP/last.out"
assert_exit "--all with another command exits 2" 2 sat status --all

printf '== agents-md --prune\n'
before="$(tree_sum "$P")"
assert_exit "prune --dry-run exits 0" 0 sat agents-md --all --prune --dry-run "$P"
assert_eq "prune dry run changes nothing" "$before" "$(tree_sum "$P")"
assert_exit "prune exits 0" 0 sat agents-md --all --prune "$P"
assert_not "own: shim removed" test -e "$P/own/CLAUDE.md"
assert "own: AGENTS.md stays" test -f "$P/own/AGENTS.md"
assert_eq "own/sub: nested shim kept without --nested" "$SHIM" "$(cat "$P/own/sub/CLAUDE.md")"
assert_exit "prune --nested exits 0" 0 sat agents-md --all --prune --nested "$P"
assert_not "own/sub: nested shim removed with --nested" test -e "$P/own/sub/CLAUDE.md"
assert_not "twin: shim removed" test -e "$P/twin/CLAUDE.md"
assert_not "fork2: shim removed" test -e "$P/fork2/CLAUDE.md"
assert "extra: Claude-only lines kept" grep -q -- '- extra' "$P/extra/CLAUDE.md"
assert "linked: symlink kept" test -L "$P/linked/CLAUDE.md"
assert_eq "fork: upstream CLAUDE.md kept" "# upstream rules" "$(cat "$P/fork/CLAUDE.md")"
assert_eq "both: kept for the hand merge" "# both claude" "$(cat "$P/both/CLAUDE.md")"
assert_eq "prune: forensics/ untouched" "# evidence" "$(cat "$P/forensics/kit/CLAUDE.md")"
assert_exit "a path inside forensics/ is an explicit ask" 0 sat agents-md "$P/forensics/kit"
assert_eq "explicit forensics run converts" "# evidence" "$(cat "$P/forensics/kit/AGENTS.md")"

# ---------------------------------------------------------------- summary

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" != 0 ]; then exit 1; fi
exit 0
