# Stata Gotchas — Critical Pitfalls

These are Stata-specific traps that cause silent bugs. Check your code against ALL of these before running.

---

## 1. Missing Values Sort to +Infinity

Stata's `.` (and `.a`-`.z`) are **greater than all numbers**. Any comparison using `>` or `>=` includes missing values.

```stata
* WRONG — includes observations where income is missing!
gen high_income = (income > 50000)

* RIGHT — explicitly exclude missing
gen high_income = (income > 50000) if !missing(income)

* WRONG — missing ages appear in this list
list if age > 60

* RIGHT
list if age > 60 & !missing(age)
```

**Rule:** Every `>`, `>=` comparison MUST have `& !missing(var)` unless you intend to include missing.

---

## 2. `=` vs `==` in Expressions

`=` is assignment; `==` is comparison. Mixing them is a syntax error or silent bug.

```stata
* WRONG — syntax error
gen employed = 1 if status = 1

* RIGHT
gen employed = 1 if status == 1
```

---

## 3. Local Macro Syntax

Locals use `` `name' `` (backtick + single-quote). Globals use `$name` or `${name}`. Forgetting the closing quote is the #1 macro bug.

```stata
local controls "age education income"
regress wage `controls'        // correct
regress wage `controls         // WRONG — missing closing quote
regress wage 'controls'        // WRONG — wrong quote characters
```

---

## 4. `by` Requires Prior Sort (Use `bysort`)

```stata
* WRONG — error if data not sorted by id
by id: gen first = (_n == 1)

* RIGHT — bysort sorts automatically
bysort id: gen first = (_n == 1)
```

---

## 5. Factor Variable Notation (`i.` and `c.`)

Use `i.` for categorical, `c.` for continuous. Omitting `i.` treats categories as continuous.

```stata
* WRONG — treats race as continuous (race=3 has 3x effect of race=1)
regress wage race education

* RIGHT — creates dummies automatically
regress wage i.race education

* Interactions
regress wage i.race##c.education    // full factorial (main effects + interaction)
regress wage i.race#c.education     // interaction only (no main effects)
```

---

## 6. `generate` vs `replace`

`generate` creates new variables; `replace` modifies existing. Using `generate` on an existing name errors.

```stata
gen x = 1
gen x = 2          // ERROR: x already defined
replace x = 2      // correct
```

---

## 7. String Comparison Is Case-Sensitive

```stata
* May miss "Male", "MALE", etc.
keep if gender == "male"

* Safer — normalize case first
keep if lower(gender) == "male"
```

Also watch for leading/trailing spaces: use `strtrim()`.

---

## 8. `merge` — Always Check `_merge`

Never skip `tab _merge`. It costs nothing and is the only diagnostic you get.

```stata
merge 1:1 id using other.dta
tab _merge                      // ALWAYS do this
assert _merge == 3              // or handle _merge != 3 explicitly
drop _merge
```

Common `_merge` values: 1 = master only, 2 = using only, 3 = matched.

---

## 9. `preserve` / `restore` Must Be Paired

```stata
preserve
collapse (mean) avg_x=x, by(group)
* ... do something with collapsed data ...
restore                          // returns to pre-collapse data

* If you want to KEEP changes instead of restoring:
restore, not
```

Standard collapse-merge-back pattern:
```stata
tempfile stats
preserve
collapse (mean) avg_x=x, by(group)
save `stats'
restore
merge m:1 group using `stats'
tab _merge
assert _merge == 3
drop _merge
```

For simple group stats, `bysort group: egen avg_x = mean(x)` avoids the round-trip.

---

## 10. Weight Types Are Not Interchangeable

- `fweight` — frequency weights (replication: each obs represents N identical obs)
- `aweight` — analytic weights (inverse variance: `1/variance` or population size)
- `pweight` — probability/sampling weights (survey: implies robust SE automatically)
- `iweight` — importance weights (rarely used outside ML estimation)

Using the wrong weight type produces valid-looking but wrong results.

---

## 11. `capture` Swallows Errors Silently

```stata
* WRONG — error is silently eaten
capture drop myvar

* RIGHT — check return code after capture
capture some_command
if _rc != 0 {
    di as error "Failed with code: " _rc
    exit _rc
}
```

---

## 12. Line Continuation Uses `///`

```stata
regress y x1 x2 x3 ///
    x4 x5 x6, ///
    vce(robust)
```

Do NOT use `\` (that's other languages). Bare newlines break the command.

---

## 13. Stored Results: `r()` vs `e()` vs `s()`

- `r()` — r-class commands (`summarize`, `tabulate`, `count`, etc.)
- `e()` — e-class commands (estimation: `regress`, `logit`, `reghdfe`, etc.)
- `s()` — s-class commands (parsing — rarely used directly)

A new estimation command **overwrites** previous `e()` results. Store them first:
```stata
regress y x1 x2
estimates store model1
* Now safe to run another regression
```

---

## 14. `egen` Functions Differ from `gen` Functions

```stata
* WRONG — gen doesn't have mean()
gen avg = mean(x)

* RIGHT — use egen for aggregate functions
egen avg = mean(x)

* Group-specific:
bysort group: egen group_avg = mean(x)
```

`egen` functions: `mean`, `total`, `count`, `min`, `max`, `sd`, `median`, `pctile`, `rowmean`, `rowtotal`, `group`, `tag`, `rank`, `std`.

---

## 15. `destring` Fails on Mixed-Type Columns

If data has `"NA"`, `"."`, or other non-numeric strings, `destring` fails or silently drops observations.

```stata
* WRONG — fails if column has "NA" strings
destring income, replace

* RIGHT — replace NA strings first
replace income_str = "" if income_str == "NA"
destring income_str, gen(income) force
```

Always check for non-numeric strings before `destring`:
```stata
list if real(income_str) == . & income_str != "" & income_str != "."
```

---

## Deep Dive

For comprehensive Stata programming reference, consult:
- `u.pdf` (User's Guide) — Chapter 12: Data, Chapter 13: Functions, Chapter 18: Programming
- `p.pdf` (Programming Reference) — macros, loops, programs, Mata
- dylantmoore/stata-skill `references/` directory — 37 detailed reference files
