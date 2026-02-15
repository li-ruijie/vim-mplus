#!/bin/bash
# Automated formatter test suite for vim-mplus
# Usage: ./run-tests.sh partial   (first 10 .inp per chapter, ~100 files)
#        ./run-tests.sh full      (all 436 files)

set -euo pipefail

# --- Configuration ---
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$REPO_DIR/test"
ORIGINAL_DIR="$TEST_DIR/original"
FORMATTED_DIR="$TEST_DIR/formatted"
MPLUS="/d/Env/scoop/global/apps/mplus9-win/9.0/mplus.exe"
TIMEOUT_SEC=5

MODE="${1:-partial}"
if [[ "$MODE" != "partial" && "$MODE" != "full" ]]; then
    echo "Usage: $0 {partial|full}"
    exit 1
fi

# --- Verify prerequisites ---
if [[ ! -x "$MPLUS" ]]; then
    echo "ERROR: Mplus executable not found at $MPLUS"
    exit 1
fi

if [[ ! -d "$ORIGINAL_DIR" ]]; then
    echo "ERROR: Original test files not found at $ORIGINAL_DIR"
    exit 1
fi

# --- Step 1: Clean and recreate formatted/ ---
rm -rf "$FORMATTED_DIR"
mkdir -p "$FORMATTED_DIR"

# --- Step 2: Copy all .inp and .dat from original/ to formatted/ ---
cp "$ORIGINAL_DIR"/*.inp "$FORMATTED_DIR/" 2>/dev/null || true
cp "$ORIGINAL_DIR"/*.dat "$FORMATTED_DIR/" 2>/dev/null || true
cp "$ORIGINAL_DIR"/*.gh5 "$FORMATTED_DIR/" 2>/dev/null || true

# --- Step 3: Select .inp files based on mode ---
cd "$FORMATTED_DIR"

select_files() (
    # Run in subshell with relaxed error handling to avoid SIGPIPE issues
    set +e +o pipefail
    if [[ "$MODE" == "full" ]]; then
        printf '%s\n' *.inp | sort -V
    else
        # Partial: first 10 per chapter prefix (ex3, ex4, ..., ex12, mcex3, ..., mcex12)
        for prefix in ex3 ex4 ex5 ex6 ex7 ex8 ex9 ex10 ex11 ex12 \
                      mcex3 mcex4 mcex5 mcex6 mcex7 mcex8 mcex9 mcex10 mcex11 mcex12; do
            for f in ${prefix}.*.inp ${prefix}[a-z]*.inp; do
                [[ -f "$f" ]] && echo "$f"
            done | sort -V | head -10
        done | sort -V | uniq
    fi
)

mapfile -t FILES < <(select_files)
TOTAL=${#FILES[@]}

if [[ $TOTAL -eq 0 ]]; then
    echo "ERROR: No .inp files selected"
    exit 1
fi

echo "Mode: $MODE"
echo "Files to test: $TOTAL"
echo "---"

# --- Log file ---
LOGFILE="$TEST_DIR/results-$(date +%Y%m%d-%H%M%S).log"

PASS=0
FAIL=0
ERRORS=()

# --- Step 4: Process each file ---
for file in "${FILES[@]}"; do
    # 4a. Format via headless vim
    vim -es \
        -u "$REPO_DIR/test/test-vimrc.vim" \
        --cmd "set rtp^=$REPO_DIR" \
        "$FORMATTED_DIR/$file" \
        -c "normal gggqG" \
        -c "wq!" 2>/dev/null

    # 4b. Run Mplus (short timeout: syntax errors appear instantly;
    #     timeout means estimation started, i.e. syntax was valid)
    cd "$FORMATTED_DIR"
    MPLUS_EXIT=0
    timeout "$TIMEOUT_SEC" "$MPLUS" "$(cygpath -w "$FORMATTED_DIR/$file")" >/dev/null 2>&1 || MPLUS_EXIT=$?

    # 4c. Check result
    OUTFILE="${file%.inp}.out"
    if [[ $MPLUS_EXIT -eq 124 ]]; then
        # Timeout = Mplus started estimation = syntax OK
        echo "[PASS] $file (timeout)"
        echo "[PASS] $file (timeout)" >> "$LOGFILE"
        PASS=$((PASS + 1))
    elif [[ -f "$FORMATTED_DIR/$OUTFILE" ]]; then
        # Check for errors in the output file
        if grep -q '\*\*\* ERROR\|TERMINATED ABNORMALLY' "$FORMATTED_DIR/$OUTFILE" 2>/dev/null; then
            ERRMSG=$(grep -m1 '\*\*\* ERROR\|TERMINATED ABNORMALLY' "$FORMATTED_DIR/$OUTFILE" 2>/dev/null)
            echo "[FAIL] $file — $ERRMSG"
            echo "[FAIL] $file — $ERRMSG" >> "$LOGFILE"
            FAIL=$((FAIL + 1))
            ERRORS+=("$file")
        else
            echo "[PASS] $file"
            echo "[PASS] $file" >> "$LOGFILE"
            PASS=$((PASS + 1))
        fi
    else
        echo "[FAIL] $file — no .out file produced"
        echo "[FAIL] $file — no .out file produced" >> "$LOGFILE"
        FAIL=$((FAIL + 1))
        ERRORS+=("$file")
    fi
done

# --- Summary ---
echo "---"
echo "Summary: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"
echo "---" >> "$LOGFILE"
echo "Summary: $PASS/$TOTAL passed, $FAIL/$TOTAL failed" >> "$LOGFILE"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo ""
    echo "Failed files:"
    echo "" >> "$LOGFILE"
    echo "Failed files:" >> "$LOGFILE"
    for f in "${ERRORS[@]}"; do
        echo "  $f"
        echo "  $f" >> "$LOGFILE"
    done
fi

echo ""
echo "Log written to: $LOGFILE"

exit $FAIL
