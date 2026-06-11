# Claude Code Codex Strongest

> **The opinionated, batteries-included Claude Code + Codex setup.**
> 33 skills · 22 agents · 25 commands · 12 hooks · 8 MCP servers — preconfigured, **one-click installable (no clone, no git)** on Windows & macOS.

[简体中文](#中文说明) · [English](#english)

---

## 中文说明

### 这是什么

为 [Claude Code](https://claude.com/claude-code) 和 Codex 准备的「开箱即用」配置全家桶 + 一键安装器。

把作者本机日积月累调教好的 `~/.claude/`（skills、subagents、commands、hooks、MCP servers）整个打包发出来，再写两个跨平台安装器：你**下载一个文件、双击一下**，VS Code、Windows VS Code desktop shortcut、Claude Code CLI、anthropic.claude-code VS Code 扩展、Codex CLI、openai.chatgpt VS Code 扩展、中文语言包、Office 文档预览扩展、Node.js、Git、PowerShell、uv 全自动装好，配置部署到你的 `~/.claude/`，**Claude Code Codex Strongest / claude-code-codex-strongest** 配置部署到 `~/.codex/`，8 个 MCP 服务器写进 `~/.claude.json`。

适用于：
- 想用 Claude Code 但屁都不懂、不知从哪入手的小白
- 想要"满血版"配置而不是默认空配置的中级用户
- 想 fork 一份起步、再加自己定制的高级用户

### 🚀 一键安装（推荐，不用克隆仓库）

**最简单：去 [Releases 页面](https://github.com/liujiarui0918/claude-code-codex-strongest/releases/latest) 下载一个文件，双击。**

#### Windows (Win 10/11)

1. 打开 [Releases 页面](https://github.com/liujiarui0918/claude-code-codex-strongest/releases/latest)，下载 **`install-windows.bat`**
2. **双击它**（若 SmartScreen 拦截：点"更多信息"→"仍要运行"）
3. 等它自动装完（VS Code、Windows VS Code desktop shortcut、Claude Code CLI、anthropic.claude-code VS Code extension、Codex CLI、openai.chatgpt VS Code extension、cc-switch 等）——**不再有填 key 的弹窗**
4. 装完会**自动打开 cc-switch**：点 Add Provider 填 API key + Base URL（选 Claude/Anthropic 预设，或你的中转站；gpt/OpenAI 格式中转站也行）→ 点 Enable
5. 运行 `codex login` 登录 Codex；打开 VS Code，`Ctrl+Shift+P` → 输入 `Claude Code: Open Chat`，或在终端跑 `claude` / `codex`

> 前提：Win11 自带 winget；Win10 若没有，去 Microsoft Store 装一下 "App Installer"。

#### macOS (12 Monterey 及以上)

1. 打开 [Releases 页面](https://github.com/liujiarui0918/claude-code-codex-strongest/releases/latest)，下载 **`install-macos.command`**
2. **双击它**（若被拦：右键 → 打开，或"系统设置 → 隐私与安全性 → 仍要打开"）
3. 等它自动装完（含 Claude Code CLI、anthropic.claude-code VS Code extension、Codex CLI、openai.chatgpt VS Code extension、cc-switch 和 Claude Code Codex Strongest / claude-code-codex-strongest 配置）——**不再有填 key 的弹窗**
4. 装完会**自动打开 cc-switch**：Add Provider 填 API key + Base URL（Claude/Anthropic 预设，或你的中转站；gpt/OpenAI 也行）→ Enable
5. 运行 `codex login` 登录 Codex；然后用 VS Code 或终端跑 `claude` / `codex`

#### 或者：一行命令（给会用终端的人）

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.sh | bash
```

> **国内用户注意**：以上都从 GitHub 下载，**需要梯子**。下载失败基本都是网络问题，开 VPN 重试。

### 重置 / 干净重装

机器上已经装过 VS Code / Claude Code、有旧配置或装坏了？用 **reset 模式**：备份并清掉旧的 `~/.claude`、`~/.claude.json`、登录态、VS Code 扩展，然后全新装一遍。

```powershell
# Windows（先 clone 或下载仓库后运行）
.\install\install-windows.ps1 -Reset
```

```bash
# macOS
bash install/install-macos.sh --reset
# 一行命令版
curl -fsSL https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.sh | bash -s -- --reset
```

> 普通重装（不加 `-Reset`）也是安全的：会把已存在的 `~/.claude` 和 `~/.claude.json` **自动备份**到 `.bak.<时间戳>` 再覆盖。`-Reset` 是"彻底归零"——连扩展和登录都重置，适合修坏掉的环境。

### 安装器做了什么

| 工具 | Windows 渠道 | macOS 渠道 |
|------|-------------|-----------|
| VS Code | winget `Microsoft.VisualStudioCode` + Windows VS Code desktop shortcut | brew `--cask visual-studio-code` |
| VS Code 扩展 | `code --install-extension anthropic.claude-code`; `openai.chatgpt`; `MS-CEINTL.vscode-language-pack-zh-hans`; `cweijan.vscode-office` | 同 |
| Claude Code CLI | npm `@anthropic-ai/claude-code` | 同 |
| Codex CLI | npm `@openai/codex`（装完运行 `codex login`） | 同 |
| Git | winget `Git.Git` | brew `git` |
| Node.js LTS | winget `OpenJS.NodeJS` | brew `node` |
| uv (Python 包管理) | winget `astral-sh.uv` | `curl ...astral.sh/uv/install.sh` |
| PowerShell 7 | （Win 自带 5.1 即够） | brew `--cask powershell`（hook 需要） |

部署内容：
- `~/.claude/`：skills / agents / commands / hooks / docs / output-styles 全套
- `~/.claude/settings.json`：自动生成（hook 路径等填好，UTF-8 无 BOM；API key/URL 默认交给 cc-switch 配，除非用 `--token` 预填）
- `~/.claude.json`：写入 8 个 MCP 服务器（Windows 用 `cmd /c` 包装，macOS 直连）
- `~/.codex/`：部署 **Claude Code Codex Strongest / claude-code-codex-strongest** 安全模板（`AGENTS.md` / `config.toml` / `.gitignore`），不复制 `auth.json`；装完运行 `codex login`
- 已存在的配置自动备份到 `.bak.<时间戳>`

### 功能预览

**Skills** (33 个 · 任务模式触发)
- 推理与流程：brainstorming, writing-plans, executing-plans, systematic-debugging, test-driven-development, verification-before-completion
- 开发实践：requesting-code-review, root-cause-tracing, using-git-worktrees, finishing-a-development-branch
- 工具调用：using-context7, using-deepwiki, using-playwright, using-sequential-thinking, using-cron, using-memory
- 元技能：skill-creator, writing-skills, prompt-engineering, lean-context, defense-in-depth
- + 10 个

**Subagents** (22 个 · 专项 Agent 自动分发)
- planner, code-reviewer, security-reviewer, debugger, explore, build-fixer, refactor-assistant, performance-analyst, accessibility-auditor, ...

**Commands** (25 个 · `/` 触发)
- 工作流：`/plan`, `/tdd`, `/review`, `/debug`, `/verify`, `/ship`, `/cleanup`
- 诊断：`/doctor`, `/mcp-status`, `/skills`, `/agents`, `/memory-search`, `/backup`
- 内容：`/changelog`, `/gen-tests`, `/refactor`, `/explain`, `/eli5`, `/deep-research`, ...

**Hooks** (12 个 · 生命周期事件)
- `block-dangerous` PreToolUse — 拦截 `rm -rf /`、`Format-Volume`、`git push --force` 到保护分支、**`git --no-verify`** 等危险命令
- `protect-secrets` PreToolUse — 拦截读/写 `.env`、SSH key、AWS creds
- `protect-linter-configs` PreToolUse — 拦截偷改 `.eslintrc`/`biome.json`/`.ruff.toml` 等来糊弄 linter（思路源自 ECC，可用 `CLAUDE_DISABLED_HOOKS` 关）
- `auto-format` PostToolUse — 编辑文件后自动 Prettier/Black 格式化
- `typecheck` PostToolUse — 异步类型检查 .ts/.py
- `command-log` PostToolUse — 命令审计日志
- `session-start-context` SessionStart — 注入项目当前状态 / git context
- `smart-context` UserPromptSubmit — 根据 prompt 智能引导 skill 触发
- `notify` Notification + `stop-sound` Stop — Toast 通知 + 完成提示音
- `precompact-backup` PreCompact — 压缩前备份完整 transcript
- `subagent-stop` SubagentStop — 子 agent 结束记录

**MCP Servers** (8 个 · 装进 `~/.claude.json`)
- `sequential-thinking` — 多步推理链
- `context7` — 实时库文档查询
- `deepwiki` — 公开 GitHub repo 文档问答
- `playwright` — 浏览器自动化
- `memory` — 知识图谱
- `fetch` — 通用 HTTP 抓取
- `time` — 时区转换（默认 Asia/Shanghai，可用 `-Timezone`/`--timezone` 改）
- `git-mcp` — Git 操作

### 配置说明

#### API key 填在哪（没有弹窗了）
装完 **cc-switch 会自动打开**——在里面点 Add Provider 填 API key + Base URL，再点 Enable：
- **官方 Anthropic**：[console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) 生成 `sk-ant-...`，选 Anthropic 预设
- **国内中转站**：填中转商给的 token + base URL（cc-switch 内置预设；gpt/OpenAI 格式中转站也支持）
- **想跳过 cc-switch**：用 `--token`(+ `--url`)把凭证预写进 settings.json，或 `--no-cc-switch` 后自己配

> 💡 **哪里找便宜好用的中转站？** 这里有一份全网实时更新的低价高质量 API 中转站价格表：[📊 API 中转站价格汇总表](https://docs.qq.com/sheet/DWFhhV3pMVnJGZXpO?tab=000001)（作者持续维护）
>
> 💡 **公益站推荐**：[anyrouter](https://anyrouter.top/register?aff=rQEI) — 每天免费赠送 $25 Claude Opus 4.8 额度，注册即用。

**👉 小白完整使用教程（中转站 + cc-switch 配置 + Claude Code 工作流）：[docs/guide-for-beginners.md](docs/guide-for-beginners.md)**

#### 模型名 / 用 GPT、DeepSeek 等别家模型
- **在 cc-switch 里选模型（推荐）**：每个 Provider 可设模型名，还能按 Opus/Sonnet/Haiku 分级映射。
- **或用 `--model` 标志**（脚本化安装）：会把 `ANTHROPIC_MODEL` 和 `ANTHROPIC_DEFAULT_HAIKU_MODEL` 都设成它，这样**单模型中转站**（如只有 `deepseek-chat`）前台和后台调用都走它，不会因后台 Haiku 调用失败。
- **大多数中转站本身就暴露 Anthropic 格式 `/v1/messages` 端点**（服务端帮你转 GPT/DeepSeek），这种情况**只要模型名对就行，不需要任何本地翻译**。
- **多供应商/多模型切换（默认安装）**：[cc-switch](https://github.com/farion1231/cc-switch)（Win: `winget install -e --id farion1231.CC-Switch`；Mac: `brew install --cask cc-switch`）默认会装上并在装完自动打开——一个 GUI，集中管理多套 Provider（含按 Opus/Sonnet/Haiku 分级映射）、一键切换、健康检查、用量统计，并自带 OpenAI↔Anthropic 代理，**兼容 gpt 等 OpenAI 格式中转站**。不想要就加 `--no-cc-switch` / `-NoCcSwitch`。
- **真要本地把原生 OpenAI 格式翻译成 Anthropic**（直连 `api.deepseek.com` 这类）：用 [claude-code-router](https://github.com/musistudio/claude-code-router)（transformer + 按任务路由）。本项目不自造翻译轮子。

#### 进阶：克隆仓库后本地运行
```powershell
git clone https://github.com/liujiarui0918/claude-code-codex-strongest.git
cd claude-code-codex-strongest
.\install\install-windows.ps1            # 或 bash install/install-macos.sh
```

#### 自定义安装位置 / 时区
```powershell
.\install\install-windows.ps1 -ClaudeHome 'D:\my-claude' -Timezone 'America/New_York'
./install/install-macos.sh --claude-home '/opt/my-claude' --timezone 'Europe/London'
```

#### 非交互模式（CI/批量部署）
```powershell
.\install\install-windows.ps1 -ApiToken 'sk-ant-xxx' -BaseUrl '' -Model '' -NonInteractive -Force
./install/install-macos.sh --token 'sk-ant-xxx' --url '' --non-interactive --force

# 用别家模型（cc-switch 默认会装；加 -NoCcSwitch / --no-cc-switch 可跳过）：
.\install\install-windows.ps1 -ApiToken 'xxx' -BaseUrl 'https://relay.example.com' -Model 'deepseek-chat' -NonInteractive -Force
./install/install-macos.sh --token 'xxx' --url 'https://relay.example.com' --model 'deepseek-chat' --non-interactive --force
```

### Claude Code Codex Strongest / claude-code-codex-strongest

本项目还有一份面向 Codex CLI / VS Code 的适配配置，命名为 **Claude Code Codex Strongest / claude-code-codex-strongest**，默认放在 `C:\Users\liujiarui\.codex`。它围绕 `@openai/codex` 和 VS Code 插件 `openai.chatgpt` 整理入口：`AGENTS.md` 作为 Codex 可读的项目规则入口，`config.toml` 负责模型、沙箱与 MCP servers 配置。

Claude Code Codex Strongest 不会复制 Claude 登录态、token、sessions、logs 或缓存；它保留本仓库的 Claude skills / agents / commands / docs 作为 Codex 可读的规则库和工作流参考，让 Codex 在不执行 Claude 专属 hook 的前提下复用同一套工程实践。

### 文件结构

```
~/.claude/
├── CLAUDE.md              # 用户级全局指令（@include docs/）
├── docs/                  # 环境、工作流、工具、安全四份分模块
├── settings.json          # 安装器自动生成（含 12 hooks）
├── skills/                # 33 个 skill 目录
├── agents/                # 22 个 .md 子 agent
├── commands/              # 25 个 slash command
├── hooks/                 # PowerShell hook（12 个注册 + 若干工具脚本）
└── output-styles/         # 5 个输出风格
~/.claude.json            # 8 个 MCP 服务器（安装器写入）
```

### 卸载

```powershell
# Windows
Remove-Item -Recurse -Force $env:USERPROFILE\.claude
```

```bash
# macOS
rm -rf ~/.claude
```

（注：这只删配置，不卸载 VS Code/Node/CLI。那些用各自的卸载方式。MCP 配置在 `~/.claude.json` 里，按需手动清。）

### 致谢

本仓库整合并改造了多个优秀的开源 Claude Code 配置项目，特此感谢：

| 上游项目 | 贡献内容 | License |
|---------|---------|---------|
| [obra/superpowers](https://github.com/obra/superpowers) | Skills 核心方法论 | MIT |
| [obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace) | Skills 集合 | MIT |
| [wshobson/agents](https://github.com/wshobson/agents) | Subagents 集合 | MIT |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | Subagents 灵感 | MIT |
| [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | `block-no-verify` + linter `config-protection` hook 思路（用 PowerShell 重写） | MIT |
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 官方 plugin 参考 | Anthropic |

具体哪些文件来自哪里、做了什么改动，见 [LICENSE](LICENSE) 与各文件头部。

### 反馈 / Issue

发 Issue：[github.com/liujiarui0918/claude-code-codex-strongest/issues](https://github.com/liujiarui0918/claude-code-codex-strongest/issues)

### License

[MIT](LICENSE)

---

## English

### What is this

A **batteries-included, opinionated Claude Code + Codex setup** with **one-click, no-clone installers** for Windows and macOS.

This repo bundles the author's full `~/.claude/` configuration — skills, subagents, commands, hooks, and MCP servers — refined over months on a daily-driver machine. The installers bootstrap everything from a blank machine: VS Code, the Claude Code CLI, the `anthropic.claude-code` VS Code extension, Codex CLI, and the `openai.chatgpt` VS Code extension, Node.js, Git, PowerShell 7, and uv — then deploy the config to `~/.claude/`, Claude Code Codex Strongest / claude-code-codex-strongest templates to `~/.codex/`, and 8 MCP servers into `~/.claude.json`.

### 🚀 Quick Start (no clone, no git)

**Easiest: grab one file from the [latest release](https://github.com/liujiarui0918/claude-code-codex-strongest/releases/latest) and double-click it.**

- **Windows:** download `install-windows.bat` → double-click (if SmartScreen warns: "More info" → "Run anyway")
- **macOS:** download `install-macos.command` → double-click (if blocked: right-click → Open)

No credential popup — cc-switch installs and opens at the end; add your Claude provider (API key + Base URL) there, then Enable. For Codex, run `codex login`, then use `claude` or `codex` in your terminal.

**Or one line in a terminal:**

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.ps1 | iex
```
```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.sh | bash
```

> Everything downloads from GitHub. Behind the Great Firewall? Enable a VPN and retry.

### Reset / clean reinstall

Machine already has VS Code / Claude Code with old or broken config? Use **reset mode** — it backs up and clears `~/.claude`, `~/.claude.json`, the login session, and the VS Code extension, then installs fresh:

```powershell
.\install\install-windows.ps1 -Reset
```
```bash
bash install/install-macos.sh --reset
curl -fsSL https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.sh | bash -s -- --reset
```

A normal re-install (without `-Reset`) is also safe: it auto-backs-up existing config to `.bak.<timestamp>` before overwriting.

### What you get

- **VS Code** + Windows VS Code desktop shortcut + official **Claude Code extension** (`anthropic.claude-code`) + official **Codex / ChatGPT extension** (`openai.chatgpt`) + Chinese language pack (`MS-CEINTL.vscode-language-pack-zh-hans`) + Office document preview (`cweijan.vscode-office`)
- **Claude Code CLI** (`claude` on PATH)
- **Codex CLI** (`@openai/codex`; run `codex login`, then `codex`)
- **Claude Code Codex Strongest / claude-code-codex-strongest config** deployed to `~/.codex/` without auth/runtime files
- **33 skills** auto-triggered on intent ("debug this" → `systematic-debugging`)
- **22 specialized subagents** for parallel research, review, planning, etc.
- **25 slash commands** (`/plan`, `/tdd`, `/review`, `/debug`, `/verify`, ...)
- **12 lifecycle hooks** (block-dangerous incl. `git --no-verify`, protect-secrets, protect-linter-configs, auto-format, smart-context, ...)
- **8 MCP servers** (sequential-thinking, context7, deepwiki, playwright, memory, fetch, time, git-mcp) — written into `~/.claude.json`

### Configuration flags

- `--token` / `-ApiToken`: optional — prewrite an API key for scripted installs (otherwise enter it in cc-switch, which opens at the end)
- `--url` / `-BaseUrl`: optional relay URL (empty = official Anthropic API)
- `--model` / `-Model`: optional model name; pins `ANTHROPIC_MODEL` + `ANTHROPIC_DEFAULT_HAIKU_MODEL` (e.g. `deepseek-chat`, `gpt-4o`). Empty = Claude Code defaults
- `--no-cc-switch` / `-NoCcSwitch`: skip [cc-switch](https://github.com/farion1231/cc-switch) (installed by default — a GUI to switch between multiple API providers/models, incl. OpenAI-format relays)
- `--reset` / `-Reset`: clean reinstall (back up + wipe old state)
- `--timezone` / `-Timezone`: IANA tz for the `time` MCP (default Asia/Shanghai)
- `--claude-home` / `-ClaudeHome`: override `~/.claude` location
- `--non-interactive --force` / `-NonInteractive -Force`: silent CI/scripted install

### License

[MIT](LICENSE). Bundles third-party MIT-licensed content from `obra/superpowers`, `wshobson/agents`, `VoltAgent/awesome-claude-code-subagents`, `affaan-m/everything-claude-code`, and `anthropics/claude-plugins-official`. See [LICENSE](LICENSE) for attribution.

### Contributing

Issues and PRs welcome at [github.com/liujiarui0918/claude-code-codex-strongest](https://github.com/liujiarui0918/claude-code-codex-strongest).
