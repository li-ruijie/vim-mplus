#!/usr/bin/env bash
# Check with Mplus that formatting an input does not change what Mplus reads.
# Usage: ./run-tests.sh [partial|full]
#
#   partial   the first 10 inputs of every chapter of examples (the default)
#   full      every input
#
# Every example input is run through Mplus as it is and again after gq has
# formatted it. The two runs have to end with the same exit status and the
# same output below the echoed input. That output holds the messages about
# the input, the summary of the analysis, and the model results. Four
# things are left out of the comparison: the lines that give a time, the
# blank lines, the amount of white space, and the difference between
# capitals and small letters. Mplus prints the title and some labels as the
# input writes them, and the formatter turns a tab into four spaces and
# writes code in capitals.
#
# Mplus reads 90 characters of an input line. Where a line of an example is
# longer, Mplus has cut it, and the formatter breaks it, so the two runs
# are of different inputs. Such an example is reported as skipped when its
# runs differ.
#
# The script is skipped when Mplus is not found. It reads these variables.
#
#   MPLUS             the Mplus executable. Without it, mplus on the PATH is
#                     taken, and then the place where Scoop installs it.
#   MPLUS_EXAMPLES    the directory with the example inputs and their data,
#                     searched with every directory below it. The default
#                     is test/original/.
#   MPLUS_TIME_LIMIT  the seconds that one run may take, 60 by default.
#                     Where a run of an example takes longer, only the
#                     messages about the input are compared.
#   MPLUS_TEST_DIR    the directory for the runs. The default is a new
#                     temporary directory. A run that is given the directory
#                     of an earlier run takes up where that run stopped, so
#                     give a new directory after a change to the plugin.
#   MPLUS_TEST_EDITOR the Vim or Neovim that formats, vim by default.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$TEST_DIR")"
# shellcheck source=test/mplus-common.sh
source "$TEST_DIR/mplus-common.sh"

MODE="${1:-partial}"
if [[ "$MODE" != "partial" && "$MODE" != "full" ]]; then
    echo "Usage: $0 {partial|full}"
    exit 1
fi

if ! find_mplus; then
    echo "SKIP: Mplus was not found. Set MPLUS to the Mplus executable."
    exit 0
fi

EXAMPLES="${MPLUS_EXAMPLES:-$TEST_DIR/original}"
EDITOR_BIN="${MPLUS_TEST_EDITOR:-vim}"
if ! command -v "$EDITOR_BIN" >/dev/null 2>&1; then
    echo "ERROR: the editor $EDITOR_BIN was not found"
    exit 1
fi
if [[ "$(basename "$EDITOR_BIN")" == *nvim* ]]; then
    EDITOR_ARGS=(--headless -u NONE -i NONE)
else
    EDITOR_ARGS=(-N -u NONE -i NONE -es)
fi

# A native Windows editor needs Windows paths.
native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -m "$1"
    else
        printf '%s\n' "$1"
    fi
}

# The inputs in the order of their numbers. A chapter is a directory and
# the start of a name up to its first dot (ex3, mcex3).
mapfile -t FILES < <(find "$EXAMPLES" -name '*.inp' 2>/dev/null | sort -V |
    awk -F/ -v mode="$MODE" '{
        chapter = $NF
        sub(/\..*/, "", chapter)
        if (mode == "full" || ++count[substr($0, 1, length($0) - length($NF)) chapter] <= 10)
            print
    }')
TOTAL=${#FILES[@]}
if [[ $TOTAL -eq 0 ]]; then
    echo "ERROR: no *.inp files were found in $EXAMPLES"
    exit 1
fi

WORK="${MPLUS_TEST_DIR:-$(mktemp -d)}"
mkdir -p "$WORK/original" "$WORK/formatted"
LOGFILE="$TEST_DIR/results-$(date +%Y%m%d-%H%M%S).log"

report() {
    echo "$1"
    echo "$1" >>"$LOGFILE"
}

report "Mplus: $MPLUS"
report "Mode: $MODE, $TOTAL inputs from $EXAMPLES"
report "Runs: $WORK"
report "---"

# Copy the input $1 into the directory $2, with the data that it needs. A
# file of the directory of the input is needed when the input names it, or
# when a file that is already taken names it, as the list of the data sets
# of a Monte Carlo study does.
stage() {
    local source file name before=0
    source="$(dirname "$1")"
    mkdir -p "$2"
    cp "$1" "$2/"
    for file in "$source"/*; do
        case "$file" in *.[iI][nN][pP] | *.[oO][uU][tT]) continue ;; esac
        if [[ -f "$file" ]]; then
            printf '%s\n' "${file##*/}"
        fi
    done >"$WORK/names.txt"
    while [[ "$(find "$2" -type f | wc -l)" -ne $before ]]; do
        before="$(find "$2" -type f | wc -l)"
        awk 'FILENAME == ARGV[1] { names[tolower($0)] = $0; next }
            {
                line = tolower($0)
                for (name in names)
                    if (index(line, name)) {
                        print names[name]
                        delete names[name]
                    }
            }' "$WORK/names.txt" "$2"/* |
            while IFS= read -r name; do
                cp -n "$source/$name" "$2/"
            done
    done
}

# Format the input $1 in place with gq. The editor leaves with an error
# when the formatter of the plugin is not set or fails.
format_input() {
    "$EDITOR_BIN" "${EDITOR_ARGS[@]}" \
        --cmd "let &runtimepath = '$(native_path "$REPO_DIR"),' . \$VIMRUNTIME" \
        --cmd 'filetype plugin indent on' \
        -c 'setfiletype mplus-inp' \
        -c 'if &formatexpr !~# "^mplus#format#" | cquit | endif' \
        -c 'try | execute "normal gggqG" | catch | cquit | endtry' \
        -c 'wq!' "$(native_path "$1")" </dev/null >/dev/null 2>&1
}

# Run the input $1 in a directory of its own below $WORK/$2 and print the
# status of the run. With "formatted" as $2 the input is formatted first,
# and the status is "unformatted" when that fails. The status is kept in a
# file, and a run that has one is not made again.
run_example() {
    local name dir
    name="$(basename "$1" .inp)"
    dir="$WORK/$2/$name"
    if [[ ! -f "$dir/status" ]]; then
        stage "$1" "$dir"
        if [[ "$2" == formatted ]] && ! format_input "$dir/$name.inp"; then
            echo unformatted >"$dir/status.tmp"
        else
            run_mplus "$dir" "$name.inp" >"$dir/status.tmp"
        fi
        mv "$dir/status.tmp" "$dir/status"
    fi
    cat "$dir/status"
}

# Print the messages about the input from the Mplus output $1, which stand
# between the echoed input and the summary of the analysis.
messages() {
    below_echo "$1" | sed '/^SUMMARY OF ANALYSIS/,$d'
}

# Tell whether the outputs of the two runs of the example $1 are the same
# in the lines that the function $2 prints, without regard to case and to
# the amount of white space.
same() {
    diff -ibq <("$2" "$WORK/original/$1/$1.out") <("$2" "$WORK/formatted/$1/$1.out") >/dev/null
}

PASS=0
FAIL=0
SKIP=0
ERRORS=()
for input in "${FILES[@]}"; do
    name="$(basename "$input" .inp)"
    original="$(run_example "$input" original)"
    formatted="$(run_example "$input" formatted)"
    note=""
    problem=""
    if [[ "$formatted" == unformatted ]]; then
        problem="the editor did not format the input"
    elif [[ ! -f "$WORK/original/$name/$name.out" || ! -f "$WORK/formatted/$name/$name.out" ]]; then
        problem="no output file"
    elif [[ "$original" == timeout || "$formatted" == timeout ]]; then
        note=" (over the time limit, messages compared)"
        if ! same "$name" messages; then
            problem="the messages about the input differ"
        fi
    elif [[ "$original" != "$formatted" ]]; then
        problem="exit status $original as written, $formatted when formatted"
    elif ! same "$name" below_echo; then
        problem="the output differs (compare $name/$name.out in original/ and formatted/)"
    fi

    if [[ -z "$problem" ]]; then
        report "[PASS] $name$note"
        PASS=$((PASS + 1))
    elif tr -d '\r' <"$input" | LC_ALL=C grep -q '.\{91\}'; then
        report "[SKIP] $name: Mplus cut a line of the input, which is over 90 characters"
        SKIP=$((SKIP + 1))
    else
        report "[FAIL] $name: $problem"
        FAIL=$((FAIL + 1))
        ERRORS+=("$name")
    fi
done

report "---"
report "Summary: $PASS/$TOTAL passed, $FAIL/$TOTAL failed, $SKIP/$TOTAL skipped"
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    report ""
    report "Failed inputs:"
    for name in "${ERRORS[@]}"; do
        report "  $name"
    done
fi

echo ""
echo "Log written to: $LOGFILE"

exit $FAIL
