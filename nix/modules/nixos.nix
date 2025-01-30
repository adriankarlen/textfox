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
  inherit (lib.types) listOf path enum str bool;

  cfg = config.textfox;
in {
  imports = [./options.nix];

  options.textfox = {
    package = mkPackageOption pkgs "firefox-unwrapped" {};

    extraPoliciesFiles = mkOption {
      type = listOf path;
      default = [];
      description = "Custom policy.json files passed; see 'about:policies'.";
    };

    extraPrefsFiles = mkOption {
      type = listOf path;
      default = [];
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
      description = "Custome userContent.css appended to the hooked textfox file.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = let

      textfox-chrome = let
        chrome = "${../../chrome}";

      in pkgs.runCommand "textfox-chrome" { 
          inherit (cfg) configCss extraUserChrome extraUserContent;
          passAsFile = ["configCss" "extraUserChrome" "extraUserContent"];
        } ''
        mkdir -p "$out"

        cp -r "${chrome}/icons" "$out/icons"
        
        cat "${chrome}/overwrites.css" >> "$out/userChrome.css"
        cat "${chrome}/userChrome.css" >> "$out/userChrome.css"
        cat "${chrome}/sidebar.css" >> "$out/userChrome.css"
        cat "${chrome}/browser.css" >> "$out/userChrome.css"
        cat "${chrome}/findbar.css" >> "$out/userChrome.css"
        cat "${chrome}/navbar.css" >> "$out/userChrome.css"
        cat "${chrome}/urlbar.css" >> "$out/userChrome.css"
        sed "s|./icons|$out/icons|g" "${chrome}/icons.css" >> "$out/userChrome.css"
        cat "${chrome}/menus.css" >> "$out/userChrome.css"
        cat "${chrome}/tabs.css" >> "$out/userChrome.css"

        cat "${chrome}/defaults.css" >> "$out/userChrome.css"

        cat "${chrome}/content/sidebery.css" >> "$out/userContent.css"
        cat "${chrome}/content/newtab.css" >> "$out/userContent.css"
        cat "${chrome}/content/about.css" >> "$out/userContent.css"

        cat "${chrome}/defaults.css" >> "$out/userContent.css"

        cat "$configCssPath" >> "$out/userChrome.css"
        cat "$configCssPath" >> "$out/userContent.css"

        cat "$extraUserChromePath" >> "$out/userChrome.css"
        cat "$extraUserContentPath" >> "$out/userContent.css"
      '';

    in [(pkgs.wrapFirefox cfg.package {
      inherit (cfg) extraPoliciesFiles extraPrefsFiles;
      pname = "textfox";
      extraPolicies = optionalAttrs cfg.config.tabs.vertical.enable {
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

        pref("shyfox.enable.ext.mono.toolbar.icons", ${toJSON cfg.config.icons.toolbar.extensions.enable});
        pref("shyfox.enable.ext.mono.context.icons", ${toJSON cfg.config.icons.context.extensions.enable});
        pref("shyfox.enable.context.menu.icons", ${toJSON cfg.config.icons.context.firefox.enable});
      '';
    })];
  };
}

