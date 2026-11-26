#!/usr/bin/env bash
# Hold syntax/mplus-out.vim to the oracle test/corpus/kinds.py, line by line.
# Usage: ./check-syntax.sh [-d DIR] [editor ...]
#
# For every Mplus output (*.out) under DIR, or under the directory named by
# MPLUS_EXAMPLES, each editor writes the kind and the fold level of every
# line as the syntax file reads them (test/corpus/dump.vim states how a
# syntax group maps to a kind), and kinds.py compares them with its own. The
# script prints every line that differs and every error message, and exits
# with the number of editors that differ. Each argument is a Vim or Neovim
# executable, and without arguments the check runs in vim and in nvim. It
# needs Python 3 and a directory of outputs, and says so when either is
# missing.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

DIR="${MPLUS_EXAMPLES:-}"
if [[ $# -ge 2 && "$1" == "-d" ]]; then
    DIR="$2"
    shift 2
fi
EDITORS=("$@")
if [[ ${#EDITORS[@]} -eq 0 ]]; then
    EDITORS=(vim nvim)
fi

PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 \
        && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 6))' 2>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done
if [[ -z "$PYTHON" ]]; then
    echo "ERROR: the check needs Python 3, and neither python3 nor python is one"
    exit 1
fi
if [[ -z "$DIR" ]]; then
    echo "ERROR: name a directory of Mplus outputs with -d or with MPLUS_EXAMPLES"
    exit 1
fi
if [[ ! -d "$DIR" ]]; then
    echo "ERROR: $DIR is no directory"
    exit 1
fi

WORK="$(mktemp -d)"
LIST="$WORK/list.txt"
DUMP="$WORK/dump.txt"
: > "$LIST"
: > "$DUMP"
trap 'rm -- "$LIST" "$DUMP"; rmdir -- "$WORK"' EXIT

# A native Windows editor and Python need Windows paths.
to_native() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi
}
"$PYTHON" -c 'import sys, pathlib
for p in sorted(pathlib.Path(sys.argv[1]).rglob("*.out")): print(p.as_posix())' \
    "$(to_native "$DIR")" > "$LIST"
if [[ ! -s "$LIST" ]]; then
    echo "ERROR: no Mplus output (*.out) under $DIR"
    exit 1
fi

FAIL=0
for editor in "${EDITORS[@]}"; do
    if [[ "$(basename "$editor")" == *nvim* ]]; then
        ARGS=(--headless -u NONE -i NONE)
    else
        ARGS=(-N -u NONE -i NONE -es)
    fi
    : > "$DUMP"
    # Standard input is closed so that an editor left in Ex mode by a script
    # error exits.
    CHECK_LIST="$(to_native "$LIST")" CHECK_OUT="$(to_native "$DUMP")" \
        "$editor" "${ARGS[@]}" -S "$(to_native "$HERE/dump.vim")" </dev/null >/dev/null 2>&1 || true
    if [[ "$(grep -c '^= ' "$DUMP" || true)" -ne "$(wc -l < "$LIST")" ]]; then
        echo "[FAIL] $editor wrote $(grep -c '^= ' "$DUMP" || true) of $(wc -l < "$LIST") outputs"
        FAIL=$((FAIL + 1))
    elif "$PYTHON" "$(to_native "$HERE/kinds.py")" compare "$(to_native "$DUMP")"; then
        echo "[PASS] $editor"
    else
        echo "[FAIL] $editor"
        FAIL=$((FAIL + 1))
    fi
done

exit $FAIL
