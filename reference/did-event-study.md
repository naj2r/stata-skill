# DiD and Event Studies — TWFE, Staggered Treatment, Modern Estimators

TWFE is biased under staggered treatment with heterogeneous effects. Use modern estimators.

## Basic Two-Period DiD

```stata
regress outcome i.treated##i.post, vce(cluster state_id)
* treated#post coefficient = DiD estimate
```

## TWFE (and Its Problems)

```stata
reghdfe outcome post_treatment, absorb(unit_id year) vce(cluster unit_id)
```

**Problem with staggered adoption:** TWFE uses already-treated units as controls ("forbidden comparisons"), producing negative weights and bias under heterogeneous effects.

```stata
ssc install bacondecomp
bacondecomp outcome, ddetail    // diagnose
```

---

## Manual Event Study

```stata
gen rel_time = year - treatment_year
replace rel_time = -999 if missing(treatment_year)  // never-treated
replace rel_time = -5 if rel_time < -5 & rel_time != -999
replace rel_time = 5 if rel_time > 5 & rel_time != -999

* Variable names CANNOT contain hyphens — use lead/lag prefixes
forvalues k = 5(-1)2 {
    gen lead`k' = (rel_time == -`k')
}
forvalues k = 0/5 {
    gen lag`k' = (rel_time == `k')      // omit period -1 as reference
}
reghdfe outcome lead5-lead2 lag0-lag5, absorb(unit_id year) vce(cluster unit_id)
test lead5 lead4 lead3 lead2           // pre-trend test
```

**Gotcha — uniform timing:** When all treated units share the same treatment_year, event-time dummies are collinear with year FEs. Fix: interact with treatment indicator:
```stata
gen treated = !missing(treatment_year)
forvalues k = 5(-1)2 { gen lead`k' = treated * (rel_time == -`k') }
forvalues k = 0/5 { gen lag`k' = treated * (rel_time == `k') }
reghdfe outcome lead5-lead2 lag0-lag5, absorb(unit_id year) vce(cluster unit_id)
```

---

## Callaway and Sant'Anna (2021) — csdid

The recommended modern estimator. Computes group-time ATTs then aggregates.

```stata
ssc install csdid
ssc install drdid

csdid outcome x1 x2, ivar(unit_id) time(year) gvar(treatment_year) ///
    method(dripw) notyet

estat simple       // overall ATT
estat group        // by cohort
estat event, window(-5 5) estore(cs_event)
csdid_plot         // event study plot
estat pretrend     // formal pre-trend test
```

**Options:** `notyet` = not-yet-treated as controls (recommended). `long2` = never-treated only.

---

## Other Modern Estimators

**de Chaisemartin-D'Haultfoeuille:**
```stata
ssc install did_multiplegt
did_multiplegt outcome unit_id year treatment, ///
    robust_dynamic dynamic(5) placebo(3) breps(100) cluster(unit_id)
```

**Sun-Abraham (interaction-weighted):**
```stata
ssc install eventstudyinteract
eventstudyinteract outcome lead5-lead2 lag0-lag5, ///
    cohort(treatment_year) control_cohort(never_treated) ///
    absorb(unit_id year) vce(cluster unit_id)
```

**Imputation (Borusyak-Jaravel-Spiess):**
```stata
ssc install did_imputation
did_imputation outcome unit_id year treatment_year, ///
    horizons(0/5) pretrend(5)
event_plot, default_look
```

---

## Pre-Trend Testing

```stata
* Visual: compare trends before treatment
preserve
collapse (mean) outcome, by(treated year)
twoway (connected outcome year if treated==0) ///
       (connected outcome year if treated==1), ///
       xline(2010, lcolor(red) lpattern(dash)) legend(order(1 "Control" 2 "Treated"))
restore

* Formal: joint test of pre-treatment leads
test lead5 lead4 lead3 lead2
```

---

## Standard Errors

Cluster at treatment level. For <40 clusters, use wild cluster bootstrap:
```stata
reghdfe outcome post_treatment, absorb(unit_id year) cluster(state)
boottest post_treatment, cluster(state) boottype(wild) reps(9999)  // ssc install boottest
```

## Which Estimator

| Situation | Use |
|-----------|-----|
| Two periods, two groups | Basic DiD |
| Multiple periods, uniform timing | TWFE or event study |
| Staggered adoption | `csdid` (recommended default) |
| Single treated unit | Synthetic control (`synth`) |

---

## Essential Packages

`reghdfe`, `ftools`, `csdid`, `drdid`, `did_multiplegt`, `did_imputation`, `eventstudyinteract`, `bacondecomp`, `boottest`, `coefplot`, `parmest` — all via `ssc install`.

---

## Deep Dive

- Roth et al. (2023) "What's Trending in Difference-in-Differences?"
- Callaway & Sant'Anna (2021) "Difference-in-Differences with Multiple Time Periods"
- Goodman-Bacon (2021) "Difference-in-Differences with Variation in Treatment Timing"
- `help csdid`, `help did_multiplegt`, `help did_imputation`
