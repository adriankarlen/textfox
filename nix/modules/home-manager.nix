inputs: {config, lib, pkgs, ...}:
let 
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application\ Support/Firefox/Profiles/"
    else ".mozilla/firefox/";
  extensionList = lib.optionals cfg.config.tabs.vertical.sidebery.enable [ inputs.firefox-addons.packages.${system}.sidebery ];

  cfg = config.textfox;
in {

  imports = [ 
    ./options.nix
    (lib.mkChangedOptionModule 
      [ "textfox" "profile" ] 
      [ "textfox" "profiles" ]
      (config: 
        let profile = lib.getAttrFromPath [ "textfox" "profile" ] config;
        in [ profile ]
      )
    )
  ];

  options.textfox = {
    profiles = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "List of Firefox profiles to apply the textfox configuration to";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles = lib.mkMerge (map (profile: {
        "${profile}" = {
          extraConfig = builtins.readFile "${package}/user.js";
          extensions.packages = extensionList;
          containersForce = true;
          userChrome = lib.mkBefore (builtins.readFile "${package}/chrome/userChrome.css");
        };
      }) cfg.profiles);
    };

    home.file = lib.mkMerge (map (profile: {
      "${configDir}${profile}/chrome" = {
        source = pkgs.lib.cleanSourceWith {
          src = "${package}/chrome";
          filter = path: type:
            !(type == "regular" && baseNameOf path == "userChrome.css");
        };
        recursive = true;
      };
      "${configDir}${profile}/chrome/config.css" = {
        text = cfg.configCss;
      };
    }) cfg.profiles);
  };
}
