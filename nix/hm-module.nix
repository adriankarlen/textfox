inputs: {config, lib, pkgs, ...}:
let 
  cfg = config.textfox;
  inherit (pkgs.stdenv.hostPlatform) system;
  package = inputs.self.packages.${system}.default;
in {
  options.textfox = {
    enable = lib.mkEnableOption "Enable textfox";
    profile = lib.mkOption {
      type = lib.types.str;
      description = "The profile to apply the textfox configuration to";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles."${cfg.profile}" = {
          extraConfig = builtins.readFile "${package}/user.js";
        };
      };

      home.file.".mozilla/firefox/${cfg.profile}/chrome" = {
        source = "${package}/chrome";
        recursive = true;
      };
    };
}