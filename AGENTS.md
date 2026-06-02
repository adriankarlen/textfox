# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

textfox is a Firefox userChrome CSS theme for TUI enthusiasts. No JavaScript framework, no bundler — just CSS files, SVG icons, shell scripts, and a Nix flake.

## Commands

**Nix formatting (CI enforced):**
```sh
nix run nixpkgs#nixfmt-tree        # format all Nix files
nix run nixpkgs#nixfmt-tree -- --check  # check only (what CI runs)
```

**Install/uninstall (manual testing):**
```sh
sh tf-install.sh    # interactive install to a Firefox profile
sh tf-uninstall.sh  # interactive uninstall
```

No test suite exists. Changes are validated by loading Firefox with the theme applied.

## Architecture

### CSS layer

`chrome/userChrome.css` is the entry point — it `@import`s every other CSS file and applies global font/body rules. Load order matters: `defaults.css` must come before `config.css` (user overrides).

All theming flows through CSS custom properties prefixed `--tf-*`, defined in `chrome/defaults.css`. Users customize by creating `chrome/config.css` which overrides those variables. Never hard-code colors; always reference `--tf-*` vars or Firefox's own theme vars (e.g. `var(--lwt-accent-color)`).

CSS file responsibilities:
- `defaults.css` — canonical `--tf-*` variable definitions and their defaults
- `overwrites.css` — Firefox internal style resets
- `navbar.css`, `urlbar.css`, `sidebar.css`, `tabs.css`, `findbar.css`, `menus.css`, `browser.css` — per-component styles
- `icons.css` — icon overrides (references SVGs in `chrome/icons/`)
- `content/newtab.css`, `content/about.css` → loaded into `userContent.css`

### Nix layer

The flake exposes two delivery mechanisms:

**home-manager module** (`nix/modules/home-manager.nix`):
- Copies `chrome/` directory into the Firefox profile via `home.file`
- Writes a generated `config.css` (from `textfox.configCss`) into `chrome/config.css`
- Injects `user.js` prefs via `programs.firefox.profiles.<name>.extraConfig`

**NixOS module** (`nix/modules/nixos.nix`):
- Uses `wrapTextfox` (`nix/pkgs/wrapTextfox.nix`) to wrap the Firefox binary
- `wrapTextfox` generates a single concatenated `userChrome.css` and `userContent.css` at build time (no `@import`, all CSS inlined), then installs them via an autoconfig script that runs on Firefox startup and copies files from the Nix store to the profile's `chrome/` dir
- Hash-file mechanism detects when the Nix store path changes and restarts Firefox to apply updates

All Nix option definitions live in `nix/modules/options.nix` and are shared by both modules. The `textfox.configCss` (read-only) attribute assembles the final CSS string from all structured options.

### Key design constraints

- No hard-coded colors anywhere in CSS — theme colors come from Firefox's LWT variables or user's `config.css`
- `config.css` is user-owned and excluded from wrapTextfox's `@import` chain (it's appended at the end)
- Icon logic (`shyfox.*` prefs) is inherited from ShyFox; the same `about:config` keys apply

### Keeping CSS and Nix in sync

Adding or renaming a `--tf-*` variable requires changes in three places:

1. `chrome/defaults.css` — add the variable with its default value
2. `nix/modules/options.nix` — add a corresponding `mkOption` under `options.textfox.config`
3. `nix/modules/options.nix` `configCss` string — wire the new option into the generated `:root { }` block

The `configCss` read-only option is what home-manager writes as `config.css` and what `wrapTextfox` appends last. If a variable exists in `defaults.css` but not in `configCss`, Nix users can't configure it and the default will always win over their `textfox.config.*` settings.
