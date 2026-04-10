# Architecture

## The Problem

A flat skill file for Stata faces a trade-off. Too short, and Claude lacks the detail to write correct code (missing value semantics, merge conventions, panel data patterns). Too long, and every session pays the context window cost even when the user only needs a quick `summarize`.

Previous approaches either dump everything into one file (wastes context, dilutes attention) or provide nothing (Claude reinvents Stata conventions from scratch every session, making the same mistakes).

## The Solution: Tiered Progressive Disclosure

The bundle organizes Stata knowledge into tiers that load progressively based on task complexity.

```
User prompt
    |
    v
SKILL.md (Tier 1, always loaded, ~120 lines)
    |--- Routing table lookup
    |         |
    v         v
reference/X.md (Tier 2, on-demand, 100-150 lines each)
    |
    v  (if full pipeline needed)
technique-guides/X.md (Tier 3, end-to-end workflows)
    |
    v  (if still stuck)
Stata PDF documentation (Tier 4, last resort via pdfgrep)
    |
    v  (if reference gap found)
UPGRADE_LOG.md (log for human review)
```

Most tasks resolve at Tier 1 or Tier 2. A typical regression task loads SKILL.md (always) plus one reference file. Only full analysis pipelines reach Tier 3.

## Tier 1: SKILL.md (Always Loaded)

SKILL.md is the entry point. It contains:

- **Environment auto-detection:** Searches PATH and common install locations for Stata.
- **CLI invocation:** Batch mode flags for Windows (`/e`) and Unix (`-b`).
- **Top-5 gotchas:** The highest-frequency mistakes, always visible.
- **Do-file template:** Standard header, bootstrap block, logging.
- **Coding conventions:** Naming, estimation, data safety patterns.
- **Routing table:** Maps tasks to reference files. Claude reads 1-2 files per task.
- **Escalation protocol:** What to do when the routing table is not enough.
- **Phase protocol:** How Stata work maps to clo-author's adversarial agent system.

At ~120 lines, this costs minimal context but handles the majority of requests.

## Tier 2: reference/ Files (On Demand)

Eleven reference files, each 100-150 lines, covering specific domains:

| File | Covers |
|------|--------|
| `gotchas.md` | All 15+ Stata pitfalls with code examples |
| `data-management.md` | merge, reshape, collapse, append |
| `regression.md` | reghdfe, IV, margins, post-estimation |
| `panel-data.md` | xtreg, xtset, panel diagnostics |
| `did-event-study.md` | DiD, TWFE, csdid, event studies |
| `tables-output.md` | esttab, estout, etable, LaTeX tables |
| `graphics.md` | graph twoway, schemes, export |
| `programming.md` | macros, loops, programs, Mata |
| `matching-iv.md` | psmatch2, ivreg2, teffects |
| `documentation.md` | Stata PDF docs, pdfgrep, cheap-scan1 |
| `mcp-stata.md` | MCP server tool reference |

Claude selects files via the routing table in SKILL.md. The routing table maps task descriptions to file paths so Claude does not need to guess.

## Tier 3: technique-guides/ (Full Pipelines)

Five technique guides provide end-to-end workflows for multi-step analysis:

| File | Covers |
|------|--------|
| `core-econometrics.md` | Full DiD/IV/matching analysis |
| `data-prep.md` | Data cleaning pipeline |
| `postestimation-reporting.md` | margins, coefplot, esttab workflow |
| `robustness-sensitivity.md` | Placebo, permutation, alternative specs |
| `best-practices.md` | Reproducibility, logging, assertions |

These load only when Claude is executing a full analysis pipeline, not for isolated commands.

## Tier 4: Stata PDF Documentation (Last Resort)

When reference files do not cover a topic, Claude can search Stata's PDF manuals using `pdfgrep` or the "cheap-scan1" pattern documented in `reference/documentation.md`. This is slow and context-heavy, so it is the last resort before logging a gap.

## Escalation Protocol

The protocol in SKILL.md defines the order:

1. **Use routing table** to load 1-2 reference files.
2. **If do-file fails:** Read `reference/gotchas.md` and check against all pitfalls.
3. **If method is wrong:** Read the relevant technique guide for end-to-end workflow.
4. **If still stuck:** Search Stata PDF docs with pdfgrep.
5. **If reference gap:** Log to `UPGRADE_LOG.md` for human review.

This keeps context usage proportional to task difficulty.

## Supporting Infrastructure

### hooks/stata-lint.sh

A PreToolUse hook that fires on every Edit or Write to a `.do` file. Checks for the 5 most common mistakes (missing value comparisons, merge without `_merge`, single `=` in conditions, bare `by` without sort, global macro syntax with locals). Warns via stderr but never blocks -- exit code is always 0.

### rules/stata-gotchas.md

Always-in-context rules file. Contains the top 10 Stata rules plus estimation safety notes. Unlike reference files (which load on demand), this is present in every session where the Stata skill is active.

### agent-patches/

Markdown snippets appended to clo-author agent files by `sync.sh`. Adds Stata awareness to the coder, data-engineer, and coder-critic agents without replacing their existing content.

### UPGRADE_LOG.md

A structured log where Claude records gaps it discovers during Stata work. You review this periodically and push improvements to the reference files. See [Learning Loop](learning-loop.md).
