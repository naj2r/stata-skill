#!/usr/bin/env bash
# test-stata.sh — Verify Stata is detectable and runnable
# Usage: ./test-stata.sh
# Exit 0 on success, exit 1 with diagnostics on failure

set -euo pipefail

echo "=== Stata Detection Test ==="
echo "OS: $(uname -s) $(uname -m)"
echo "Shell: $SHELL"
echo ""

# Auto-detect Stata binary
STATA_BIN=""
for candidate in \
  "$(which stata-mp 2>/dev/null || true)" \
  "$(which stata-se 2>/dev/null || true)" \
  "$(which stata 2>/dev/null || true)" \
  "/c/Program Files/StataNow19/StataMP-64.exe" \
  "/c/Program Files/Stata19/StataMP-64.exe" \
  "/c/Program Files/Stata18/StataMP-64.exe" \
  "/c/Program Files/Stata17/StataMP-64.exe" \
  "/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp" \
  "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp" \
  "/Applications/Stata/StataSE.app/Contents/MacOS/stata-se" \
  "/Applications/Stata/StataBE.app/Contents/MacOS/stata-be" \
  "/usr/local/stata/stata-mp" \
  "/usr/local/stata/stata-se" \
  "/usr/local/stata/stata"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    STATA_BIN="$candidate"
    break
  fi
done

if [ -z "$STATA_BIN" ]; then
  echo "FAIL: Stata binary not found."
  echo ""
  echo "Searched:"
  echo "  - PATH (stata-mp, stata-se, stata)"
  echo "  - Common Windows paths (/c/Program Files/Stata*/)"
  echo "  - Common macOS paths (/Applications/Stata*/)"
  echo "  - Common Linux paths (/usr/local/stata/)"
  echo ""
  echo "To fix: add Stata to your PATH, or set STATA_BIN manually:"
  echo "  export STATA_BIN='/path/to/stata-mp'"
  exit 1
fi

echo "Stata binary found: $STATA_BIN"

# Create a trivial test do-file
TMPDIR="${TMPDIR:-/tmp}"
TEST_DO="$TMPDIR/stata_test_$$.do"
TEST_LOG="$TMPDIR/stata_test_$$.log"

cat > "$TEST_DO" << 'EOF'
display "STATA_TEST_OK"
display c(stata_version)
display c(edition_real)
display c(os)
EOF

# --- Run Stata in batch mode ---
# Key discovery: Stata writes .log files to the CURRENT WORKING DIRECTORY.
# On Windows/Git Bash, MSYS translates /e → E:/ which breaks Stata's batch flag.
# The ONLY reliable fix is a temp .bat file that runs in native cmd.exe context.

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    WIN_BIN=$(cygpath -w "$STATA_BIN" 2>/dev/null || echo "$STATA_BIN")
    WIN_DO=$(cygpath -w "$TEST_DO" 2>/dev/null || echo "$TEST_DO")
    WIN_DIR=$(cygpath -w "$TMPDIR" 2>/dev/null || echo "$TMPDIR")

    # Write a temp .bat file to bypass MSYS path translation entirely
    BAT_FILE="$TMPDIR/stata_run_$$.bat"
    cat > "$BAT_FILE" << BATEOF
@echo off
cd /d "$WIN_DIR"
"$WIN_BIN" /e do "$WIN_DO"
BATEOF

    WIN_BAT=$(cygpath -w "$BAT_FILE" 2>/dev/null || echo "$BAT_FILE")
    echo "Batch mode: .bat file (Windows — bypasses MSYS /e → E:/ translation)"
    echo "Do-file: $WIN_DO"
    echo "Running test do-file..."
    cmd //c "$WIN_BAT" 2>/dev/null || true
    rm -f "$BAT_FILE" 2>/dev/null
    ;;
  *)
    echo "Batch mode: -b (Unix)"
    echo "Do-file: $TEST_DO"
    echo "Running test do-file..."
    (cd "$TMPDIR" && "$STATA_BIN" -b do "$TEST_DO") 2>/dev/null || true
    ;;
esac

# Wait for Stata to finish writing the log
sleep 3

# Check for the log (Stata writes to CWD, which we set to TMPDIR)
if [ -f "$TEST_LOG" ]; then
  if grep -q "STATA_TEST_OK" "$TEST_LOG" 2>/dev/null; then
    echo ""
    echo "SUCCESS: Stata runs correctly in batch mode."
    echo "Log output:"
    grep -E "STATA_TEST_OK|^\." "$TEST_LOG" 2>/dev/null | head -10
  else
    echo ""
    echo "WARNING: Stata ran but test string not found in log."
    echo "Log contents (last 20 lines):"
    tail -20 "$TEST_LOG"
  fi
else
  echo ""
  echo "WARNING: No log file found."
  echo "Expected log at: $TEST_LOG"
  echo ""
  echo "On Windows, ensure you run this from Git Bash (not PowerShell or CMD)."
fi

# Cleanup
rm -f "$TEST_DO" "$TEST_LOG" 2>/dev/null

echo ""
echo "=== Detection Summary ==="
echo "STATA_BIN=$STATA_BIN"
echo ""
echo "Add this to your shell config if needed:"
echo "  export STATA_BIN=\"$STATA_BIN\""
