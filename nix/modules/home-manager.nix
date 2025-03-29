inputs: {config, lib, pkgs, ...}:
let 
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/Firefox/Profiles/"
    else ".mozilla/firefox/";
  extensionList = [ config.nur.repos.rycee.firefox-addons.sidebery ];

  cfg = config.textfox;
in {

  imports = [
    inputs.nur.hmModules.nur

    ./options.nix
  ];

  options.textfox = {
    profile = lib.mkOption {
      type = lib.types.str;
      description = "The profile to apply the textfox configuration to";
    };
    useLegacyExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If 'extensions' should be used instead of 'extensions.packages' for extension config";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles."${cfg.profile}" = {
        extraConfig = builtins.readFile "${package}/user.js";
        containersForce = true;
        userChrome = lib.mkBefore (builtins.readFile "${package}/chrome/userChrome.css");
      } // (
        if cfg.useLegacyExtensions
        then { extensions = extensionList; }
        else { extensions.packages = extensionList; }
      );
    };

    home.file."${configDir}${cfg.profile}/chrome" = {
      source = pkgs.lib.cleanSourceWith {
        src = "${package}/chrome";
        filter = path: type:
          !(type == "regular" && baseNameOf path == "userChrome.css");
      };
      recursive = true;
    };
    home.file."${configDir}${cfg.profile}/chrome/config.css" = {
      text = cfg.configCss;
    };
  };
}
