{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkRenamedOptionModule;
  inherit (lib.strings) replaceStrings;
  inherit (lib.types) bool str;

  cfg = config.textfox.config;
in {
  imports = [
    (mkRenamedOptionModule ["textfox" "config" "displayHorizontalTabs"] ["textfox" "config" "tabs" "horizontal" "enable"])
    (mkRenamedOptionModule ["textfox" "config" "sidebery" "margin"] ["textfox" "config" "tabs" "vertical" "margin"])
  ];

  options.textfox = {
    enable = mkEnableOption "Textfox.";
          
    config = {
      displayWindowControls = mkEnableOption "window controls.";
      displayNavButtons = mkEnableOption "back and forward navigation buttons in the Firefox UI.";
      displayUrlbarIcons = mkEnableOption "icons inside url bar.";
      displaySidebarTools = mkEnableOption "sidebar tools section." // {default = true;};

      displayTitles = mkOption {
        type = bool;
        default = true;
        description = "If titles (tabs, navbar, main etc.) should be shown";
      };

      newtabLogo = mkOption {
        type = str;
        default = ''
             __            __  ____
             / /____  _  __/ /_/ __/___  _  __
            / __/ _ \| |/ / __/ /_/ __ \| |/ /
          / /_/  __/>  </ /_/ __/ /_/ />  <
          \__/\___/_/|_|\__/_/  \____/_/|_|
        '';
        apply = p: replaceStrings ["\n" "\\"] ["\\A" "\\\\"] p;
        description = "ASCII logo used for new tab page";
      };

      background.color = mkOption {
        type = str;
        default = "var(--lwt-accent-color, -moz-dialog)";
        description = "Background color of all elements.";
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

      icons = {
        toolbar.extensions.enable = mkEnableOption "monochrome extension toolbar buttons.";
        context.extensions.enable = mkEnableOption "monochrome extension context menu items.";
        context.firefox.enable = mkEnableOption "icons for common context menu items.";
      };

      tabs = {
        horizontal.enable = mkEnableOption "display of horizontal tabs.";
        vertical.enable = mkEnableOption "display of vertical tabs." // {default = true;};
        vertical.margin = mkOption {
          type = str;
          default = "0.8rem";
          description = "Margin used between elements in sidebery.";
        };
      };

      extraConfig = mkOption {
        type = str;
        default = "";
        description = "Extra lines to add to config.css";
      };

      textTransform = mkOption {
        type = str;
        default = "none";
        description = "Text transform to use";
      };
    };

    configCss = mkOption {
      readOnly = true;
      visible = false;
      type = str;
      default = ''
        :root {
          --tf-font-family: ${cfg.font.family};
          --tf-font-size: ${cfg.font.size};
          --tf-accent: ${cfg.font.accent};
          --tf-bg: ${cfg.background.color};
          --tf-border: ${cfg.border.color};
          --tf-border-transition: ${cfg.border.transition};
          --tf-border-width: ${cfg.border.width};
          --tf-rounding: ${cfg.border.radius};
          --tf-margin: ${cfg.tabs.vertical.margin};
          --tf-text-transform: ${cfg.textTransform};
          --tf-display-horizontal-tabs: ${if cfg.tabs.horizontal.enable then "block" else "none"};
          --tf-display-window-controls: ${if cfg.displayWindowControls then "flex" else "none"};
          --tf-display-nav-buttons: ${if cfg.displayNavButtons then "flex" else "none"};
          --tf-display-urlbar-icons: ${if cfg.displayUrlbarIcons then "flex" else "none"};
          --tf-display-sidebar-tools: ${if cfg.displaySidebarTools then "flex" else "none"};
          --tf-display-titles: ${if cfg.displayTitles then "flex" else "none"};
          --tf-newtab-logo: "${cfg.newtabLogo}";
        }
        ${cfg.extraConfig}
      '';
    };
  };
}

