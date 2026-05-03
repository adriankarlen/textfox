
```
   __            __  ____          
  / /____  _  __/ /_/ __/___  _  __
 / __/ _ \| |/_/ __/ /_/ __ \| |/_/
/ /_/  __/>  </ /_/ __/ /_/ />  <  
\__/\___/_/|_|\__/_/  \____/_/|_|  
```

_a firefox theme for the tui enthusiast_

## Preview

![image](https://github.com/adriankarlen/textfox/blob/main/misc/vertical-tabs.png)

![image](https://github.com/adriankarlen/textfox/blob/main/misc/horizontal-tabs.png)

> [!NOTE]
> The color scheme used in the pictures is [Rosé Pine Moon](https://github.com/rose-pine/firefox).
> `textfox` tries to not hard code any colors, [Firefox Color extension](https://addons.mozilla.org/en-US/firefox/addon/firefox-color/) is the
> recommended approach to coloring Firefox with `textfox`.

## Installation

### Installation script

1. Download/clone the repo.
2. Inside the download run `sh tf-install.sh` and follow the script
   instructions.

> [!IMPORTANT]
> This script automates file writes, use with caution.

> [!NOTE]
> The installation script copies to contents of the repos `chrome` directory to
> the path specified, this way your `config.css` or any other `css`-files not
> part of the repo will be kept.

### Manual

1. Download the files
2. Go to `about:profiles`
3. Find the names of target profiles (ex: `Profile: Default`)
4. Open the profile's root directory
5. Move the files chrome directory and user.js there
6. Restart Firefox

> [!IMPORTANT]
> textfox now supports horizontal tabs, to enable them change the
> `--tf-display-horizontal-tabs` variable in your `config.css` to `block`. See
> [CSS configurations](#css-configurations) for more info.

> [!NOTE]
> If you don't want to use the provided user.js, please read through it and
> apply the settings in `about:config` manually. These are needed for the css to
> work.

### Nix

This repo includes a Nix flake that exposes a home-manager module that installs textfox.

To enable the module, add the repo as a flake input, import the module, and enable textfox.

<details><summary>Install using your home-manager module defined within your `nixosConfigurations`:</summary>

```nix

  # flake.nix

  {

      inputs = {
         # ---Snip---
         home-manager = {
           url = "github:nix-community/home-manager";
           inputs.nixpkgs.follows = "nixpkgs";
         };

         textfox.url = "github:adriankarlen/textfox";
         # ---Snip---
      }

      outputs = {nixpkgs, home-manager, ...} @ inputs: {
          nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [
            home-manager.nixosModules.home-manager
              {
               # Must pass in inputs so we can access the module
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                };
              }
           ];
        };
     }
  }
```
```nix

# home.nix

imports = [ inputs.textfox.homeManagerModules.default ];

textfox = {
    enable = true;
    # Replace with the names of profiles, defined in home-manager, or find existing ones in `about:profiles`
    profiles = ["profile_1" "profile_2"];
    config = {
        # Optional config
    };
};
```
</details>

<details><summary>Install using `home-manager.lib.homeManagerConfiguration`:</summary>

```nix

  # flake.nix

  {
    inputs = {
       # ---Snip---
       home-manager = {
         url = "github:nix-community/home-manager";
         inputs.nixpkgs.follows = "nixpkgs";
       };

       textfox.url = "github:adriankarlen/textfox";
       # ---Snip---
    }

    outputs = {nixpkgs, home-manager, textfox ...}: {
        homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            modules = [
                textfox.homeManagerModules.default
                # ...
            ];
        };
    };
  }
```
  ```nix

  # home.nix

  textfox = {
      enable = true;
      # Replace with the names of profiles, defined in home-manager, or find existing ones in `about:profiles`
      profiles = ["profile_1" "profile_2"];
      config = {
          # Optional config
      };
  };
  ```
</details>

<details><summary>Configuration options:</summary>

All configuration options are optional and can be set as this example shows (real default values [can be found below](#defaults)):

```nix

  textfox = {
      enable = true;
      # Replace with the names of profiles, defined in home-manager, or find existing ones in `about:profiles`
      profiles = ["profile_1" "profile_2"];
      config = {
        background = {
          color = "#123456";
        };
        border = {
          color = "#654321";
          width = "4px";
          transition = "1.0s ease";
          radius = "3px";
        };
        displayWindowControls = true;
        displayNavButtons = true;
        displayUrlbarIcons = true;
        displaySidebarTools = false;
        displayTitles = false;
        newtabLogo = "   __            __  ____          \A   / /____  _  __/ /_/ __/___  _  __\A  / __/ _ \\| |/_/ __/ /_/ __ \\| |/_/\A / /_/  __/>  </ /_/ __/ /_/ />  <  \A \\__/\\___/_/|_|\\__/_/  \\____/_/|_|  ";
        font = {
          family = "Fira Code";
          size = "15px";
          accent = "#654321";
        };
        tabs = {
          horizontal.enable = true;
          vertical.enable = true;
        };
        navbar = {
          margin = "8px 8px 2px";
          padding = "4px";
        };
        bookmarks = {
          alignment = "left";
        };
        icons = {
          toolbar.extensions.enable = true;
          context.extensions.enable = true;
          context.firefox.enable = true;
        };
        textTransform = "uppercase";
        extraConfig = "/* custom css here */";
      };
  };
```
</details>

## Uninstallation

### Uninstall script

1. Inside the cloned repo run `sh tf-uninstall.sh` and follow the script
   instructions.

> [!IMPORTANT]
> This script automates file removal, use with caution.

> [!NOTE]
> The uninstall script will offer to restore the most recent backup created by
> the install script (e.g. `chrome-YYYYMMDD_HHMMSS.bak`) if one is found in
> your Firefox profile directory.

### Manual

1. Go to `about:profiles`
2. Open the root directory of the profile textfox was installed to
3. Delete the `chrome` directory
4. Delete `user.js` (only if it was placed there by textfox)
5. Restart Firefox

> [!NOTE]
> If you had a previous `chrome` directory before installing textfox, the
> install script backed it up as `chrome-YYYYMMDD_HHMMSS.bak`. You can restore
> it by renaming it back to `chrome`.

## Customization

The icon configuration utilizes code that is originally from ShyFox, therefore
the same settings are used (these can be set in about:config).
| Setting | true | false (default) |
| -------------------------------------- | --------------------------------------------------------------------- | ------------------------- |
| `shyfox.enable.ext.mono.toolbar.icons` | Supported extensions get monochrome icons as toolbar buttons | Standard icons used |
| `shyfox.enable.ext.mono.context.icons` | Supported extensions get monochrome icons as context menu items | Standard icons used |
| `shyfox.enable.context.menu.icons` | Many context menu items get icons | No icons in context menus |

### CSS configurations
The theme ships with a `defaults.css`, this file can be overridden by creating a
`config.css` inside the chrome directory.

#### Defaults
```css
:root {
  --tf-font-family: "SF Mono", Consolas, monospace; /* Font family of config */
  --tf-font-size: 14px; /* Font size of config */
  --tf-accent: var(--toolbarbutton-icon-fill); /* Accent color used, eg: color when hovering a container  */
  --tf-bg: var(--lwt-accent-color, -moz-dialog); /* Background color of all elements, tab colors derive from this */
  --tf-border: var(--arrowpanel-border-color, --toolbar-field-background-color); /* Border color when not hovered */
  --tf-border-transition: 0.2s ease; /* Smooth color transitions for borders */
  --tf-border-width: 2px; /* Width of borders */
  --tf-rounding: 0px; /* Border radius used through out the config */
  --tf-text-transform: none; /* Text transform to use */
  --tf-display-horizontal-tabs: none; /* If horizontal tabs should be shown, none = hidden, block = shown */
  --tf-display-window-controls: none; /* If the window controls should be shown (won't work with sidebery and hidden horizontal tabs), none = hidden, flex = shown */ 
  --tf-display-nav-buttons: none; /* If the navigation buttons (back, forward) should be shown, none = hidden, flex = shown */
  --tf-display-urlbar-icons: none; /* If the icons inside the url bar should be shown, none = hidden, flex = shown */
  --tf-display-sidebar-tools: flex; /* If the "Customize sidebar" button on the sidebar should be shown, none = hidden, flex = shown */ 
  --tf-display-titles: flex; /* If titles (tabs, navbar, main etc.) should be shown, none = hidden, flex = shown */
  --tf-newtab-logo: "   __            __  ____          \A   / /____  _  __/ /_/ __/___  _  __\A  / __/ _ \\| |/_/ __/ /_/ __ \\| |/_/\A / /_/  __/>  </ /_/ __/ /_/ />  <  \A \\__/\\___/_/|_|\\__/_/  \\____/_/|_|  ";
  --tf-navbar-margin: 8px 8px 2px; /* navbar margin */
  --tf-navbar-padding: 4px; /* navbar padding */
  --tf-bookmarks-alignment: center; /* alignment of bookmarks in the bookmarks toolbar (if you have many bookmarks, left is recommended) */
}

```

### Changing the new tab logo

The new tab logo can be any string you want, to create a string with line breaks
add a `\A` at every line break, also make sure to break any backslashes, eg. if
you want a `\`, you need to write `\\`. I used [this tool](https://www.patorjk.com/software/taag/#p=display&f=Slant&t=textfox)
to create the current logo.

Wanna hide the logo? Simply pass an empty string as the logo.

### Recipes

Here are some example changes that you can do to achieve different looks.

#### Swap positions of tabs and window controls when using horizontal tabs
```css
/* path: chrome/config.css */
:root {
  --tf-display-horizontal-tabs: inline-flex;
  --tf-display-window-controls: flex;
}
```

#### Rounded borders
```css
/* path: chrome/config.css */
:root {
  --tf-rounding: 4px;
}
```

#### Align bookmarks to the left
```css
/* path: chrome/config.css */
:root {
  --tf-bookmarks-alignment: left;
}
```

#### Adjust title margins

The titles (e.g. "tabs", "navbar", "main") are `::before` pseudo-elements positioned on the border of each container. Override the margin per selector to reposition them.

```css
/* path: chrome/config.css */
/* These are just the default values, change them to fit your needs */

/* main title */
#tabbrowser-tabbox::before {
  margin: -1.75rem 0rem !important;
}

/* navbar title */
#nav-bar::before {
  margin: -16px 8px !important;
}

/* bookmarks title */
#PersonalToolbar::before {
  margin: -1.25rem 0.4rem !important;
}

/* tools title */
.buttons-wrapper::before {
  margin: -0.85rem 0.85rem !important;
}

/* tool title */
#sidebar-box::before {
  margin: -0.85rem 0.85rem !important;
}

/* vertical tabs title */
box#vertical-tabs::before {
  margin: -1.75rem .4rem !important;
}

/* horizontal tabs title */
#TabsToolbar::before {
  margin: -1rem .75rem !important;
}

/* findbar title */
findbar::before {
  margin: -1.75rem .75rem !important;
}
```

#### Do you have a banger recipe?
Feel free to open a PR and add it here!

## Community

Join [#textfox:matrix.org](https://matrix.to/#/#textfox:matrix.org) for support and discussion.

## Acknowledgements

[Naezr](https://github.com/Naezr) - Icon logic and some sidebery logic.
