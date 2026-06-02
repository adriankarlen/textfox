---
name: firefox-chrome
description: >-
  Ground truth for Firefox's internal chrome UI — the DOM structure (browser.xhtml)
  and built-in CSS that userChrome themes target. Use when writing or fixing
  textfox CSS and you need to know a real selector, element ID, attribute, or
  Firefox's own default styling — instead of guessing. Triggers: "what selector",
  "what element is X", "did this break", "firefox renamed/removed", "userChrome",
  "why doesn't this rule apply", "find the real DOM node", any time CSS targets
  Firefox internals. Always targets the LATEST Firefox release (the only version
  textfox supports).
---

# firefox-chrome

textfox is a Firefox `userChrome.css` theme. It styles Firefox's **internal browser
UI** (toolbars, urlbar, tabs, menus). That UI is real DOM defined in Firefox's
source, with its own default CSS. Selectors, element IDs, and attributes **change
between Firefox versions** — this is the #1 cause of theme breakage, and an agent
cannot know the current internals from memory.

This skill bridges that gap: query Firefox's actual source for the **latest
release** so every selector you write is verified, not guessed.

## The truth source

`firefox-release` tree on searchfox = the latest shipped Firefox. textfox only
supports the latest version, so this is the only tree that matters.

Two operations:

### 1. Search (find selectors / elements / where something is styled)

Use the helper — it's sandbox-safe (no pipes, handles encoding, parses JSON):

```sh
sh tools/firefox-chrome/sf-search.sh "QUERY" "PATH_GLOB"
```

- `QUERY` — a class, id, attribute, or any substring. Supports searchfox syntax.
- `PATH_GLOB` (optional) — e.g. `*.css`, `*.xhtml`. Narrow noisy queries with it.

Output: `path:line: matched line`, grouped by match kind. **Zero matches for a
selector textfox already uses = strong signal Firefox renamed/removed it** → search
the surrounding area for the new name.

Examples:
```sh
sh tools/firefox-chrome/sf-search.sh "urlbar-background" "*.css"   # who styles it
sh tools/firefox-chrome/sf-search.sh "nav-bar" "*.xhtml"           # find the DOM node
sh tools/firefox-chrome/sf-search.sh "tab-background-start"        # everywhere
```

### 2. Read a full file (see structure / default rules in context)

Use **WebFetch** (raw github fetch is blocked for curl in this sandbox, WebFetch
works) against the github mirror, `release` branch:

```
https://raw.githubusercontent.com/mozilla-firefox/firefox/release/<PATH>
```

`<PATH>` is the path from a search hit (e.g. `browser/themes/shared/urlbar-searchbar.css`).

Or read it rendered (with line numbers) on searchfox via WebFetch:
```
https://searchfox.org/firefox-release/source/<PATH>
```

## Where things live (map)

- `browser/base/content/browser.xhtml` + `*.inc.xhtml` (e.g. `navigator-toolbox.inc.xhtml`)
  — the main window **DOM**: element IDs, structure, attributes. Start here for
  "what do I select".
- `browser/themes/shared/` — most cross-platform skin CSS
  (`urlbar-searchbar.css`, `tabbrowser/`, `toolbarbuttons.css`, `findbar.css`,
  `browser-shared.css`, sidebar, menus). Firefox's **own defaults** you override.
- `browser/themes/{windows,osx,linux}/browser.css` — per-OS overrides.
- `toolkit/content/widgets/` — custom elements / shadow DOM (`moz-*`, panels,
  `<tab>`, `<toolbarbutton>`). Check here when a node has no obvious markup —
  it's likely a custom element with internal shadow structure.
- `browser/components/` — feature UI (sidebar, customize mode, etc.).

## Workflows

**Write a new rule for element X**
1. `sf-search.sh "X" "*.xhtml"` → confirm the real id/class/attribute + nesting.
2. `sf-search.sh "<that selector>" "*.css"` → see Firefox's default rules (specificity,
   what you must override, which vars it already uses).
3. Read the CSS file via WebFetch for full context if the rule is non-trivial.
4. Write the rule in the matching `chrome/*.css` file per repo conventions (below).

**Diagnose breakage after a Firefox update**
1. Take the textfox selector that stopped working.
2. `sf-search.sh "<selector>"` → if zero hits, it was renamed/removed.
3. Search nearby terms / read the relevant `*.xhtml` to find the replacement.
4. Update the selector; note the change in the commit message.

**"Why doesn't my rule apply?"**
- Check specificity/`!important` of Firefox's own rule (search step 2 above).
- Confirm the node isn't inside shadow DOM (`toolkit/content/widgets/`) where
  `userChrome.css` can't reach without the element exposing parts/vars.

## Live DOM inspection (optional, heavier — `firefox-live.sh`)

Static search above is enough for most work. Reach for live inspection when you
need **runtime truth** the source can't give:

- **computed styles** — which rule actually won the cascade (FF defaults +
  textfox + config combined)
- **runtime state attributes** — `[open]`, `[focused]`, `[busy]`, `brighttext`,
  etc. that only exist on the live element
- **shadow DOM as instantiated**
- **verify your own CSS landed** — the profile is seeded with the repo's `chrome/`

```sh
sh tools/firefox-chrome/firefox-live.sh nav-bar
sh tools/firefox-chrome/firefox-live.sh --selector "#urlbar .urlbar-background" \
   -- --computed background-color,border,box-shadow
sh tools/firefox-chrome/firefox-live.sh back-button -- --html --children
sh tools/firefox-chrome/firefox-live.sh --vanilla nav-bar   # bare FF, no textfox
```

It launches a throwaway Firefox (ephemeral profile seeded with `chrome/`,
`--marionette -remote-allow-system-access`), queries the live chrome DOM via
`ff_inspect.py`, prints JSON, then kills FF and deletes the profile.

Notes / gotchas:
- Needs a real display. Linux headless: prefix `xvfb-run -a`.
- First run provisions a venv at `~/.cache/textfox-firefox-live/venv`
  (installs `marionette_driver`).
- `-remote-allow-system-access` is **required** by modern Firefox for chrome
  context; without it `set_context("chrome")` throws `System access is required`.
- `ff_inspect.py` must NOT be renamed to `inspect.py` — it would shadow Python's
  stdlib `inspect` module and break the import.
- Security: Marionette is a local control surface. This uses an ephemeral,
  localhost-only profile and kills Firefox on exit. Don't point it at a real
  profile.
- An agent sandbox may block launching the Firefox binary (e.g. macOS `.app`
  bundle guard). If so, the user runs the script in their own terminal.

## Repo conventions (from CLAUDE.md — always apply)

- **No hard-coded colors.** Use `--tf-*` vars (defined in `chrome/defaults.css`)
  or Firefox's own LWT vars (e.g. `var(--lwt-accent-color)`).
- Put rules in the right per-component file (`navbar.css`, `urlbar.css`,
  `tabs.css`, …). `userChrome.css` only `@import`s; load order matters.
- New `--tf-*` var ⇒ update all three: `chrome/defaults.css`,
  `nix/modules/options.nix` (`mkOption`), and the `configCss` block.
