# Tables and Output — esttab, estout, etable, LaTeX

---

## Core Workflow: Estimate, Store, Table

```stata
ssc install estout    // provides esttab, estout, estpost, eststo

eststo clear
eststo m1: quietly regress price mpg, robust
eststo m2: quietly regress price mpg weight, robust
eststo m3: quietly regress price mpg weight foreign, robust

esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R-squared") fmt(%9.0fc %9.3f))
```

---

## esttab — Publication Tables

### LaTeX Export

```stata
esttab m1 m2 m3 using "table1.tex", replace booktabs ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) label ///
    mtitles("(1)" "(2)" "(3)") ///
    title("Table 1: Price Determinants\label{tab:main}") ///
    stats(N r2, fmt(%9.0fc %9.3f) labels("Observations" "R-squared")) ///
    addnotes("Robust standard errors in parentheses.")
```

### RTF (Word)

```stata
esttab m1 m2 m3 using "table1.rtf", replace se star(* 0.10 ** 0.05 *** 0.01)
```

### Key Options

| Option | Purpose |
|--------|---------|
| `se`/`t`/`p`/`ci` | Below coefficients |
| `b(fmt)` `se(fmt)` | Number format |
| `label` | Variable labels |
| `booktabs` | LaTeX formatting |
| `keep()`/`drop()` | Variable selection |
| `indicate()` | FE indicators |
| `stats()` | Summary stats rows |
| `mgroups()` | Column group headers |

---

## Adding FE Indicators and Dep Var Mean

```stata
* FE indicators (for reghdfe — must add manually since absorb() hides them)
estadd local firm_fe "Yes" : m1 m2
estadd local year_fe "No" : m1
estadd local year_fe "Yes" : m2

* Dep var mean
quietly summarize price
estadd scalar depvar_mean = r(mean) : m1 m2

esttab m1 m2, se ///
    stats(firm_fe year_fe depvar_mean N r2, ///
        labels("Firm FE" "Year FE" "Dep. Var. Mean" "Observations" "R-squared") ///
        fmt(0 0 %9.2f %9.0fc %9.3f))
```

---

## Multi-Panel with mgroups

```stata
esttab using "table.tex", replace booktabs ///
    mgroups("OLS" "IV", pattern(1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) ///
        span erepeat(\cmidrule(lr){@span}))
```

---

## estout — More Control

```stata
estout m1 m2 using "table.tex", style(tex) replace ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N r2, fmt(0 3) labels("N" "R-squared")) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) legend label
```

## etable (Stata 17+)

Built-in, no package needed:
```stata
etable, estimates(m1 m2) showstars showstarsnote ///
    export("table1.docx", replace)
```

---

## Summary Statistics Tables

```stata
estpost summarize price mpg weight, detail
esttab, cells("mean(fmt(2)) sd(fmt(2)) min max count") nomtitle nonumber

* Balance table
estpost ttest price mpg weight, by(treatment)
esttab, cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2) star)") nomtitle nonumber
```

---

## LaTeX Tips

```stata
* Fragment (default) — include via \input{table.tex}
esttab using "table.tex", booktabs replace

* Custom preamble (threeparttable)
esttab using "table.tex", booktabs label replace ///
    prehead("\begin{table}[htbp]\centering" ///
            "\caption{Main Results}\begin{threeparttable}" ///
            "\begin{tabular}{l*{3}{c}}") ///
    postfoot("\end{tabular}" ///
             "\begin{tablenotes}\footnotesize" ///
             "\item Standard errors in parentheses." ///
             "\end{tablenotes}\end{threeparttable}\end{table}")
```

---

## Gotchas

- Forgetting `replace` — file exists error.
- `estimates table` does NOT support `title()` — use `esttab`.
- Missing variable labels — set `label variable` before `esttab ..., label`.
- Always test `.tex` output compiles before submission.

---

## Deep Dive

- `help esttab` — full option reference
- Ben Jann's estout docs: <http://repec.sowi.unibe.ch/stata/estout/>
- `help etable` — Stata 17+ built-in tables
- Stata [TABLES] manual (5 MB PDF) — the `collect` framework
