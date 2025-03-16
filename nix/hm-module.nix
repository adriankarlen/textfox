inputs: {config, lib, pkgs, ...}:
let 
  cfg = config.textfox;
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/Firefox/Profiles/"
    else ".mozilla/firefox/";
in {

  imports = [
    inputs.nur.hmModules.nur
  ];

  options.textfox = {
    enable = lib.mkEnableOption "Enable textfox";
    profile = lib.mkOption {
      type = lib.types.str;
      description = "The profile to apply the textfox configuration to";
    };
    copyOnActivation = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.hostPlatform.isDarwin;
      description = "Copy the chrome/ folder into the designated firefox profile on home-manager activation instead of symlinking it. This is for user content styling to fully work on macOS";
    };
    config = lib.mkOption {
      default = {};
      type = lib.types.submodule {
        options = {
          background = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                color = lib.mkOption {
                  type = lib.types.str;
                  default = "var(--lwt-accent-color, -moz-dialog)";
                  description = "Background color of all elements, tab colors derive from this";
                };
              };
            };
          };
          displayHorizontalTabs = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enables horizontal tabs at the top";
          };
          displayWindowControls = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enables window controls";
          };
          displayNavButtons = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Show back and forward navigation buttons in the Firefox UI";
          };
          displayUrlbarIcons = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Show icons inside url bar";
          };
          displaySidebarTools = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show sidebar tools section";
          };
          displayTitles = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show titles on blocks";
          };
          newtabLogo = lib.mkOption {
            type = lib.types.str;
            default = "   __            __  ____          \A   / /____  _  __/ /_/ __/___  _  __\A  / __/ _ \\| |/_/ __/ /_/ __ \\| |/_/\A / /_/  __/>  </ /_/ __/ /_/ />  <  \A \\__/\\___/_/|_|\\__/_/  \\____/_/|_|  ";
            description = "The ascii logo used for new tab page";
          };
          font = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                family = lib.mkOption {
                  type = lib.types.str;
                  default = "\"SF Mono\", Consolas, monospace";
                  description = "The font family to use";
                };
                size = lib.mkOption {
                  type = lib.types.str;
                  default = "14px";
                  description = "The font size to use";
                };
                accent = lib.mkOption {
                  type = lib.types.str;
                  default = "var(--toolbarbutton-icon-fill)";
                  description = "The accent color to use";
                };
              };
            };
          };
          border = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                color = lib.mkOption {
                  type = lib.types.str;
                  default = "var(--arrowpanel-border-color, --toolbar-field-background-color)";
                  description = "Border color when not hovered";
                };
                transition = lib.mkOption {
                  type = lib.types.str;
                  default = "0.2s ease";
                  description = "Color transitions for borders";
                };
                width = lib.mkOption {
                  type = lib.types.str;
                  default = "2px";
                  description = "Width of borders";
                };
                radius = lib.mkOption {
                  type = lib.types.str;
                  default = "0px";
                  description = "Border radius used throughout the config";
                };
              };
            };
          };
          sidebery = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                margin = lib.mkOption {
                  type = lib.types.str;
                  default = "0.8rem";
                  description = "Margin used between elements in sidebery";
                };
              };
            };
          };
        };
      };
    };
  };

  config = let
    configCss = pkgs.writeText "config.css" (lib.strings.concatStrings [
      ":root {"
      (lib.strings.concatStrings [ " --tf-font-family: " cfg.config.font.family ";" ])
      (lib.strings.concatStrings [ " --tf-font-size: " cfg.config.font.size ";" ])
      (lib.strings.concatStrings [ " --tf-font-accent: " cfg.config.font.accent ";" ])
      (lib.strings.concatStrings [ " --tf-background: " cfg.config.background.color ";" ])
      (lib.strings.concatStrings [ " --tf-border-color: " cfg.config.border.color ";" ])
      (lib.strings.concatStrings [ " --tf-border-transition: " cfg.config.border.transition ";" ])
      (lib.strings.concatStrings [ " --tf-border-width: " cfg.config.border.width ";" ])
      (lib.strings.concatStrings [ " --tf-border-radius: " cfg.config.border.radius ";" ])
      (lib.strings.concatStrings [ " --tf-sidebery-margin: " cfg.config.sidebery.margin ";" ])
      (lib.strings.concatStrings [ " --tf-display-horizontal-tabs: " (if cfg.config.displayHorizontalTabs then "block" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-display-window-controls: " (if cfg.config.displayWindowControls then "flex" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-display-nav-buttons: " (if cfg.config.displayNavButtons then "flex" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-display-urlbar-icons: " (if cfg.config.displayUrlbarIcons then "flex" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-display-customize-sidebar: " (if cfg.config.displaySidebarTools then "flex" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-display-titles: " (if cfg.config.displayTitles then "flex" else "none") ";" ])
      (lib.strings.concatStrings [ " --tf-newtab-logo: " cfg.config.newtabLogo ";" ])
      " }"
    ]);

    linkCfg = {
      home.file."${configDir}${cfg.profile}/chrome" = {
        source = "${package}/chrome";
        recursive = true;
      };

      home.file."${configDir}${cfg.profile}/chrome/config.css" = {
        source = configCss;
      };
    };

    copyOnActivationCfg = {
      home.activation.copyTextfoxProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        PROFILE_DIR="${configDir}${cfg.profile}"

        cd "${package}"
        SRC_FILES=$(find . -type f | grep ./chrome)

        if [ ! -d "$HOME/$PROFILE_DIR" ]; then
          echo "Profile ${cfg.profile} does not exist, creating it"
          mkdir -p "$HOME/$PROFILE_DIR"
        fi

        cd "$HOME/$PROFILE_DIR"

        for file in $SRC_FILES; do
          dirname=$(dirname "$file")
          if [ ! -d "$dirname" ]; then
            mkdir -p "$dirname"
          fi
          cp -L "${package}/$file" "$HOME/$PROFILE_DIR/$file"
          chmod 744 "$HOME/$PROFILE_DIR/$file"
        done

        cp -L ${configCss} "$HOME/$PROFILE_DIR/chrome/config.css"
        chmod 744 "$HOME/$PROFILE_DIR/chrome/config.css"
      '';
    };
  in lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.firefox = {
        enable = true;
        profiles."${cfg.profile}" = {
          extensions = [ config.nur.repos.rycee.firefox-addons.sidebery ];
          extraConfig = builtins.readFile "${package}/user.js";
        };
      };
    }
    (lib.mkIf cfg.copyOnActivation copyOnActivationCfg)
    (lib.mkIf (!cfg.copyOnActivation) linkCfg)
  ]);
}
