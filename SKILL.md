---
name: stata
description: "Working with Stata in CLI and do-file environments. Use this skill whenever the user mentions Stata, .do files, .dta files, .ado files, reghdfe, esttab, or any Stata command — even casually. Also trigger when the user asks to run regressions, clean data, or produce tables and the project context suggests Stata is the tool (e.g., existing .do files in the repo). Covers: invoking Stata from the terminal, writing and running do-files, reading Stata documentation PDFs efficiently, and integrating with existing project pipelines. If the user references Stata at all, use this skill."
---

# Stata Skill — CLI Execution, Do-Files, and Documentation

## Environment Auto-Detection

Stata is detected automatically. The skill searches these locations in order:

```bash
# The first match wins:
which stata-mp || which stata-se || which stata          # PATH lookup
"/c/Program Files/StataNow19/StataMP-64.exe"             # Windows (Git Bash)
"/c/Program Files/Stata19/StataMP-64.exe"                 # Windows alternate
"/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp" # macOS
"/usr/local/stata/stata-mp"                               # Linux
```

If none found, ask the user for their Stata installation path. Run `test-stata.sh` (in this skill's root) to verify detection.

## Running Stata — Two Options

### Option A: MCP-Stata (interactive, preferred when available)

If the `stata` MCP server is running, use it directly — no `.do` files or `.bat` wrappers needed:
```
run_command("regress price mpg weight, robust")    // instant result as JSON
get_stored_results()                                // r()/e() as structured data
describe()                                          // variable metadata
get_data(start=0, count=10)                         // browse rows
export_graph(format="png")                          // save graphs
```
- **Persistent session:** data stays loaded between commands, no Stata restart overhead
- **Structured output:** JSON results, no log parsing needed
- **Lower token cost:** ~80-350 tokens/interaction vs ~200-700 for batch mode
- See `reference/mcp-stata.md` for all 22 tools

### Option B: Batch mode (always available, no extra setup)

**Windows/Git Bash** — MUST use a temp `.bat` file. MSYS translates `/e` → `E:/` which breaks Stata.
```bash
WIN_BIN=$(cygpath -w "$STATA_BIN")
WIN_DO=$(cygpath -w "path/to/myfile.do")
WIN_DIR=$(cygpath -w "$(pwd)")
# Write temp .bat — runs in native cmd.exe, no MSYS mangling
cat > /tmp/_run.bat << BATEOF
@echo off
cd /d "$WIN_DIR"
"$WIN_BIN" /e do "$WIN_DO"
BATEOF
cmd //c "$(cygpath -w /tmp/_run.bat)"
rm /tmp/_run.bat
cat myfile.log    # Stata writes .log to CWD, not next to .do file
```

**macOS/Linux:**
```bash
"$STATA_BIN" -b do "path/to/myfile.do"
cat myfile.log
```

Key facts:
- **Log location:** Stata writes `.log` to the **current working directory**, not next to the `.do` file
- If do-file errors, Stata still exits — check `.log` for `r(...)` error codes
- No graph windows in batch mode — use `graph export` to save figures

### Quick one-liner
```bash
echo 'use "mydata.dta", clear
describe
summarize' > /tmp/quick_check.do

# Windows Git Bash:
cat > /tmp/_run.bat << BATEOF
@echo off
cd /d "$(cygpath -w /tmp)"
"$(cygpath -w "$STATA_BIN")" /e do "$(cygpath -w /tmp/quick_check.do)"
BATEOF
cmd //c "$(cygpath -w /tmp/_run.bat)" && cat /tmp/quick_check.log

# macOS/Linux:
# (cd /tmp && "$STATA_BIN" -b do quick_check.do) && cat /tmp/quick_check.log
```

## Top-5 Gotchas (Always Remember)

1. **Missing = +infinity:** `x > 100` includes missing. Always add `& !missing(x)`
2. **`==` for comparison:** `=` is assignment. `if status = 1` is WRONG → `if status == 1`
3. **Check `_merge`:** After `merge`, always `tab _merge` before proceeding
4. **Use `bysort`:** Bare `by var:` errors if not pre-sorted → `bysort var:`
5. **Local macro syntax:** `` `name' `` (backtick + single-quote), NOT `$name`

For all 15+ gotchas with code examples: **read `reference/gotchas.md`**

## Do-File Template

```stata
/*==============================================================================
 [NN]_[description].do
 Purpose:  [What this script does]
 Input:    [What datasets/files it reads]
 Output:   [What datasets/files it creates]
 Author:   [Author name]
 Date:     [YYYY-MM-DD]
==============================================================================*/

// --- Bootstrap (standalone execution support) ---
capture log close
if "$RB" == "" {
    do "[path/to]/code/master/paths.do"
    do "[path/to]/code/master/globals.do"
}
log using "$OUTPUT/logs/[NN]_[description].log", replace

// --- Main code ---
// [Your code here]

// --- Cleanup ---
log close
```

## Coding Conventions

- **Regressions:** `reghdfe depvar treatvar, absorb(unit_id year) vce(cluster unit_id)`
- **Tables:** `esttab` to export `.tex` — follow existing project patterns
- **Variable names:** `snake_case`
- **Estimate store names:** ≤32 characters (hard limit)
- **Data safety:** `preserve`/`restore`; `tempvar`/`tempfile` for temporaries
- **Validation:** `assert` for data integrity (panel balance, expected row counts)
- **String conversion:** Replace `"NA"` → `""` before `destring`

## Routing Table — Read On Demand

Only load 1-2 reference files per task. All paths relative to this skill's directory.

| Task | Read This File |
|------|---------------|
| Missing values, common bugs | `reference/gotchas.md` |
| merge, reshape, collapse, append | `reference/data-management.md` |
| reghdfe, IV, margins, post-estimation | `reference/regression.md` |
| xtreg, panel diagnostics, xtset | `reference/panel-data.md` |
| DiD, TWFE, csdid, event studies | `reference/did-event-study.md` |
| esttab, estout, etable, LaTeX tables | `reference/tables-output.md` |
| graph twoway, schemes, export | `reference/graphics.md` |
| macros, loops, programs, Mata | `reference/programming.md` |
| psmatch2, ivreg2, teffects | `reference/matching-iv.md` |
| Stata PDF docs, pdfgrep, cheap-scan1 | `reference/documentation.md` |
| MCP server (interactive Stata) | `reference/mcp-stata.md` |

### Technique Guides (end-to-end workflows)

| Workflow | Read This File |
|----------|---------------|
| Full DiD/IV/matching analysis | `technique-guides/core-econometrics.md` |
| Data cleaning pipeline | `technique-guides/data-prep.md` |
| margins, coefplot, esttab workflow | `technique-guides/postestimation-reporting.md` |
| Placebo, permutation, alt specs | `technique-guides/robustness-sensitivity.md` |
| Reproducibility, logging, assertions | `technique-guides/best-practices.md` |

## Escalation Protocol

1. **FIRST ATTEMPT:** Use the routing table to read 1-2 reference files
2. **IF DO-FILE FAILS:** Read `reference/gotchas.md` — check code against all 15 pitfalls
3. **IF METHOD IS WRONG:** Read the relevant `technique-guides/*.md` for end-to-end workflow
4. **IF STILL STUCK:** Search Stata PDF docs with pdfgrep (see `reference/documentation.md`)
5. **IF REFERENCE GAP:** Log to `UPGRADE_LOG.md`:
   ```
   ## [date] — [topic] — [what was missing] — [suggested addition]
   ```

## Stata Phase Protocol (for clo-author integration)

When working inside a clo-author project with the adversarial agent system:

- **Phase 0 (Design):** Handled by strategist. No Stata-specific action.
- **Phase 1 (Data):** data-engineer loads/inspects data. Read `reference/data-management.md`.
- **Phase 2 (Specification):** Coder writes estimating equation. Read relevant reference file. Submit to coder-critic BEFORE running estimation.
- **Phase 3 (Analysis):** Implement specification. Read `technique-guides/core-econometrics.md` if needed.
- **Phase 4 (Robustness):** Read `technique-guides/robustness-sensitivity.md`. Implement all checks from strategy memo.
- **Phase 5 (Output):** Read `reference/tables-output.md`. Produce publication-ready tables/figures.

Each phase flows through coder → coder-critic automatically. Pass `--deliberate` to pause between phases for user input.

## Integration Notes

This skill is **user-level** — available in every Claude Code session. Projects may also have project-level overrides in `.claude/skills/stata/` with project-specific conventions. When both exist, defer to project-level for project conventions; use this for general Stata knowledge.
