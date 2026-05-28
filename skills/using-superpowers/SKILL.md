---
name: using-superpowers
description: Use at session start to orient: pick the right skill before doing anything.
---

# Using Superpowers

**Iron Law**: 在动手之前，先扫一眼这份清单。任务和某个 skill 的匹配度 **≥1% 就要 invoke 它**——skill 比你的直觉更可靠。

## 触发时机

- session 刚开始，用户给了一个非平凡任务
- 你正想"直接开干"——停下来，先查这里
- 你不确定该走哪条路径

## 本机可用 Skills（按场景分类）

### Meta / Orientation
- [[using-superpowers]] — 你正在读的这个
- [[init]] — 初始化 CLAUDE.md
- [[update-config]] — 改 settings.json / hooks / permissions
- [[keybindings-help]] — 改快捷键
- [[fewer-permission-prompts]] — 扫历史把常用命令加白名单

### Brainstorming（理解需求）
- [[brainstorming]] — 任何创造性 / 非平凡设计任务**之前**必走
- [[loop]] — 周期性任务 / 轮询

### Planning（把想法变成可执行步骤）
- [[writing-plans]] — 把 spec 拆成 2-5 分钟的可验证任务

### Execution（执行）
- [[executing-plans]] — 按 plan 跑，分批检查点
- [[subagent-driven-development]] — 复杂多任务，每任务一个干净 subagent
- [[dispatching-parallel-agents]] — ≥2 个独立任务，一条消息并发派
- [[test-driven-development]] — 实现新功能 / 修 bug，RED → GREEN → REFACTOR

### Implementation / Domain
- [[claude-api]] — Anthropic SDK 应用、prompt caching、模型迁移
- [[run]] — 启动本项目的 app
- [[verify]] — 跑起来观察行为，验证改动真的工作

### Review / Quality
- [[code-review]] — 复查当前 diff（low/medium/high/max effort）
- [[simplify]] — 等价于 code-review --fix
- [[review]] — review 一个 PR
- [[security-review]] — 当前分支的 pending changes 安全审查

## Skill Priority Order

**Process skills 优先于 implementation skills**。意思是：

1. 如果用户在描述需求 → [[brainstorming]] **先**，不要直接写代码
2. 如果已有 spec → [[writing-plans]] **先**，不要边想边写
3. 如果已有 plan → [[executing-plans]] / [[subagent-driven-development]] **先**，不要随手开干
4. 写代码时如果是新功能 / 修 bug → [[test-driven-development]] **先**写测试
5. 改完之后 → [[verify]] 或 [[code-review]] 收尾

## Red Flags

- 用户提了个模糊需求，你已经开始 Write 文件了 → **停**，回到 [[brainstorming]]
- 你打算连开 5 个 Edit 没做 plan → **停**，回到 [[writing-plans]]
- 你要实现一个 function，但没写测试 → **停**，回到 [[test-driven-development]]
- 你看到 ≥2 个独立子任务 sequential 做 → **停**，回到 [[dispatching-parallel-agents]]
- 用户说"从今往后每次 X 都 Y" → 这是 hook 需求，不是 memory，去 [[update-config]]

## MUST Do

- **先报告打算走哪条 skill 链**，再开干。例：「这个任务需要 [[brainstorming]] → [[writing-plans]] → [[subagent-driven-development]]」
- 遇到不确定的就**回到这份清单**，不要硬刚
- 一次只在一个 skill 的语境下工作；切 skill 时显式声明

## MUST NOT Do

- 不要"我感觉直接写就行"——感觉是不可靠的
- 不要把 skill 名字写出来但不真正调用它
- 不要在已经有 plan 的情况下再回去 brainstorm（除非 plan 被推翻）
