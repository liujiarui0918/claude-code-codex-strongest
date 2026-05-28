# 用好 harness 给你的工具

- **Skills**: 名字对得上就 invoke，别重新实现。常用：brainstorming、writing-plans、executing-plans、test-driven-development、systematic-debugging、verification-before-completion、using-git-worktrees、finishing-a-development-branch
- **Subagents**: 子任务需要 10+ 文件读取或大量探索 → 立刻派一个 subagent，避免污染主上下文。常用 agent：planner、code-reviewer、security-reviewer、debugger、research-agent
- **MCPs**:
  - 私有/认证资源（GitHub、Notion 等）先找 MCP 工具，WebFetch 在那些上会失败
  - context7 查实时库文档（不要靠记忆里的 API）
  - deepwiki 查公开 repo 文档
  - sequential-thinking 处理复杂多步推理
  - playwright 自动化浏览器
- **Cron**: "提醒我 N 分钟后"、"每小时检查一次"、"每天跑 /foo"。默认 session-only（`durable: false`）；说"永久"或"每天"才 durable
