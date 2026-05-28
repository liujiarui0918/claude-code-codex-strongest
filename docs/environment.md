# 环境与 Shell

## 环境

- OS: Windows 10/11 (PowerShell 5.1 自带) 或 macOS 12+ (PowerShell 7 由安装器自动安装)
- 默认模型: Opus 4.7 (1M context)，偏向充分而非压缩
- Auto-memory 已启用，由 harness 自动管理项目学习成果——不要在这里重复"remember this"
- Skills/Subagents/Commands/Hooks/MCPs 全部已配置，**优先用工具而不是自己重头实现**

## Shell — PowerShell（Win 5.1 / Mac 7+），不是 Bash

- `&&` 和 `||` 在 PS 5.1 无效（PS 7 支持）。跨平台兼容用 `; if ($?) { ... }` 链
- 原生 exe 不要 `2>&1`——会把 stderr 行包成 ErrorRecord 并破坏 `$?`
- Windows PS 5.1 默认文件编码 UTF-16 LE + BOM。写给别的工具读 → 加 `-Encoding utf8`
- 环境变量: `$env:NAME`，不是 `$NAME` 或 `export`
- 含空格的路径: 双引号包；调原生 exe 用 `& "/path with space/app"`
- 别用 Unix 名字（Win 上）: `head`、`tail`、`which`、`touch`、`wc -l`、`rm -rf`、`chmod`——要么不存在要么行为不同
- 不要交互式命令（`Read-Host`、`git rebase -i`、`git add -i`）——会卡死

## 文件位置参考

- 全局配置: `~/.claude/`
- Skills: `~/.claude/skills/<name>/SKILL.md`
- Agents: `~/.claude/agents/<name>.md`
- Commands: `~/.claude/commands/<name>.md`
- Hooks: `~/.claude/hooks/<name>.ps1`
- Memory: `~/.claude/projects/<project-slug>/memory/`
- Logs: `~/.claude/logs/`
