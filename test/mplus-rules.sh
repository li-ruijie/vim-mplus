#!/usr/bin/env bash
# Check against Mplus where a section of an input starts.
# Usage: ./mplus-rules.sh
#
# Every case of header-cases.txt is put on the second line of the TITLE of
# a small input, followed by a word and by one more line of text. What
# Mplus makes of the case shows in its output.
#
#   text      the title that Mplus prints has the line as it was written
#   rejected  Mplus stops with "Unknown command"
#   command   Mplus stops at the word, which is no statement of the command,
#             or prints the word as a title line of its own (TITLE)
#   skipped   Mplus runs the analysis, and the title that it prints has
#             neither the line nor the line after it
#
# The script is skipped when Mplus is not found. MPLUS names the executable,
# as in run-tests.sh. The inputs and outputs are in a temporary directory.
# The files of a case that is read as expected are removed, and so is the
# directory when no case is left in it. Otherwise its name is printed.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=test/mplus-common.sh
source "$TEST_DIR/mplus-common.sh"

if ! find_mplus; then
    echo "SKIP: Mplus was not found. Set MPLUS to the Mplus executable."
    exit 0
fi

WORK="$(mktemp -d)"
echo "Mplus: $MPLUS"

TOTAL=0
FAIL=0
while IFS= read -r case; do
    if [[ -z "$case" || "$case" == \#* ]]; then
        continue
    fi
    TOTAL=$((TOTAL + 1))
    expected="${case%%|*}"
    header="$(printf '%b' "${case#*|}")"
    dir="$WORK/$(printf '%03d' "$TOTAL")"
    mkdir "$dir"
    printf '%s\n' '1 2' '2 1' '3 5' '4 3' '5 6' '6 4' '7 8' '8 7' '9 9' '10 12' \
        >"$dir/d.dat"
    printf '%s\n' 'TITLE: zzfirst' "$header zzmark" 'zzafter' 'DATA: FILE = d.dat;' \
        'VARIABLE: NAMES = y x;' 'MODEL: y ON x;' >"$dir/t.inp"

    status="$(run_mplus "$dir" t.inp)"
    trim='s/^[ \t]*//; s/[ \t]*$//'
    below="$(below_echo "$dir/t.out" | sed "$trim")"
    line="$(sed "$trim" <<<"$header zzmark")"
    if [[ "$status" == timeout ]]; then
        got=timeout
    elif grep -qxF -- "$line" <<<"$below"; then
        got=text
    elif grep -q 'Unknown command' <<<"$below"; then
        got=rejected
    elif [[ "$status" != 0 ]] || grep -qxF 'zzmark' <<<"$below"; then
        got=command
    elif ! grep -q 'zzafter' <<<"$below"; then
        got=skipped
    else
        got=unclear
    fi

    if [[ "$got" != "$expected" ]]; then
        echo "[FAIL] '${case#*|}' is $got, expected $expected ($dir)"
        FAIL=$((FAIL + 1))
    else
        rm -- "$dir/d.dat" "$dir/t.inp" "$dir/t.out"
        rmdir "$dir"
    fi
done <"$TEST_DIR/header-cases.txt"

echo "Summary: $((TOTAL - FAIL))/$TOTAL cases read as expected"
if ! rmdir "$WORK" 2>/dev/null; then
    echo "Kept: $WORK"
fi
exit $FAIL
