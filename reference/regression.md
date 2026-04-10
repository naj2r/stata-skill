# Regression — OLS, IV, Logit/Probit, Post-Estimation

---

## reghdfe: The Workhorse

```stata
ssc install reghdfe
ssc install ftools

reghdfe y x1 x2, absorb(firm_id year) vce(cluster firm_id year)

eststo clear
eststo m1: reghdfe y x1, absorb(firm_id year) vce(cluster firm_id)
eststo m2: reghdfe y x1 x2, absorb(firm_id year) vce(cluster firm_id)
esttab m1 m2, se star(* 0.10 ** 0.05 *** 0.01) stats(N r2, fmt(%9.0fc %9.3f))
```

## Basic OLS

```stata
regress y x1 x2, vce(robust)              // Huber-White SEs
regress y x1 x2, vce(cluster state_id)    // clustered SEs
regress y x1 x2, vce(hc3)                 // small-sample correction
```

**Gotchas:**
- Need ~50+ clusters for reliable inference. Fewer? Use `boottest`.
- Clustered SEs are automatically robust to heteroskedasticity.
- Stata auto-drops collinear variables — watch for "(omitted)".

---

## IV Regression

```stata
ivregress 2sls y x2 (x1 = z1 z2), first vce(robust)

* ivreg2 — better diagnostics
ivreg2 y x2 (x1 = z1 z2), first robust

* IV with fixed effects
ivreghdfe y x2 (x1 = z1), absorb(firm_id year) cluster(firm_id)

* Critical diagnostics
estat firststage       // F > 10 for strong instruments
estat endogenous       // H0: variable is exogenous
estat overid           // H0: instruments valid (need overidentification)
```

**Gotchas:**
- ALL exogenous regressors are automatically instruments — do not omit them.
- Never manually do 2SLS — standard errors will be wrong.

---

## Logit / Probit

```stata
logit union wage age grade, robust
margins, dydx(*)                      // ALWAYS report marginal effects
margins, at(wage=(5 10 15) age=35)    // predicted probabilities
logit union wage age grade, or        // odds ratios
```

**Gotcha:** Pseudo-R-squared is NOT variance explained.

---

## Margins

```stata
regress y c.education##c.experience i.gender
margins, dydx(education)                           // AME
margins, dydx(education) at(experience=(5 10 15))  // varying effect
margins gender, dydx(education)                    // by group
marginsplot
```

**Never interpret interaction coefficients directly — use `margins`.**

---

## Estimates Store/Restore

```stata
regress price mpg weight, robust
estimates store m1
estimates restore m1
predict yhat_m1
```

`estimates table` has limited options. Use `esttab` for publication tables.

---

## Post-Estimation Tests

```stata
test education                         // H0: beta = 0
test education experience              // joint test
test education = experience            // equal coefficients
lincom education - experience          // difference + SE + CI
nlcom _b[education]/_b[experience]     // ratio (delta method)
testparm i.region#c.education          // joint test — wildcards OK
```

**`test` vs `testparm`:** `test` cannot parse negative factor levels. Use `testparm`:
```stata
* WRONG: test 1.treated#-5.time
* RIGHT: testparm 1.treated#(-5 -4 -3).time
```

---

## Interactions

```stata
regress wage i.gender##c.education     // categorical x continuous
regress wage c.education##c.experience // continuous x continuous
regress wage ib3.education_cat         // custom reference category
```

**Gotcha:** `ib()` prefixes its OWN variable: `ib(-1).time#1.treated`, not `treated#ib(-1).time`.

## Diagnostics

```stata
estat vif            // VIF > 10 = multicollinearity
estat hettest        // Breusch-Pagan
estat ovtest         // Ramsey RESET
predict cooksd, cooksd
```

---

## Deep Dive

- `help regress postestimation` — complete post-estimation commands
- `help margins` — the most important post-estimation command
- Stata [R] manual: `regress`, `ivregress`, `logit`, `probit`
- reghdfe: <https://github.com/sergiocorreia/reghdfe>
