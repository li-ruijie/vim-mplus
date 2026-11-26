#!/usr/bin/env bash
# Run the slow examples of test/slow-examples.txt through run-tests.sh with
# a longer time limit, so that Mplus can finish them.
# Usage: ./run-slow.sh [-t SECONDS] [-j RUNS] [-n FILE] DIR
#
#   -t SECONDS  the seconds that one run of Mplus may take, 600 by default
#   -j RUNS     the number of examples run side by side, 2 by default
#   -n FILE     the list of examples, test/slow-examples.txt by default
#   DIR         the directory for the runs, the verdicts, and the log
#
# The verdict of an example is written to DIR/verdicts/<name> as soon as it
# is done. The script can be ended at any time and started again with the
# same DIR, and it then runs only the examples that have no verdict. The
# time in which the machine sleeps does not count toward the limit, and a
# run that was cut off is run again at the next start. MPLUS_EXAMPLES names
# the directory of the examples, as for run-tests.sh.

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
LIMIT=600
JOBS=2
LIST="$TEST_DIR/slow-examples.txt"
while getopts t:j:n: option; do
    case "$option" in
    t) LIMIT="$OPTARG" ;;
    j) JOBS="$OPTARG" ;;
    n) LIST="$OPTARG" ;;
    *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-t SECONDS] [-j RUNS] [-n FILE] DIR"
    exit 1
fi
mkdir -p "$1"
exec "$TEST_DIR/run-tests.sh" -t "$LIMIT" -j "$JOBS" -r "$1" -n "$LIST" full
