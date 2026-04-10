# Programming — Macros, Loops, Programs, Tempfiles, Mata

## Local Macros (backtick-quote syntax!)

Referenced with `` `name' `` — backtick on the left, single quote on the right.

```stata
local filename "mydata.dta"
use "`filename'", clear

local controls "age education income"
regress outcome treatment `controls'
```

**Extended macro functions:**
```stata
local lbl : variable label price
local count : word count `mylist'
local third : word 3 of `mylist'
```

**Gotcha:** Locals vanish when the do-file or program ends. Globals (`$name`) persist for the session — use only for project paths (`global datadir "/home/user/data"`).

---

## forvalues / foreach

```stata
forvalues i = 1/10 {
    display "Iteration `i'"
}

foreach var of varlist price mpg weight {
    quietly summarize `var'
    display "`var': mean = " r(mean)
}

foreach y of local outcomes {
    regress `y' treatment, robust
    estimates store model_`y'
}
```

**Gotcha:** Stata has NO `++`, `--`, `+=`. Increment manually: `local i = `i' + 1`.

---

## Programs with syntax

```stata
capture program drop myreg
program define myreg
    version 17
    syntax varlist(min=2) [if] [in] [, Robust CLuster(varname)]
    gettoken depvar indepvars : varlist
    if "`cluster'" != "" {
        regress `depvar' `indepvars' `if' `in', cluster(`cluster')
    }
    else {
        regress `depvar' `indepvars' `if' `in' `=cond("`robust'"!="",", robust","")'
    }
end
```

Key: `varlist(min=2 numeric)`, `[if] [in]`, capitalize minimal abbreviation in option names.

## tempvar / tempfile

```stata
tempfile merged
save `merged'
use otherdata, clear
merge 1:1 id using `merged'
```

## return / ereturn

```stata
program define compute_stats, rclass
    syntax varname
    quietly summarize `varlist'
    return scalar mean = r(mean)
end
```

**Gotcha:** r-class results overwritten by NEXT r-class command. Save to locals: `local m = r(mean)`. e-class persists until the next estimation command.

## preserve / restore / quietly / capture

```stata
preserve
collapse (mean) avg_price=price, by(foreign)
restore

quietly regress price mpg weight
display "R2 = " e(r2)

capture confirm file "data.dta"
if _rc { display "File not found" }
```

---

## Mata Basics

Compiled matrix language — 10-1000x faster for loops and matrix ops.

```stata
mata
    X = st_data(., ("mpg", "weight"))     // read (copies data)
    st_view(V, ., ("mpg", "weight"))      // view (no copy, faster)
    XtX = cross(X, X)                     // X'X
    st_numscalar("r(mean_mpg)", mean(X[.,1]))
end
display r(mean_mpg)
```

**Key st_* functions:** `st_data`, `st_view`, `st_store`, `st_numscalar`, `st_global`, `st_addvar`. Do not call Stata commands inside Mata loops.

---

## Deep Dive

- Stata [P] manual (4 MB PDF): `syntax`, `program`, `macro`, `return`
- Stata [M] manual: complete Mata reference
- `help syntax` — the parsing engine specification
- `help mata` — Mata overview
