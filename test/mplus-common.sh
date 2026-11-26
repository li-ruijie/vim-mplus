# Functions for the test scripts that run Mplus. This file is sourced.

# Set MPLUS to the Mplus executable and return 0, or return 1 when there is
# none. The value of MPLUS in the environment is taken first, then mplus on
# the PATH, then the place where Scoop installs Mplus on Windows, which is
# below the directory named by SCOOP_GLOBAL.
find_mplus() {
    local candidate
    if [[ -n "${MPLUS:-}" ]]; then
        if [[ ! -x "$MPLUS" ]]; then
            echo "ERROR: MPLUS is set to $MPLUS, which is no executable file"
            exit 1
        fi
        return 0
    fi
    for candidate in "$(command -v mplus 2>/dev/null || true)" \
        "${SCOOP_GLOBAL:-/d/Env/scoop/global}/apps/mplus/current/mplus.exe"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            MPLUS="$candidate"
            return 0
        fi
    done
    return 1
}

# End the Mplus run of the input $2, which was started as process $1. The
# further processes that Mplus starts for an analysis with PROCESSORS = 2
# are no children of that process on Windows, so every Mplus process with
# the name of the input on its command line is ended there. The name has to
# stand there as a word of its own, so that the run of ex9.33.inp does not
# end that of mcex9.33.inp beside it. PowerShell reads the commands from its
# standard input, where a command that runs over several lines is carried
# out at the blank line after it.
end_mplus() {
    if command -v powershell >/dev/null 2>&1; then
        MPLUS_IMAGE="$(basename "$MPLUS")" MPLUS_INPUT="$2" \
            powershell -NoProfile -Command - >/dev/null 2>&1 <<'END' || true
$name = '(^|[\s"\\/])' + [regex]::Escape($env:MPLUS_INPUT) + '($|[\s"])'
Get-CimInstance Win32_Process -Filter "Name='$env:MPLUS_IMAGE'" |
    Where-Object { $_.CommandLine -match $name } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

END
    else
        pkill -P "$1" 2>/dev/null || true
        kill "$1" 2>/dev/null || true
    fi
}

# Run Mplus on the input $2 in the directory $1 and print its exit status,
# or "timeout" when it has run for MPLUS_TIME_LIMIT seconds (60 by default)
# without finishing. Mplus writes its output next to the input. With a file
# name as $3, the status, the seconds that Mplus ran, and the seconds that
# the machine slept during the run are written to that file.
#
# The time in which the machine slept does not count. The run is looked at
# every 0.2 seconds, and a look that comes more than 30 seconds after the
# one before shows that the machine slept in between, as Mplus waits while
# it sleeps.
#
# A run that is over its time is ended with all its processes, so that none
# is left to disturb the next run. Several runs side by side reported errors
# in inputs that are sound, so run-tests.sh runs one at a time by default.
run_mplus() {
    local pid status=0 start=$SECONDS last=$SECONDS slept=0 ran
    (cd "$1" && exec "$MPLUS" "$2" </dev/null >/dev/null 2>&1) &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        if ((SECONDS - last > 30)); then
            slept=$((slept + SECONDS - last))
        fi
        last=$SECONDS
        if ((SECONDS - start - slept >= ${MPLUS_TIME_LIMIT:-60})); then
            ran=$((SECONDS - start - slept))
            end_mplus "$pid" "$2"
            status=timeout
            break
        fi
        sleep 0.2
    done
    if [[ "$status" == timeout ]]; then
        wait "$pid" 2>/dev/null || true
    else
        wait "$pid" || status=$?
    fi
    if [[ -n "${3:-}" ]]; then
        echo "$status ${ran:-$((SECONDS - start - slept))} $slept" >"$3"
    fi
    echo "$status"
}

# Tell whether the Mplus output $1 is complete. Mplus ends every output
# that it finishes, also one that stops at an error in the input, with its
# copyright line.
complete_output() {
    [[ -f "$1" ]] && [[ "$(tr -d '\r' <"$1" | grep . | tail -n 1)" == Copyright* ]]
}

# Print the lines of the Mplus output $1 that follow the echoed input,
# without the carriage returns, the blank lines, and the lines that give a
# time. The echoed input is indented, and it ends at the first line that is
# not.
below_echo() {
    tr -d '\r' <"$1" | awk '
        echo == 0 { if ($0 == "INPUT INSTRUCTIONS") echo = 1; next }
        echo == 1 && /^[^ \t]/ { echo = 2 }
        echo == 2 && NF && !/Time:/ { print }'
}
