#!/usr/bin/env sh
# Live-inspect Firefox's chrome DOM with textfox applied.
#
# Launches a throwaway Firefox instance (--marionette, ephemeral profile seeded
# with the repo's chrome/ theme), queries the LIVE browser-UI DOM via
# ff_inspect.py, prints JSON, then tears everything down.
#
# Use this AFTER the static skill (sf-search.sh) when you need runtime truth:
#   - computed styles (which rule actually won the cascade, incl. textfox)
#   - runtime state attributes ([open], [focused], [busy], ...)
#   - shadow DOM as instantiated
#
# Usage:
#   firefox-live.sh ELEMENT_ID
#   firefox-live.sh --selector "CSS"  [-- ff_inspect.py flags]
#   firefox-live.sh --vanilla nav-bar          # bare Firefox, no textfox
#   firefox-live.sh back-button -- --html --children
#
# Cross-platform: detects firefox on macOS / Linux (native, snap, flatpak).
# Linux headless (no $DISPLAY): prefix with `xvfb-run -a`.
set -eu

PORT="${FF_MARIONETTE_PORT:-2828}"
TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TOOL_DIR/../.." && pwd)"   # tools/firefox-chrome -> repo root
VENV="$HOME/.cache/textfox-firefox-live/venv"
SEED=1
QUERY=""
SELECTOR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --vanilla)  SEED=0; shift ;;
    --selector) SELECTOR="${2:?--selector needs a value}"; shift 2 ;;
    --port)     PORT="${2:?--port needs a value}"; shift 2 ;;
    --)         shift; break ;;
    -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
    -*)         echo "unknown flag: $1" >&2; exit 1 ;;
    *)          QUERY="$1"; shift ;;
  esac
done
# remaining "$@" = passthrough flags for ff_inspect.py

# --- locate firefox -------------------------------------------------------
find_firefox() {
  if command -v firefox >/dev/null 2>&1; then command -v firefox; return 0; fi
  for p in \
    "/Applications/Firefox.app/Contents/MacOS/firefox" \
    "/usr/bin/firefox" "/usr/lib/firefox/firefox" \
    "/usr/lib64/firefox/firefox" "/snap/bin/firefox"; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  if command -v flatpak >/dev/null 2>&1 && flatpak info org.mozilla.firefox >/dev/null 2>&1; then
    echo "FLATPAK"; return 0
  fi
  return 1
}
FIREFOX="$(find_firefox)" || { echo "error: firefox not found" >&2; exit 1; }

# --- ensure venv + marionette_driver -------------------------------------
if [ ! -x "$VENV/bin/python" ]; then
  echo "provisioning venv (first run)..." >&2
  mkdir -p "$(dirname "$VENV")"
  python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install -q --upgrade pip marionette_driver >&2
fi

# --- ephemeral profile ----------------------------------------------------
PROFILE="$(mktemp -d "${TMPDIR:-/tmp}/tf-ff-profile.XXXXXX")"
FF_PID=""
cleanup() {
  if [ -n "$FF_PID" ]; then
    kill "$FF_PID" 2>/dev/null || true
    wait "$FF_PID" 2>/dev/null || true   # let Firefox fully exit before deleting
  fi
  rm -rf "$PROFILE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

{
  echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
  echo "user_pref(\"marionette.port\", $PORT);"
  echo 'user_pref("browser.shell.checkDefaultBrowser", false);'
  echo 'user_pref("datareporting.policy.dataSubmissionEnabled", false);'
} > "$PROFILE/user.js"

if [ "$SEED" -eq 1 ] && [ -d "$REPO_ROOT/chrome" ]; then
  mkdir -p "$PROFILE/chrome"
  cp -R "$REPO_ROOT/chrome/." "$PROFILE/chrome/"
fi

# --- launch ---------------------------------------------------------------
# -remote-allow-system-access: required by modern Firefox for chrome-context access
if [ "$FIREFOX" = "FLATPAK" ]; then
  flatpak run org.mozilla.firefox --marionette -remote-allow-system-access \
    --new-instance --profile "$PROFILE" about:blank >/dev/null 2>&1 &
else
  "$FIREFOX" --marionette -remote-allow-system-access \
    --new-instance --profile "$PROFILE" about:blank >/dev/null 2>&1 &
fi
FF_PID=$!

# --- inspect --------------------------------------------------------------
# "$@" here = passthrough flags after `--` (e.g. --html --children)
if [ -n "$SELECTOR" ]; then
  "$VENV/bin/python" "$TOOL_DIR/ff_inspect.py" --port "$PORT" --selector "$SELECTOR" "$@"
elif [ -n "$QUERY" ]; then
  "$VENV/bin/python" "$TOOL_DIR/ff_inspect.py" --port "$PORT" --id "$QUERY" "$@"
else
  echo "error: provide an element ID or --selector" >&2
  exit 1
fi
