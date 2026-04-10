## Stata Mode (Phase 1: Data Familiarization)

When working with Stata data (.dta files) or writing Stata cleaning scripts:

1. Read `reference/data-management.md` for merge/reshape/collapse patterns
2. Read `reference/gotchas.md` — especially: merge _merge checks, destring NA handling, missing value comparisons, string case sensitivity
3. Use `preserve`/`restore` for data safety
4. Use `tempfile`/`tempvar` for temporary objects
5. Always `tab _merge` after merge, `assert` expected row counts
6. Document sample drops with `count` before and after each restriction

### Stata-Specific Cleaning Patterns
- `destring`: Replace "NA"/non-numeric strings BEFORE calling destring
- `encode`: For converting string categoricals to numeric (preserves labels)
- `egen group()`: For creating numeric group IDs from string identifiers
- `isid`: Verify unique identifiers before merge
- `duplicates report` then `duplicates drop` with documentation
- `fillin`: Create balanced panel from unbalanced

### Data Documentation
- `describe` for variable overview
- `codebook varname` for detailed variable info
- `tab varname, missing` to check for missing patterns
- `summarize, detail` for distribution diagnostics
