{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) toJSON;
  inherit (lib.types) enum str bool;

  cfg = config.textfox;
in {
  options.textfox = {
    enable = mkEnableOption "Textfox; a firefox with css edits.";
    package = mkPackageOption pkgs "firefox-unwrapped" {};

    windowControls = mkOption {
      type = bool;
      default = false;
      description = "Show window control buttons";
    };

    navButtons = mkOption {
      type = bool;
      default = false;
      description = "Show back and forward buttons";
    };

    urlbarIcons = mkOption {
      type = bool;
      default = false;
      description = "Show icons inside url bar";
    };

    sidebarTools = mkOption {
      type = bool;
      default = true;
      description = "Show sidebar tools section.";
    };

    titles = mkOption {
      type = bool;
      default = true;
      description = "Show titles on blocks.";
    };

    newtabLogo = mkOption {
      type = str;
      default = "   __            __  ____          \A" +
                "/ /____  _  __/ /_/ __/___  _  __\A" +
               "/ __/ _ \\| |/_/ __/ /_/ __ \\| |/_/\A" +
              "/ /_/  __/>  </ /_/ __/ /_/ />  <  \A" +
             "\\__/\\___/_/|_|\\__/_/  \\____/_/|_|  ";
      description = "ASCII logo used for new tab page";
    };

    font = {
      family = mkOption {
        type = str;
        default = "\"SF Mono\", Consolas, monospace";
        description = "Default font family";
      };
      size = mkOption {
        type = str;
        default = "14px";
        description = "The font size to use";
      };
      accent = mkOption {
        type = str;
        default = "var(--toolbarbutton-icon-fill)";
        description = "The accent color to use";
      };
    };

    icons = {
      toolbar.extensions = mkOption {
        type = bool;
        default = false;
        description = "Supported extensions get monochrome icons as toolbar buttons";
      };

      context = {
        extensions = mkOption {
          type = bool;
          default = false;
          description = "Supported extensions get monochrome icons as context menu items";
        };

        firefox = mkOption {
          type = bool;
          default = false;
          description = "Many context menu items get icons";
        };
      };
    };

    tab = {
      style = mkOption {
        type = enum ["vertical" "horizontal"];
        default = "vertical";
        description = "Show horizontal or vertical (sideberry) tabs.";
      };
      margin = mkOption {
        type = str;
        default = "0.8rem";
        description = "Margin used between elements in sideberry (vertical tabs).";
      };
    };

    background.color = mkOption {
      type = str;
      default = "var(--lw-accent-color, -moz-dialog)";
      description = "Background color of all elements.";
    };

    border = {
      color = mkOption {
        type = str;
        default = "var(--arrowpanel-border-color, --toolbar-field-background-color)";
        description = "Border color when not hovered";
      };
      transition = mkOption {
        type = str;
        default = "0.2s ease";
        description = "Color transitions for borders";
      };
      width = mkOption {
        type = str;
        default = "2px";
        description = "Width of borders";
      };
      radius = mkOption {
        type = str;
        default = "0px";
        description = "Border radius used throughout the config";
      };
    };

    extraUserChrome = mkOption {
      type = str;
      default = "";
      description = "Custom userChrome.css appended to the hooked textfox file.";
    };

    extraUserContent = mkOption {
      type = str;
      default = "";
      description = "Custome userContent.css appended to the hooked textfox file.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = let
      textfoxConfig = ''
        :root {
          --tf-font-family: ${cfg.font.family};
          --tf-font-size: ${cfg.font.size};
          --tf-accent: ${cfg.font.accent};
          --tf-bg: ${cfg.background.color};
          --tf-border: ${cfg.border.color};
          --tf-border-transition: ${cfg.border.transition};
          --tf-border-width: ${cfg.border.width};
          --tf-rounding: ${cfg.border.radius};
          --tf-margin: ${cfg.tab.margin};
          --tf-display-horizontal-tabs: ${if cfg.tab.style == "horizontal" then "block" else "none"};
          --tf-display-window-controls: ${if cfg.windowControls then "flex" else "none"};
          --tf-display-nav-buttons: ${if cfg.navButtons then "flex" else "none"};
          --tf-display-urlbar-icons: ${if cfg.urlbarIcons then "flex" else "none"};
          --tf-display-sidebar-tools: ${if cfg.sidebarTools then "flex" else "none"};
          --tf-display-titles: ${if cfg.titles then "flex" else "none"};
          --tf-newtab-logo: ${cfg.newtabLogo};
        }
      '';

      textfox-chrome = pkgs.runCommand "textfox-chrome" { 
        inherit (cfg) extraUserChrome extraUserContent;
        inherit textfoxConfig;
        passAsFile = ["textfoxConfig" "extraUserChrome" "extraUserContent"];
      } ''
        mkdir -p "$out"

        cp -r "${../chrome}/icons" "$out/icons"
        
        cat "${../chrome}/overwrites.css" >> "$out/userChrome.css"
        cat "${../chrome}/userChrome.css" >> "$out/userChrome.css"
        cat "${../chrome}/sidebar.css" >> "$out/userChrome.css"
        cat "${../chrome}/browser.css" >> "$out/userChrome.css"
        cat "${../chrome}/findbar.css" >> "$out/userChrome.css"
        cat "${../chrome}/navbar.css" >> "$out/userChrome.css"
        cat "${../chrome}/urlbar.css" >> "$out/userChrome.css"
        sed "s|./icons|$out/icons|g" "${../chrome}/icons.css" >> "$out/userChrome.css"
        cat "${../chrome}/menus.css" >> "$out/userChrome.css"
        cat "${../chrome}/tabs.css" >> "$out/userChrome.css"

        cat "${../chrome}/defaults.css" >> "$out/userChrome.css"

        cat "${../chrome}/content/sidebery.css" >> "$out/userContent.css"
        cat "${../chrome}/content/newtab.css" >> "$out/userContent.css"
        cat "${../chrome}/content/about.css" >> "$out/userContent.css"

        cat "${../chrome}/defaults.css" >> "$out/userContent.css"

        cat "$textfoxConfigPath" >> "$out/userChrome.css"
        cat "$textfoxConfigPath" >> "$out/userContent.css"

        cat "$extraUserChromePath" >> "$out/userChrome.css"
        cat "$extraUserContentPath" >> "$out/userContent.css"
      '';


    in [(pkgs.wrapFirefox cfg.package {
      extraPolicies = optionalAttrs (cfg.tab.style == "vertical") {
        ExtensionSettings = {
          # Declarative installation of sidebery
          "{3c078156-979c-498b-8990-85f7987dd929}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
        };
      };

      extraPrefs = ''
        // This is a Firefox autoconfig file:
        // https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig

        const {classes: Cc, interfaces: Ci, utils: Cu} = Components;
        Cu.import("resource://gre/modules/FileUtils.jsm");
        var updated = false;

        // Create nsiFile objects 
        var chromeDir = Services.dirsvc.get("ProfD", Ci.nsIFile);
        chromeDir.append("chrome");

        // XP_UNIX forces symlinks to be resolved when copying
        // so we are just going to normal copy from nix store
        // <https://bugzilla.mozilla.org/show_bug.cgi?id=480726>
        var textfoxChrome = new FileUtils.File("${textfox-chrome}");
        var userChrome = new FileUtils.File("${textfox-chrome}/userChrome.css");
        var userContent = new FileUtils.File("${textfox-chrome}/userContent.css");

        var hashFile = chromeDir.clone();
        hashFile.append(textfoxChrome.displayName);

        if (!chromeDir.exists()) {
            chromeDir.create(Ci.nsIFile.DIRECTORY_TYPE, FileUtils.PERMS_DIRECTORY);
            userChrome.copyTo(chromeDir, "userChrome.css");
            userContent.copyTo(chromeDir, "userContent.css");
            updated = true;

        } else if (!hashFile.exists()) {
            chromeDir.remove(1);
            userChrome.copyTo(chromeDir, "userChrome.css");
            userContent.copyTo(chromeDir, "userContent.css");
            updated = true;
        }

        // Restart Firefox immediately if one of the files got updated
        if (updated === true) {
            // Write into storage the iteration of the config via nix hash
            hashFile.create(Ci.nsIFile.NORMAL_FILE_TYPE, 0b100100100);

            var appStartup = Cc["@mozilla.org/toolkit/app-startup;1"].getService(Ci.nsIAppStartup);
            appStartup.quit(Ci.nsIAppStartup.eForceQuit | Ci.nsIAppStartup.eRestart);
        }

        // Needed prefs to use textfox
        pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        pref("svg.context-properties.content.enabled", true);
        pref("layout.css.has-selector.enabled", true);

        pref("shyfox.enable.ext.mono.toolbar.icons", ${toJSON cfg.icons.toolbar.extensions});
        pref("shyfox.enable.ext.mono.context.icons", ${toJSON cfg.icons.context.extensions});
        pref("shyfox.enable.context.menu.icons", ${toJSON cfg.icons.context.firefox});
      '';
    })];
  };
}

