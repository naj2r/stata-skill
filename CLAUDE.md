# Stata Skill Bundle — Repository Guide

This repo is the source of truth for the Stata skill bundle used with Claude Code.

## Purpose

Provides Claude Code with Stata knowledge via a tiered progressive disclosure system:
- **Tier 1 (SKILL.md):** Always loaded. Auto-detect env, CLI, routing table, top-5 gotchas.
- **Tier 2 (reference/):** On-demand. 100-150 line files loaded per the routing table.
- **Tier 3 (technique-guides/):** End-to-end workflows. Loaded for full analysis pipelines.
- **Hooks + Rules:** `stata-lint.sh` warns on .do file mistakes; `stata-gotchas.md` keeps rules in context.

## How to Deploy

```bash
./sync.sh                                              # user-level only
./sync.sh /path/to/project                             # + project-level
./sync.sh "C:/Users/jensenn/Research/repos/Emissions-Coding"  # example
```

## How to Modify

- **Add a gotcha:** Edit `reference/gotchas.md`, update `rules/stata-gotchas.md` if top-10 worthy
- **Add a reference topic:** Create `reference/new-topic.md`, add to routing table in `SKILL.md`
- **Add a technique guide:** Create `technique-guides/new-guide.md`, add to technique table in `SKILL.md`
- **Add a lint check:** Edit `hooks/stata-lint.sh`
- **Add agent patches:** Edit files in `agent-patches/`

## Learning Loop

When Claude encounters a gap in the reference files during a session, it logs to `UPGRADE_LOG.md`. Review this file periodically and push improvements:

1. Read `UPGRADE_LOG.md`
2. For each entry: decide if it warrants a reference file update
3. Make the edit, clear the log entry
4. Re-deploy with `sync.sh`

## Compatibility

- Works standalone as a user-level skill (`~/.claude/skills/stata/`)
- Plugs into `hugosantanna/clo-author` projects via `agent-patches/` and `hooks/`
- Tested on Windows (Git Bash), macOS, Linux

## Attribution

Synthesized from:
- [dylantmoore/stata-skill](https://github.com/dylantmoore/stata-skill) — gotchas, reference files, routing table
- [tmonk/mcp-stata](https://github.com/tmonk/mcp-stata) — MCP server tool reference
- [nealcaren/sociology-analysis-agents](https://github.com/nealcaren/sociology-analysis-agents) — technique guides, phase workflow
- Aniket Panjwani's economist's guide — PATH/skill/PDF pattern
