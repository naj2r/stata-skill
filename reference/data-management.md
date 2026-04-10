# Data Management — Merge, Reshape, Collapse, Destring

---

## Merge: Always Check _merge

```stata
merge 1:1 person_id using income_data    // unique key in both
merge m:1 state_fips year using controls  // key unique in using only

tab _merge                                // ALWAYS inspect first
assert _merge == 3
drop _merge
```

**Gotchas:**
- `m:m` is almost always wrong — produces combinatorial explosion.
- Verify uniqueness BEFORE merging: `isid id` or `duplicates report id`.
- `keep(3) nogenerate` skips the `_merge` check — only when you are certain.
- `keepusing(var1 var2)` limits variables from the using dataset.
- `assert(match master) nogenerate` — assert + drop in one step.

---

## Reshape Wide/Long

```stata
reshape wide income, i(id) j(year)       // long → wide
reshape long income, i(id) j(year)       // wide → long
reshape long ht wt, i(famid) j(age)      // multiple stubs
reshape long score, i(id) j(subject) string  // string suffix
```

**Gotchas:**
- `i()` must uniquely identify rows in the TARGET format.
- `duplicates report id year` before reshaping — duplicates cause cryptic errors.
- `fillin id year` creates missing combinations (useful for balanced panels).

---

## Collapse — Destroys Your Data

**Always `preserve` first.**

```stata
preserve
collapse (mean) avg_inc=income (sd) sd_inc=income (count) n=income, by(state year)
save state_stats, replace
restore
```

### Collapse + Merge Back

```stata
tempfile groupstats
preserve
collapse (mean) mean_price=price, by(foreign)
save `groupstats'
restore
merge m:1 foreign using `groupstats', assert(match) nogenerate
```

**When `egen` is simpler:** `bysort foreign: egen mean_price = mean(price)`

Stats: `mean`, `median`, `sd`, `sum`, `count`, `min`, `max`, `p1`-`p99`, `firstnm`, `lastnm`.

---

## Append

```stata
use survey_2020, clear
append using survey_2021 survey_2022
```

**Gotcha:** Silently misaligns same-name variables with different types. Use `force` but inspect.

---

## Encode / Decode

```stata
encode gender_str, gen(gender)           // string → labeled numeric
decode gender, gen(gender_str)           // numeric → string
```

**Gotchas:**
- `encode` assigns codes ALPHABETICALLY. Pre-define labels for specific codes:
  ```stata
  label define g_lbl 0 "Male" 1 "Female"
  encode gender_str, gen(gender) label(g_lbl)
  ```
- Clean strings FIRST — `" Male"` and `"Male"` become separate categories.

---

## Destring

```stata
destring price_str, replace
destring price_str, gen(price) ignore("$" "," "%")
```

**NA handling:** Stata ignores `"NA"`, `"N/A"`, `"-999"`. Replace FIRST:
```stata
foreach var of varlist _all {
    capture confirm string variable `var'
    if !_rc { replace `var' = "" if inlist(`var', "NA", "N/A", ".", "missing") }
}
destring _all, replace
```

---

## Duplicates and isid

```stata
isid person_id                           // errors if not unique
duplicates report id year
duplicates tag id year, gen(dup)
bysort id year (revenue): keep if _n == _N   // keep highest revenue
```

## fillin

```stata
fillin id year
tab _fillin                              // _fillin=1 for new rows
```

---

## Deep Dive

- Stata [D] manual: `merge`, `reshape`, `collapse`, `append`, `encode`, `destring`
- `frames` (Stata 16+) avoids much preserve/collapse/merge overhead
- `ssc install reshapewide` for complex multi-stub reshaping
