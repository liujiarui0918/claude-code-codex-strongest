---
description: Explain a piece of code, an error, or a concept — pedagogical mode
argument-hint: <code/concept/error>
allowed-tools: Read, Glob, Grep, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

解释："$ARGUMENTS"

流程：

1. **识别类型**：
   - 是文件 / 函数 / 行号 → Read 文件，把上下文（caller、imports、相关类型）拉进来
   - 是 library / framework / API → 用 `mcp__context7__resolve-library-id` 找到 ID，再 `mcp__context7__query-docs` 拿当前文档（不要靠训练记忆，会过时）
   - 是 error message → 拆 stack trace，定位真正 throw 点，看周围代码

2. **四段式讲解**：
   - **What**：它做什么（一句话，黑盒视角）
   - **How**：内部机制 / 步骤 / 关键算法（白盒视角，**这里展开**）
   - **Why**：为什么这么设计（trade-off、历史、约束）
   - **When**：什么时候该用 / 不该用

3. **一个最小例子**：能跑的最简代码（5-15 行），不要 dump 整文件。

4. **1-2 个 gotcha**：常见踩坑（off-by-one、async 时序、内存所有权、closure capture 等）。

铁律：

- **不能说"it just works" / "magic happens"** —— 必须解释 mechanism。如果你不知道机制，直说"我不确定底层 X，需要查"。
- 假设读者会编程但不熟这块。不要 dumb down 到 ELI5（那是 `/eli5`），也不要直接灌专业术语。
- 术语第一次出现 → 一句话定义。
- 如果在 `explanatory` output style 下被调用，可以更展开。

输出建议结构：

```
## What
...

## How
...

## Why
...

## When
...

## Minimal example
```code
...
```

## Gotchas
- ...
- ...
```
