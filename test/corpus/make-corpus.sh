#!/usr/bin/env bash
# Make a corpus of Mplus outputs for the tests of the output syntax.
# Usage: test/corpus/make-corpus.sh CACHE_DIR [--all-examples] [--only REGEX]
#
# Two sets of runs are made below CACHE_DIR, each run in a directory of its
# own with the data that its input names.
#
#   all-options  example inputs with their OUTPUT command replaced by every
#                option that Mplus takes (an OUTPUT command is added where
#                the input has none), so that the outputs show the parts,
#                tables, and warnings that the shipped outputs lack. These
#                are the inputs ex*.inp and ten of the Monte Carlo inputs
#                mcex*.inp (MONTE_CARLO in corpus.py), whose outputs change
#                little with more options. --all-examples takes every input.
#   failures     the inputs of test/corpus/failures/, which make Mplus
#                print the messages of a failed or doubtful estimation and
#                of bad input
#
# Where Mplus stops at an OUTPUT option (MODINDICES with a mixture model),
# the input is run again without it, and the run before is kept as
# <name>-try<n>.out. A run that is over the time limit is not made again.
#
# An input that has a record (run.json in its directory) is not run again,
# so a second call takes up where the first stopped. Delete the record by
# name to run the input again. With --only, only the inputs whose set and
# name ("all-options/chapter07/ex7.1.inp", "failures/noconv-ml.inp") match
# the Python regular expression REGEX are run. At the end the script writes
# CACHE_DIR/manifest.tsv, a line for each run of Mplus (the input, the
# options added, the exit status, the seconds, and whether the run was over
# the time limit) and a line for each example that the set leaves out. When
# every input has a record and no --only was given, it also writes the empty
# file CACHE_DIR/DONE. It writes nothing outside CACHE_DIR, and Mplus is
# given a scratch directory inside the run directory.
#
# The script is skipped when Mplus is not found. It reads these variables.
#
#   MPLUS             the Mplus executable, found as in run-tests.sh
#   MPLUS_EXAMPLES    the directory with the example inputs and their data,
#                     searched with every directory below it. The default is
#                     the directory examples beside the executable.
#   MPLUS_TIME_LIMIT  the seconds that one run may take, 60 by default. A run
#                     that takes longer is ended with all its processes.
#   MPLUS_JOBS        the runs made side by side, 3 by default
#   PYTHON            Python 3, by default python3 or python on the PATH

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=test/mplus-common.sh
source "$TEST_DIR/mplus-common.sh"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 CACHE_DIR [--only REGEX]"
    exit 1
fi
if ! find_mplus; then
    echo "SKIP: Mplus was not found. Set MPLUS to the Mplus executable."
    exit 0
fi
PYTHON="${PYTHON:-$(command -v python3 || command -v python || true)}"
if [[ -z "$PYTHON" ]]; then
    echo "ERROR: Python 3 was not found. Set PYTHON to the interpreter."
    exit 1
fi
EXAMPLES="${MPLUS_EXAMPLES:-$(dirname "$MPLUS")/examples}"

# A native Windows Python needs Windows paths.
native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s\n' "$1"
    fi
}

CACHE="$1"
shift
mkdir -p "$CACHE"
# The paths are native already. MSYS would also rewrite a REGEX that starts
# with a slash into a Windows path.
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
    exec "$PYTHON" -I -B "$(native_path "$TEST_DIR/corpus/corpus.py")" \
    --mplus "$(native_path "$MPLUS")" --examples "$(native_path "$EXAMPLES")" \
    --time-limit "${MPLUS_TIME_LIMIT:-60}" --jobs "${MPLUS_JOBS:-3}" \
    "$@" "$(native_path "$CACHE")"
