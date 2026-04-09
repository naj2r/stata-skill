# Post-Estimation and Reporting

After estimation: marginal effects, coefficient plots, regression tables, and publication-quality output.

---

## 1. Margins and Marginal Effects

### Average marginal effects (AME)

```stata
logit union wage age i.race, robust

* AME for all variables
margins, dydx(*)

* AME for specific variable
margins, dydx(wage)

* Post results for tabling
margins, dydx(*) post
esttab, cells("b(fmt(4)) se(fmt(4)) p(fmt(3))") ///
    title("Average Marginal Effects")
```

### Predictive margins at specific values

```stata
reg price i.foreign##c.mpg weight, robust

* Predicted price at selected MPG values, by origin
margins foreign, at(mpg=(15(5)40))

* Plot
marginsplot, ///
    title("Predicted Price by MPG and Origin") ///
    ytitle("Predicted Price ($)") xtitle("Miles per Gallon") ///
    legend(order(1 "Domestic" 2 "Foreign"))
graph export "$figures/figure_margins.png", replace width(2400)
```

### Interaction effects

```stata
reg y c.income##i.treat x1 x2, robust

* Marginal effect of income, by treatment status
margins, dydx(income) at(treat=(0 1))

* Contrast: difference in marginal effects
margins treat, dydx(income) contrast(nowald)
```

---

## 2. Coefficient Plots with coefplot

### Basic coefficient plot

```stata
reg price mpg weight length headroom trunk, robust

coefplot, drop(_cons) xline(0, lpattern(dash)) ///
    title("Coefficient Estimates") ///
    xtitle("Estimate and 95% CI")
graph export "$figures/coefplot_basic.png", replace
```

### Multiple models side by side

```stata
quietly reg price mpg weight, robust
estimates store m1
quietly reg price mpg weight i.foreign, robust
estimates store m2
quietly reg price mpg weight i.foreign headroom trunk, robust
estimates store m3

coefplot m1 m2 m3, drop(_cons 1.foreign) xline(0) ///
    legend(order(2 "Model 1" 4 "Model 2" 6 "Model 3"))
graph export "$figures/coefplot_models.png", replace
```

### Event study plot

```stata
* After event study regression (e.g., reghdfe y ib(-1).event_time, ...)
coefplot, keep(*.event_time) vertical omitted baselevels ///
    yline(0, lpattern(dash) lcolor(gs8)) ///
    xline(5.5, lpattern(dash) lcolor(cranberry)) ///
    ciopts(recast(rcap) lcolor(navy)) ///
    mcolor(navy) msymbol(D) ///
    xtitle("Periods Relative to Treatment") ///
    ytitle("Estimated Effect") ///
    title("Event Study: Dynamic Treatment Effects")
graph export "$figures/event_study.png", replace width(2400)
```

### Subgroup coefficient comparison

```stata
* Same model estimated on different subgroups
quietly reg y treat x1 x2 if male == 1, robust
estimates store m_male
quietly reg y treat x1 x2 if male == 0, robust
estimates store m_female

coefplot m_male m_female, keep(treat) xline(0) ///
    legend(order(2 "Male" 4 "Female")) ///
    title("Treatment Effect by Gender")
graph export "$figures/coefplot_subgroups.png", replace
```

---

## 3. Regression Tables with esttab

### Estimate, store, table workflow

```stata
* Step 1: Estimate and store
quietly reg price mpg, robust
estimates store m1

quietly reg price mpg weight, robust
estimates store m2

quietly reg price mpg weight i.foreign, robust
estimates store m3

quietly reghdfe price mpg weight, absorb(rep78) cluster(rep78)
estimates store m4

* Step 2: Build table
esttab m1 m2 m3 m4, ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("(1)" "(2)" "(3)" "(4)") ///
    title("Table 2: Price Determinants") ///
    drop(0.foreign _cons) ///
    order(mpg weight 1.foreign) ///
    stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f)) ///
    addnotes("Robust standard errors in parentheses." ///
             "Model 4 includes rep78 fixed effects, SEs clustered by rep78.")
```

### Adding custom rows

```stata
* Add rows for FE indicators
esttab m1 m2 m3 m4, ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2 fe_unit fe_year, ///
        labels("Observations" "R-squared" "Unit FE" "Year FE") ///
        fmt(%9.0fc %9.3f 0 0)) ///
    drop(_cons)
```

### Scalars for custom stats

```stata
quietly reghdfe y treat x1, absorb(id year) cluster(id)
estadd local fe_unit "Yes"
estadd local fe_year "Yes"
estimates store m1

esttab m1, stats(N r2 fe_unit fe_year, ///
    labels("N" "R-squared" "Unit FE" "Year FE"))
```

---

## 4. Export Formats

### RTF (Word-compatible)

```stata
esttab m1 m2 m3 using "$tables/table2_results.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("(1)" "(2)" "(3)") ///
    stats(N r2, labels("N" "R-squared") fmt(%9.0fc %9.3f))
```

### LaTeX

```stata
esttab m1 m2 m3 using "$tables/table2_results.tex", replace ///
    booktabs se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("(1)" "(2)" "(3)") ///
    label ///
    stats(N r2, labels("Observations" "\$R^2\$") fmt(%9.0fc %9.3f))
```

### CSV

```stata
esttab m1 m2 m3 using "$tables/table2_results.csv", replace csv ///
    se star(* 0.10 ** 0.05 *** 0.01)
```

---

## 5. Descriptive Statistics Tables (Table 1)

### Overall summary

```stata
estpost summarize price mpg weight length
esttab, cells("count mean(fmt(2)) sd(fmt(2)) min max") ///
    nomtitle nonumber ///
    title("Table 1: Descriptive Statistics")
```

### By-group summary with export

```stata
* Treatment group
estpost tabstat price mpg weight, by(foreign) stat(mean sd n) nototal
esttab using "$tables/table1_descriptives.rtf", replace ///
    cells("mean(fmt(2)) sd(fmt(2)) count") ///
    nomtitle nonumber
```

### Balance table with t-tests

```stata
foreach var in mpg weight length {
    quietly ttest `var', by(treat)
    local p_`var' = r(p)
}
* Report p-values alongside means
```

---

## 6. Graph Formatting for Publication

### Clean scheme setup

```stata
set scheme s1mono                    // black and white

* Or use grstyle for fine control
grstyle init
grstyle set plain
grstyle set legend 6, nobox
grstyle set color navy maroon forest_green dkorange
```

### Standard graph options

```stata
twoway (scatter y x) (lfit y x), ///
    title("Title") ///
    xtitle("X Label") ytitle("Y Label") ///
    xlabel(, labsize(small)) ///
    ylabel(, angle(horizontal) labsize(small)) ///
    legend(order(1 "Data" 2 "Fit") pos(6) rows(1)) ///
    graphregion(color(white)) ///
    note("Source: description.")
```

### Export at publication quality

```stata
graph export "$figures/figure1.pdf", replace        // vector (journals)
graph export "$figures/figure1.png", replace width(2400)  // raster (slides)
```

### Multi-panel figures

```stata
twoway scatter y1 x, name(g1, replace) title("Panel A")
twoway scatter y2 x, name(g2, replace) title("Panel B")
graph combine g1 g2, rows(1) graphregion(color(white))
graph export "$figures/combined.png", replace width(2400)
```

---

## 7. Model Diagnostics

### VIF (multicollinearity)

```stata
reg price mpg weight length, robust
estat vif
* VIF > 10 = high collinearity concern
```

### Residual diagnostics

```stata
reg price mpg weight, robust
predict resid, residual
predict yhat, xb

histogram resid, normal title("Residual Distribution")
graph export "$figures/resid_hist.png", replace

scatter resid yhat, yline(0, lpattern(dash)) ///
    title("Residuals vs Fitted")
graph export "$figures/resid_fitted.png", replace
```

### Heteroskedasticity test

```stata
reg price mpg weight
estat hettest
* If significant, use robust or cluster SEs (which you should anyway)
```

---

## 8. Complete Output Workflow

```stata
* ===========================================================================
* 04_output.do -- Tables and Figures
* ===========================================================================
clear all
set more off
use "$clean/analysis_sample.dta", clear

* --- Table 1: Descriptives ---
estpost summarize outcome treat income age
esttab using "$tables/table1_descriptives.rtf", replace ///
    cells("count mean(fmt(2)) sd(fmt(2)) min max") nomtitle nonumber

* --- Table 2: Main Models ---
quietly reg outcome treat, robust
estimates store m1
quietly reg outcome treat income age, robust
estimates store m2
quietly reghdfe outcome treat income age, absorb(state year) cluster(state)
estimates store m3

esttab m1 m2 m3 using "$tables/table2_main.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("(1)" "(2)" "(3)") ///
    stats(N r2, labels("N" "R-squared") fmt(%9.0fc %9.3f))

* --- Figure 1: Coefficient Plot ---
coefplot m3, drop(_cons) xline(0) title("Treatment Effect Estimates")
graph export "$figures/figure1_coefplot.png", replace width(2400)

* --- Figure 2: Margins ---
reg outcome i.treat##c.income age, robust
margins treat, at(income=(20000(10000)80000))
marginsplot, title("Predicted Outcome by Treatment") ytitle("Outcome")
graph export "$figures/figure2_margins.png", replace width(2400)

display "Output generation complete: $S_DATE $S_TIME"
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Average marginal effects | `margins, dydx(*)` |
| Margins at values | `margins, at(x=(1 2 3))` |
| Plot margins | `marginsplot` |
| Coefficient plot | `coefplot, drop(_cons) xline(0)` |
| Event study plot | `coefplot, keep(*.event_time) vertical` |
| Store estimates | `estimates store name` |
| Table to RTF | `esttab ... using "f.rtf", replace` |
| Table to LaTeX | `esttab ... using "f.tex", replace booktabs` |
| Table to CSV | `esttab ... using "f.csv", replace csv` |
| VIF | `estat vif` (after `reg`) |
| Residuals | `predict resid, residual` |
