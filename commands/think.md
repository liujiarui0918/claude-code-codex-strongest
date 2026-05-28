---
description: Use sequential-thinking MCP for complex multi-step reasoning, with revisions and branches
argument-hint: <problem or decision>
allowed-tools: mcp__sequential-thinking__sequentialthinking, Read, Glob, Grep
---

用户要深入思考："$ARGUMENTS"

流程：

1. Invoke `using-sequential-thinking` skill 先看 skill 的指导原则。

2. 调 `mcp__sequential-thinking__sequentialthinking` tool，从 `thoughtNumber: 1` 开始，`totalThoughts` 初估 5-10（可以随推进调整）。

3. 每一步 thought 必须包含明确推理：
   - 当前观察 / 假设
   - 这一步要解决什么子问题
   - 信号是否指向继续 / 修正 / 分支

4. 如果发现前面某 thought 错了 → 设 `isRevision: true` + `revisesThought: <编号>`，明确说哪里错了，再给出修正。

5. 如果一条路径走不下去想换思路 → 设 `branchFromThought: <编号>` + `branchId: <短标签>`，开新分支不丢弃主线。

6. 复杂度超出预期 → 调高 `totalThoughts` 或最后一步设 `needsMoreThoughts: true`。

7. 必要时用 Read / Glob / Grep 拉具体文件证据，**不要凭记忆推理代码**。

最终输出：

- **结论**：一句话
- **关键洞察**：3-5 条 bullet
- **不确定的点**：明确列出（什么前提没验证 / 什么数据缺失）
- **下一步建议**：可执行的 1-3 个动作

铁律：宁可多想 2 步、明示不确定，也不要假装收敛得很漂亮。
