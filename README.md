# sage-agent-tools

Skills and rules for coding agents, from the Sage.is team. One bundle serves
Claude Code, OpenCode and Codex. Each skill is a folder with a `SKILL.md`; each
rule is a Markdown fragment that lands in `~/.claude/CLAUDE.md`.

Skills: `for-humanity`, `for-simplicity`, `panel-push`, `poka-yoke`,
`presentation-interview`, `startr-init`, `todo-scope`.

## Install

Pick one route per machine. Both put the same skills in front of the agent;
running both lists every skill twice.

### Route A: Homebrew (Claude Code, OpenCode and Codex)

```sh
brew tap sage-is/apps
brew trust --tap sage-is/apps
brew install sage-agent-tools
sage-agent-tools install
sage-agent-tools rules install
```

### Route B: Claude Code plugin (Claude Code only)

```sh
claude plugin marketplace add Sage-is/agent-tools
claude plugin install sage@sage-agent-tools
```

`sage-agent-tools install` refuses to run while the plugin is installed
(exit 4), so a machine cannot drift into both routes.

## What the installer does

- Symlinks each skill from `$(brew --prefix)/share/sage-agent-tools/skills/`
  into `~/.claude/skills/` and `~/.agents/skills/`. The links point at the
  Homebrew path, so they survive `brew upgrade`.
- Adds that `skills/` path to `skills.paths` in `~/.config/opencode/opencode.json`.
- Moves a real directory of the same name to `~/.claude/backups/<stamp>/` first,
  and never links a bundle root.
- `rules install` writes the rule fragments between two marker lines in
  `~/.claude/CLAUDE.md`. Text outside the markers stays. A file without markers
  is backed up and kept below the block. `~/.config/opencode/AGENTS.md` becomes
  a symlink to that file.
- `status` and `doctor` report link state; every subcommand takes `--dry-run`.

To undo it: `sage-agent-tools uninstall` removes only links that point into the
bundle and restores the newest backup, then `brew uninstall sage-agent-tools`.
On the plugin route: `claude plugin uninstall sage@sage-agent-tools`.

## Private bundle

Sage.is team members add `sage-agent-tools-private` from the in-house tap; the
same installer picks it up next to the public bundle.

## Development

```sh
make check     # frontmatter, paths, denylist, self-reference, manifests, installer tests
make review    # make check plus a tick table of every shipped file
make release   # git-release (git-flow-next): tags vX.Y.Z from develop
```

`develop` is the working branch, `master` the released one. The denylist of
words that must never reach this repo lives outside it, at
`~/.config/sage-agent-tools/denylist.txt`, one extended regex per line.

Shipping a release:

1. [MANUALLY] Review gate: `make review`, then read every file in the tick table.
2. [WE] `make release`; the tag sets the version in `bin/sage-agent-tools` and
   `.claude-plugin/plugin.json`.
3. [WE] Point the tap's formula at the new tag and run `brew test sage-agent-tools`.

## Licence

MIT, see `LICENSE`. Exceptions and attributions are in `NOTICE.md`:
`for-humanity` is CC BY-SA 4.0.
