# Stata Skill Bundle for Claude Code

## What This Solves

Claude Code makes the same Stata mistakes repeatedly: missing values treated as infinity in comparisons, merges without `_merge` checks, single `=` where `==` is needed, bare `by` without sort. Without structured guidance, Claude either gets no Stata help at all or gets a wall of text that wastes context window.

This bundle gives Claude Code a **tiered progressive disclosure system** for Stata. A compact always-loaded skill file (SKILL.md) handles routing, while detailed reference files and technique guides load on demand. A lint hook catches mistakes in real time. Always-in-context rules prevent the top 10 gotchas. An upgrade log lets Claude flag its own knowledge gaps for you to review.

## Architecture

The bundle has three content tiers plus supporting infrastructure. **Tier 1** is SKILL.md (~120 lines, always loaded): environment auto-detection, CLI invocation, top-5 gotchas, do-file template, and a routing table. **Tier 2** is `reference/` (11 files, 100-150 lines each, loaded on demand via the routing table). **Tier 3** is `technique-guides/` (5 end-to-end workflow files for full analysis pipelines). Supporting these: `hooks/stata-lint.sh` (PreToolUse hook that warns on .do file mistakes), `rules/stata-gotchas.md` (top-10 rules always in context), `agent-patches/` (Stata sections for clo-author agents), and `UPGRADE_LOG.md` (Claude logs gaps for periodic review).

## Quick Start

```bash
git clone https://github.com/hugosantanna/stata-skill.git
cd stata-skill

# 1. Verify Stata is detected
./test-stata.sh

# 2. Deploy to user-level (available in all sessions)
./sync.sh

# 3. Optional: deploy to a clo-author project
./sync.sh /path/to/your/project
```

After deployment, start a new Claude Code session and mention Stata. The skill triggers automatically.

## Guide Contents

- [Installation](installation.md) -- step-by-step setup with troubleshooting
- [Architecture](architecture.md) -- how tiered progressive disclosure works
- [Learning Loop](learning-loop.md) -- hooks, rules, escalation, and self-improvement
- [Agent Integration](agent-integration.md) -- clo-author adversarial system and phase protocol
- [MCP Server Setup](mcp-server-setup.md) -- interactive Stata sessions via tmonk/mcp-stata
- [Customization](customization.md) -- overrides, custom rules, and contributing back

## Attribution

This bundle synthesizes work from multiple sources:

- **[dylantmoore/stata-skill](https://github.com/dylantmoore/stata-skill)** -- gotchas, reference files, routing table pattern
- **[tmonk/mcp-stata](https://github.com/tmonk/mcp-stata)** -- MCP server for interactive Stata sessions
- **[nealcaren/sociology-analysis-agents](https://github.com/nealcaren/sociology-analysis-agents)** -- 6-phase research workflow, technique guides
- **Aniket Panjwani** -- economist's guide pattern (PATH detection, skill hierarchy, PDF documentation access)

## License

See the individual source repositories for their respective licenses.
