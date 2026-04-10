# Installation

## Prerequisites

- **Stata 17+** installed (MP, SE, or BE). The `test-stata.sh` script checks common install locations automatically.
- **Claude Code** installed and working (`claude` command available in your terminal).
- **Git Bash** (Windows) or a standard shell (macOS/Linux).

## Step 1: Clone the Repository

```bash
git clone https://github.com/hugosantanna/stata-skill.git
cd stata-skill
```

## Step 2: Verify Stata Detection

```bash
./test-stata.sh
```

This script searches for Stata in your PATH and common install locations. On success, it prints the detected binary path and runs a trivial do-file in batch mode. If detection fails, it tells you exactly what it searched and how to fix it.

If Stata is installed in a non-standard location:

```bash
export STATA_BIN="/path/to/your/stata-mp"
./test-stata.sh
```

## Step 3: Deploy to User Level

```bash
./sync.sh
```

This copies SKILL.md, reference files, and technique guides to `~/.claude/skills/stata/`. The skill is now available in every Claude Code session, regardless of project.

## Step 4: Deploy to a Project

```bash
./sync.sh /path/to/your/project
```

This does everything in Step 3, plus:
- Copies the skill to `<project>/.claude/skills/stata/`
- Copies `stata-lint.sh` to `<project>/.claude/hooks/`
- Copies `stata-gotchas.md` to `<project>/.claude/rules/`

For project-only deployment (skipping user-level):

```bash
./sync.sh --project-only /path/to/your/project
```

## Step 5: clo-author Projects

For projects using [hugosantanna/clo-author](https://github.com/hugosantanna/clo-author), `sync.sh` also patches the agent files:

- **coder.md** -- appends a "Stata Mode" section (language detection, phase protocol, reference loading)
- **data-engineer.md** -- appends a "Stata Mode" section (data loading, inspection, format handling)
- **coder-critic.md** -- appends a "Stata Code Quality" checklist (missing values, merge checks, macro syntax)

Patches append to existing agent files; they never overwrite. If a Stata section already exists, the patch is skipped.

## Step 6: Register the Lint Hook

`sync.sh` copies the hook file but cannot modify `settings.json` automatically. Add this to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/stata-lint.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

If `settings.json` already has a `hooks` section, merge the `PreToolUse` entry into the existing structure.

## Step 7: Verify

1. Start a new Claude Code session (existing sessions do not pick up skill changes).
2. Mention "Stata" in your prompt -- for example, "Run a regression in Stata."
3. Claude should reference the Stata skill and follow the do-file conventions.

## Troubleshooting

**Stata not found by test-stata.sh:**
- Verify Stata is installed and the binary is executable.
- Set `STATA_BIN` explicitly: `export STATA_BIN="/c/Program Files/Stata19/StataMP-64.exe"`
- On Windows, use Git Bash paths (`/c/Program Files/...`), not Windows paths (`C:\Program Files\...`).

**Skill not triggering in Claude Code:**
- Confirm files exist at `~/.claude/skills/stata/SKILL.md` (user-level) or `<project>/.claude/skills/stata/SKILL.md` (project-level).
- Start a **new** session -- skills are loaded at session start.
- Check that your prompt mentions Stata, .do files, .dta files, or Stata-specific commands.

**Lint hook not firing:**
- Confirm `stata-lint.sh` is executable: `chmod +x .claude/hooks/stata-lint.sh`
- Confirm the hook is registered in `.claude/settings.json` (Step 6).
- The hook only fires on `.do` file edits -- it silently skips other file types.

**Agent patches not applied:**
- `sync.sh` requires `<project>/.claude/agents/` to exist with `coder.md`, `data-engineer.md`, and `coder-critic.md` already present. These come from clo-author's setup.
