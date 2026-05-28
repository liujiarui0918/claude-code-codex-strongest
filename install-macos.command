#!/usr/bin/env bash
# ============================================================================
# Claude Code Strongest - Double-click launcher for macOS
#
# Just double-click this file in Finder (Terminal will open).
# If macOS blocks it: System Settings > Privacy & Security > "Open Anyway".
# ============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Launching Claude Code Strongest installer..."
echo ""

exec bash "$SCRIPT_DIR/install/install-macos.sh" "$@"
