inputs: { config, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/Firefox/Profiles/"
    else ".mozilla/firefox/";

  configDirLibreWolf =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/LibreWolf/Profiles/"
    else ".librewolf/";

  cfg = config.textfox;

  cfgFirefox = {
    enable = true;
    profiles."${cfg.profile}" = {
      extraConfig = builtins.readFile "${package}/user.js";
      extensions = [ config.nur.repos.rycee.firefox-addons.sidebery ];
      containersForce = true;
      userChrome = lib.mkBefore (builtins.readFile "${package}/chrome/userChrome.css");
    };
  };
in
{

  imports = [
    inputs.nur.hmModules.nur

    ./options.nix
  ];

  options.textfox = {
    profile = lib.mkOption {
      type = lib.types.str;
      description = "The profile to apply the textfox configuration to";
    };
    librewolf = lib.mkEnableOption "Enable LibreWolf browser configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = cfgFirefox;
    programs.librewolf = cfgFirefox // { enable = lib.mkDefault cfg.librewolf; };

    home.file =
      let
        chrome = {
          source = pkgs.lib.cleanSourceWith {
            src = "${package}/chrome";
            filter = path: type:
              !(type == "regular" && baseNameOf path == "userChrome.css");
          };
          recursive = true;
        };
      in
      {
        "${configDir}${cfg.profile}/chrome" = chrome;
        "${configDirLibreWolf}${cfg.profile}/chrome" = chrome;

        "${configDir}${cfg.profile}/chrome/config.css".text = cfg.configCss;
        "${configDirLibreWolf}${cfg.profile}/chrome/config.css".text = cfg.configCss;
      };
  };
}
