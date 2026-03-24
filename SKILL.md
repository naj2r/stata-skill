---
name: stata
description: "Working with Stata in CLI and do-file environments. Use this skill whenever the user mentions Stata, .do files, .dta files, .ado files, reghdfe, esttab, or any Stata command — even casually. Also trigger when the user asks to run regressions, clean data, or produce tables and the project context suggests Stata is the tool (e.g., existing .do files in the repo). Covers: invoking Stata from the terminal, writing and running do-files, reading Stata documentation PDFs efficiently, and integrating with existing project pipelines. If the user references Stata at all, use this skill."
---

# Stata — CLI Execution, Do-Files, and Documentation

## What is Stata?

Stata is a statistical software package widely used in economics, political science, and public health for data management, regression analysis, and reproducible research pipelines. Most economists interact with Stata through its GUI, but for automation and integration with tools like Claude Code, command-line (batch) execution is essential.

## Environment: Nick's Setup

- **Stata version:** Stata/MP 19 (StataNow)
- **Executable:** `C:\Program Files\StataNow19\StataMP-64.exe`
- **Shell:** Git Bash on Windows (`.bashrc` has Stata on PATH)
- **Git Bash path:** `/c/Program Files/StataNow19/StataMP-64.exe`
- **Documentation PDFs:** `C:\Program Files\StataNow19\docs\` (37 manuals — see reference list below)

## Running Stata from the Command Line

### Batch mode (run a do-file, no GUI)

This is what you'll use most often. Stata runs the do-file and exits. Output goes to a `.log` file in the same directory as the do-file.

```bash
# From Git Bash:
"/c/Program Files/StataNow19/StataMP-64.exe" /e do "path/to/myfile.do"
```

The `/e` flag tells Stata to run in batch (execute) mode — no GUI window, just process and exit. Stata writes a log file (`myfile.log`) alongside the do-file automatically.

**Important details:**
- Stata's working directory defaults to where the do-file lives unless you `cd` inside the do-file
- If the do-file errors, Stata still exits — check the `.log` file for `r(...)` error codes
- Batch mode does NOT display graph windows; use `graph export` to save figures to disk

### Interactive console mode

```bash
# Opens Stata in console mode (text-only, no GUI):
"/c/Program Files/StataNow19/StataMP-64.exe" /q
```

The `/q` flag runs the console (quiet) version. Useful for quick checks but generally prefer batch mode for reproducibility.

### Quick one-liner pattern

For simple tasks (checking variable names, summarizing data), you can write a temporary do-file and run it:

```bash
echo 'use "mydata.dta", clear
describe
summarize' > /tmp/quick_check.do
"/c/Program Files/StataNow19/StataMP-64.exe" /e do "/tmp/quick_check.do"
cat /tmp/quick_check.log
```

## Writing Do-Files

### Standard template

Every do-file should follow this structure (adapted from the project-level stata-code skill):

```stata
/*==============================================================================
 [NN]_[description].do
 Purpose:  [What this script does]
 Input:    [What datasets/files it reads]
 Output:   [What datasets/files it creates]
 Author:   Nick Jensen
 Date:     [YYYY-MM-DD]
==============================================================================*/

// --- Bootstrap (allows standalone execution) ---
capture log close
if "$RB" == "" {
    do "[absolute/path/to]/code/master/paths.do"
    do "[absolute/path/to]/code/master/globals.do"
}
log using "$OUTPUT/logs/[NN]_[description].log", replace

// --- Main code ---

// [Your code here]

// --- Cleanup ---
log close
```

The bootstrap preamble is important: it means the do-file works whether run from the master pipeline or standalone from the CLI.

### Coding conventions

- **Regressions:** Use `reghdfe` for two-way fixed effects: `reghdfe depvar treatvar, absorb(unit_id year) vce(cluster unit_id)`
- **Tables:** Use `esttab` to export to `.tex`: follow the formatting pattern in existing project do-files
- **Variable names:** `snake_case` (e.g., `treatment_var`, `outcome_var`)
- **Estimate store names:** ≤32 characters (Stata hard limit)
- **Data safety:** Use `preserve`/`restore` to protect data in memory
- **Validation:** Include `assert` statements for data integrity (panel balance, expected row counts, treatment identities)
- **Temp objects:** Always use `tempvar`/`tempfile` — never leave temporary objects behind
- **String conversion:** When importing data with `"NA"` strings, replace to `""` before `destring`
- **Group operations:** `egen` for group stats, `bysort` for within-group processing

### Output paths (project convention)

When working within a project that has `paths.do` and `globals.do`:
- Tables for paper: `$TABLES/$TABLE_SUB/`
- Raw data: `$DATA_RAW/`
- Final data: `$DATA/`
- Logs: `$OUTPUT/logs/`
- Figures: `$OUTPUT/figures/`

If the project doesn't have these globals, ask the user about their directory structure.

## Stata Documentation (PDFs)

Stata ships with extensive PDF documentation at `C:\Program Files\StataNow19\docs\`. These are large PDFs (some 30+ MB) — do NOT read them directly into context. Instead, use token-efficient extraction tools.

### Available manuals

| File | Topic | Size |
|------|-------|------|
| `r.pdf` | Estimation/regression commands (largest manual) | 30 MB |
| `bayes.pdf` | Bayesian analysis | 19 MB |
| `gsm.pdf` | Getting Started (Mac) | 19 MB |
| `g.pdf` | Graphics reference | 19 MB |
| `gsu.pdf` | Getting Started (Unix) | 13 MB |
| `gsw.pdf` | Getting Started (Windows) | 13 MB |
| `xt.pdf` | Panel data / longitudinal (xt commands) | 12 MB |
| `rpt.pdf` | Reporting and tables | 9 MB |
| `me.pdf` | Marginal effects, margins, contrasts | 9 MB |
| `pss.pdf` | Power, sample size, precision | 8 MB |
| `st.pdf` | Survival analysis | 8 MB |
| `ts.pdf` | Time series | 8 MB |
| `d.pdf` | Data management commands | 8 MB |
| `mv.pdf` | Multivariate statistics | 7 MB |
| `causal.pdf` | Causal inference (DID, treatment effects) | 7 MB |
| `adapt.pdf` | Adaptive designs | 5 MB |
| `h2oml.pdf` | Machine learning (H2O integration) | 5 MB |
| `tables.pdf` | Tables command reference | 5 MB |
| `sem.pdf` | Structural equation modeling | 5 MB |
| `sp.pdf` | Spatial analysis | 5 MB |
| `m.pdf` | Mata programming language | 5 MB |
| `i.pdf` | Base reference (index) | 6 MB |
| `p.pdf` | Programming reference | 4 MB |
| `irt.pdf` | Item response theory | 4 MB |
| `meta.pdf` | Meta-analysis | 5 MB |
| `lasso.pdf` | LASSO and elastic net | 3 MB |
| `u.pdf` | User's Guide (core concepts) | 4 MB |
| `mi.pdf` | Multiple imputation | 3 MB |
| `erm.pdf` | Extended regression models | 3 MB |
| `cm.pdf` | Choice models | 3 MB |
| `bma.pdf` | Bayesian model averaging | 3 MB |
| `dsge.pdf` | Dynamic stochastic general equilibrium | 3 MB |
| `fn.pdf` | Functions reference | 3 MB |
| `svy.pdf` | Survey data | 3 MB |
| `ig.pdf` | Glossary and index | 2 MB |
| `fmm.pdf` | Finite mixture models | 2 MB |
| `stoc.pdf` | Stochastic frontier | 2 MB |

### How to read Stata docs efficiently

These PDFs are too large to read directly — they'll burn tokens or crash context. Use these approaches in order of preference:

#### Option 1: cheap-scan1 (best for deep reading)

If the project has the `cheap-scan1` skill available (check `.claude/skills/cheap-scan1/`), use it. It extracts text locally with pymupdf (zero tokens), triages relevance, and only sends relevant sections to the LLM. This is by far the most token-efficient approach for understanding a Stata manual section.

```bash
# Extract and process a specific Stata manual
python ".claude/skills/cheap-scan1/extract_pdf.py" "/c/Program Files/StataNow19/docs/xt.pdf" "./stata_docs/scanned_xt/"
```

Then follow the cheap-scan1 protocol for staged reading.

#### Option 2: split-pdf (fallback for scanned PDFs)

If cheap-scan1 reports the PDF is a scanned image (unlikely for Stata docs, but possible), fall back to split-pdf which reads via vision in 4-page chunks:

```python
# Split into manageable chunks
from PyPDF2 import PdfReader, PdfWriter
# (see split-pdf skill for full script)
```

#### Option 3: Direct targeted search with pdfgrep/pdftotext

For quick command lookups when you know what you're looking for:

```bash
# Search for a specific command across all Stata docs
pdftotext "/c/Program Files/StataNow19/docs/r.pdf" - | grep -i "reghdfe" -A 5

# Or use pdfgrep if installed
pdfgrep -i "margins" "/c/Program Files/StataNow19/docs/me.pdf" | head -20
```

#### Which manual to check

For applied microeconometrics work, the most commonly needed manuals are:

- **`r.pdf`** — All estimation commands (reg, ivregress, probit, logit, etc.)
- **`xt.pdf`** — Panel data: xtreg, xtlogit, xtpoisson, xtdidregress
- **`causal.pdf`** — DID, treatment effects, inverse probability weighting
- **`d.pdf`** — Data management: merge, reshape, collapse, encode
- **`me.pdf`** — margins, marginsplot, contrasts
- **`tables.pdf`** — collect, table, etable (Stata 17+ table system)
- **`u.pdf`** — Core concepts (estimation postcommands, factor variables, etc.)
- **`p.pdf`** — Programming: macros, loops, programs, mata

## Integration Notes

This skill is scoped at the **user level** — it's available in every Claude Code session regardless of project. Individual projects may also have a project-level `stata-code` skill (in `.claude/skills/stata-code/`) with project-specific conventions (path globals, pipeline numbering, specific table formats). When both exist, defer to the project-level skill for project-specific conventions and use this skill for general Stata knowledge, CLI invocation, and documentation lookup.
