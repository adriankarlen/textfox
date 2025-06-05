#!/bin/bash

read -e -p "Path to firefox profile: " path
path="${path/#\~/$HOME}"  # Expand ~ to $HOME
path="${path%/}"  # Remove trailing slash if exists
path="$(echo "$path" | sed 's/\/\//\//g')"  # Normalize double slashes
# remove single and double quotes
path="$(echo "$path" | sed "s/[\"']//g")"
if [ ! -d "$path" ]; then
  echo "The specified path does not exist. Please check the path and try again."
  exit 1
fi

echo "Found profile at ${path}"

if [ -d "$path/chrome" ]; then
  read -p "This operation will copy the contents to your chrome dir, do you want to create a backup? (Y/N): " should_backup
  bdir="${path}/chrome_backup-$(date +%Y%m%d_%H%M%S)"
  case "$should_backup" in
    [Yy]* )
      [ ! -d "${bdir}" ] && mkdir "${bdir}"
      echo "Creating backup of the existing chrome directory in ${bdir}";
      cp -rf "$path/chrome" "$path/chrome_backup";
      ;;
    [Nn]* )
      echo "No backup created, proceeding with the installation."
      ;;
    *) echo "Please answer Y or N."
      ;;
  esac
else
  mkdir "$path/chrome"
fi

cp -rf "chrome/"* "$path/chrome/"

read -p "Do you want to install the user.js file? (Y/N): " install_js

case "$install_js" in
  [Yy]* ) cp "user.js" "$path/user.js";
    ;;
  [Nn]* )
    echo "Skipping user.js installation."
    ;;
  *)
    echo "Please answer Y or N."
    ;;
esac

echo "Installation completed, thank you for using textfox."
exit 0
