# MCP Server Setup (tmonk/mcp-stata)

## What the MCP Server Adds

The default Stata workflow in this bundle uses **batch mode**: write a do-file, run it, read the log. This works well for reproducible pipelines but is clumsy for interactive exploration.

[tmonk/mcp-stata](https://github.com/tmonk/mcp-stata) provides an MCP (Model Context Protocol) server that gives Claude an interactive Stata session. With it, Claude can:

- **Run commands interactively** without writing temporary do-files
- **Inspect data in memory** (describe, list, summarize) with immediate results
- **Export graphs** directly from the running session
- **Access stored results** (`r()`, `e()`, `c()`) between commands
- **Maintain state** across multiple commands in the same session

## Prerequisites

- **Stata 17+** with PyStata support (bundled with Stata 17 and later)
- **Python 3.11+**
- **uvx** (from [uv](https://github.com/astral-sh/uv)) or pip

## Installation

The simplest method uses uvx (no virtual environment needed):

```bash
uvx mcp-stata
```

Or with pip:

```bash
pip install mcp-stata
```

## Configuration

Add the MCP server to your Claude Code settings. In `.claude/settings.json` (project-level) or `~/.claude/settings.json` (user-level):

```json
{
  "mcpServers": {
    "stata": {
      "command": "uvx",
      "args": ["mcp-stata"],
      "env": {
        "STATA_PATH": "/path/to/stata"
      }
    }
  }
}
```

Replace `/path/to/stata` with your Stata installation directory (not the binary -- the directory containing it):

| OS | Typical STATA_PATH |
|----|-------------------|
| Windows | `C:\\Program Files\\Stata19` |
| macOS | `/Applications/Stata` |
| Linux | `/usr/local/stata` |

## When to Use MCP vs Batch Mode

| Use MCP (interactive) | Use batch mode (do-files) |
|----------------------|--------------------------|
| Exploring a new dataset | Running the final analysis pipeline |
| Checking variable distributions | Producing reproducible results |
| Iterating on a regression spec | Code that others will review or re-run |
| Quick data inspection | Anything that needs a log file |
| Debugging a failing command | CI/CD or automated workflows |

**General rule:** Use MCP for exploration and debugging. Switch to batch mode (do-files) when the code needs to be reproducible, logged, and reviewable.

In practice, a typical workflow starts with MCP for exploration (Phase 1: Data), then switches to do-files for the analysis pipeline (Phases 2-5).

## MCP Server Tools

The MCP server exposes several tools to Claude. For full documentation of each tool and its parameters, see `reference/mcp-stata.md` in the skill bundle.

Key tools:
- **run_command** -- execute a single Stata command and return output
- **run_do_file** -- execute an entire do-file
- **get_data** -- retrieve data from memory as a table
- **get_results** -- access stored `r()`, `e()`, or `c()` results

## Troubleshooting

**"PyStata not found" error:**
- Ensure Stata 17+ is installed. PyStata ships with Stata 17 and later.
- Set `STATA_PATH` to the Stata installation directory, not the binary.

**MCP server not connecting:**
- Verify the server runs standalone: `uvx mcp-stata` should start without errors.
- Check that `settings.json` syntax is valid JSON.
- Restart Claude Code after changing settings.

**Commands hang or timeout:**
- Long-running Stata commands may exceed the MCP timeout. For heavy computation, use batch mode instead.
