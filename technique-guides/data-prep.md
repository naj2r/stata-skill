# Data Preparation

Cleaning pipeline: import, inspect, clean, construct variables, merge, validate, save. All code tested on Stata 15+.

---

## 1. Import

### CSV

```stata
import delimited "$raw/survey_data.csv", clear varnames(1)

* Force all columns as strings for safe cleaning
import delimited "$raw/messy_data.csv", clear varnames(1) stringcols(_all)
```

### Excel

```stata
import excel "$raw/data.xlsx", sheet("Sheet1") firstrow clear

* Specific cell range
import excel "$raw/data.xlsx", cellrange(A2:F100) firstrow clear
```

### Multiple files (loop + append)

```stata
clear
local files: dir "$raw/" files "*.csv"
local first = 1
foreach f of local files {
    if `first' == 1 {
        import delimited "$raw/`f'", clear varnames(1)
        local first = 0
    }
    else {
        preserve
        import delimited "$raw/`f'", clear varnames(1)
        tempfile temp
        save `temp'
        restore
        append using `temp'
    }
}
```

### Always save immediately after import

```stata
compress
save "$clean/data_imported.dta", replace
```

---

## 2. Inspect

```stata
describe
codebook, compact
summarize
misstable summarize
misstable patterns
tab varname, missing          // check missing patterns per variable
duplicates report id          // check uniqueness
isid id                       // assert unique -- fails if not
```

### Quick data profile

```stata
* Dimensions
display "Observations: " _N
display "Variables: " c(k)

* Key variable distributions
foreach var of varlist outcome treat income age {
    display _n "=== `var' ==="
    summarize `var', detail
}
```

---

## 3. Clean

### Destring safely

```stata
* Replace non-numeric strings BEFORE destring
replace income_str = "" if income_str == "NA" | income_str == "N/A" | income_str == "."
destring income_str, gen(income) force

* Check what was forced to missing
count if missing(income) & !missing(income_str)
```

### Recode missing values

```stata
* Standardize coded missings
recode satisfaction (-99 = .) (-88 = .d) (9999 = .r)
* .d = don't know, .r = refused

* CRITICAL: Stata treats missing as +infinity
* WRONG:  keep if income < 50000       -- drops missing too
* RIGHT:  keep if income < 50000 & !missing(income)
```

### String cleaning

```stata
* Trim whitespace and standardize case
replace name = strtrim(name)
replace name = strproper(name)
replace state = strupper(state)

* Encode string categoricals to numeric (preserves labels)
encode state_name, gen(state_id)

* Create numeric group IDs from strings
egen group_id = group(firm_name)
```

### Labeling

```stata
* Variable labels
label variable treat "Treatment indicator (1 = treated)"
label variable ln_income "Log household income"

* Value labels
label define yesno_lbl 0 "No" 1 "Yes"
label values treat yesno_lbl

* Label data
label data "Analysis sample, created $S_DATE"
```

---

## 4. Construct Variables

### Common transformations

```stata
* Log (handle zeros with IHS)
gen ln_income = ln(income)
gen ihs_income = asinh(income)       // inverse hyperbolic sine for zeros
gen ln_income_p1 = ln(income + 1)    // less preferred but common

* Standardize
egen z_income = std(income)

* Categorical bins
gen age_cat = 1 if age < 30
replace age_cat = 2 if age >= 30 & age < 50
replace age_cat = 3 if age >= 50 & !missing(age)
label define age_lbl 1 "Under 30" 2 "30-49" 3 "50+"
label values age_cat age_lbl
```

### Treatment timing variables

```stata
* First treatment year
gen treat_year = year if treatment == 1
bysort id: egen first_treat = min(treat_year)
drop treat_year

* Post-treatment indicator
gen post = (year >= first_treat) & !missing(first_treat)

* Relative time to treatment (for event studies)
gen rel_time = year - first_treat
```

### Winsorization

```stata
egen p1 = pctile(income), p(1)
egen p99 = pctile(income), p(99)
gen income_w = income
replace income_w = p1  if income < p1
replace income_w = p99 if income > p99 & !missing(income)
drop p1 p99
```

---

## 5. Merge

### Every merge gets a check

```stata
* Verify keys are unique in using data
use "$raw/state_controls.dta", clear
isid state_fips
use "$clean/individual_data.dta", clear

* Merge
merge m:1 state_fips using "$raw/state_controls.dta"

* REQUIRED: inspect merge results
tab _merge
count if _merge == 1   // master only
count if _merge == 2   // using only
count if _merge == 3   // matched

* Handle unmatched explicitly (document why)
assert _merge != 2     // or: drop if _merge == 2, with comment
drop _merge
```

### Merge patterns

```stata
merge 1:1 id using "file.dta"           // unique keys both sides
merge m:1 state using "state_data.dta"   // many individuals to one state
merge 1:m hh_id using "members.dta"      // one household to many members
```

### Append (stacking datasets)

```stata
use "$raw/wave1.dta", clear
gen wave = 1
append using "$raw/wave2.dta"
replace wave = 2 if missing(wave)
```

---

## 6. Reshape

### Wide to long

```stata
* income2018 income2019 income2020 --> income + year
reshape long income, i(id) j(year)
```

### Long to wide

```stata
reshape wide income, i(id) j(year)
```

### Common reshape pitfall

```stata
* If reshape fails, check for duplicates in i-j combinations
duplicates report id year
duplicates drop id year, force   // only if justified
```

---

## 7. Panel Data Construction

### Declare panel

```stata
xtset id year
xtdescribe           // shows panel balance, gaps
```

### Fill gaps for balanced panel

```stata
* fillin creates all i-j combinations
fillin id year

* _fillin == 1 marks newly created rows
tab _fillin
* Decide how to handle: set outcome to missing, or impute
```

### Check for gaps

```stata
bysort id (year): gen gap = year - year[_n-1] if _n > 1
tab gap   // all 1s if no gaps
drop gap
```

### Panel summaries

```stata
distinct id             // number of units
distinct year           // number of periods
xtdescribe              // pattern of participation
xtsum outcome           // between vs within variation
```

---

## 8. Missing Data Handling

### Audit

```stata
misstable summarize
misstable patterns, frequency
```

### Missingness by group

```stata
bysort treat: misstable summarize outcome x1 x2
```

### Create analysis sample flag

```stata
gen sample_main = 1
replace sample_main = 0 if missing(outcome)
replace sample_main = 0 if missing(treat)
replace sample_main = 0 if age < 25 | age > 55

tab sample_main
```

---

## 9. Validate and Save

### Document sample flow

```stata
display "Initial N: " _N
drop if missing(outcome)
display "After dropping missing outcome: " _N
drop if missing(treat)
display "After dropping missing treatment: " _N
keep if age >= 25 & age <= 55
display "After age restriction: " _N
display "Final analysis sample: " _N
```

### Assertions for data integrity

```stata
isid id year                              // unique panel keys
assert !missing(outcome) if sample_main == 1
assert treat == 0 | treat == 1
assert year >= 2000 & year <= 2023
```

### Save

```stata
compress
label data "Analysis sample -- created $S_DATE"
save "$clean/analysis_sample.dta", replace
```

### Export codebook

```stata
log using "$logs/codebook.log", replace
codebook
log close
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Import CSV | `import delimited "f.csv", clear varnames(1)` |
| Import Excel | `import excel "f.xlsx", firstrow clear` |
| Check unique ID | `isid id` |
| Check duplicates | `duplicates report id` |
| Missing audit | `misstable summarize` |
| Merge (many:1) | `merge m:1 key using "f.dta"` |
| Reshape wide->long | `reshape long stub, i(id) j(time)` |
| Declare panel | `xtset id year` |
| Balance panel | `fillin id year` |
| Compress + save | `compress` then `save "f.dta", replace` |
