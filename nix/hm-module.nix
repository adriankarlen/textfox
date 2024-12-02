inputs: {config, lib, pkgs, ...}:
let 
  cfg = config.textfox;
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
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
          displayNavButtons = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Show back and forward navigation buttons in the Firefox UI";
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

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles."${cfg.profile}" = {
        extraConfig = builtins.readFile "${package}/user.js";
        extensions = [ config.nur.repos.rycee.firefox-addons.sidebery ];
      };
    };

    home.file.".mozilla/firefox/${cfg.profile}/chrome" = {
      source = "${package}/chrome";
      recursive = true;
    };
    home.file.".mozilla/firefox/${cfg.profile}/chrome/config.css" = {
      text = lib.strings.concatStrings [
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
        (lib.strings.concatStrings [ " --tf-display-nav-buttons: " (if cfg.config.displayNavButtons then "block" else "none") ";" ])
        (lib.strings.concatStrings [ " --tf-newtab-logo: " cfg.config.newtabLogo ";" ])
        " }"
      ];
    };
  };
}
