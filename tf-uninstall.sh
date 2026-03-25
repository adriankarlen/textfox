#!/bin/bash
# textfox uninstallation script

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

remove_chrome() {
  local fp="$1"
  fp="$(clean_path "${fp}")"
  if [[ -d "${fp}/chrome" ]]; then
    echo "Removing ${fp}/chrome/"
    rm -rf "${fp}/chrome"
    echo "✓ chrome directory removed"
  else
    echo "No chrome directory found at ${fp}/chrome, skipping."
  fi
}

remove_user_js() {
  local fp="$1"
  fp="$(clean_path "${fp}")"
  if [[ -f "${fp}/user.js" ]]; then
    read -rp "Do you want to remove the user.js file? (Y/N): " remove_js
    case "$remove_js" in
    [Yy]*)
      rm -v "${fp}/user.js"
      echo "✓ user.js removed"
      ;;
    *)
      echo "Skipping user.js removal."
      ;;
    esac
  else
    echo "No user.js found at ${fp}/user.js, skipping."
  fi
}

restore_backup() {
  local fp="$1"
  fp="$(clean_path "${fp}")"
  local latest_backup
  latest_backup="$(find "${fp}" -maxdepth 1 -name 'chrome-*.bak' -type d 2>/dev/null | sort -r | head -n 1)"
  if [[ -n "${latest_backup}" ]]; then
    read -rp "Backup found: ${latest_backup}. Restore it? (Y/N): " do_restore
    case "$do_restore" in
    [Yy]*)
      mv -v "${latest_backup}" "${fp}/chrome"
      echo "✓ Backup restored to ${fp}/chrome"
      ;;
    *)
      echo "Skipping backup restore."
      ;;
    esac
  else
    echo "No textfox backup found in ${fp}."
  fi
}

tf_uninstall() {
  printf "\nUninstalling textfox...\n"
  local fp
  if [[ "$#" -eq 1 ]]; then
    fp="$(clean_path "$1")"
  else
    read -rp "Path to Firefox profile: " fp
    fp="$(clean_path "${fp}")"
  fi

  local ffpp="${fp}"
  if [[ ! -d "${ffpp}" ]]; then
    echo "[!!] Directory ${ffpp} does not exist"
    while [[ ! -d "${ffpp}" ]]; do
      read -rp "Path to Firefox profile: " fp
      ffpp="$(clean_path "${fp}")"
    done
  fi

  echo "Using Firefox Profile @ ${ffpp}"
  remove_chrome "${ffpp}"
  remove_user_js "${ffpp}"
  restore_backup "${ffpp}"
  printf "✓ Uninstallation completed\n"
}

print_logo
tf_uninstall "$@"
