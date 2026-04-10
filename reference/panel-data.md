# Panel Data — xtset, FE/RE, Hausman, Dynamic Panels

---

## xtset

```stata
xtset firm_id year
xtset firm_id                    // no time dimension
```

After `xtset`, time-series operators work: `L.wage` (lag), `F.wage` (lead), `D.wage` (first difference).

**Always start with:**
```stata
xtdescribe                       // balanced/unbalanced, gaps
xtsum ln_wage age tenure         // between/within decomposition
```

`xtsum` shows whether variation is cross-sectional or longitudinal — critical for model choice.

---

## Fixed Effects (FE)

Eliminates time-invariant confounders. **Cannot estimate time-invariant variables.**

```stata
xtreg ln_wage age tenure, fe vce(cluster idcode)
xtreg ln_wage age tenure i.year, fe vce(cluster idcode)
testparm i.year                  // test if time FEs needed
```

### reghdfe — Preferred for Multiple FE

```stata
reghdfe ln_wage age tenure, absorb(idcode year) vce(cluster idcode)
reghdfe ln_wage age tenure, absorb(idcode year) vce(cluster idcode year)  // two-way
```

## Random Effects (RE)

Assumes u_i uncorrelated with regressors. More efficient; can include time-invariant vars.

```stata
xtreg ln_wage age tenure female, re vce(robust)
```

---

## Hausman Test: FE vs RE

```stata
quietly xtreg ln_wage age tenure, fe
estimates store fixed
quietly xtreg ln_wage age tenure, re
estimates store random
hausman fixed random          // p < 0.05 → use FE
```

**Gotchas:**
- Requires DEFAULT SEs — invalid with `vce(robust)`. Test with defaults, then re-estimate with clusters.
- "Not positive definite" → `hausman fe re, sigmamore`.
- Robust alternative: `ssc install xtoverid` then `xtreg ..., re` / `xtoverid`.

### Mundlak Test

```stata
bysort idcode: egen mean_age = mean(age)
xtreg ln_wage age tenure mean_age, re
test mean_age                    // significant → use FE
```

---

## Panel Diagnostics

```stata
xtreg ln_wage age tenure, re
xttest0                          // H0: sigma_u=0 (pooled OLS OK)

xtserial ln_wage age tenure      // Wooldridge autocorrelation test
```

---

## Dynamic Panels (Lagged DV)

Lagged DV in FE creates Nickell bias when T is small.

```stata
xtabond n L(0/2).(w k), vce(robust)      // Arellano-Bond (diff GMM)
xtdpdsys n L(0/1).(w k), vce(robust)     // Blundell-Bond (system GMM)

estat abond        // AR(1) significant, AR(2) NOT
estat sargan       // H0: instruments valid (want p > 0.05)
```

**Gotcha:** Too many instruments → Sargan test loses power.

---

## Panel Count/Binary

```stata
xtpoisson y x1 x2, fe vce(robust)
xtlogit y x1 x2, fe
```

## xtdidregress (Stata 17+)

```stata
xtdidregress (outcome x1 x2) (treatment), group(unit_id) time(year)
```

---

## When to Use What

| Model | When |
|-------|------|
| FE | Time-invariant confounders; Hausman rejects RE |
| RE | Need time-invariant vars; units random sample |
| FD | T=2; random walk errors |
| GMM | Lagged DV; small T, large N |
| reghdfe | Multiple FE; two-way clustering |

---

## Deep Dive

- Stata [XT] manual (12 MB PDF)
- `help xtreg postestimation`
- Wooldridge (2010) Ch. 10-11
- reghdfe: <https://github.com/sergiocorreia/reghdfe>
