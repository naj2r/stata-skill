# Agent Integration with clo-author

This bundle is designed to plug into [hugosantanna/clo-author](https://github.com/hugosantanna/clo-author), an adversarial agent system for economics research. This page explains how nealcaren's 6-phase research workflow maps to clo-author's agents, what gets patched into each agent, and how the adversarial review loop works.

## The Adversarial Agent System

clo-author uses three agents in a review loop:

- **coder** -- writes code, runs analysis, produces output
- **data-engineer** -- handles data loading, cleaning, transformation
- **coder-critic** -- reviews code for correctness, robustness, and methodology

The loop works like this: the coder (or data-engineer) writes code, then the coder-critic reviews it. If the critic finds issues, the coder revises. This continues until the critic approves. The Stata skill bundle adds Stata-specific awareness to each agent so the adversarial loop catches Stata-specific mistakes.

## Phase Protocol

nealcaren's 6-phase research workflow provides structure for empirical analysis. Each phase flows through the adversarial system automatically.

| Phase | Name | Primary Agent | Stata Skill Action |
|-------|------|---------------|-------------------|
| 0 | Design | strategist | No Stata action. Research design and identification strategy. |
| 1 | Data | data-engineer | Load/inspect data. Read `reference/data-management.md`. |
| 2 | Specification | coder | Write estimating equation. Read relevant reference file. Submit to coder-critic BEFORE running estimation. |
| 3 | Analysis | coder | Implement specification. Read `technique-guides/core-econometrics.md` if needed. |
| 4 | Robustness | coder | Read `technique-guides/robustness-sensitivity.md`. Implement all checks from strategy memo. |
| 5 | Output | coder | Read `reference/tables-output.md`. Produce publication-ready tables and figures. |

Each phase passes through the coder-critic for review before advancing to the next phase.

## What Gets Patched

`sync.sh` appends Stata-specific sections to the existing agent markdown files. It never overwrites -- it appends, and it skips if a Stata section is already present.

### coder.md: "Stata Mode" Section

Added to the coder agent:
- Language detection trigger (when Stata is detected in the project or prompt)
- Instruction to read SKILL.md and follow the routing table
- Phase protocol awareness (which reference files to load per phase)
- Do-file template and coding conventions
- Escalation protocol for when reference files are insufficient

### data-engineer.md: "Stata Mode" Section

Added to the data-engineer agent:
- Stata data loading patterns (`use`, `import delimited`, `import excel`)
- Data inspection checklist (`describe`, `codebook`, `tab`, `summarize`)
- Merge and reshape conventions with `_merge` checking
- Reference to `reference/data-management.md` for detailed patterns

### coder-critic.md: "Stata Code Quality" Checklist

Added to the coder-critic agent:
- Missing value checks (comparisons must include `!missing()`)
- Merge validation (every `merge` must have `_merge` handling)
- Macro syntax verification (locals use backtick-quote, globals use `$`)
- Estimation safety (estimates stored before next model, names under 32 chars)
- Panel data checks (data `xtset` before panel commands)
- Reproducibility checks (log files, assertions, `set seed` for randomization)

## Flow Diagram

```
User request (mentions Stata or project has .do files)
    |
    v
Language detection (SKILL.md triggers)
    |
    v
Phase protocol determines current phase
    |
    v
+------------------------------------------+
|  coder / data-engineer                   |
|  - Reads SKILL.md routing table          |
|  - Loads 1-2 reference files             |
|  - Writes do-file following conventions  |
+------------------------------------------+
    |
    v
+------------------------------------------+
|  stata-lint.sh (PreToolUse hook)         |
|  - Warns on common .do file mistakes     |
|  - Agent self-corrects if warned         |
+------------------------------------------+
    |
    v
+------------------------------------------+
|  coder-critic                            |
|  - Reviews against Stata checklist       |
|  - Checks missing values, merges, macros |
|  - Approves or requests revision         |
+------------------------------------------+
    |
    |--- Issues found ---> back to coder
    |
    v (approved)
Next phase (or done)
```

## Deliberation Mode

By default, phases flow automatically without pausing between them. To pause for user input between phases, pass `--deliberate`:

```
--deliberate
```

With deliberation on, after each phase completes and the coder-critic approves, the system pauses and asks for your input before starting the next phase. This is useful for:

- Reviewing intermediate results before proceeding
- Adjusting the analysis strategy mid-stream
- Adding ad-hoc robustness checks not in the original plan

Deliberation is off by default because most established workflows benefit from uninterrupted execution.

## How sync.sh Patches Agents

The patching process:

1. `sync.sh` checks if `<project>/.claude/agents/` exists.
2. For each agent file (`coder.md`, `data-engineer.md`, `coder-critic.md`):
   - Reads the corresponding patch from `agent-patches/` (e.g., `coder-stata-mode.md`)
   - Checks if the target already contains "Stata Mode" or "Stata Code Quality"
   - If not present, appends the patch (preceded by a blank line) to the end of the agent file
   - If already present, skips with a message
3. Patch files are plain markdown that start with a heading like `## Stata Mode`.

To undo a patch, remove the Stata section from the bottom of the agent file. To update a patch, remove the old section and re-run `sync.sh`.

## Standalone Use (Without clo-author)

The Stata skill works without clo-author. Without the agent system:
- SKILL.md still loads and provides routing, gotchas, and conventions
- The lint hook still catches mistakes
- The rules file still provides always-in-context guidance
- The phase protocol section in SKILL.md is simply ignored

The agent patches are the only component specific to clo-author.
