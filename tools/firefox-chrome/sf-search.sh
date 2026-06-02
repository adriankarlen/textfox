#!/usr/bin/env sh
# Search the LATEST Firefox release chrome source via searchfox's JSON API.
# This is the ground truth for what selectors/elements/CSS exist in the Firefox
# version that textfox targets.
#
# Usage:
#   sf-search.sh "QUERY" ["PATH_GLOB"]
#
# Examples:
#   sf-search.sh "urlbar-background" "*.css"     # where is .urlbar-background styled
#   sf-search.sh "tab-background"                # everywhere it appears
#   sf-search.sh "id=\"nav-bar\"" "*.xhtml"      # find an element in the DOM
#
# Output: "<path>:<line>: <matched line>" grouped by match kind
# (Definitions, Textual Occurrences, ...). Zero output for a known textfox
# selector usually means it was renamed/removed in the latest Firefox.
set -eu

q="${1:?usage: sf-search.sh QUERY [PATH_GLOB]}"
path="${2:-}"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [ -n "$path" ]; then
  curl -s -G 'https://searchfox.org/firefox-release/search' \
    -H 'Accept: application/json' \
    --data-urlencode "q=$q" \
    --data-urlencode "path=$path" \
    --data-urlencode "format=json" \
    -o "$tmp"
else
  curl -s -G 'https://searchfox.org/firefox-release/search' \
    -H 'Accept: application/json' \
    --data-urlencode "q=$q" \
    --data-urlencode "format=json" \
    -o "$tmp"
fi

python3 - "$tmp" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"error: bad response from searchfox ({e})", file=sys.stderr)
    sys.exit(1)

hits = 0
for category, groups in data.items():
    if category.startswith("*"):  # *title*, *timedout*, *limits*
        continue
    if not isinstance(groups, dict):
        continue
    for kind, files in groups.items():
        print(f"== {kind} ==")
        for f in files:
            for ln in f.get("lines", []):
                hits += 1
                print(f"{f['path']}:{ln['lno']}: {ln['line'].strip()}")

if data.get("*timedout*"):
    print("(searchfox: query timed out — narrow it with a PATH_GLOB)", file=sys.stderr)
if hits == 0:
    print("(no matches — selector/element may not exist in latest Firefox)", file=sys.stderr)
PY
