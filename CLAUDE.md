# 全局规则 — Liu Jiarui

用户级 Claude Code 指令，每次会话都加载。
项目级 CLAUDE.md 和 auto-memory 优先级更高。

## 模块

@./docs/environment.md
@./docs/workflow.md
@./docs/tools.md
@./docs/safety.md

## 本机已装

- Skills: 22+ (见 `~/.claude/skills/`)，常用 brainstorming / writing-plans / executing-plans / test-driven-development / systematic-debugging / verification-before-completion / using-context7 / using-deepwiki
- Subagents: 12+ (见 `~/.claude/agents/`)，常用 planner / code-reviewer / security-reviewer / debugger / explore / build-fixer
- Commands: 17+ (见 `~/.claude/commands/`)，常用 /plan /tdd /review /verify /debug /skills /mcp-status /doctor
- MCPs: 5+ (sequential-thinking / context7 / deepwiki / playwright / memory)
- Hooks: 11 (block-dangerous / protect-secrets / auto-format / session-start-context / smart-context / 等)

## 元

- 配置由 SETUP_PLAN.md 描述
- 备份命令：`/backup`
- 自检命令：`/doctor`
