# Matching and IV — PSM, Treatment Effects, Instruments, RD

---

## Propensity Score Matching (psmatch2)

```stata
ssc install psmatch2

logit treatment age education income married i.region
predict pscore, pr

psmatch2 treatment, outcome(earnings) pscore(pscore) neighbor(1) caliper(0.05) common

pstest age education income married, both graph   // balance check
psgraph                                            // common support
```

**Algorithms:** `neighbor(k)`, `kernel kerneltype(epan) bwidth(0.06)`, `radius caliper(0.05)`.

### Bias Correction

```stata
regress earnings treatment age education income ///
    if _support==1 [aweight=_weight], vce(robust)
```

---

## teffects — Built-in Treatment Effects

```stata
teffects psmatch (earnings) (treatment age education income), att nn(1) caliper(0.05)
tebalance summarize                      // balance
teffects overlap                         // overlap plot

* Doubly robust (recommended — consistent if EITHER model is correct)
teffects aipw (y x1 x2) (treatment x1 x2), att
```

Other estimators: `teffects ra` (regression adjustment), `teffects ipw`, `teffects ipwra`.

---

## Balance Assessment

Rule of thumb: |standardized bias| < 5% after matching.

```stata
pstest age education income, both        // after psmatch2
tebalance summarize                      // after teffects
```

---

## Sensitivity Analysis

```stata
* Vary neighbors
forvalues k = 1/5 {
    quietly teffects psmatch (y) (treatment x1 x2), att nn(`k')
    estimates store nn`k'
}
estimates table nn*, b se

* Rosenbaum bounds
ssc install rbounds
rbounds y treatment if _support==1
```

---

## Coarsened Exact Matching / Entropy Balancing

```stata
ssc install cem
cem age (#10) education (#5) income (#10), treatment(treatment)
regress y treatment x1 x2 [iweight=cem_weights], robust

ssc install ebalance
ebalance treatment age education income, generate(eb_weight)
regress y treatment [aweight=eb_weight], vce(robust)
```

---

## IV: ivreg2 with Diagnostics

```stata
ssc install ivreg2
ivreg2 y x2 (x1 = z1 z2), first robust
```

**Auto-reported diagnostics:**
- Kleibergen-Paap rk F: weak instrument test (want F > 10)
- Hansen J: overidentification (H0: instruments valid, want p > 0.05)

```stata
ssc install ivreghdfe
ivreghdfe y x2 (x1 = z1), absorb(firm_id year) cluster(firm_id)
```

**Gotchas:**
- All exogenous regressors are automatically instruments — do not omit.
- LIML more robust to weak instruments: `ivregress liml y x2 (x1 = z), first`.

---

## Weak Instruments

```stata
ssc install weakiv
ivreg2 y (x1 = z1 z2), robust
weakiv                                   // Anderson-Rubin CI
```

First-stage F < 10 → worry. F < 5 → do not trust 2SLS.

---

## Regression Discontinuity (rdrobust)

```stata
ssc install rdrobust
ssc install rddensity

rdrobust y running_var, c(0)
rdrobust y running_var, c(0) kernel(triangular) bwselect(mserd)
rddensity running_var, c(0)             // manipulation test
rdplot y running_var, c(0)              // RD plot
```

Requires Stata 16+. For Stata 15, use manual local linear regression.

---

## Deep Dive

- Stata [CAUSAL] manual (7 MB PDF): `teffects`, treatment effects framework
- `help psmatch2`, `help rdrobust`
- Cattaneo, Idrobo, Titiunik (2020) *Practical Introduction to RD Designs*
