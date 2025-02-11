{
  lib,
  wrapFirefox,
  runCommandLocal
}: 
  browser: { 
    configCss ? "",
    extraUserChrome ? "",
    extraUserContent ? "",
    ...
  } @ args: let

    textfoxChrome = runCommandLocal "textfox-chrome" {
      inherit configCss extraUserChrome extraUserContent;
      passAsFile = ["configCss" "extraUserChrome" "extraUserContent"];

      src = ./../../chrome;
    } ''
      mkdir -p "$out"
      cp -r "$src/icons" "$out/icons"

      ### USERCHROME
      cat "$src/overwrites.css" >> "$out/userChrome.css"
      cat "$src/userChrome.css" >> "$out/userChrome.css"
      cat "$src/sidebar.css" >> "$out/userChrome.css"
      cat "$src/browser.css" >> "$out/userChrome.css"
      cat "$src/findbar.css" >> "$out/userChrome.css"
      cat "$src/navbar.css" >> "$out/userChrome.css"
      cat "$src/urlbar.css" >> "$out/userChrome.css"
      sed "s|./icons|$out/icons|g" "$src/icons.css" >> "$out/userChrome.css"
      cat "$src/menus.css" >> "$out/userChrome.css"
      cat "$src/tabs.css" >> "$out/userChrome.css"

      cat "$src/defaults.css" >> "$out/userChrome.css"
      cat "$configCssPath" >> "$out/userChrome.css"
      cat "$extraUserChromePath" >> "$out/userChrome.css"

      ### USERCONTENT
      cat "$src/content/sidebery.css" >> "$out/userContent.css"
      cat "$src/content/newtab.css" >> "$out/userContent.css"
      cat "$src/content/about.css" >> "$out/userContent.css"

      cat "$src/defaults.css" >> "$out/userContent.css"
      cat "$configCssPath" >> "$out/userContent.css"
      cat "$extraUserContentPath" >> "$out/userContent.css"
    '';

    configScript = ''
      /* TEXTFOX GENERATED CONFIG */

      const {classes: Cc, interfaces: Ci, utils: Cu} = Components;
      Cu.import("resource://gre/modules/FileUtils.jsm");
      var updated = false;

      // Create nsiFile objects 
      var chromeDir = Services.dirsvc.get("ProfD", Ci.nsIFile);
      chromeDir.append("chrome");

      // XP_UNIX forces symlinks to be resolved when copying
      // so we are just going to normal copy from nix store
      // <https://bugzilla.mozilla.org/show_bug.cgi?id=480726>
      var textfoxChrome = new FileUtils.File("${textfoxChrome}");
      var userChrome = new FileUtils.File("${textfoxChrome}/userChrome.css");
      var userContent = new FileUtils.File("${textfoxChrome}/userContent.css");

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

      /* END TEXTFOX AUTOCONFIG */
    '';

  in wrapFirefox browser (
    lib.removeAttrs args [
      "configCss" 
      "extraUserChrome" 
      "extraUserContent"
    ] // {
      pname = args.pname or "textfox";
      extraPrefs = configScript + (args.extraPrefs or "");
    }
  )

