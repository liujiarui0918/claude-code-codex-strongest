# Claude Code Strongest

> **The opinionated, batteries-included Claude Code setup.**
> 33 skills · 22 agents · 25 commands · 11 hooks · 8 MCP servers — preconfigured, one-click installable on Windows & macOS.

[简体中文](#中文说明) · [English](#english)

---

## 中文说明

### 这是什么

为 [Claude Code](https://claude.com/claude-code) 准备的「开箱即用」配置全家桶 + 一键安装器。

把作者本机日积月累调教好的 `~/.claude/`（skills、subagents、commands、hooks、MCP servers）整个打包发出来，再写两个跨平台安装器：你**双击一下**，VS Code、Claude Code CLI、官方插件、Node.js、Git、PowerShell、uv 全自动装好，把这套配置部署到你的 `~/.claude/`。

适用于：
- 想用 Claude Code 但不知道从哪入手的小白
- 想要"满血版"配置而不是默认空配置的中级用户
- 想 fork 一份起步、再加自己定制的高级用户

### 一键安装

#### Windows (Win 10/11)

1. 先确认 [Windows Package Manager (winget)](https://aka.ms/getwinget) 已装（Win 11 自带，Win 10 从 Microsoft Store 装 "App Installer"）
2. 克隆本仓库到本地：
   ```powershell
   git clone https://github.com/liujiarui0918/claude-code-strongest.git
   cd claude-code-strongest
   ```
   （没 git？先 `winget install Git.Git`，新开终端再 clone）
3. 双击 `install-windows.bat`（或 PowerShell 跑 `.\install-windows.bat`）
4. 弹出窗口里填 API key（必填）+ Base URL（可空 = 用官方 Anthropic API）
5. 装完打开 VS Code，Ctrl+Shift+P → 输入 `Claude Code: Open Chat`

#### macOS (12 Monterey 及以上)

1. 克隆仓库：
   ```bash
   git clone https://github.com/liujiarui0918/claude-code-strongest.git
   cd claude-code-strongest
   ```
2. 跑安装器：
   ```bash
   bash install/install-macos.sh
   ```
   （或赋权后双击 `install-macos.command`：`chmod +x install-macos.command`）
3. 弹出原生对话框填 API key + URL
4. 装完用 VS Code 或终端跑 `claude`

### 安装器做了什么

| 工具 | Windows 渠道 | macOS 渠道 |
|------|-------------|-----------|
| VS Code | winget `Microsoft.VisualStudioCode` | brew `--cask visual-studio-code` |
| Claude Code 官方插件 | `code --install-extension anthropic.claude-code` | 同 |
| Claude Code CLI | npm `@anthropic-ai/claude-code` | 同 |
| Git | winget `Git.Git` | brew `git` |
| Node.js LTS | winget `OpenJS.NodeJS` | brew `node` |
| uv (Python 包管理) | winget `astral-sh.uv` | `curl ...astral.sh/uv/install.sh` |
| PowerShell 7 | （Win 自带 5.1 即够） | brew `--cask powershell`（hook 需要） |

部署 `~/.claude/`：
- `settings.json` 自动生成（API key、URL、hook 路径全填好）
- 已存在的 `~/.claude/` 自动备份到 `~/.claude.bak.<时间戳>/`
- 11 个 PowerShell hook（跨平台路径，自动适配你的用户名）

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

**Hooks** (11 个 · 生命周期事件)
- `block-dangerous` PreToolUse — 拦截 `rm -rf /`、`Format-Volume` 等危险命令
- `protect-secrets` PreToolUse — 拦截读/写 `.env`、SSH key、AWS creds
- `auto-format` PostToolUse — 编辑文件后自动 Prettier/Black 格式化
- `typecheck` PostToolUse — 异步类型检查 .ts/.py
- `session-start-context` SessionStart — 注入项目当前状态 / git context
- `smart-context` UserPromptSubmit — 根据 prompt 智能引导 skill 触发
- `precompact-backup` PreCompact — 压缩前备份完整 transcript
- `notify` Notification — Toast 通知 + stop-sound
- ...

**MCP Servers** (8 个)
- `sequential-thinking` — 多步推理链
- `context7` — 实时库文档查询
- `deepwiki` — 公开 GitHub repo 文档问答
- `playwright` — 浏览器自动化
- `memory` — 知识图谱
- `fetch` — 通用 HTTP 抓取
- `time` — 时区转换
- `git-mcp` — Git 操作

### 配置说明

#### API key 怎么拿
- **官方 Anthropic**：[console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) 生成 `sk-ant-...`
- **国内中转站**（自行选择）：填中转商提供的 token + base URL

#### 自定义安装位置
```powershell
# Windows
.\install\install-windows.ps1 -ClaudeHome 'D:\my-claude'

# macOS
./install/install-macos.sh --claude-home '/opt/my-claude'
```

#### 非交互模式（CI/批量部署）
```powershell
# Windows
.\install\install-windows.ps1 -ApiToken 'sk-ant-xxx' -BaseUrl '' -NonInteractive -Force

# macOS
./install/install-macos.sh --token 'sk-ant-xxx' --url '' --non-interactive --force
```

### 文件结构

```
~/.claude/
├── CLAUDE.md              # 用户级全局指令（@include docs/）
├── docs/                  # 环境、工作流、工具、安全四份分模块
├── settings.json          # 安装器自动生成
├── skills/                # 33 个 skill 目录
├── agents/                # 22 个 .md 子 agent
├── commands/              # 25 个 slash command
├── hooks/                 # 11 个 PowerShell hook
└── output-styles/         # 5 个输出风格
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

（注：这只删配置，不卸载 VS Code/Node/CLI。那些用各自的卸载方式。）

### 致谢

本仓库整合并改造了多个优秀的开源 Claude Code 配置项目，特此感谢：

| 上游项目 | 贡献内容 | License |
|---------|---------|---------|
| [obra/superpowers](https://github.com/obra/superpowers) | Skills 核心方法论 | MIT |
| [obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace) | Skills 集合 | MIT |
| [wshobson/agents](https://github.com/wshobson/agents) | Subagents 集合 | MIT |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | Subagents 灵感 | MIT |
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 官方 plugin 参考 | Anthropic |

具体哪些文件来自哪里、做了什么改动，见 [LICENSE](LICENSE) 与各文件头部。

### 反馈 / Issue

发 Issue：[github.com/liujiarui0918/claude-code-strongest/issues](https://github.com/liujiarui0918/claude-code-strongest/issues)

### License

[MIT](LICENSE)

---

## English

### What is this

A **batteries-included, opinionated Claude Code setup** packaged with one-click installers for Windows and macOS.

This repo bundles the author's full `~/.claude/` configuration — skills, subagents, commands, hooks, and MCP servers — that took months to refine on a daily-driver machine. The installers bootstrap everything from a blank machine: VS Code, Claude Code CLI, the official VS Code extension, Node.js, Git, PowerShell 7, and uv — then deploy the full config to your home directory.

### Quick Start

**Windows 10/11:**
```powershell
git clone https://github.com/liujiarui0918/claude-code-strongest.git
cd claude-code-strongest
.\install-windows.bat
```

**macOS 12+:**
```bash
git clone https://github.com/liujiarui0918/claude-code-strongest.git
cd claude-code-strongest
bash install/install-macos.sh
```

Get an API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys), paste it into the popup, and you're done.

### What you get

- **VS Code** + official **Claude Code extension** (`anthropic.claude-code`)
- **Claude Code CLI** (`claude` command on PATH)
- **33 skills** auto-triggered on intent ("debug this" → `systematic-debugging`)
- **22 specialized subagents** for parallel research, review, planning, etc.
- **25 slash commands** (`/plan`, `/tdd`, `/review`, `/debug`, `/verify`, ...)
- **11 lifecycle hooks** (block-dangerous, protect-secrets, auto-format, smart-context, ...)
- **8 MCP servers** (sequential-thinking, context7, deepwiki, playwright, memory, fetch, time, git-mcp)

### Configuration

- `--token` / GUI prompt: your Anthropic API key
- `--url` / GUI prompt: optional relay URL (leave empty for official Anthropic API)
- `--claude-home`: override `~/.claude` location
- `--non-interactive --force`: silent install for CI/scripted deploy

### License

[MIT](LICENSE). Bundles third-party MIT-licensed content from `obra/superpowers`, `wshobson/agents`, `VoltAgent/awesome-claude-code-subagents`, and `anthropics/claude-plugins-official`. See [LICENSE](LICENSE) for attribution.

### Contributing

Issues and PRs welcome at [github.com/liujiarui0918/claude-code-strongest](https://github.com/liujiarui0918/claude-code-strongest).
