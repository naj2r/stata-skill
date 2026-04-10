# MCP-Stata — tmonk/mcp-stata Server Reference

22 tools for controlling Stata from Claude Code or any MCP client.

---

## Installation

```bash
pip install mcp-stata
```

The server auto-detects Stata (searches common install paths). Add to Claude Code:

```bash
claude mcp add --scope user stata -- python -m mcp_stata
```

This creates the user-level config in `~/.claude.json`:
```json
{
  "mcpServers": {
    "stata": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "mcp_stata"],
      "env": {}
    }
  }
}
```

**Troubleshooting:** Set `STATA_PATH` env var if auto-detect fails. Set `MCP_STATA_LOGLEVEL=DEBUG` for diagnostics.

### Why MCP over batch mode?

| | Batch (`/e do`) | MCP-Stata |
|---|---|---|
| Token cost | ~200-700/interaction | ~80-350/interaction |
| Latency | 3-5s (cold start each time) | <1s (persistent session) |
| Output format | Raw log text | Structured JSON |
| Data inspection | Write new .do, re-run | `describe()`, `get_data()` |
| Session state | Stateless (reload each time) | Persistent (data stays loaded) |
| Setup | None (uses .bat wrapper) | `pip install mcp-stata` |
| Artifacts | .do + .log files saved | No .do file by default |

---

## Tools by Category

### Command Execution

| Tool | Purpose |
|------|---------|
| `run_command(code)` | Run Stata syntax |
| `run_do_file(path)` | Execute a .do file |
| `read_log(path, offset)` | Tail log from long-running command |

Options: `echo` (True), `as_json` (True), `trace` (False), `raw` (False), `max_output_lines`.

### Data Loading and Inspection

| Tool | Purpose |
|------|---------|
| `load_data(source)` | Load via sysuse/webuse/use heuristics |
| `get_data(start, count)` | Retrieve rows as JSON (max 500) |
| `describe()` | Variable types, labels, storage |
| `codebook(variable)` | Detailed variable summary |
| `get_variable_list()` | Names, labels, types |

### Results and Help

| Tool | Purpose |
|------|---------|
| `get_stored_results()` | r() and e() results as JSON |
| `get_help(topic)` | Help text (Markdown or plain) |

### Graph Management

| Tool | Purpose |
|------|---------|
| `list_graphs()` | Graphs in memory |
| `export_graph(name, format)` | Export to pdf/png |
| `export_graphs_all()` | Export all graphs |

### Session Management

| Tool | Purpose |
|------|---------|
| `create_session(id)` | New Stata session |
| `list_sessions()` | Active sessions |
| `stop_session(id)` | Terminate session |
| `break_session(id)` | Interrupt running command |

### UI Data Browser

`get_ui_channel()` returns a localhost HTTP endpoint with bearer auth for high-volume data browsing (paging, sorting, filtering). Key endpoints: `/v1/vars`, `/v1/page`, `/v1/views`, `/v1/arrow`.

---

## Error Handling

JSON envelope: `{ "rc": 0, "stdout": "...", "stderr": "", "log_path": "..." }`. `rc` = Stata's `r(XXX)` codes. Use `trace=True` for diagnostics.

## MCP Resources

| URI | Content |
|-----|---------|
| `stata://data/summary` | summarize |
| `stata://data/metadata` | describe |
| `stata://graphs/list` | graph list |
| `stata://results/stored` | r()/e() |

---

## Typical Workflow

```
load_data("auto")
describe()
get_data(start=0, count=10)
run_command("regress price mpg weight, robust")
get_stored_results()
run_command("coefplot, drop(_cons) xline(0)")
export_graph(format="png")
```

---

## Deep Dive

- GitHub: <https://github.com/tmonk/mcp-stata>
- MCP specification: <https://modelcontextprotocol.io>
