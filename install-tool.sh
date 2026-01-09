#!/bin/bash
# Install summarize-session as a system-wide command
#
# Installs to ~/.local/bin/summarize-session (in PATH by default)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/summarize-session.sh"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/summarize-session"

echo "Installing Session Recovery Summarizer..."
echo ""

# Create bin directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy script
cp "$SOURCE_SCRIPT" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "✓ Installed to: $INSTALL_PATH"
echo ""

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
  echo "✓ ~/.local/bin is in your PATH"
else
  echo "⚠ ~/.local/bin is NOT in your PATH"
  echo ""
  echo "Add this to your ~/.zshrc or ~/.bashrc:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
  echo ""
  echo "Then run: source ~/.zshrc"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  summarize-session              # Current session"
echo "  summarize-session SESSION_ID   # Specific session"
echo ""
echo "Example:"
echo "  summarize-session | pbcopy     # Copy to clipboard"
echo "  summarize-session > brief.md   # Save to file"
echo ""
