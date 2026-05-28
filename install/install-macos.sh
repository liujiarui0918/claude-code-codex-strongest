#!/usr/bin/env bash
# ============================================================================
# Claude Code Strongest - One-Click Setup (macOS)
#
# Installs:  Homebrew, VS Code, Claude Code CLI, official VS Code extension,
#            git, Node.js, PowerShell 7, uv (for Python MCP servers)
# Deploys:   ~/.claude/ — 33 skills / 22 agents / 25 commands / 11 hooks / 8 MCPs
#
# Usage:     ./install-macos.sh
#            ./install-macos.sh --token sk-ant-xxx --url https://relay.example.com
#            ./install-macos.sh --non-interactive --token sk-ant-xxx
# ============================================================================
set -euo pipefail

# Compatible with bash 3.2 (macOS default). Do not use mapfile, associative arrays, ${var,,}.

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
API_TOKEN=""
BASE_URL=""
NON_INTERACTIVE=0
SKIP_PREREQS=0
FORCE=0
DRY_RUN=0

# Resolve repo root: this script is in <repo>/install/, go up one.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------
if [ -t 1 ]; then
    C_CYAN='\033[36m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'
    C_GRAY='\033[90m'; C_MAGENTA='\033[35m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
else
    C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_GRAY=''; C_MAGENTA=''; C_BOLD=''; C_RESET=''
fi

log_step() { printf "${C_CYAN}>>> %s${C_RESET}\n" "$*"; }
log_ok()   { printf "${C_GREEN}    [OK]   %s${C_RESET}\n" "$*"; }
log_warn() { printf "${C_YELLOW}    [WARN] %s${C_RESET}\n" "$*"; }
log_err()  { printf "${C_RED}    [ERR]  %s${C_RESET}\n" "$*" >&2; }
log_info() { printf "${C_GRAY}    %s${C_RESET}\n" "$*"; }

show_welcome() {
    printf "\n"
    printf "${C_MAGENTA}+------------------------------------------------------------+${C_RESET}\n"
    printf "${C_MAGENTA}|     Claude Code Strongest - One-Click Setup (macOS)        |${C_RESET}\n"
    printf "${C_MAGENTA}|                                                            |${C_RESET}\n"
    printf "${C_MAGENTA}|   Installs: VS Code + Claude Code CLI + extension          |${C_RESET}\n"
    printf "${C_MAGENTA}|   Deploys:  33 skills / 22 agents / 25 commands /          |${C_RESET}\n"
    printf "${C_MAGENTA}|             11 hooks / 8 MCP servers                       |${C_RESET}\n"
    printf "${C_MAGENTA}+------------------------------------------------------------+${C_RESET}\n\n"
}

# ----------------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Source brew's shellenv whether it's Apple Silicon or Intel.
ensure_brew_on_path() {
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    # uv installs to ~/.local/bin
    if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --token)            API_TOKEN="$2"; shift 2 ;;
        --url)              BASE_URL="$2";  shift 2 ;;
        --claude-home)      CLAUDE_HOME="$2"; shift 2 ;;
        --non-interactive)  NON_INTERACTIVE=1; shift ;;
        --skip-prereqs)     SKIP_PREREQS=1;    shift ;;
        --force)            FORCE=1;           shift ;;
        --dry-run)          DRY_RUN=1;         shift ;;
        -h|--help)
            cat <<EOF
Usage: $0 [options]

Options:
  --token TOKEN           Anthropic API key (sk-ant-... or relay token)
  --url URL               Base URL (empty = official api.anthropic.com)
  --claude-home PATH      Override ~/.claude install location
  --non-interactive       Skip prompts (--token required)
  --skip-prereqs          Skip installing brew / VS Code / Node / etc.
  --force                 Overwrite existing ~/.claude without prompting
  --dry-run               Print actions without doing anything
  -h, --help              Show this help

Get your API key: https://console.anthropic.com/settings/keys
EOF
            exit 0
            ;;
        *) log_err "Unknown option: $1"; exit 2 ;;
    esac
done

# ----------------------------------------------------------------------------
# Prerequisites
# ----------------------------------------------------------------------------
install_homebrew() {
    if command_exists brew; then
        log_ok "Homebrew already installed"
        return 0
    fi
    log_step "Installing Homebrew (will prompt for sudo password)"
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 0
    fi
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_on_path
    if command_exists brew; then
        log_ok "Homebrew installed"
    else
        log_err "Homebrew install completed but brew not on PATH. Open a new terminal and re-run."
        exit 1
    fi
}

brew_install() {
    local label="$1"; shift
    local args="$*"
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would run: brew install $args"
        return 0
    fi
    log_step "Installing $label (brew install $args)"
    if brew install $args 2>&1 | tail -10; then
        log_ok "$label installed"
    else
        log_warn "$label install returned non-zero; continuing"
    fi
}

install_uv() {
    if command_exists uv; then
        log_ok "uv already installed"
        return 0
    fi
    log_step "Installing uv (Python package manager)"
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would run: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 0
    fi
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ensure_brew_on_path
    if command_exists uv; then
        log_ok "uv installed"
    else
        log_warn "uv install script ran but uv not on PATH (try opening a new terminal)"
    fi
}

install_claude_cli() {
    if command_exists claude; then
        log_ok "Claude Code CLI already installed"
        return 0
    fi
    if ! command_exists npm; then
        log_warn "npm not available; skipping Claude Code CLI. Re-run after Node installs."
        return 0
    fi
    log_step "Installing Claude Code CLI via npm"
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would run: npm install -g @anthropic-ai/claude-code"
        return 0
    fi
    if npm install -g @anthropic-ai/claude-code 2>&1 | tail -3; then
        if command_exists claude; then
            log_ok "Claude Code CLI installed"
        else
            log_warn "npm reported success but 'claude' not on PATH (try opening a new terminal)"
        fi
    else
        log_warn "npm install failed; install manually: npm install -g @anthropic-ai/claude-code"
    fi
}

install_vscode_ext() {
    if ! command_exists code; then
        log_warn "'code' CLI not on PATH; skipping extension install."
        log_info "After VS Code is installed, run: code --install-extension anthropic.claude-code"
        return 0
    fi
    log_step "Installing VS Code extension: anthropic.claude-code"
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would run: code --install-extension anthropic.claude-code --force"
        return 0
    fi
    if code --install-extension anthropic.claude-code --force >/dev/null 2>&1; then
        log_ok "VS Code extension installed"
    else
        log_warn "Extension install failed; install manually from VS Code Extensions panel"
    fi
}

install_prerequisites() {
    log_step "Phase 1/4: Installing prerequisites"

    # Xcode CLT (git etc.) — Homebrew install will trigger this if missing.
    install_homebrew

    brew_install 'VS Code'      --cask visual-studio-code
    brew_install 'Git'          git
    brew_install 'Node.js LTS'  node
    brew_install 'PowerShell 7' --cask powershell

    ensure_brew_on_path

    install_uv
    install_claude_cli
    install_vscode_ext

    printf "\n"
}

# ----------------------------------------------------------------------------
# User input
# ----------------------------------------------------------------------------
prompt_creds_osascript() {
    # Try native macOS dialog via osascript.
    local token url
    token=$(osascript <<EOF 2>/dev/null
try
    set theResult to display dialog "Anthropic API Key (sk-ant-... or relay token):" default answer "" with hidden answer with title "Claude Code Strongest" buttons {"Cancel", "Next"} default button "Next"
    return text returned of theResult
on error
    return "__CANCELLED__"
end try
EOF
)
    if [ -z "$token" ] || [ "$token" = "__CANCELLED__" ]; then
        return 1
    fi

    url=$(osascript <<EOF 2>/dev/null
try
    set theResult to display dialog "Anthropic Base URL (leave empty for official api.anthropic.com):" default answer "" with title "Claude Code Strongest" buttons {"Cancel", "Install"} default button "Install"
    return text returned of theResult
on error
    return "__CANCELLED__"
end try
EOF
)
    if [ "$url" = "__CANCELLED__" ]; then
        return 1
    fi

    API_TOKEN="$token"
    BASE_URL="$url"
    return 0
}

prompt_creds_console() {
    printf "\n"
    log_step "Enter credentials"
    log_info "Get API key from: https://console.anthropic.com/settings/keys"
    log_info "(Chinese users: enter your relay token + URL)"
    printf "\n"

    if [ -z "$API_TOKEN" ]; then
        printf "Anthropic API Key (input hidden): "
        read -r -s API_TOKEN
        printf "\n"
    fi
    if [ -z "$BASE_URL" ]; then
        printf "Anthropic Base URL (leave empty for official): "
        read -r BASE_URL
    fi
}

get_creds() {
    if [ $NON_INTERACTIVE -eq 1 ]; then
        if [ -z "$API_TOKEN" ]; then
            log_err "--non-interactive requires --token"
            exit 2
        fi
        return 0
    fi
    if [ -n "$API_TOKEN" ] && [ -n "$BASE_URL" ]; then
        log_ok "Using credentials from command line"
        return 0
    fi
    # Try osascript dialog
    if command_exists osascript && prompt_creds_osascript; then
        log_ok "Credentials captured via dialog"
        return 0
    fi
    log_warn "Falling back to console prompt"
    prompt_creds_console
    if [ -z "$API_TOKEN" ]; then
        log_err "API token is required."
        exit 2
    fi
}

# ----------------------------------------------------------------------------
# Deploy
# ----------------------------------------------------------------------------
backup_existing() {
    if [ ! -e "$CLAUDE_HOME" ]; then
        return 0
    fi
    local ts; ts=$(date +%Y%m%d-%H%M%S)
    local backup="$CLAUDE_HOME.bak.$ts"
    log_step "Backing up existing $CLAUDE_HOME -> $backup"
    if [ $DRY_RUN -eq 0 ]; then
        mv "$CLAUDE_HOME" "$backup"
    fi
    log_ok "Backup at $backup"
}

deploy_repo() {
    log_step "Phase 2/4: Deploying files to $CLAUDE_HOME"

    if [ -e "$CLAUDE_HOME" ]; then
        if [ $FORCE -eq 0 ] && [ $NON_INTERACTIVE -eq 0 ]; then
            printf "%s exists. Backup and overwrite? [Y/n]: " "$CLAUDE_HOME"
            read -r ans
            ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
            if [ -n "$ans" ] && [ "$ans" != "y" ]; then
                log_err "Install aborted by user."
                exit 1
            fi
        fi
        backup_existing
    fi

    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would rsync $REPO_ROOT/ -> $CLAUDE_HOME/"
        return 0
    fi

    mkdir -p "$CLAUDE_HOME"
    rsync -a \
        --exclude 'install/' \
        --exclude 'settings.template.json' \
        --exclude 'LICENSE' \
        --exclude 'README.md' \
        --exclude '.gitignore' \
        --exclude '.gitattributes' \
        --exclude '.git/' \
        --exclude 'install-windows.bat' \
        --exclude 'install-macos.command' \
        "$REPO_ROOT/" "$CLAUDE_HOME/"
    log_ok "Files copied"
}

render_settings() {
    log_step "Phase 3/4: Rendering settings.json from template"
    local tpl="$REPO_ROOT/settings.template.json"
    local out="$CLAUDE_HOME/settings.json"

    if [ ! -f "$tpl" ]; then
        log_err "Template not found: $tpl"
        exit 1
    fi

    local claude_home_slashes; claude_home_slashes="$CLAUDE_HOME"
    # On macOS $CLAUDE_HOME uses /. No backslash conversion needed.

    if [ $DRY_RUN -eq 1 ]; then
        log_info "[dry-run] would render $tpl -> $out"
        return 0
    fi

    local content; content=$(cat "$tpl")

    # Drop the ANTHROPIC_BASE_URL line entirely if URL is empty.
    if [ -z "$BASE_URL" ]; then
        content=$(printf '%s\n' "$content" | grep -v '"ANTHROPIC_BASE_URL"')
    fi

    # Bash 3.2-safe substitution.
    content="${content//\{\{ANTHROPIC_AUTH_TOKEN\}\}/$API_TOKEN}"
    content="${content//\{\{ANTHROPIC_BASE_URL\}\}/$BASE_URL}"
    content="${content//\{\{CLAUDE_HOME\}\}/$claude_home_slashes}"

    # Verify no placeholders left.
    if echo "$content" | grep -qE '\{\{[A-Z_]+\}\}'; then
        log_err "Unfilled placeholders remain in settings.json"
        echo "$content" | grep -oE '\{\{[A-Z_]+\}\}' | sort -u
        exit 1
    fi

    printf '%s' "$content" > "$out"
    log_ok "Wrote $out"
}

# ----------------------------------------------------------------------------
# Verify
# ----------------------------------------------------------------------------
verify_install() {
    log_step "Phase 4/4: Verifying install"

    local ok=0 fail=0
    check() {
        local name="$1"
        local test_cmd="$2"
        if eval "$test_cmd" >/dev/null 2>&1; then
            log_ok "$name"
            ok=$((ok+1))
        else
            log_err "$name"
            fail=$((fail+1))
        fi
    }

    check "settings.json exists"      "[ -f '$CLAUDE_HOME/settings.json' ]"
    check "settings.json parses"      "python3 -c 'import json,sys; json.load(open(\"$CLAUDE_HOME/settings.json\"))' 2>&1 | grep -qv Error"
    check "CLAUDE.md exists"          "[ -f '$CLAUDE_HOME/CLAUDE.md' ]"
    check "docs/ has >=4 files"       "[ \$(ls -1 '$CLAUDE_HOME/docs' 2>/dev/null | wc -l | tr -d ' ') -ge 4 ]"
    check "skills/ has >=30 entries"  "[ \$(ls -1 '$CLAUDE_HOME/skills' 2>/dev/null | wc -l | tr -d ' ') -ge 30 ]"
    check "agents/ has >=20 entries"  "[ \$(ls -1 '$CLAUDE_HOME/agents'/*.md 2>/dev/null | wc -l | tr -d ' ') -ge 20 ]"
    check "commands/ has >=20"        "[ \$(ls -1 '$CLAUDE_HOME/commands'/*.md 2>/dev/null | wc -l | tr -d ' ') -ge 20 ]"
    check "hooks/ has >=11 .ps1"      "[ \$(ls -1 '$CLAUDE_HOME/hooks'/*.ps1 2>/dev/null | wc -l | tr -d ' ') -ge 11 ]"

    if [ $fail -gt 0 ]; then
        log_err "Verification: $fail of $((ok+fail)) checks failed"
        exit 1
    fi
    log_ok "All verification checks passed ($ok/$((ok+fail)))"
}

show_success() {
    printf "\n"
    printf "${C_GREEN}${C_BOLD}+============================================================+${C_RESET}\n"
    printf "${C_GREEN}${C_BOLD}|             INSTALLATION COMPLETE!                         |${C_RESET}\n"
    printf "${C_GREEN}${C_BOLD}+============================================================+${C_RESET}\n\n"
    printf "  Claude Code config installed at: ${C_BOLD}%s${C_RESET}\n\n" "$CLAUDE_HOME"
    printf "  ${C_YELLOW}Next steps:${C_RESET}\n"
    printf "    1. Open VS Code (or run: ${C_BOLD}code .${C_RESET})\n"
    printf "    2. Press ${C_BOLD}Cmd+Shift+P${C_RESET} -> \"Claude Code: Open Chat\"\n"
    printf "    3. Try a command: ${C_BOLD}/doctor${C_RESET} to verify your setup\n\n"
    printf "  ${C_YELLOW}Or from a terminal:${C_RESET}\n"
    printf "    ${C_BOLD}claude${C_RESET}\n\n"
    printf "  ${C_CYAN}Documentation: https://github.com/liujiarui0918/claude-code-strongest${C_RESET}\n\n"
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
main() {
    show_welcome

    log_info "Repo root: $REPO_ROOT"
    log_info "Install target: $CLAUDE_HOME"
    if [ $DRY_RUN -eq 1 ]; then
        log_warn "DRY-RUN MODE — no actual changes will be made"
    fi
    printf "\n"

    if [ $SKIP_PREREQS -eq 0 ]; then
        install_prerequisites
    else
        log_warn "Skipping prerequisites install (--skip-prereqs)"
    fi

    get_creds
    log_ok "Credentials captured"

    deploy_repo
    render_settings

    if [ $DRY_RUN -eq 0 ]; then
        verify_install
    fi

    show_success
}

trap 'log_err "Install failed at line $LINENO"; exit 1' ERR
main "$@"
