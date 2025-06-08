#!/bin/bash
# textfox installation script

print_logo() {
  cat <<EOF
   __            __  ____          
  / /____  _  __/ /_/ __/___  _  __
 / __/ _ \| |/_/ __/ /_/ __ \| |/_/
/ /_/  __/>  </ /_/ __/ /_/ />  <  
\__/\___/_/|_|\__/_/  \____/_/|_|  
EOF
}

clean_path() {
  local fp="$1"
  fp="${fp/#\~/$HOME}" # Expand ~ to $HOME
  fp="${fp%/}"         # Remove trailing slash if exists
  fp="${fp/\/\//\/}"   # Remove double slashes
  fp="${fp//\'/}"      # Remove single quotes
  fp="${fp//\"/}"      # Remove double quotes
  echo "$fp"
}

backup_existing_profile() {
  local fp="$1"
  fp="$(clean_path "${fp}")"
  if [[ -d "${fp}/chrome" ]]; then
    echo "[!!] Backing up existing chrome directory..."
    mv -v "${fp}/chrome" "${fp}/chrome-$(date +%Y%m%d_%H%M%S).bak"
  fi
}

copy_chrome() {
  local fp="$1"
  fp="$(clean_path "${fp}")"
  if [[ -d "${fp}" ]]; then
    echo "Copying textfox/chrome/ -> ${fp}/chrome/"
    cp -r "chrome" "${fp}/chrome"
  else
    echo "The specified Firefox profile path does not exist: ${fp}"
    return 1
  fi
}

install_user_js() {
  local fp="$1"
  fp="$(clean_path "${fp}")"

  # Optionally install user.js
  read -rp "Do you want to install the user.js file? (Y/N): " install_js

  case "$install_js" in
  [Yy]*)
    cp -v "user.js" "$fp/user.js"
    ;;
  *)
    echo "Skipping user.js installation."
    ;;
  esac
}

tf_install() {
  printf "\nInstalling textfox...\n"
  local fp
  if [[ "$#" -eq 1 ]]; then
    fp="$(clean_path "$1")"
  else
    read -rp "Path to Firefox profile: " fp
    fp="$(clean_path "${fp}")"
  fi

  ffpp="$(clean_path "${fp}")"
  if [[ ! -d "${ffpp}" ]]; then
    echo "[!!] Directory ${ffpp} does not exist"
    while [[ ! -d "${ffpp}" ]]; do
      read -rp "Path to Firefox profile: " fp
      ffpp="$(clean_path "${fp}")"
    done
  fi

  echo "Using Firefox Profile @ ${ffpp}"
  backup_existing_profile "${ffpp}"
  copy_chrome "${ffpp}"
  install_user_js "${ffpp}"
  printf "✓ Installation completed\n"
}

print_logo
tf_install "$@"
