#requires -version 5.1
$ErrorActionPreference = 'Stop'

# Adapted from everything-claude-code (affaan-m/everything-claude-code, MIT) — the "config-protection"
# idea: stop the agent from silencing a linter/formatter by editing its config instead of fixing the
# actual code. Blocks Edit/Write/MultiEdit to known linter/formatter config files.
#
# This restricts the AGENT's footguns, not the user. Override when an edit is genuinely intended:
#   - ask the user to confirm, OR
#   - add 'protect-linter-configs' to $env:CLAUDE_DISABLED_HOOKS
#
# Deliberately does NOT block pyproject.toml / tsconfig.json — those legitimately hold non-lint
# content (deps, build config), so blocking them would cause too many false positives.

if ($env:CLAUDE_DISABLED_HOOKS -and $env:CLAUDE_DISABLED_HOOKS -match 'protect-linter-configs') { exit 0 }

try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) { exit 0 }
    $payload = $jsonText | ConvertFrom-Json
} catch {
    exit 0
}

try {
    $toolName = [string]$payload.tool_name
    if ($toolName -notin @('Edit', 'Write', 'MultiEdit')) { exit 0 }

    $fp = $null
    if ($payload.tool_input -and $payload.tool_input.file_path) {
        $fp = [string]$payload.tool_input.file_path
    }
    if ([string]::IsNullOrWhiteSpace($fp)) { exit 0 }

    $name = Split-Path $fp -Leaf
    if ([string]::IsNullOrWhiteSpace($name)) { exit 0 }

    # Each entry: { rx = filename regex (anchored); tool = human label }
    $configPatterns = @(
        @{ rx = '^\.eslintrc(\.(js|cjs|mjs|json|ya?ml))?$';    tool = 'ESLint' },
        @{ rx = '^eslint\.config\.(js|mjs|cjs|ts)$';           tool = 'ESLint (flat config)' },
        @{ rx = '^biome\.jsonc?$';                             tool = 'Biome' },
        @{ rx = '^\.?ruff\.toml$';                             tool = 'Ruff' },
        @{ rx = '^\.prettierrc(\.(js|cjs|json|ya?ml|toml))?$'; tool = 'Prettier' },
        @{ rx = '^prettier\.config\.(js|cjs|mjs|ts)$';         tool = 'Prettier' },
        @{ rx = '^\.shellcheckrc$';                            tool = 'ShellCheck' },
        @{ rx = '^\.yamllint(\.ya?ml)?$';                      tool = 'yamllint' },
        @{ rx = '^\.hadolint\.ya?ml$';                         tool = 'hadolint' },
        @{ rx = '^\.flake8$';                                  tool = 'flake8' },
        @{ rx = '^\.pylintrc$';                                tool = 'pylint' },
        @{ rx = '^\.stylelintrc(\.(js|cjs|json|ya?ml))?$';     tool = 'stylelint' }
    )

    foreach ($p in $configPatterns) {
        if ($name -match $p.rx) {
            $msg = "[protect-linter-configs] Refused to edit $name ($($p.tool) config). " +
                   "Editing a linter/formatter config can silence the tool instead of fixing the code. " +
                   "If this change is genuinely intended (not to bypass a failing check), ask the user to confirm, " +
                   "or set `$env:CLAUDE_DISABLED_HOOKS to include 'protect-linter-configs'."
            [Console]::Error.WriteLine($msg)
            exit 2
        }
    }

    exit 0
} catch {
    exit 0
}
