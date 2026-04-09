# Core Econometrics

End-to-end workflows for causal inference methods in Stata. Each section: when to use, setup, estimation, interpretation, common mistakes.

---

## 1. Two-Way Fixed Effects (TWFE)

**When to use:** Panel data with unit and time dimensions; unobserved unit/time confounders; consistent treatment timing (or verified no negative weights).

```stata
* Declare panel
xtset id year

* TWFE with reghdfe (preferred)
reghdfe y treat x1 x2, absorb(id year) cluster(id)

* Two-way clustering (unit + time)
reghdfe y treat x1 x2, absorb(id year) cluster(id year)

* Store and compare
quietly reghdfe y treat x1, absorb(id year) cluster(id)
estimates store m_oneway

quietly reghdfe y treat x1, absorb(id year) cluster(id year)
estimates store m_twoway

esttab m_oneway m_twoway, se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("One-way" "Two-way")
```

**Interpretation:** Coefficient on `treat` is the average treatment effect, controlling for all time-invariant unit characteristics and common time shocks.

**Common mistakes:** Using `xtreg, fe` instead of `reghdfe` (slower, less flexible). Forgetting to cluster SEs. Applying TWFE with staggered treatment timing without checking for negative weights.

---

## 2. Difference-in-Differences (DiD)

### 2a. Traditional DiD (simultaneous treatment)

```stata
* Explicit interaction
reg y i.treated##i.post x1 x2, cluster(id)

* Or manually
gen treat_post = treated * post
reghdfe y treat_post, absorb(id year) cluster(id)
```

**Interpretation:** The `treat_post` coefficient is the ATT -- the change in the treated group relative to the change in the control group.

### 2b. Staggered DiD with Callaway-Sant'Anna (csdid)

**When to use:** Treatment timing varies across units. Traditional TWFE can produce biased estimates due to negative weighting.

```stata
* gvar = first treatment period (0 for never-treated)
csdid y, ivar(id) time(year) gvar(first_treat) notyet

* Aggregate to event study
csdid_estat event

* Simple overall ATT
csdid_estat simple

* Group-level ATTs
csdid_estat group
```

**Key options:** `notyet` uses not-yet-treated as controls (recommended). `never` restricts to never-treated controls only.

### 2c. de Chaisemartin-D'Haultfoeuille (did_multiplegt)

```stata
did_multiplegt y id year treat, robust_dynamic dynamic(5) placebo(3) ///
    breps(100) cluster(id)
```

**Common mistakes:** Not testing parallel trends. Using `notyet` vs `never` without justification. Ignoring anticipation effects.

---

## 3. Event Studies

### Manual event study

```stata
* Create event time
gen event_time = year - first_treat
replace event_time = -99 if missing(first_treat)  // never treated

* Bin endpoints
replace event_time = -6 if event_time < -6 & event_time != -99
replace event_time = 6  if event_time > 6  & event_time != -99

* Estimate with i. notation, omit t = -1
reghdfe y ib(-1).event_time, absorb(id year) cluster(id)

* Plot
coefplot, vertical keep(*.event_time) omitted baselevels ///
    yline(0, lpattern(dash)) ///
    xline(4.5, lcolor(red) lpattern(dash)) ///
    xtitle("Periods Relative to Treatment") ytitle("Effect") ///
    title("Event Study")
graph export "$figures/event_study.png", replace
```

### Event study from csdid

```stata
csdid y, ivar(id) time(year) gvar(first_treat) notyet
csdid_estat event
csdid_plot
```

**Interpretation:** Pre-treatment coefficients should be near zero and statistically insignificant (parallel trends). Post-treatment coefficients show dynamic treatment effects.

**Common mistakes:** Not binning endpoints (estimates at extreme leads/lags are noisy). Omitting the wrong reference period. Interpreting pre-trends as "close enough" without formal testing.

---

## 4. Instrumental Variables (IV)

**When to use:** Endogenous regressor (omitted variable bias, simultaneity, measurement error) with a valid instrument.

### Setup and estimation

```stata
* ivreg2 with first-stage diagnostics
ivreg2 y (x_endog = z_instrument) x_control, first robust

* IV with fixed effects
ivreghdfe y (x_endog = z_instrument) x_control, absorb(id year) cluster(id)
```

### First-stage diagnostics (critical)

```stata
ivreg2 y (x_endog = z_instrument) x_control, first robust

* Check in output:
*   Kleibergen-Paap rk Wald F statistic > 10  (instrument relevance)
*   Stock-Yogo critical values for comparison
*   Hansen J p-value > 0.10 if overidentified   (instrument validity)
```

### Reduced form (always report)

```stata
* Direct effect of instrument on outcome
reg y z_instrument x_control, robust
```

### Multiple instruments

```stata
ivreg2 y (x_endog = z1 z2 z3) x_control, robust
* Hansen J test reported automatically
* H0: all instruments valid. Want high p-value.
```

**Common mistakes:** Weak instruments (F < 10) -- use Anderson-Rubin CI instead. Not reporting the reduced form. Claiming exclusion restriction holds without theoretical argument.

---

## 5. Matching

### 5a. Propensity Score Matching (psmatch2)

```stata
* Estimate propensity score and match
psmatch2 treat x1 x2 x3 i.category, outcome(y) neighbor(1) common caliper(0.05)

* Check balance
pstest x1 x2 x3, both

* ATT is displayed in psmatch2 output
```

### 5b. teffects (built-in, Stata 13+)

```stata
* PSM via teffects
teffects psmatch (y) (treat x1 x2 x3), atet nn(1)

* Inverse probability weighting
teffects ipw (y) (treat x1 x2 x3), atet
```

### 5c. Balance assessment

```stata
* After psmatch2
pstest x1 x2 x3, both graph
graph export "$figures/balance_plot.png", replace

* Key output:
*   Mean bias < 5% after matching (rule of thumb)
*   t-tests insignificant for all covariates
```

### 5d. Coarsened Exact Matching (CEM)

```stata
cem age (20 30 40 50 60) income (#5), treatment(treat)
reg y treat x1 x2 [iweight=cem_weights], robust
```

**Common mistakes:** Not checking balance after matching. Matching on post-treatment variables. Using too tight a caliper (losing sample). Not reporting number of dropped observations.

---

## 6. Standard Errors and Inference

### Clustered SEs

```stata
reghdfe y treat x1, absorb(id year) cluster(state)         // one-way
reghdfe y treat x1, absorb(id year) cluster(state year)     // two-way
```

### Wild cluster bootstrap (few clusters, < ~40)

```stata
reg y treat x1 x2, cluster(state)
boottest treat, cluster(state) reps(999) seed(12345) nograph
```

### Randomization inference

```stata
ritest treat _b[treat], reps(1000) seed(12345) strata(block): ///
    reg y treat x1, robust
```

**Common mistakes:** Clustering at the wrong level. Using conventional SEs with < 40 clusters (use `boottest`). Not setting seed for bootstrap/permutation tests.

---

## Package Installation

```stata
* Core estimation
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install coefplot, replace

* Causal inference
ssc install csdid, replace
ssc install drdid, replace
ssc install did_multiplegt, replace
ssc install ivreg2, replace
ssc install ivreghdfe, replace
ssc install ranktest, replace

* Matching
ssc install psmatch2, replace
ssc install cem, replace

* Inference
ssc install boottest, replace
ssc install ritest, replace
```

---

## Quick Reference

| Method | Command | Key diagnostic |
|--------|---------|---------------|
| TWFE | `reghdfe y x, absorb(id t) cluster(id)` | Staggered timing check |
| DiD (staggered) | `csdid y, ivar(id) time(t) gvar(g) notyet` | Pre-trends via `csdid_estat event` |
| Event study | `coefplot` after `reghdfe` with leads/lags | Pre-treatment coefficients ~ 0 |
| IV | `ivreg2 y (endog = iv), first robust` | First-stage F > 10 |
| PSM | `psmatch2 treat x, outcome(y) common` | `pstest` balance < 5% bias |
| Wild bootstrap | `boottest treat, cluster(c) reps(999)` | Compare to conventional p-value |
