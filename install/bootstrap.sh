#!/usr/bin/env bash
# ============================================================================
# No-clone bootstrap for claude-code-strongest (macOS / Linux).
#
# Downloads the repo tarball (no git required), extracts to a temp dir, and
# runs install-macos.sh. Extra arguments are passed through to the installer.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/liujiarui0918/claude-code-strongest/main/install/bootstrap.sh | bash
#
# With arguments:
#   curl -fsSL .../bootstrap.sh | bash -s -- --reset
#
# Pin a version/branch:
#   CCS_REF=v1.0.0 bash bootstrap.sh
# ============================================================================
set -euo pipefail

REPO="liujiarui0918/claude-code-strongest"
REF="${CCS_REF:-main}"

case "$REF" in
    v[0-9]*|[0-9]*) URL="https://github.com/$REPO/archive/refs/tags/$REF.tar.gz" ;;
    *)              URL="https://github.com/$REPO/archive/refs/heads/$REF.tar.gz" ;;
esac

echo ">>> Claude Code Strongest bootstrap (ref: $REF)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "    Downloading..."
if ! curl -fsSL "$URL" -o "$TMP/repo.tar.gz"; then
    echo "    Download failed from $URL"
    echo "    If you are in mainland China, turn on a VPN and try again."
    exit 1
fi

echo "    Extracting..."
tar -xzf "$TMP/repo.tar.gz" -C "$TMP"

DIR="$(find "$TMP" -maxdepth 1 -type d -name 'claude-code-strongest-*' | head -1)"
if [ -z "$DIR" ]; then
    echo "    Extraction failed: repo folder not found."
    exit 1
fi

chmod +x "$DIR/install/install-macos.sh" 2>/dev/null || true
echo ">>> Running installer..."
bash "$DIR/install/install-macos.sh" "$@"
