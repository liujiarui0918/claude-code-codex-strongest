#requires -version 5.1
$ErrorActionPreference = 'Stop'

try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) { exit 0 }
    $payload = $jsonText | ConvertFrom-Json
} catch {
    exit 0
}

try {
    $prompt = $null
    if ($payload.prompt) { $prompt = [string]$payload.prompt }
    if ([string]::IsNullOrWhiteSpace($prompt)) { exit 0 }

    $hints = @()

    # --- Existing triggers ---------------------------------------------------

    # Test
    if ($prompt -match '(?i)\btest(s|ing)?\b' -or $prompt -match '测试') {
        $hints += "Tests detected. Consider the 'test-driven-development' skill and the /verify command."
    }

    # Debug
    if ($prompt -match '(?i)\b(debug|bug)\b' -or $prompt -match '调试' -or $prompt -match '排查') {
        $hints += "Debugging detected. Consider the 'systematic-debugging' skill and the /debug command."
    }

    # Refactor
    if ($prompt -match '(?i)\brefactor(ing)?\b' -or $prompt -match '重构') {
        $hints += "Refactor detected. Consider the 'refactor-assistant' agent and the /refactor command."
    }

    # Review / PR
    if ($prompt -match '(?i)\b(review|PR|pull\s*request)\b' -or $prompt -match '审查' -or $prompt -match '代码评审') {
        $hints += "Review detected. Consider the 'code-reviewer' agent and the /review command."
    }

    # Plan / design
    if ($prompt -match '(?i)\b(plan|planning|design)\b' -or $prompt -match '设计' -or $prompt -match '计划' -or $prompt -match '规划') {
        $hints += "Planning detected. Consider the 'brainstorming' + 'writing-plans' skills and the /plan command."
    }

    # Secrets warning
    if ($prompt -match '(?i)\b(secret|password|api[-_ ]?key|token|credentials?)\b' -or $prompt -match '凭证' -or $prompt -match '密码' -or $prompt -match '令牌') {
        $hints += "Warning: do not paste real secrets/passwords/keys/tokens into prompts. Use env vars or a secret manager."
    }

    # --- New triggers --------------------------------------------------------

    # Cron / reminders / recurring
    if ($prompt -match '(?i)\bremind\s+me\b' -or
        $prompt -match '(?i)\bin\s+\d+\s*(minute|min|hour|hr|day|second|sec)s?\b' -or
        $prompt -match '(?i)\bevery\s+(minute|hour|day|week|\d+)\b' -or
        $prompt -match '(?i)\b(daily|hourly|weekly|nightly)\b' -or
        $prompt -match '提醒我' -or $prompt -match '每隔' -or $prompt -match '每天' -or $prompt -match '每小时') {
        $hints += "Scheduling detected. Consider the 'using-cron' skill and the CronCreate tool."
    }

    # Screenshot / image
    if ($prompt -match '(?i)\bscreenshot' -or
        $prompt -match '(?i)\bimage\b' -or
        $prompt -match '(?i)\.(png|jpg|jpeg|gif|webp|bmp)\b' -or
        $prompt -match '图片' -or $prompt -match '截图' -or $prompt -match '图像') {
        $hints += "Image / screenshot detected. Consider the 'extracting-from-images' skill."
    }

    # Library / framework / package docs (context7)
    if ($prompt -match '(?i)\b(library|framework|package|SDK|API)\b' -or
        $prompt -match '(?i)\b(react|next\.?js|django|flask|express|vue|angular|svelte|fastapi|spring|rails|laravel|tailwind|prisma|drizzle|tanstack|vite|webpack|rollup|nestjs|nuxt)\b' -or
        $prompt -match '依赖库' -or $prompt -match '框架') {
        $hints += "Library/framework reference detected. Use the 'using-context7' skill (context7 MCP) for current docs."
    }

    # GitHub URL -> deepwiki
    if ($prompt -match '(?i)github\.com/[\w.\-]+/[\w.\-]+') {
        $hints += "GitHub URL detected. Consider the 'using-deepwiki' skill (deepwiki MCP) to explore the repo."
    }

    # Regex
    if ($prompt -match '(?i)\bregex(p)?\b' -or
        $prompt -match '(?i)\bregular\s+expression' -or
        $prompt -match '正则') {
        $hints += "Regex work detected. Consider the 'regex-expert' agent or the /regex command."
    }

    # SQL / database
    if ($prompt -match '(?i)\bSQL\b' -or
        $prompt -match '(?i)\b(select|insert|update|delete)\s+(from|into|set)\b' -or
        $prompt -match '(?i)\b(query|database|schema|migration)\b' -or
        $prompt -match '数据库' -or $prompt -match '查询') {
        $hints += "SQL/database work detected. Consider the 'sql-expert' agent."
    }

    # Explain / ELI5
    if ($prompt -match '(?i)\bexplain\b' -or
        $prompt -match '(?i)\bELI5\b' -or
        $prompt -match '(?i)\bhow does .* work\b' -or
        $prompt -match '解释' -or $prompt -match '通俗') {
        $hints += "Explanation request detected. Consider the /explain or /eli5 command."
    }

    # Changelog / release notes
    if ($prompt -match '(?i)\bchangelog\b' -or
        $prompt -match '(?i)\brelease\s+notes?\b' -or
        $prompt -match '更新日志' -or $prompt -match '发布说明') {
        $hints += "Changelog/release notes detected. Consider the /changelog command."
    }

    # Deps audit / outdated / vulns
    if ($prompt -match '(?i)\boutdated\b' -or
        $prompt -match '(?i)\bvulnerab(le|ility|ilities)\b' -or
        $prompt -match '(?i)\b(deps|dependencies)\s+(update|audit|upgrade)\b' -or
        $prompt -match '(?i)\bCVE\b' -or
        $prompt -match '依赖更新' -or $prompt -match '漏洞') {
        $hints += "Dependency audit detected. Consider the /deps-audit command."
    }

    # Migration (X -> Y / version migration)
    if ($prompt -match '(?i)\bmigrate\s+from\s+\S+\s+to\s+\S+' -or
        $prompt -match '(?i)\b(upgrade|migration)\s+(from|to)\s+v?\d' -or
        $prompt -match '(?i)\bv?\d+\s*->\s*v?\d+' -or
        $prompt -match '迁移') {
        $hints += "Migration detected. Consider the 'migration-assistant' agent."
    }

    # Accessibility / a11y / WCAG
    if ($prompt -match '(?i)\baccessibility\b' -or
        $prompt -match '(?i)\ba11y\b' -or
        $prompt -match '(?i)\bWCAG\b' -or
        $prompt -match '(?i)\bARIA\b' -or
        $prompt -match '可访问性' -or $prompt -match '无障碍') {
        $hints += "Accessibility work detected. Consider the 'accessibility-auditor' agent."
    }

    # Prompt engineering / LLM calls
    if ($prompt -match '(?i)\bprompt\s+(engineering|design|template)\b' -or
        $prompt -match '(?i)\b(improve|refine|tune)\s+(this\s+)?prompt\b' -or
        $prompt -match '(?i)\bwrite\s+a\s+prompt\b' -or
        $prompt -match '(?i)\bsystem\s+prompt\b' -or
        $prompt -match '提示词' -or $prompt -match '提示工程') {
        $hints += "Prompt engineering detected. Consider the 'prompt-engineer' agent and 'prompt-engineering' skill."
    }

    # Advanced git ops
    if ($prompt -match '(?i)\b(rebase|cherry[-\s]?pick|bisect|reflog|squash)\b' -or
        $prompt -match '变基' -or $prompt -match '挑拣') {
        $hints += "Advanced git operation detected. Consider the 'git-operator' agent."
    }

    if ($hints.Count -eq 0) { exit 0 }

    $body = ($hints | ForEach-Object { "Hint: $_" }) -join "`n"

    $out = @{
        hookSpecificOutput = @{
            hookEventName     = 'UserPromptSubmit'
            additionalContext = $body
        }
    } | ConvertTo-Json -Depth 5 -Compress

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::Out.Write($out)
    exit 0
} catch {
    exit 0
}