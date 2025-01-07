#!/bin/bash

read -e -p "Path to firefox profile: " path
echo $path

if [ -d "$path/chrome" ]; then
  while true; do
    read -p "This operation will copy the contents to your chrome dir, do you want to create a backup? (Y/N): " should_backup
    case "$should_backup" in
      [Yy]* ) cp -rf "$path/chrome" "$path/chrome_backup";
        break
        ;;
      [Nn]* ) 
        break
        ;;
      *) echo "Please answer Y or N."
        ;;
    esac
  done
else
  mkdir "$path/chrome"
fi

cp -rf "chrome/"* "$path/chrome/"

read -p "Do you want to install the user.js file? (Y/N): " install_js 

case "$install_js" in
  [Yy]* ) cp "user.js" "$path/user.js";
    break
    ;;
  [Nn]* ) 
    break
    ;;
  *) 
    break
    ;;
esac

echo "Installation completed, thank you for using textfox."
