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

- [x] **First release v0.1.0**: reviewed, tagged and on both taps (Alexander, 2026-10-14) #critical
  - [x] [MANUALLY] Review gate walked on the 51-row checklist; `presentation-interview` now takes `persona` (default) or `style`; no client names found in the public tree (denylist stays open for additions); patatap audio stays private until replaced
  - [x] [WE] `version` line dropped from the formula; `tool-release.sh` and `release-tools.sh` derive it from the `v<X.Y.Z>.tar.gz` url, so `brew audit --strict` is clean
  - [x] [WE] `develop` and `master` pushed, `v0.1.0` tagged; `sage-is/apps/sage-agent-tools` pinned to sha256 `a3167176…`, installed, tested, audited
  - [x] [WE] Private: `Sage.is/agent-tools-private` `v0.1.0` and `sage-is/private/sage-agent-tools-private` pinned (Gitea archive with `HOMEBREW_GITEA_TOKEN` header); `sage-agent-tools install`, `rules install`, `sounds install` and `doctor` green on the first Mac

- [ ] **Split the long SKILL.md files into `references/`**: a line-for-line copy ships first so the review reads the files as they were
  - [ ] [WE] `for-humanity` (673 lines): pattern catalogue to `references/`
  - [ ] [WE] `startr-init` (438 lines): Makefile blocks to `references/`
  - [ ] [WE] `todo-scope` (405 lines): examples to `references/`
  - [ ] [WE] `panel-push` (304 lines): personality matrices to `references/`
  - [ ] [WE] `make check` still passes and each SKILL.md names its reference files

- [ ] **Move `sounds/` to the public bundle**: the seven patatap mp3s, `play-sound.sh`, `sounds.js` and `claude-hooks.json` ship in the private bundle until their licence is known
  - [ ] [MANUALLY] Confirm the patatap audio licence allows redistribution, or replace the seven cues: asked Izzy (iplante@sage.is) for custom cues on 2026-10-14, 20-minute call proposed for the week of 2026-10-19
  - [ ] [WE] Move `sounds/` here, add `sounds` to `pkgshare.install` in the formula, add the attribution to `NOTICE.md`
  - [ ] [WE] `sage-agent-tools sounds test` passes on a clean temp HOME after the move

- [ ] **Codex verification**: the third agent has not been exercised against the bundle
  - [ ] [MANUALLY] Install Codex on one Mac
  - [ ] [WE] `ls -la ~/.agents/skills` shows the bundle links and Codex's `/skills` listing shows each name once
  - [ ] [WE] `sage-agent-tools doctor` reports Codex presence and its link state
