inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.types) listOf path str;
  inherit (lib.trivial) boolToString;

  inherit (pkgs.stdenv.hostPlatform) system;
  wrapTextfox = inputs.self.packages.${system}.wrapTextfox;

  cfg = config.textfox;
in
{
  imports = [ ./options.nix ];

  options.textfox = {
    package = mkPackageOption pkgs "firefox-unwrapped" { };

    extraPoliciesFiles = mkOption {
      type = listOf path;
      default = [ ];
      description = "Custom policy.json files passed; see 'about:policies'.";
    };

    extraPrefsFiles = mkOption {
      type = listOf path;
      default = [ ];
      description = "Custom autoconfig.js files passed";
    };

    extraUserChrome = mkOption {
      type = str;
      default = "";
      description = "Custom userChrome.css appended to the hooked textfox file.";
    };

    extraUserContent = mkOption {
      type = str;
      default = "";
      description = "Custom userContent.css appended to the hooked textfox file.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      let
        preferences =
          let
            icons = config.textfox.config.icons;
          in
          ''
            pref("shyfox.enable.ext.mono.toolbar.icons", ${boolToString icons.toolbar.extensions.enable});
            pref("shyfox.enable.ext.mono.context.icons", ${boolToString icons.context.extensions.enable});
            pref("shyfox.enable.context.menu.icons", ${boolToString icons.context.firefox.enable});
          '';

      in
      [
        (wrapTextfox cfg.package {
          inherit (cfg)
            extraPoliciesFiles
            extraPrefsFiles
            extraUserChrome
            extraUserContent
            configCss
            ;

          extraPolicies = policies;
          extraPrefs = preferences;
        })
      ];
  };
}
