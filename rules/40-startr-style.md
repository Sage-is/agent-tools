## startr.style — First-Party, Mobile-First

`startr.style` is first-party: the public repo is https://github.com/Startr/Style.

- **Mobile-first.** In markup using its inline props (`--p`, `--d`, `--gtc`, `--size` …), write the base no-suffix values for the smallest viewport first, then add `-sm`/`-md`/`-lg`/`-xl` overrides only where the layout changes. Suffixes are `min-width` queries, so desktop-first breaks phones. Never repeat the base value in a suffixed prop. `/startr-style design` implements this as Rule #0.
- **Footguns.** When the framework bites a consumer repo (shorthand collisions like `--td`/`--bs`, hover-only states, silent typos, unversioned CDN, `color-mix` fallbacks), name both the consumer workaround and the upstream fix. Recommend upstream when the bug is structural or the workaround runs past a few lines.
- **Never edit `Startr/Style` silently.** Surface the trade-off (one fix reaches every consumer) and ask first.

