# Customization

## Overriding the Auto-Detected Stata Path

SKILL.md auto-detects Stata by searching PATH and common install locations. To override this (non-standard install, multiple versions, or specific edition):

```bash
export STATA_BIN="/path/to/your/stata-mp"
```

Add this to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to make it permanent. The test script and SKILL.md both honor `STATA_BIN` if set.

## Project-Specific Coding Conventions

The user-level skill provides general Stata knowledge. Projects often have their own conventions (variable naming, directory structure, master do-file patterns).

To add project-specific overrides, create a project-level skill file:

```
<project>/.claude/skills/stata/SKILL.md
```

When both user-level and project-level skills exist, Claude defers to the project-level file for project conventions and uses the user-level file for general Stata knowledge. Your project-level SKILL.md can be minimal -- just the conventions that differ from the defaults:

```markdown
---
name: stata
description: "Project-specific Stata conventions for [project name]"
---

# Project Stata Conventions

- Variable naming: `varname_source` (e.g., `emissions_epa`)
- All do-files must source `code/master/paths.do` and `code/master/globals.do`
- Output tables go to `$OUTPUT/tables/` as `.tex` files
- Figures go to `$OUTPUT/figures/` as `.pdf` files
- Preferred clustering: `vce(cluster state_fips)`
```

## Adding Custom Packages to Reference Files

If your project uses Stata packages not covered by the existing reference files (e.g., `rdrobust`, `synth`, `bacondecomp`), add them to the relevant reference file in `reference/`:

1. Edit the source file in this repo (e.g., `reference/did-event-study.md` for `bacondecomp`).
2. Follow the existing format: command name, syntax, key options, common pitfalls.
3. Re-deploy with `./sync.sh` (and `./sync.sh /path/to/project`).

If no existing reference file fits, create a new one:
1. Create `reference/new-topic.md` (100-150 lines).
2. Add a row to the routing table in `SKILL.md`.
3. Re-deploy.

## Adding Custom Lint Rules

To add project-specific lint checks, edit `hooks/stata-lint.sh`. The pattern is:

```bash
# Check N: Description
if echo "$CONTENT" | grep -qP 'pattern_to_catch' 2>/dev/null; then
  WARNINGS="${WARNINGS}WARNING [stata-lint]: What's wrong and how to fix it.
"
fi
```

Rules should:
- Use `grep -qP` for Perl-compatible regex
- Append to `$WARNINGS` (do not echo directly)
- Include actionable fix instructions in the warning text
- Never change the exit code (always exit 0 -- warn, don't block)

After editing, re-deploy with `sync.sh`.

## Creating Project-Level Overrides

For projects that need heavier customization, you can maintain a parallel set of reference files at the project level:

```
<project>/.claude/skills/stata/
    SKILL.md                    # project-specific routing/conventions
    reference/                  # project-specific references
        custom-topic.md
    technique-guides/           # project-specific workflows
        project-pipeline.md
```

The user-level skill provides the base; the project-level skill adds or overrides as needed.

## Contributing Improvements Back

The `UPGRADE_LOG.md` file captures gaps Claude discovers during Stata work. To turn these into permanent improvements:

1. Read `UPGRADE_LOG.md` for pending entries.
2. For each entry, edit the appropriate source file:
   - New gotcha: `reference/gotchas.md` (and `rules/stata-gotchas.md` if top-10 worthy)
   - New reference content: the relevant `reference/*.md` file
   - New lint check: `hooks/stata-lint.sh`
   - New technique: the relevant `technique-guides/*.md` file
3. Clear the processed entries from `UPGRADE_LOG.md`.
4. Re-deploy with `./sync.sh`.
5. If the improvement is general (not project-specific), submit a PR to the repo.

This workflow turns runtime mistakes into permanent fixes across all your projects.
