#!/usr/bin/env bash
# Integration tier: drive the real game and check what it actually did.
#
#   test/ft/run.sh                       # headless, no display, whole suite
#   test/ft/run.sh -v                    # with the game's own log lines
#   test/ft/run.sh "lualib"              # only tests matching a Lua pattern
#   test/ft/run.sh -g --no-auto-start    # open a window and pick tests by hand
#
# RL_FACTORIO    the game binary, if it is not where Steam puts it here
# RL_FT_DATA     the throwaway data directory the run happens in
#
# Everything else is factorio-test-cli's; see `npx factorio-test run --help`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

factorio="${RL_FACTORIO:-/home/sparr/Games/Steam/steamapps/common/Factorio/bin/x64/factorio}"
# Deliberately outside the repo: the CLI symlinks the mod under test into this
# directory's mods folder, and a data directory inside the repo would therefore make
# the repo contain itself.
data="${RL_FT_DATA:-$HOME/.cache/ritnlib-factorio-test}"

if [[ ! -x node_modules/.bin/factorio-test ]]; then
    echo "the test runner is not installed. Run:" >&2
    echo "  npm install" >&2
    exit 2
fi
[[ -x "$factorio" ]] || { echo "no factorio binary at $factorio" >&2; exit 2; }

# rl-tests is the marker telling control.lua this is a test run. It is not on the mod
# portal, so the CLI cannot fetch it; put it where the CLI looks and it leaves it alone.
mkdir -p "$data/mods"
ln -sfn "$root/test/ft/rl-tests" "$data/mods/rl-tests"

exec node_modules/.bin/factorio-test run \
    --factorio-path "$factorio" \
    --data-directory "$data" \
    --output-file "$data/results.json" \
    "$@"
