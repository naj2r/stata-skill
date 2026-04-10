# Robustness and Sensitivity Analysis

Systematic robustness checks: alternative specifications, placebo tests, leave-one-out, wild cluster bootstrap, permutation inference, Oster bounds.

---

## 1. Alternative Specifications

### Alternative control sets

```stata
* Minimal controls
reghdfe outcome treat, absorb(id year) cluster(state)
estimates store r_minimal

* Baseline controls
reghdfe outcome treat x1 x2, absorb(id year) cluster(state)
estimates store r_baseline

* Extended controls
reghdfe outcome treat x1 x2 x3 x4 x5, absorb(id year) cluster(state)
estimates store r_extended

* Log outcome
gen ln_outcome = ln(outcome)
reghdfe ln_outcome treat x1 x2, absorb(id year) cluster(state)
estimates store r_log
```

### Alternative fixed effects

```stata
* Unit + time FE (baseline)
reghdfe outcome treat x1 x2, absorb(id year) cluster(state)
estimates store r_fe_base

* Region-by-year FE (more demanding)
reghdfe outcome treat x1 x2, absorb(id region#year) cluster(state)
estimates store r_fe_region_year

* Unit-specific trends
reghdfe outcome treat x1 x2, absorb(id year id#c.year) cluster(state)
estimates store r_fe_trends
```

### Alternative standard errors

```stata
* Cluster at different levels
reghdfe outcome treat x1, absorb(id year) cluster(id)
estimates store se_id

reghdfe outcome treat x1, absorb(id year) cluster(state)
estimates store se_state

reghdfe outcome treat x1, absorb(id year) cluster(state year)
estimates store se_twoway
```

---

## 2. Alternative Samples

### Exclude outliers

```stata
* Winsorized outcome
egen p1 = pctile(outcome), p(1)
egen p99 = pctile(outcome), p(99)
gen outcome_w = outcome
replace outcome_w = p1  if outcome < p1
replace outcome_w = p99 if outcome > p99 & !missing(outcome)
drop p1 p99

reghdfe outcome_w treat x1 x2, absorb(id year) cluster(state)
estimates store r_winsor
```

### Different time windows

```stata
reghdfe outcome treat x1 x2 if year <= 2015, absorb(id year) cluster(state)
estimates store r_early

reghdfe outcome treat x1 x2 if year >= 2010, absorb(id year) cluster(state)
estimates store r_late
```

### Exclude specific units

```stata
* Drop largest state (influential observation)
reghdfe outcome treat x1 x2 if state != 6, absorb(id year) cluster(state)
estimates store r_no_ca
```

---

## 3. Placebo Tests

### Pre-treatment effects (for DiD)

```stata
* Restrict to pre-treatment period -- should find no effect
preserve
keep if year < first_treat | missing(first_treat)
gen fake_post = (year >= 2008)   // arbitrary pre-period date
gen fake_treat = treated * fake_post

reghdfe outcome fake_treat, absorb(id year) cluster(state)
estimates store placebo_pre
restore
```

### Fake treatment timing

```stata
* Shift treatment date back by N years -- should find null
gen fake_first_treat = first_treat - 3
gen fake_treated = (year >= fake_first_treat) & !missing(fake_first_treat)

preserve
keep if year < first_treat | missing(first_treat)   // only pre-period
reghdfe outcome fake_treated x1 x2, absorb(id year) cluster(state)
estimates store placebo_timing
restore
```

### Outcome that should not be affected

```stata
* If treatment affects wages, it should not affect height
reghdfe unrelated_outcome treat x1 x2, absorb(id year) cluster(state)
estimates store placebo_outcome

* Null coefficient = passes placebo test
```

### Pre-trend test via event study

```stata
* Run event study and check pre-treatment coefficients
reghdfe outcome ib(-1).event_time, absorb(id year) cluster(state)

* Joint test of pre-treatment coefficients
testparm *bn.event_time   // test that pre-treatment dummies are jointly zero
```

---

## 4. Leave-One-Out

### Drop each treated unit one at a time

```stata
* Get list of treated units
levelsof id if treated == 1, local(treated_units)

* Run main spec dropping each treated unit
foreach u of local treated_units {
    quietly reghdfe outcome treat x1 x2 if id != `u', ///
        absorb(id year) cluster(state)
    estimates store loo_`u'
}

* Compare -- if results swing dramatically when one unit is dropped,
* that unit is driving the result
```

### Drop each cluster one at a time

```stata
levelsof state, local(states)
gen loo_coef = .
gen loo_state = .
local i = 0

foreach s of local states {
    local ++i
    quietly reghdfe outcome treat x1 x2 if state != `s', ///
        absorb(id year) cluster(state)
    replace loo_coef = _b[treat] in `i'
    replace loo_state = `s' in `i'
}

* Plot distribution of leave-one-out estimates
histogram loo_coef if !missing(loo_coef), ///
    xline(`main_coef', lcolor(red)) ///
    title("Leave-One-Out: Dropping Each State") ///
    xtitle("Coefficient on Treatment")
graph export "$figures/loo_distribution.png", replace
```

---

## 5. Wild Cluster Bootstrap

**When to use:** Fewer than ~40 clusters. Conventional cluster-robust SEs are unreliable with few clusters.

```stata
* Step 1: Run main regression with clustering
reghdfe outcome treat x1 x2, absorb(id year) cluster(state)

* Step 2: Wild cluster bootstrap p-value
boottest treat, cluster(state) reps(999) seed(12345) nograph

* Output reports:
*   Bootstrap t-statistic
*   p-value (compare to conventional)
*   95% confidence interval

* Step 3: Compare
display "Conventional p-value:  " 2*ttail(e(df_r), abs(_b[treat]/_se[treat]))
* If bootstrap p-value differs substantially, report both
```

### Bootstrap with subcluster

```stata
* Cluster at state, bootstrap at state
reg outcome treat x1 x2, cluster(state)
boottest treat, cluster(state) reps(999) seed(12345) nograph
```

---

## 6. Randomization / Permutation Inference

**When to use:** Small samples, non-standard test statistics, exact p-values without distributional assumptions.

```stata
* Permute treatment assignment, re-estimate each time
ritest treat _b[treat], reps(1000) seed(12345) strata(block): ///
    reg outcome treat x1 x2, robust

* Output:
*   Observed coefficient
*   Permutation p-value (fraction of permuted coefficients >= observed)
```

### Stratified permutation

```stata
* Permute within strata (e.g., state or block)
ritest treat _b[treat], reps(1000) seed(12345) strata(state): ///
    reghdfe outcome treat x1, absorb(year) cluster(state)
```

---

## 7. Oster Bounds (Coefficient Stability)

**When to use:** Assess how much omitted variable bias would be needed to explain away the result. Based on Oster (2019).

```stata
* Install: ssc install psacalc, replace

* Step 1: Short regression (no controls)
reg outcome treat
local b_short = _b[treat]
local r2_short = e(r2)

* Step 2: Long regression (full controls)
reg outcome treat x1 x2 x3 x4
local b_long = _b[treat]
local r2_long = e(r2)

* Step 3: Calculate delta (Oster)
* delta = how much more important unobservables would need to be
* relative to observables to drive the coefficient to zero
psacalc delta treat, rmax(1.3 * `r2_long') mcontrol(x1 x2 x3 x4)

* Interpretation:
*   delta > 1  => unobservables would need to be MORE important than
*                 observables to explain away the result (robust)
*   delta < 1  => result may be fragile to omitted variables
```

### Bounding exercise

```stata
* Calculate beta* at different Rmax assumptions
foreach rmax in 1.0 1.3 1.5 2.0 {
    local rmax_val = `rmax' * `r2_long'
    psacalc beta treat, rmax(`rmax_val') mcontrol(x1 x2 x3 x4)
}
* If beta* remains same-signed across reasonable Rmax, result is stable
```

---

## 8. Method-Specific Diagnostics

### DiD: Staggered treatment robustness

```stata
* Compare TWFE to Callaway-Sant'Anna
reghdfe outcome treat, absorb(id year) cluster(id)
estimates store twfe

csdid outcome, ivar(id) time(year) gvar(first_treat) notyet
csdid_estat simple
* If estimates diverge, TWFE may be biased by heterogeneous effects
```

### IV: Weak instrument robustness

```stata
ivreg2 outcome (endog = instrument) x1 x2, first robust

* Anderson-Rubin weak-instrument-robust CI
* Reported automatically by ivreg2

* Reduced form
reg outcome instrument x1 x2, robust
estimates store reduced_form
```

### Matching: Sensitivity to caliper and neighbors

```stata
foreach cal in 0.01 0.05 0.10 {
    psmatch2 treat x1 x2, outcome(outcome) caliper(`cal') common
    display "Caliper = `cal': ATT = " r(att)
}

foreach nn in 1 3 5 {
    psmatch2 treat x1 x2, outcome(outcome) neighbor(`nn') common
    display "Neighbors = `nn': ATT = " r(att)
}
```

---

## 9. Compile Robustness Table

```stata
esttab r_baseline r_minimal r_extended r_log r_fe_region_year r_winsor ///
    using "$tables/table_robustness.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat) ///
    mtitles("Baseline" "Minimal" "Extended" "Log Y" "Region x Year" "Winsor") ///
    title("Table 3: Robustness Checks") ///
    addnotes("All models include unit and year FE." ///
             "Standard errors clustered at state level.")
```

### Placebo table

```stata
esttab placebo_pre placebo_timing placebo_outcome ///
    using "$tables/table_placebo.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(fake_treat fake_treated treat) ///
    mtitles("Pre-treatment" "Fake timing" "Unrelated Y") ///
    title("Appendix Table: Placebo Tests")
```

---

## Quick Reference

| Check | Command/Approach | Pass criterion |
|-------|-----------------|----------------|
| Alt controls | Add/remove covariates | Coefficient stable |
| Alt FE | Region x year, unit trends | Coefficient stable |
| Alt SEs | Different cluster levels | Significance unchanged |
| Placebo (pre-trend) | Fake treatment in pre-period | Null coefficient |
| Placebo (outcome) | Unrelated outcome | Null coefficient |
| Leave-one-out | Drop each unit/cluster | No single driver |
| Wild bootstrap | `boottest treat, cluster() reps(999)` | p-value consistent |
| Permutation | `ritest treat _b[treat], reps(1000)` | p-value consistent |
| Oster delta | `psacalc delta treat` | delta > 1 |
