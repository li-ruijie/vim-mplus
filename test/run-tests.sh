#!/usr/bin/env bash
# Check with Mplus that formatting an input does not change what Mplus reads.
# Usage: ./run-tests.sh [-t SECONDS] [-j RUNS] [-r DIR] [-n FILE] [partial|full]
#
#   partial     the first 10 inputs of every chapter of examples (the default)
#   full        every input
#   -t SECONDS  the seconds that one run of Mplus may take, MPLUS_TIME_LIMIT
#               or 60 by default. The time in which the machine sleeps does
#               not count. Where a run of an example takes longer, only the
#               messages about the input are compared, and the tokens of
#               the input before and after gq are compared as well.
#   -j RUNS     the number of inputs that are run side by side, 1 by
#               default. The two runs of one input follow each other.
#   -r DIR      the directory for the runs, the verdicts, and the log,
#               MPLUS_TEST_DIR or a new temporary directory by default. A
#               start with the directory of an earlier one passes over every
#               input that has a verdict there and takes up the others where
#               they stopped, so give a new directory after a change to the
#               plugin.
#   -n FILE     run only the inputs whose names (ex9.27) FILE lists, one to
#               a line. Lines that start with # are left out.
#
# Every example input, and every input of test/inputs/, is run through Mplus
# as it is and again after gq has formatted it. The two runs have to end with
# the same exit status and the same output below the echoed input. That
# output holds the messages about the input, the summary of the analysis,
# and the model results. Four things are left out of the comparison: the
# lines that give a time, the blank lines, the amount of white space, and
# the difference between capitals and small letters. Mplus prints the title
# and some labels as the input writes them, and the formatter writes code in
# capitals and the text of the TITLE line on a line of its own, below which
# Mplus prints an empty line.
#
# Mplus reads 90 characters of an input line. Where a line of an example is
# longer, Mplus has cut it, and the formatter breaks it, so the two runs
# are of different inputs. Such an example is reported as skipped when its
# runs differ.
#
# The verdict of an input is written to verdicts/<name> in the directory of
# the runs as soon as both of its runs are done. It is one line with the
# verdict, the name, the exit status and the seconds of each run (with the
# seconds that the machine slept, where it did), the tokens where a run was
# over the time limit, and the reason for a failure. A run that ends
# without the end of an output, as when the machine was shut down or the
# process was ended from outside, gets no verdict, and the next start runs
# it again.
#
# The script is skipped when Mplus is not found. It reads these variables.
#
#   MPLUS             the Mplus executable. Without it, mplus on the PATH is
#                     taken, and then the place where Scoop installs it.
#   MPLUS_EXAMPLES    the directory with the example inputs and their data,
#                     searched with every directory below it. The default
#                     is test/original/.
#   MPLUS_TIME_LIMIT  the default of -t.
#   MPLUS_TEST_DIR    the default of -r.
#   MPLUS_TEST_EDITOR the Vim or Neovim that formats, vim by default.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$TEST_DIR")"
# shellcheck source=test/mplus-common.sh
source "$TEST_DIR/mplus-common.sh"

usage() {
    echo "Usage: $0 [-t SECONDS] [-j RUNS] [-r DIR] [-n FILE] [partial|full]"
    exit 1
}

JOBS=1
WORK="${MPLUS_TEST_DIR:-}"
NAMES=""
while getopts t:j:r:n: option; do
    case "$option" in
    t) MPLUS_TIME_LIMIT="$OPTARG" ;;
    j) JOBS="$OPTARG" ;;
    r) WORK="$OPTARG" ;;
    n) NAMES="$OPTARG" ;;
    *) usage ;;
    esac
done
shift $((OPTIND - 1))
MODE="${1:-partial}"
if [[ $# -gt 1 || ("$MODE" != "partial" && "$MODE" != "full") ]]; then
    usage
fi
export MPLUS_TIME_LIMIT="${MPLUS_TIME_LIMIT:-60}"

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

# The inputs of test/inputs/ come first, in both modes. They hold what no
# example has, such as a title that looks like a section header. The
# examples follow in the order of their numbers. A chapter is a directory
# and the start of a name up to its first dot (ex3, mcex3). With -n, only
# the inputs that the file names are kept.
mapfile -t FILES < <(
    {
        find "$TEST_DIR/inputs" -name '*.inp' | sort
        find "$EXAMPLES" -name '*.inp' 2>/dev/null | sort -V |
            awk -F/ -v mode="$MODE" '{
                chapter = $NF
                sub(/\..*/, "", chapter)
                if (mode == "full" || ++count[substr($0, 1, length($0) - length($NF)) chapter] <= 10)
                    print
            }'
    } | if [[ -n "$NAMES" ]]; then
        awk 'FILENAME == ARGV[1] { if ($1 !~ /^#/ && NF) keep[$1 ".inp"] = 1; next }
            { name = $0; sub(/.*\//, "", name); if (name in keep) print }' "$NAMES" -
    else
        cat
    fi
)
TOTAL=${#FILES[@]}

if [[ -z "$WORK" ]]; then
    WORK="$(mktemp -d)"
    LOGFILE="$TEST_DIR/results-$(date +%Y%m%d-%H%M%S).log"
else
    LOGFILE="$WORK/results-$(date +%Y%m%d-%H%M%S).log"
fi
mkdir -p "$WORK/original" "$WORK/formatted" "$WORK/verdicts"

report() {
    echo "$1"
    echo "$1" >>"$LOGFILE"
}

report "Mplus: $MPLUS"
report "Mode: $MODE, $TOTAL inputs from test/inputs/ and $EXAMPLES"
report "Runs: $WORK, time limit $MPLUS_TIME_LIMIT s, $JOBS side by side"
report "---"

# Copy the input $1 into the directory $2, with the data that it needs. A
# file of the directory of the input is needed when the input names it, or
# when a file that is already taken names it, as the list of the data sets
# of a Monte Carlo study does.
stage() {
    local source file name before=0 names="$2.names"
    source="$(dirname "$1")"
    mkdir -p "$2"
    cp "$1" "$2/"
    for file in "$source"/*; do
        case "$file" in *.[iI][nN][pP] | *.[oO][uU][tT]) continue ;; esac
        if [[ -f "$file" ]]; then
            printf '%s\n' "${file##*/}"
        fi
    done >"$names"
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
            }' "$names" "$2"/* |
            while IFS= read -r name; do
                cp -n "$source/$name" "$2/"
            done
    done
    rm -f "$names"
}

# Run the editor on the file $2 with the commands that follow, and end it
# when it has not finished after a minute.
editor() {
    local file="$1"
    shift
    timeout 60 "$EDITOR_BIN" "${EDITOR_ARGS[@]}" \
        --cmd "let &runtimepath = '$(native_path "$REPO_DIR"),' . \$VIMRUNTIME" \
        --cmd 'filetype plugin indent on' "$@" "$(native_path "$file")" </dev/null >/dev/null 2>&1
}

# Format the input $1 in place with gq. The editor leaves with an error
# when the formatter of the plugin is not set or fails.
format_input() {
    editor "$1" -c 'setfiletype mplus-inp' \
        -c 'if &formatexpr !~# "^mplus#format#" | cquit | endif' \
        -c 'try | execute "normal gggqG" | catch | cquit | endtry' \
        -c 'wq!'
}

# Run the input $1 in a directory of its own below $WORK/$2 and print the
# status of the run. With "formatted" as $2 the input is formatted first,
# and the status is "unformatted" when that fails. The status is kept in a
# file with the seconds of the run, and a run that has one is not made
# again. A run that Mplus did not end with an output that is complete, and
# an editor that was ended after the machine slept, leave no status, and the
# status printed is "cut".
run_example() {
    local name dir start
    name="$(basename "$1" .inp)"
    dir="$WORK/$2/$name"
    if [[ ! -f "$dir/status" ]]; then
        rm -f "$dir/$name.inp" "$dir/$name.out" "$dir/tokens"
        stage "$1" "$dir"
        start=$SECONDS
        if [[ "$2" == formatted ]] && ! format_input "$dir/$name.inp"; then
            if ((SECONDS - start > 90)); then
                echo cut
                return 0
            fi
            echo "unformatted 0 0" >"$dir/time"
        else
            run_mplus "$dir" "$name.inp" "$dir/time" >/dev/null
            case "$(cut -d' ' -f1 "$dir/time")" in
            timeout) ;;
            0 | 1) complete_output "$dir/$name.out" || { echo cut; return 0; } ;;
            *) echo cut; return 0 ;;
            esac
        fi
        cut -d' ' -f1 "$dir/time" >"$dir/status"
    fi
    cat "$dir/status"
}

# Print the status and the seconds of the run of $1 in $WORK/$2.
timing() {
    local status seconds slept
    if [[ ! -f "$WORK/$2/$1/time" ]]; then
        printf '%s %s' "$2" "$(cat "$WORK/$2/$1/status")"
        return 0
    fi
    read -r status seconds slept <"$WORK/$2/$1/time"
    printf '%s %s %ss' "$2" "$status" "$seconds"
    if ((slept > 0)); then
        printf ' (slept %ss)' "$slept"
    fi
}

# Print the token verdict of the input $1, which compares its tokens as
# written and after gq. It is kept in a file, and it is empty when the
# editor did not give one.
tokens() {
    local file="$WORK/formatted/$1/tokens"
    if [[ ! -s "$file" ]]; then
        MPLUS_WRITTEN="$(native_path "$WORK/original/$1/$1.inp")" \
            MPLUS_FORMATTED="$(native_path "$WORK/formatted/$1/$1.inp")" \
            MPLUS_TOKEN_OUT="$(native_path "$file.tmp")" \
            timeout 60 "$EDITOR_BIN" "${EDITOR_ARGS[@]}" -S "$(native_path "$TEST_DIR/token-check.vim")" \
            </dev/null >/dev/null 2>&1 || true
        if [[ -s "$file.tmp" ]]; then
            mv "$file.tmp" "$file"
        else
            rm -f "$file.tmp"
            return 0
        fi
    fi
    cat "$file"
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

# Run the input $1 as written and formatted, compare the runs, write the
# verdict, and print it as a line of the report. An input whose run was cut
# gets no verdict, and the line tells that it runs again at the next start.
check() {
    local input="$1" name original formatted note="" problem="" verdict token="" line
    name="$(basename "$input" .inp)"
    original="$(run_example "$input" original)"
    formatted="$(run_example "$input" formatted)"
    if [[ "$original" == cut || "$formatted" == cut ]]; then
        echo "[AGAIN] $name: a run was cut off, it runs again at the next start"
        return 0
    fi
    if [[ "$formatted" == unformatted ]]; then
        problem="the editor did not format the input"
    elif [[ ! -f "$WORK/original/$name/$name.out" || ! -f "$WORK/formatted/$name/$name.out" ]]; then
        problem="no output file"
    elif [[ "$original" == timeout || "$formatted" == timeout ]]; then
        token="$(tokens "$name")"
        if [[ -z "$token" ]]; then
            echo "[AGAIN] $name: the tokens were not compared, they are at the next start"
            return 0
        fi
        note=" (over the time limit, messages compared, tokens $token)"
        if ! same "$name" messages; then
            problem="the messages about the input differ"
        fi
    elif [[ "$original" != "$formatted" ]]; then
        problem="exit status $original as written, $formatted when formatted"
    elif ! same "$name" below_echo; then
        problem="the output differs (compare $name/$name.out in original/ and formatted/)"
    fi

    if [[ -z "$problem" ]]; then
        verdict=PASS
        line="[PASS] $name$note"
    elif tr -d '\r' <"$input" | LC_ALL=C grep -q '.\{91\}'; then
        verdict=SKIP
        line="[SKIP] $name: Mplus cut a line of the input, which is over 90 characters$note"
    else
        verdict=FAIL
        line="[FAIL] $name: $problem$note"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$verdict" "$name" "$(timing "$name" original)" \
        "$(timing "$name" formatted)" "${token:+tokens $token}" "$problem" \
        >"$WORK/verdicts/$name.tmp"
    mv "$WORK/verdicts/$name.tmp" "$WORK/verdicts/$name"
    echo "$line"
}

# The inputs that have no verdict yet are checked, $JOBS at a time, and
# each line of the report is written as soon as its input is done.
running=0
for input in "${FILES[@]}"; do
    if [[ -f "$WORK/verdicts/$(basename "$input" .inp)" ]]; then
        continue
    fi
    if ((JOBS > 1)); then
        check "$input" | tee -a "$LOGFILE" &
        running=$((running + 1))
        if ((running >= JOBS)); then
            wait -n || true
            running=$((running - 1))
        fi
    else
        check "$input" | tee -a "$LOGFILE"
    fi
done
wait

PASS=0
FAIL=0
SKIP=0
AGAIN=0
ERRORS=()
for input in "${FILES[@]}"; do
    name="$(basename "$input" .inp)"
    if [[ ! -f "$WORK/verdicts/$name" ]]; then
        AGAIN=$((AGAIN + 1))
        continue
    fi
    case "$(cut -f1 "$WORK/verdicts/$name")" in
    PASS) PASS=$((PASS + 1)) ;;
    SKIP) SKIP=$((SKIP + 1)) ;;
    *)
        FAIL=$((FAIL + 1))
        ERRORS+=("$name")
        ;;
    esac
done

report "---"
report "Summary: $PASS/$TOTAL passed, $FAIL/$TOTAL failed, $SKIP/$TOTAL skipped,\
 $AGAIN/$TOTAL without a verdict"
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    report ""
    report "Failed inputs:"
    for name in "${ERRORS[@]}"; do
        report "  $name"
    done
fi

echo ""
echo "Verdicts in: $WORK/verdicts"
echo "Log written to: $LOGFILE"

exit $((FAIL + AGAIN))
