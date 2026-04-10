#!/usr/bin/env bash
# stata-lint.sh — PreToolUse hook for Edit|Write
# Warns on common Stata .do file mistakes. Does NOT block (exit 0 always).
# Compatible with clo-author's protect-files.sh pattern.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input JSON
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/"file_path"\s*:\s*"//;s/"$//' 2>/dev/null || true)

# Only lint .do files
if [[ ! "$FILE_PATH" =~ \.do$ ]]; then
  exit 0
fi

# Extract content to check (new_string for Edit, content for Write)
CONTENT=$(echo "$INPUT" | grep -oP '"(?:new_string|content)"\s*:\s*"[^"]*"' | head -1 | sed 's/"(?:new_string|content)"\s*:\s*"//;s/"$//' 2>/dev/null || true)

# If we can't extract content, try reading the whole input as content
if [ -z "$CONTENT" ]; then
  CONTENT="$INPUT"
fi

WARNINGS=""

# Check 1: Comparison operators without missing value check
# Look for patterns like: if var > NUM, if var >= NUM, if var < NUM (without nearby !missing)
if echo "$CONTENT" | grep -qP '\bif\b.*[><]=?\s*\d' 2>/dev/null; then
  if ! echo "$CONTENT" | grep -qP '!missing|\.==\.' 2>/dev/null; then
    WARNINGS="${WARNINGS}WARNING [stata-lint]: Numeric comparison without !missing() check. Missing values are +infinity in Stata — 'if x > 100' includes missing. Add '& !missing(x)'.
"
  fi
fi

# Check 2: merge without _merge check
if echo "$CONTENT" | grep -qP '^\s*merge\s' 2>/dev/null; then
  if ! echo "$CONTENT" | grep -qP 'tab\s+_merge|assert\s+_merge|_merge\s*[!=<>]' 2>/dev/null; then
    WARNINGS="${WARNINGS}WARNING [stata-lint]: merge without _merge check. Always 'tab _merge' and handle unmatched observations after merge.
"
  fi
fi

# Check 3: Single = in if conditions (should be ==)
if echo "$CONTENT" | grep -qP '\bif\b[^=]*[^!=<>]=[^=]' 2>/dev/null; then
  WARNINGS="${WARNINGS}WARNING [stata-lint]: Possible '=' instead of '==' in if condition. Use '==' for comparison, '=' for assignment.
"
fi

# Check 4: Bare 'by' without sort (should be bysort)
if echo "$CONTENT" | grep -qP '^\s*by\s+\w+\s*:' 2>/dev/null; then
  if ! echo "$CONTENT" | grep -qP '^\s*sort\s' 2>/dev/null; then
    WARNINGS="${WARNINGS}WARNING [stata-lint]: 'by var:' without prior sort. Use 'bysort var:' to sort automatically.
"
  fi
fi

# Check 5: Global macro syntax where local was likely intended
if echo "$CONTENT" | grep -qP '\$[a-z][a-z_]*\b' 2>/dev/null; then
  if echo "$CONTENT" | grep -qP '^\s*local\s' 2>/dev/null; then
    WARNINGS="${WARNINGS}WARNING [stata-lint]: Using \$name with local macros defined. Local macros use backtick-quote: \`name'. Globals use \$name.
"
  fi
fi

# Output warnings to stderr (visible in Claude's context)
if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS" >&2
fi

# Always exit 0 — warn, don't block
exit 0
