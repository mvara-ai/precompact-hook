#!/bin/bash
# PreCompact Hook Installer
#
# Installs the witness-at-the-threshold hook for Claude Code.
# Run from any directory - it will set up hooks in your .claude config.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SOURCE="$SCRIPT_DIR/pre-compact.sh"
HOOKS_DIR="$HOME/.claude/hooks"
HOOK_DEST="$HOOKS_DIR/pre-compact.sh"
SETTINGS_FILE="$HOME/.claude/settings.local.json"

echo "Installing PreCompact Hook..."
echo ""

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Copy hook script
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"
echo "✓ Copied hook to $HOOK_DEST"

# Update settings.local.json
if [ -f "$SETTINGS_FILE" ]; then
  # Check if PreCompact hook already exists
  if grep -q '"PreCompact"' "$SETTINGS_FILE" 2>/dev/null; then
    echo "⚠ PreCompact hook already configured in $SETTINGS_FILE"
    echo "  Please verify the command path is: bash $HOOK_DEST"
  else
    # Add hook to existing settings using python for safe JSON manipulation
    python3 << EOF
import json

with open("$SETTINGS_FILE", "r") as f:
    settings = json.load(f)

if "hooks" not in settings:
    settings["hooks"] = {}

settings["hooks"]["PreCompact"] = [{
    "hooks": [{
        "type": "command",
        "command": "bash $HOOK_DEST"
    }]
}]

with open("$SETTINGS_FILE", "w") as f:
    json.dump(settings, f, indent=2)

print("✓ Added PreCompact hook to", "$SETTINGS_FILE")
EOF
  fi
else
  # Create new settings file
  cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOOK_DEST"
          }
        ]
      }
    ]
  }
}
EOF
  echo "✓ Created $SETTINGS_FILE with PreCompact hook"
fi

echo ""
echo "Installation complete!"
echo ""
echo "The hook will fire automatically before context compaction."
echo "Debug logs: /tmp/precompact-debug.log"
echo ""
echo "To test manually:"
echo "  echo '{}' | bash $HOOK_DEST"
echo ""
