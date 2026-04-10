#!/usr/bin/env bash
# sync.sh — Deploy stata skill bundle to user-level and optionally to a project
# Usage:
#   ./sync.sh                           # user-level only
#   ./sync.sh /path/to/project          # user-level + project
#   ./sync.sh --project-only /path      # project only (no user-level)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ONLY=false

if [ "${1:-}" = "--project-only" ]; then
  PROJECT_ONLY=true
  shift
fi

# --- User-level deployment ---
if [ "$PROJECT_ONLY" = false ]; then
  USER_SKILL="$HOME/.claude/skills/stata"
  echo "Deploying to user-level: $USER_SKILL"
  mkdir -p "$USER_SKILL/reference" "$USER_SKILL/technique-guides"
  cp "$SCRIPT_DIR/SKILL.md" "$USER_SKILL/"
  cp "$SCRIPT_DIR"/reference/*.md "$USER_SKILL/reference/" 2>/dev/null || true
  cp "$SCRIPT_DIR"/technique-guides/*.md "$USER_SKILL/technique-guides/" 2>/dev/null || true
  echo "  Done."
fi

# --- Project-level deployment ---
if [ -n "${1:-}" ]; then
  PROJ="$1"
  if [ ! -d "$PROJ/.claude" ]; then
    echo "ERROR: $PROJ/.claude does not exist. Is this a clo-author project?"
    exit 1
  fi

  echo "Deploying to project: $PROJ"

  # Skills
  SKILL_DIR="$PROJ/.claude/skills/stata"
  mkdir -p "$SKILL_DIR/reference" "$SKILL_DIR/technique-guides"
  cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/"
  cp "$SCRIPT_DIR"/reference/*.md "$SKILL_DIR/reference/" 2>/dev/null || true
  cp "$SCRIPT_DIR"/technique-guides/*.md "$SKILL_DIR/technique-guides/" 2>/dev/null || true
  echo "  Skills: done"

  # Hooks
  if [ -d "$PROJ/.claude/hooks" ]; then
    cp "$SCRIPT_DIR/hooks/stata-lint.sh" "$PROJ/.claude/hooks/"
    chmod +x "$PROJ/.claude/hooks/stata-lint.sh"
    echo "  Hook: stata-lint.sh copied"
  fi

  # Rules
  mkdir -p "$PROJ/.claude/rules"
  cp "$SCRIPT_DIR/rules/stata-gotchas.md" "$PROJ/.claude/rules/"
  echo "  Rule: stata-gotchas.md copied"

  # Agent patches (append if not already present)
  if [ -d "$PROJ/.claude/agents" ]; then
    for AGENT_FILE in coder data-engineer coder-critic; do
      PATCH="$SCRIPT_DIR/agent-patches/${AGENT_FILE}-stata-mode.md"
      if [ "$AGENT_FILE" = "coder-critic" ]; then
        PATCH="$SCRIPT_DIR/agent-patches/coder-critic-stata-checks.md"
      fi

      TARGET="$PROJ/.claude/agents/${AGENT_FILE}.md"
      if [ -f "$PATCH" ] && [ -f "$TARGET" ]; then
        # Check if already patched
        if ! grep -q "## Stata Mode\|## Stata Code Quality" "$TARGET" 2>/dev/null; then
          echo "" >> "$TARGET"
          cat "$PATCH" >> "$TARGET"
          echo "  Agent: $AGENT_FILE.md patched with Stata section"
        else
          echo "  Agent: $AGENT_FILE.md already has Stata section (skipped)"
        fi
      fi
    done
  fi

  # Remind about settings.json hook registration
  SETTINGS="$PROJ/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    if ! grep -q "stata-lint" "$SETTINGS" 2>/dev/null; then
      echo ""
      echo "  NOTE: Add stata-lint hook to $SETTINGS manually:"
      echo '  Under "hooks" > "PreToolUse", add:'
      echo '  {'
      echo '    "matcher": "Edit|Write",'
      echo '    "hooks": [{'
      echo '      "type": "command",'
      echo '      "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/stata-lint.sh",'
      echo '      "timeout": 5'
      echo '    }]'
      echo '  }'
    else
      echo "  Settings: stata-lint hook already registered"
    fi
  fi

  echo "  Done."
fi

echo ""
echo "Deployment complete. Start a new Claude Code session to pick up changes."
