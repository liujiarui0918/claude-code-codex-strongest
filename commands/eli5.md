---
description: "Explain a technical topic like to a 5-year-old: analogy first, then build up"
argument-hint: <topic>
allowed-tools: WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

用 ELI5 方式解释："$ARGUMENTS"

流程：

1. **第一段 — 纯 analogy**：
   - 0 技术词。完全用日常事物（玩具、信件、厨房、动物、教室、小镇）
   - 类比要选**结构同构**的，不是"差不多就行"
   - 例：
     - TCP/IP = 寄信，地址 = IP，邮局 = router
     - hash table = 一面墙上很多小柜子，每个都贴号
     - async/await = 厨师同时炖汤 + 切菜，不是傻等汤好

2. **第二段 — 在 analogy 上加细节**：
   - 类比怎么"运转"
   - 边界条件用类比描述（"如果两封信地址一样会怎样？"）

3. **第三段 — 引入真实术语**：
   - 把 analogy 里的元素一一对应：
     - "寄信" → packet
     - "邮局" → router
     - "地址" → IP address
   - 每个术语括号里给一句话定义

4. **第四段 — 最简单例子**：
   - 5-10 行伪代码或真代码
   - 注释说"这一行对应 analogy 里的 X"

约束：

- **总字数 ≤ 400 字**（中英文都算）
- 第一段绝对 0 技术词。如有需要 → 用 `mcp__context7__query-docs` 查权威定义后再翻译成 analogy；不要凭记忆瞎类比
- 不要嵌套类比（"就像 X，X 又像 Y"）—— 选一个就一条到底
- 不要用"想象一下" / "假设你是" 开场后又立刻切回技术语言

铁律：

- 如果一个概念你不能用 analogy 讲清楚，说明**你自己也没真懂**。先 WebSearch / context7 查清，再写
- 不要 condescending。ELI5 是化繁为简，不是把读者当傻瓜
