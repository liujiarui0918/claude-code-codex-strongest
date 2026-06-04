#!/usr/bin/env bash
# ============================================================================
# Claude Code Strongest - One-Click Installer (macOS)
#
# Double-click this file in Finder. If macOS blocks it:
#   right-click > Open, or System Settings > Privacy & Security > "Open Anyway".
# ============================================================================
set -e
echo "============================================================"
echo "   Claude Code Strongest - One-Click Installer (macOS)"
echo "============================================================"
echo
echo "This downloads the latest setup and installs everything:"
echo "  VS Code + Claude Code + cc-switch + 33 skills / 22 agents / 8 MCPs"
echo
echo "No API-key box: when it finishes, cc-switch opens so you enter your key there."
echo

TMP="$(mktemp -d)"
URL="https://github.com/liujiarui0918/claude-code-strongest/archive/refs/heads/main.tar.gz"

echo "Downloading..."
if ! curl -fsSL "$URL" -o "$TMP/r.tar.gz"; then
    echo "Download failed. If you are in mainland China, turn on a VPN and try again."
    exit 1
fi

echo "Extracting..."
tar -xzf "$TMP/r.tar.gz" -C "$TMP"
DIR="$(find "$TMP" -maxdepth 1 -type d -name 'claude-code-strongest-*' | head -1)"
[ -n "$DIR" ] || { echo "Extract failed."; exit 1; }

bash "$DIR/install/install-macos.sh" "$@"
EC=$?
rm -rf "$TMP"
exit $EC
