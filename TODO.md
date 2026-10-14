# Roadmap

This file tracks active work only.

> **Convention** — Sections below map to kanban columns. Inline source-code
> tags use the same vocabulary so items stay cross-referenced between this
> file and the codebase. `KANBAN.canvas` auto-generates from this file and
> inline tags — do not hand-edit it.
>
> | Column      | Markdown section  | Inline tag  |
> |-------------|-------------------|-------------|
> | Backlog     | `## Backlog`      |             |
> | TODO        | `## TODO`         | `# TODO:`   |
> | In Progress | `## In Progress`  | `# FIXME:`  |
> | Bugs        | `## Bugs`         | `# BUG:`    |
> | Done        | `- [x]` items / `## Done` | —   |
>
> `# DEPRECATED:` tags should be tracked as TODO items for removal at the
> stated version.

## TODO

- [ ] **First release v0.1.0**: nothing is pushed before the review gate #critical
  - [ ] [MANUALLY] Review gate: `make review`, read every file in the tick table, decide the Dorie Clark wording in `presentation-interview` (`NOTICE.md` covers the current wording), add client names to `~/.config/sage-agent-tools/denylist.txt`, rerun `make review`
    - [ ] Expect `rules/40-startr-style.md` to differ from the source CLAUDE.md section on two lines, not one: line 3 (repo path -> `https://github.com/Startr/Style`) and line 7 (`Never edit ... silently` names `Startr/Style`); both rewrites are forced by the `WEB-[A-Za-z]` denylist entry
    - [ ] Decide once whether both formulas keep the explicit `version "0.1.0"` line (then `brew audit --strict` prints "version 0.1.0 is redundant with version scanned from URL" on every release, as `tool-release.sh` and `private-release.sh` expect) or drop it and relax those two scripts' `version` checks
  - [ ] [WE] Push `develop` and `master`, then `make release` to tag `v0.1.0`
  - [ ] [WE] Tap: `make check_names NAMES=sage-agent-tools`, add `Formula/sage-agent-tools.rb`, `make tool_release TOOL=sage-agent-tools VERSION=0.1.0` as a dry run, then with `APPLY=1`
  - [ ] [WE] `brew test sage-agent-tools` and `sage-agent-tools doctor` both exit 0

- [ ] **Split the long SKILL.md files into `references/`**: a line-for-line copy ships first so the review reads the files as they were
  - [ ] [WE] `for-humanity` (673 lines): pattern catalogue to `references/`
  - [ ] [WE] `startr-init` (438 lines): Makefile blocks to `references/`
  - [ ] [WE] `todo-scope` (405 lines): examples to `references/`
  - [ ] [WE] `panel-push` (304 lines): personality matrices to `references/`
  - [ ] [WE] `make check` still passes and each SKILL.md names its reference files

- [ ] **Move `sounds/` to the public bundle**: the seven patatap mp3s, `play-sound.sh`, `sounds.js` and `claude-hooks.json` ship in the private bundle until their licence is known
  - [ ] [MANUALLY] Confirm the patatap audio licence allows redistribution
  - [ ] [WE] Move `sounds/` here, add `sounds` to `pkgshare.install` in the formula, add the attribution to `NOTICE.md`
  - [ ] [WE] `sage-agent-tools sounds test` passes on a clean temp HOME after the move

- [ ] **Codex verification**: the third agent has not been exercised against the bundle
  - [ ] [MANUALLY] Install Codex on one Mac
  - [ ] [WE] `ls -la ~/.agents/skills` shows the bundle links and Codex's `/skills` listing shows each name once
  - [ ] [WE] `sage-agent-tools doctor` reports Codex presence and its link state
