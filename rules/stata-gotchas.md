# Stata: Critical Rules

When writing or editing `.do` files, ALWAYS follow these rules:

1. **NEVER** compare with `>`, `<`, `>=`, `<=` without also checking `& !missing(varname)` — missing values are +infinity in Stata
2. **NEVER** use `merge` without immediately checking `tab _merge` and handling unmatched observations
3. **NEVER** use `=` for comparison — use `==` (single `=` is assignment)
4. **NEVER** use `by varname:` without prior `sort` — use `bysort varname:` instead
5. **ALWAYS** use backtick-quote for local macros: `` `localname' `` — not `$localname` (that's globals)
6. **ALWAYS** pair `preserve` with `restore` (or `restore, not` to keep changes)
7. **ALWAYS** use `tempvar`/`tempfile` for temporary objects — never leave them behind
8. **ALWAYS** check `_rc` after `capture` — it swallows errors silently
9. **PREFER** `reghdfe` for fixed-effects regression over `areg` or manual dummies
10. **PREFER** `graph export` over `graph save` for publication figures (export produces PDF/PNG)

## Estimation Safety
- Store estimates with `estimates store` BEFORE running the next model — `e()` gets overwritten
- Estimate store names must be ≤32 characters (Stata hard limit)
- Use `i.` prefix for categorical variables in regressions — bare numeric vars are treated as continuous
- Use `///` for line continuation, not `\`
