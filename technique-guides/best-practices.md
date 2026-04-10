# Best Practices

Master do-file pattern, logging, version control for data, assertions, reproducibility, documentation.

---

## 1. Project Directory Structure

```
project/
  code/
    00_master.do           # Runs everything
    01_clean.do            # Import and clean
    02_analysis.do         # Main estimation
    03_robustness.do       # Robustness checks
    04_output.do           # Tables and figures
  data/
    raw/                   # Original data -- NEVER modify
    clean/                 # Analysis-ready datasets
    temp/                  # Intermediate files
  output/
    tables/                # RTF / CSV / TeX
    figures/               # PNG / PDF
  logs/                    # Log files from each script
```

---

## 2. Master Do-File (00_master.do)

```stata
* ===========================================================================
* Master Do-File: [Paper Title]
* Authors: [Names]
* Date: [Date]
* Purpose: Runs entire analysis from raw data to publication output
* ===========================================================================

version 15
clear all
set more off
set maxvar 10000
set seed 20240115

* ===========================================================================
* PATH SETUP -- Edit this block only when moving to a new machine
* ===========================================================================
global root "/path/to/project"

global code    "$root/code"
global raw     "$root/data/raw"
global clean   "$root/data/clean"
global temp    "$root/data/temp"
global tables  "$root/output/tables"
global figures "$root/output/figures"
global logs    "$root/logs"

* ===========================================================================
* EXECUTION
* ===========================================================================
log using "$logs/master_log.txt", text replace

display "=== Analysis started: $S_DATE $S_TIME ==="
display "Stata version: " c(stata_version)

do "$code/01_clean.do"          // Table 1
do "$code/02_analysis.do"       // Tables 2-3
do "$code/03_robustness.do"     // Table 4, Appendix Tables
do "$code/04_output.do"         // Figures 1-4

display "=== Analysis complete: $S_DATE $S_TIME ==="

log close
exit
```

**Key principles:**
- One root path. Every other path derives from it.
- Numbered scripts run in order. Comments map scripts to paper outputs.
- `set seed` at the top for any randomized procedure.
- `version 15` locks Stata behavior across versions.

---

## 3. Do-File Header Template

Every script should start with a documentation header.

```stata
* ===========================================================================
* Script:  02_analysis.do
* Project: [Paper Title]
* Purpose: Estimate main regression specifications (Tables 2-3)
* Input:   $clean/analysis_sample.dta
* Output:  $tables/table2_main.rtf
*          $tables/table3_heterogeneity.rtf
* Author:  [Name]
* Date:    [Date]
* ===========================================================================

clear all
set more off

log using "$logs/02_analysis.log", text replace

use "$clean/analysis_sample.dta", clear

* --- [analysis code here] ---

log close
```

---

## 4. Logging

### Start and stop logs

```stata
* Text log (human-readable, recommended)
log using "$logs/02_analysis.log", text replace

* SMCL log (Stata markup, preserves formatting)
log using "$logs/02_analysis.smcl", replace

* At end of script
log close
```

### Log everything

```stata
* Display key parameters in the log
display "=== Script: 02_analysis.do ==="
display "Date: $S_DATE  Time: $S_TIME"
display "Stata version: " c(stata_version)
display "Dataset: $clean/analysis_sample.dta"
display "N = " _N
```

---

## 5. Path Management

### Good: single root variable

```stata
global root "/Users/name/project"
global raw     "$root/data/raw"
global clean   "$root/data/clean"
global tables  "$root/output/tables"
global figures "$root/output/figures"
```

### Bad: hardcoded paths

```stata
* DO NOT DO THIS
use "/Users/name/Documents/project/data/raw/survey.dta"
```

### Portable across machines

```stata
* Option A: Each user changes one line in 00_master.do
global root "/path/to/project"

* Option B: Use a separate paths.do sourced by all scripts
* paths.do contains only global definitions
do "$code/paths.do"
```

---

## 6. Assertions for Data Integrity

### After every merge

```stata
merge m:1 state using "$raw/state_controls.dta"
tab _merge
assert _merge == 3     // all observations matched
drop _merge
```

### After sample construction

```stata
* Verify expected structure
isid id year                              // unique panel keys
assert _N > 0                             // dataset is not empty
assert treat == 0 | treat == 1            // binary treatment
assert !missing(outcome) if sample == 1   // no missing in analysis sample
assert year >= 2000 & year <= 2023        // expected time range
```

### After variable construction

```stata
gen ln_income = ln(income)
assert ln_income != . if income > 0 & !missing(income)

gen age_cat = irecode(age, 29, 49, 100)
assert inrange(age_cat, 0, 2) if !missing(age)
```

---

## 7. Version Control for Data

### Never modify raw data

```stata
* Raw data is read-only. All cleaning produces new files.
use "$raw/original_survey.dta", clear
* [cleaning steps]
save "$clean/survey_cleaned.dta", replace
```

### Label datasets with creation date

```stata
compress
label data "Analysis sample -- $S_DATE"
save "$clean/analysis_sample.dta", replace
```

### Document data lineage in headers

```stata
* Input:  $raw/survey2020.dta, $raw/census_controls.dta
* Output: $clean/analysis_sample.dta
```

---

## 8. Reproducibility Essentials

### Set seed for anything stochastic

```stata
set seed 12345

* Bootstrap
bootstrap _b, reps(500) seed(12345): reg y x1 x2

* Permutation test
ritest treat _b[treat], reps(1000) seed(12345): reg y treat, robust

* Wild cluster bootstrap
boottest treat, cluster(state) reps(999) seed(12345) nograph
```

### Lock Stata version

```stata
version 15   // at the top of every script
```

### Record environment

```stata
display "Stata version: " c(stata_version)
display "Date: " c(current_date)
display "Time: " c(current_time)
display "OS: " c(os)
display "Machine: " c(machine_type)
```

### Package management

```stata
* Document required packages in README or at top of master.do
* Install block (run once):
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install coefplot, replace
ssc install csdid, replace
ssc install boottest, replace
```

---

## 9. Coding Conventions

### Naming

```stata
* Variables: snake_case
gen log_income = ln(income)
gen first_treatment_year = .

* Globals: descriptive, prefixed by category
global raw     "$root/data/raw"
global controls "age education income"

* Locals: short-lived, scoped to do-file
local depvar "outcome"
local i = 1
```

### Temporary objects

```stata
* Use tempvar / tempfile to avoid polluting the dataset
tempvar tag
gen `tag' = (income > 50000)

tempfile subset
save `subset'
```

### Preserve / restore for safety

```stata
preserve
keep if year == 2020
collapse (mean) outcome, by(state)
save "$temp/state_means_2020.dta", replace
restore
```

### Line continuation

```stata
reghdfe outcome treat ///
    x1 x2 x3 x4 x5, ///
    absorb(id year) ///
    cluster(state)
```

### Comments

```stata
* Section header
*--- Data Cleaning ---*

* Inline explanation
gen ln_wage = ln(wage)   // log wages for semi-elasticity interpretation

/* Block comment for longer notes
   explaining a non-obvious decision */
```

---

## 10. Output File Naming

### Tables

```
table1_descriptives.rtf
table2_main_results.rtf
table3_robustness.rtf
table4_heterogeneity.rtf
tableA1_balance.rtf          // appendix
tableA2_first_stage.rtf
```

### Figures

```
figure1_event_study.png
figure2_coefplot.png
figure3_margins.png
figureA1_placebo.png         // appendix
```

### Map outputs in master.do

```stata
do "$code/02_analysis.do"    // Tables 2-3, Figure 1
do "$code/03_robustness.do"  // Table 4, Appendix Tables A1-A3
do "$code/04_output.do"      // Figures 2-4
```

---

## 11. Pre-Submission Checklist

### Code quality
- [ ] Master script runs from raw data to all outputs without errors
- [ ] All paths are relative (single root variable)
- [ ] Random seeds set and documented
- [ ] `version 15` (or appropriate version) at top of every script
- [ ] Every do-file has a header (purpose, input, output, author, date)

### Reproducibility
- [ ] Log files generated for every script
- [ ] Package list documented (with install commands)
- [ ] Intermediate datasets saved for debugging
- [ ] `set seed` before every stochastic command

### Data integrity
- [ ] Raw data never modified
- [ ] Every `merge` followed by `tab _merge` + assertion
- [ ] Sample sizes documented at each restriction step
- [ ] Missing value handling explicit (no silent drops)

### Output
- [ ] Table and figure files named to match paper
- [ ] Outputs map clearly to paper sections
- [ ] SEs and significance levels documented in table notes
- [ ] Figures at publication resolution (300+ DPI)

---

## Quick Reference

| Practice | Implementation |
|----------|---------------|
| Master do-file | `00_master.do` with numbered subscripts |
| Path setup | Single `global root`, everything derives |
| Logging | `log using "$logs/script.log", text replace` |
| Seed | `set seed 12345` at top of master |
| Version lock | `version 15` at top of every script |
| Merge check | `tab _merge` + `assert` after every merge |
| Data safety | `preserve`/`restore`, `tempvar`/`tempfile` |
| Assertions | `assert`, `isid`, `count` at key checkpoints |
| Do-file header | Purpose, input, output, author, date |
