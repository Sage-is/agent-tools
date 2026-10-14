# 1. help (default target — must come first)
help:
	@echo "================================================"
	@echo "       $(OWNER)/$(PROJECT_NAME) by Startr.Cloud"
	@echo "================================================"
	@echo "This is the default make command."
	@echo "This command lists available make commands."
	@echo ""
	@echo "Usage example:"
	@echo "    make check"
	@echo ""
	@echo "Available make commands:"
	@echo ""
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | \
		awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ { \
		if ($$1 !~ "^[#.]") {print $$1}}' | \
		sort | \
		grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'
	@echo ""

# 2. Dynamic variables (git-derived)
PROJECTPATH := $(shell git rev-parse --show-toplevel)
PROJECT     := $(shell echo $$(basename $(PROJECTPATH)) | tr '[:upper:]' '[:lower:]')
# Use symbolic-ref (clean failure on empty repos) → short SHA (detached HEAD) → develop fallback.
FULL_BRANCH := $(shell git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "develop")
BRANCH      := $(shell echo $(FULL_BRANCH) | sed 's/.*\///' | tr '[:upper:]' '[:lower:]')
TAG         := $(shell git describe --always --tag 2>/dev/null || echo "v0.0.0")

# Owner and project name extracted from git remote URL
REMOTE_URL   := $(shell git config --get remote.origin.url 2>/dev/null || echo "unknown/unknown")
OWNER        := $(shell echo $(REMOTE_URL) | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$$|\1|')
PROJECT_NAME := $(shell echo $(REMOTE_URL) | sed -E 's|.*[:/][^/]+/([^/]+)(.git)?$$|\1|' | sed 's/\.git$$//')

# Container name (unused here; kept for convention parity)
CONTAINER := $(PROJECT)-$(BRANCH)

# 3. Load environment overrides from .env if present
-include .env

# 4. Project-specific custom targets
INSTALLER   := bin/sage-agent-tools
PLUGIN_JSON := .claude-plugin/plugin.json
MARKETPLACE := .claude-plugin/marketplace.json
# The shipped version lives in two places that bump_release_version keeps equal:
# VERSION="…" in $(INSTALLER) (the formula's test greps it) and "version" in $(PLUGIN_JSON).
VERSION     := $(shell sed -nE 's/.*"version":[[:space:]]*"([^"]+)".*/\1/p' $(PLUGIN_JSON) 2>/dev/null || echo 0.1.0)
# The denylist is private words that must never reach this public repo. It lives
# OUTSIDE the repo; one extended regex per line. Absent file = warning, not failure.
DENYLIST    ?= $(HOME)/.config/sage-agent-tools/denylist.txt
# Everything the bundle ships, for the tick table and the denylist grep.
SHIPPED     := skills rules bin

# check: frontmatter, absolute paths, denylist and self-reference over the shipped
# tree, then the plugin manifests (when claude is on PATH), then the installer tests.
check:
	@DENYLIST="$(DENYLIST)" bash scripts/check-skills.sh
	@if command -v claude >/dev/null 2>&1; then \
		claude plugin validate --strict . && \
		claude plugin validate --strict $(PLUGIN_JSON) && \
		claude plugin validate --strict $(MARKETPLACE); \
	else \
		echo "warning: claude is not on PATH, plugin manifests not validated"; \
	fi
	@bash tests/installer.sh

# review: check, then a tick table of every shipped file for the manual review
# gate (one row per file, walk them all), then the denylist hits if any remain.
review: check
	@echo ""
	@echo "=== Tick table: every shipped file (bytes) ==="
	@for d in $(SHIPPED); do test -d "$$d" && find "$$d" -type f; done | sort | \
		while read -r f; do \
			printf -- '- [ ] %s (%s bytes)\n' "$$f" "$$(wc -c < "$$f" | tr -d ' ')"; \
		done
	@echo ""
	@echo "=== Denylist hits ($(DENYLIST)) ==="
	@if [ -f "$(DENYLIST)" ]; then \
		pat=$$(mktemp) && grep -v -e '^#' -e '^[[:space:]]*$$' "$(DENYLIST)" > "$$pat"; \
		hits=$$(for d in $(SHIPPED) README.md; do test -e "$$d" && echo "$$d"; done | \
			xargs grep -rnIE -f "$$pat" 2>/dev/null); \
		rm -f "$$pat"; \
		if [ -n "$$hits" ]; then echo "$$hits"; else echo "none"; fi; \
	else \
		echo "warning: $(DENYLIST) is absent, denylist not checked"; \
	fi

show_version:
	@echo $(VERSION)

# Sets VERSION="…" in $(INSTALLER) and "version" in $(PLUGIN_JSON) from the
# release/* or hotfix/* branch name and commits them, so the tag git flow
# creates always equals v$(VERSION).
# git-flow-next keeps the tag prefix per branch type: in .git/config after
# `git flow init`, or only in the committed .gitflow on a fresh clone.
bump_release_version:
	@case "$(FULL_BRANCH)" in \
		release/*) key=gitflow.branch.release.tagprefix ;; \
		hotfix/*) key=gitflow.branch.hotfix.tagprefix ;; \
		*) echo "Error: bump_release_version needs a release/* or hotfix/* branch (on $(FULL_BRANCH))"; exit 1 ;; \
	esac; \
	prefix=$$(git config --get "$$key" 2>/dev/null || git config --file .gitflow --get "$$key" 2>/dev/null); \
	test "$$prefix" = "v" || { \
		echo "Error: $$key must be 'v' (git flow init --shared -f -d -m master -e develop -t v)"; \
		exit 1; }
	@v=$$(echo "$(FULL_BRANCH)" | sed 's|^[^/]*/||'); \
	sed -i.bak -E "s/^VERSION=\"[^\"]*\"/VERSION=\"$$v\"/" $(INSTALLER) && rm -f $(INSTALLER).bak && \
	sed -i.bak -E "s/(\"version\":[[:space:]]*\")[^\"]*\"/\1$$v\"/" $(PLUGIN_JSON) && rm -f $(PLUGIN_JSON).bak && \
	grep -q "^VERSION=\"$$v\"" $(INSTALLER) && grep -q "\"version\": *\"$$v\"" $(PLUGIN_JSON) && \
	git add $(INSTALLER) $(PLUGIN_JSON) && \
	if git diff --cached --quiet; then echo "version already $$v, nothing to commit"; \
	else git commit -m "chore: bump version to $$v"; fi

# Interactive release: git-release from the sage-is/apps tap
release:
	@command -v git-release >/dev/null || { echo "Needs git-release: brew tap sage-is/apps && brew trust --tap sage-is/apps && brew install git-release"; exit 1; }
	@git-release

# 8. show_vars + verify (debug / one-shot self-check)
show_vars:
	@echo "=== Dynamic Variables ==="
	@echo "PROJECTPATH=$(PROJECTPATH)"
	@echo "PROJECT=$(PROJECT)"
	@echo "OWNER=$(OWNER)"
	@echo "PROJECT_NAME=$(PROJECT_NAME)"
	@echo "FULL_BRANCH=$(FULL_BRANCH)"
	@echo "BRANCH=$(BRANCH)"
	@echo "TAG=$(TAG)"
	@echo "CONTAINER=$(CONTAINER)"
	@echo "REMOTE_URL=$(REMOTE_URL)"
	@echo "VERSION=$(VERSION)"
	@echo "DENYLIST=$(DENYLIST)"
	@echo ""

# One-shot scaffold self-check. Bundles every read-only verification into a
# single make invocation so post-scaffold testing isn't N separate processes.
verify: show_vars require_gitflow_next
	@echo "=== Targets defined in this Makefile ==="
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | \
		awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ { \
		if ($$1 !~ "^[#.]") {print "  " $$1}}' | \
		sort -u | \
		grep -E -v -e '^  [^[:alnum:]]'
	@echo ""
	@echo "OK: Makefile scaffold verified."

# 9. Git-flow-next release/hotfix flow
require_gitflow_next:
	@if ! git flow version 2>/dev/null | grep -q 'git-flow-next'; then \
		echo "Error: git-flow-next required (Go rewrite). Install: brew install git-flow-next"; \
		exit 1; \
	fi

# Before the first tag, the three bump targets start release/$(VERSION)
# (0.1.0 the first time) instead of handing `git flow release start` an empty name.
minor_release: require_gitflow_next
	# Start a minor release with incremented minor version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2+1".0"}' | grep . || echo $(VERSION)) && echo "or use 'make release_finish' to finish the release"

patch_release: require_gitflow_next
	# Start a patch release with incremented patch version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}' | grep . || echo $(VERSION)) && echo "or use 'make release_finish' to finish the release"

major_release: require_gitflow_next
	# Start a major release with incremented major version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1+1".0.0"}' | grep . || echo $(VERSION)) && echo "or use 'make release_finish' to finish the release"

# git-release's "custom" choice: make custom_release VER=1.2.3
custom_release: require_gitflow_next
	@test -n "$(VER)" || { echo "Error: make custom_release VER=X.Y.Z"; exit 1; }
	git flow release start $(VER) && echo "or use 'make release_finish' to finish the release"

hotfix: require_gitflow_next
	# Start a hotfix with incremented n.n.n.n version (incrementing the fourth number)
	git flow hotfix start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3"."$$4+1}') && echo "or use 'make hotfix_finish' to finish the hotfix"

# release_finish and hotfix_finish depend on bump_release_version, so the
# installer and plugin.json always match the tag.
release_finish: require_gitflow_next bump_release_version
	git flow release finish && git push origin develop && git push origin master && git push --tags && git checkout develop

hotfix_finish: require_gitflow_next bump_release_version
	git flow hotfix finish && git push origin develop && git push origin master && git push --tags && git checkout master

# 10. things_clean
things_clean:
	git clean --exclude='!.env*' -Xdf

# 11. .PHONY declarations
.PHONY: help show_vars verify require_gitflow_next \
	minor_release patch_release major_release custom_release hotfix \
	release_finish hotfix_finish things_clean \
	check review show_version bump_release_version release
