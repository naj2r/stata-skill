# Graphics — Twoway, Histogram, Combine, Export, Coefplot

---

## graph twoway

### Scatter

```stata
twoway scatter mpg weight, msymbol(circle) mcolor(navy%60)

* With fit line and CI
twoway (scatter mpg weight) (lfitci mpg weight, fcolor(navy%15))

* By group
twoway (scatter mpg weight if foreign==0, mcolor(blue)) ///
       (scatter mpg weight if foreign==1, mcolor(red)), ///
       legend(order(1 "Domestic" 2 "Foreign"))
```

### Line / Connected

```stata
twoway (line y1 year, lcolor(navy)) (line y2 year, lcolor(maroon) lpattern(dash)), ///
    legend(order(1 "Series A" 2 "Series B"))
```

### Confidence Intervals

```stata
twoway (rarea upper lower x, fcolor(gray%20) lwidth(none)) ///
       (line estimate x, lcolor(navy)), legend(off)
```

---

## Histogram

```stata
histogram mpg, frequency bin(15)
histogram mpg, density normal             // overlay normal curve
histogram rep78, discrete percent addlabel
histogram mpg, by(foreign)
```

## Bar / Box

```stata
graph bar (mean) mpg, over(foreign) blabel(bar, format(%4.1f))
graph box mpg, over(foreign) noout
```

**Gotcha:** `graph box` is NOT a `twoway` plot — cannot nest inside `twoway`.

---

## Titles, Axes, Legends

```stata
twoway scatter mpg weight, ///
    title("Title") xtitle("Weight (lbs)") ytitle("MPG") ///
    xlabel(2000(1000)5000, format(%9.0fc)) ylabel(10(5)40, angle(0)) ///
    note("Source: auto.dta") graphregion(color(white)) ///
    legend(position(6) rows(1))
```

Legend position: clock notation. `position(6)`=bottom. `ring(0) position(5)`=inside plot.

---

## Schemes

```stata
set scheme s1mono            // B&W journals
set scheme plotplain         // ssc install blindschemes
set scheme white_tableau     // ssc install schemepack

ssc install grstyle
grstyle init
grstyle set plain
```

---

## graph combine

```stata
twoway scatter mpg weight, name(g1, replace) nodraw title("Panel A")
twoway scatter price weight, name(g2, replace) nodraw title("Panel B")
graph combine g1 g2, rows(1) ycommon title("Combined")
```

**Gotcha:** Set scheme BEFORE creating individual graphs. Use `nodraw` for named graphs.

---

## graph export

```stata
graph export "fig.pdf", replace              // LaTeX
graph export "fig.png", width(3000) replace  // high-res journal
graph export "fig.png", width(1200) replace  // Word/slides
graph save "fig.gph", replace                // editable Stata format
```

---

## coefplot

```stata
ssc install coefplot

reg price mpg weight foreign i.rep78
coefplot, drop(_cons) xline(0) title("Coefficient Plot")

* Multiple models
coefplot m1 m2 m3, drop(_cons) xline(0) ///
    legend(order(2 "Baseline" 4 "Controls" 6 "Full"))
```

## Event Study Plots

```stata
coefplot, keep(lead* lag*) vertical yline(0, lpattern(dash)) ///
    xline(5.5, lcolor(red) lpattern(dash)) ///
    xtitle("Event Time") ytitle("Effect") ciopts(recast(rcap))
```

## marginsplot

```stata
regress mpg c.weight##i.foreign
margins foreign, at(weight=(2000(500)4500))
marginsplot, recast(line) recastci(rarea)
```

## binscatter

```stata
ssc install binscatter
binscatter y x, controls(z1 z2) xtitle("X") ytitle("Y | Controls")
```

---

## Deep Dive

- Stata [G] manual (19 MB PDF)
- Mitchell (2012) *A Visual Guide to Stata Graphics*
- `help twoway`, `help coefplot`
