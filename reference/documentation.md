# Stata Documentation — PDF Manuals, Lookup Strategy

Stata ships ~37 PDF manuals. Knowing which one to check saves enormous time.

---

## Manual Reference Table

| File | Topic | Size | When to Check |
|------|-------|------|---------------|
| r.pdf | Estimation commands | 30 MB | Any regression/estimation command |
| bayes.pdf | Bayesian analysis | 19 MB | Bayesian models |
| g.pdf | Graphics | 19 MB | Any graph customization |
| xt.pdf | Panel data | 12 MB | xtreg, xtset, panel methods |
| me.pdf | Marginal effects | 9 MB | margins, marginsplot |
| d.pdf | Data management | 8 MB | merge, reshape, collapse, import |
| causal.pdf | Causal inference | 7 MB | teffects, DiD, treatment effects |
| tables.pdf | Tables | 5 MB | table, collect, etable |
| p.pdf | Programming | 4 MB | syntax, program, macros, Mata interface |
| u.pdf | User's Guide | 4 MB | General orientation, basics |
| mi.pdf | Multiple imputation | 4 MB | mi commands |
| sem.pdf | Structural equations | 4 MB | SEM, factor analysis |
| st.pdf | Survival analysis | 3 MB | stcox, streg, sts |
| ts.pdf | Time series | 3 MB | arima, var, vecm |
| svy.pdf | Survey data | 3 MB | svyset, svy: prefix |
| mv.pdf | Multivariate | 3 MB | manova, pca, cluster |
| cm.pdf | Choice models | 2 MB | mlogit, clogit |
| fp.pdf | Fractional polynomials | 1 MB | fp, mfp |
| irt.pdf | Item response theory | 1 MB | irt commands |
| lasso.pdf | Lasso/ML | 1 MB | lasso, elasticnet |
| m.pdf | Mata reference | Large | Mata functions, st_* interface |
| mata.pdf | Mata language | Large | Mata programming |

### Most Commonly Needed for Applied Micro

1. **r.pdf** — `regress`, `logit`, `ivregress`, `poisson`, etc.
2. **xt.pdf** — `xtreg`, `xtset`, `xtpoisson`, panel diagnostics
3. **d.pdf** — `merge`, `reshape`, `collapse`, `import`
4. **g.pdf** — all graph types, schemes, export
5. **p.pdf** — programming, macros, `syntax` command
6. **causal.pdf** — `teffects`, built-in DiD (Stata 17+)

---

## Three Methods to Read Efficiently

### Method 1: Cheap Scan with pdftotext

Extract text and search with standard tools. Fast for keyword lookup.

```bash
# Extract text from a manual
pdftotext -layout r.pdf r.txt

# Search for a command
grep -i "ivregress" r.txt | head -20

# Search across all manuals
for f in *.pdf; do
    pdftotext -layout "$f" - | grep -l "margins" && echo "$f"
done
```

### Method 2: Split PDF into Sections

Large manuals (r.pdf = 30 MB) are unwieldy. Split into per-command sections.

```bash
# Using pdftk or qpdf to extract page ranges
# First check the table of contents for page numbers
qpdf r.pdf --pages r.pdf 1523-1580 -- regress_section.pdf
```

### Method 3: pdfgrep (Direct PDF Search)

```bash
# Search directly in PDFs without extraction
pdfgrep -i "heteroskedasticity" r.pdf
pdfgrep -c "margins" *.pdf          # count matches per file
pdfgrep -n "vce(cluster" r.pdf      # with page numbers
```

---

## Which Manual for Which Topic

| I need help with... | Check |
|---------------------|-------|
| `regress`, `logit`, `ivregress` | r.pdf |
| `xtreg`, `xtset`, `xtpoisson` | xt.pdf |
| `merge`, `reshape`, `collapse` | d.pdf |
| `margins`, `marginsplot` | me.pdf (or r.pdf postestimation) |
| `graph twoway`, `scheme` | g.pdf |
| `teffects`, `didregress` | causal.pdf |
| `esttab`, `estout` | NOT in manuals — these are user-written. See `help esttab` |
| `reghdfe` | NOT in manuals — see `help reghdfe` or GitHub |
| Macros, loops, `syntax` | p.pdf |
| `svyset`, survey commands | svy.pdf |
| `mi` commands | mi.pdf |
| Matrix operations | m.pdf / mata.pdf |

**Gotcha:** User-written packages (`reghdfe`, `estout`, `csdid`, `psmatch2`, etc.) are NOT in the official manuals. Use `help command` in Stata or check the package's documentation online.

---

## In-Stata Help System

```stata
help regress                    // command help
help regress postestimation     // what you can do AFTER regress
help margins                    // full margins documentation
search panel data               // keyword search
findit csdid                    // find user-written packages
```

`help command` is often faster than the PDF manual for quick syntax reference.

---

## Online Resources

- **Stata documentation**: <https://www.stata.com/manuals/>
- **Stata FAQ**: <https://www.stata.com/support/faqs/>
- **Statalist**: <https://www.statalist.org/> — official forum
- **UCLA IDRE**: <https://stats.oarc.ucla.edu/stata/> — tutorials
- **SSC archive**: <https://ideas.repec.org/s/boc/bocode.html> — user-written packages

---

## Deep Dive

- The User's Guide (u.pdf) is the best starting point for Stata newcomers
- For any estimation command, the PDF manual entry includes worked examples
- The `[R]` manual's postestimation sections document `predict`, `margins`, `test`, `lincom` for each command
