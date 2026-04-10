# Learning Loop

The bundle includes a feedback system so that Claude's Stata mistakes lead to real improvements over time. Four components work together: the lint hook catches mistakes in real time, the rules file prevents known pitfalls, the escalation protocol drives Claude to deeper references when needed, and the upgrade log captures gaps for you to fix.

## stata-lint.sh: Real-Time Warnings

The `hooks/stata-lint.sh` script is a PreToolUse hook that fires on every `Edit` or `Write` operation targeting a `.do` file. It checks the content being written for five common mistakes:

1. **Numeric comparison without `!missing()` check** -- catches `if x > 100` without `& !missing(x)`
2. **`merge` without `_merge` check** -- catches merge commands not followed by `tab _merge` or `assert _merge`
3. **Single `=` in if conditions** -- catches `if status = 1` (should be `==`)
4. **Bare `by` without sort** -- catches `by var:` without prior `sort` (should be `bysort var:`)
5. **Global macro syntax with local definitions** -- catches `$name` when `local` macros are defined

The hook warns via stderr (visible in Claude's context) but never blocks. Exit code is always 0. This means Claude sees the warning immediately and can self-correct before the user notices.

## stata-gotchas.md: Always-in-Context Rules

The `rules/stata-gotchas.md` file contains the top 10 Stata rules plus estimation safety notes. Unlike reference files (which load on demand), rules are present in every session where the Stata skill is active at the project level.

This covers ground that the lint hook cannot: patterns like "use `reghdfe` over `areg`" or "store estimates before running the next model" are convention choices, not syntactic errors a regex can catch.

## Escalation Protocol

SKILL.md defines a 5-step escalation protocol that drives Claude to progressively deeper reference material:

1. **Routing table** -- load 1-2 reference files for the task at hand
2. **Gotchas check** -- if a do-file fails, read `reference/gotchas.md` and check all 15+ pitfalls
3. **Technique guide** -- if the method is wrong, read the relevant end-to-end workflow
4. **PDF docs** -- if still stuck, search Stata's PDF manuals via pdfgrep
5. **Upgrade log** -- if no reference covers the topic, log the gap

Each step costs more context but provides more detail. Most tasks resolve at step 1. The protocol prevents Claude from jumping straight to expensive operations (PDF scanning) when a quick reference file would suffice.

## UPGRADE_LOG.md: Closing the Loop

When Claude encounters a topic not covered by existing reference files, it logs a structured entry to `UPGRADE_LOG.md`:

```
## [date] -- [topic] -- [what was missing] -- [suggested addition]
```

To close the loop:

1. Review `UPGRADE_LOG.md` periodically (weekly or after a batch of Stata work).
2. For each entry, decide whether it warrants an update to a reference file, a new gotcha rule, or a new lint check.
3. Make the edit in the source repo.
4. Clear the processed log entries.
5. Re-deploy with `./sync.sh` (and `./sync.sh /path/to/project` for project-level).

This turns Claude's runtime failures into permanent improvements.

## Example Cycle

Here is a concrete example of the learning loop in action:

1. **User asks** Claude to merge two datasets in a do-file.
2. **Claude writes** a `merge 1:1` command without checking `_merge`.
3. **stata-lint.sh fires** on the Write operation and emits: `WARNING [stata-lint]: merge without _merge check.`
4. **Claude sees the warning** in its context and adds `tab _merge` and `assert _merge == 3` after the merge.
5. **Next session**, Claude reads `rules/stata-gotchas.md` (always in context) which says: "NEVER use merge without immediately checking tab _merge." Claude writes the merge correctly from the start.
6. **If a novel pattern arises** (say, Claude does not know how to handle `_merge == 2` observations in a specific context), it reads `reference/data-management.md` via the routing table.
7. **If the reference file lacks guidance** on that specific pattern, Claude logs to `UPGRADE_LOG.md`.
8. **You review** the log entry, add the pattern to `reference/data-management.md`, and re-deploy.

Over time, the reference files grow to cover the patterns that actually come up in your work.
