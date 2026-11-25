#!/usr/bin/env bash
# Editor tests for vim-mplus that need no Mplus installation.
# Usage: ./run-unit-tests.sh [editor ...]
#
# Each argument is a Vim or Neovim executable. Without arguments the tests
# run in vim and in nvim, whichever of the two is installed. The checks over
# the Mplus examples read them from test/original/, or from the directory
# named by MPLUS_EXAMPLES, and are skipped when no example is found.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -gt 0 ]]; then
    EDITORS=("$@")
else
    EDITORS=()
    for editor in vim nvim; do
        if command -v "$editor" >/dev/null 2>&1; then
            EDITORS+=("$editor")
        fi
    done
fi

if [[ ${#EDITORS[@]} -eq 0 ]]; then
    echo "ERROR: neither vim nor nvim was found"
    exit 1
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# A native Windows editor needs a Windows path in the environment.
LOG_PATH="$LOG"
if command -v cygpath >/dev/null 2>&1; then
    LOG_PATH="$(cygpath -m "$LOG")"
fi

FAIL=0
for editor in "${EDITORS[@]}"; do
    if [[ "$(basename "$editor")" == *nvim* ]]; then
        ARGS=(--headless -u NONE -i NONE)
    else
        ARGS=(-N -u NONE -i NONE -es)
    fi
    for script in "$TEST_DIR"/unit/test_*.vim; do
        : > "$LOG"
        # Standard input is closed so that an editor left in Ex mode by a
        # script error exits. The last line of the log gives the result.
        MPLUS_TEST_LOG="$LOG_PATH" "$editor" "${ARGS[@]}" -S "$script" \
            </dev/null >/dev/null 2>&1 || true
        if [[ "$(tail -n 1 "$LOG" | tr -d '\r')" == "PASS" ]]; then
            echo "[PASS] $editor $(basename "$script")"
        else
            echo "[FAIL] $editor $(basename "$script")"
            FAIL=$((FAIL + 1))
        fi
        sed -e '$d' -e 's/^/    /' "$LOG"
    done
done

exit $FAIL
