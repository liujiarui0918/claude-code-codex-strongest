---
name: test-driven-development
description: Use when implementing new functionality OR fixing a bug with a reproducer. Iron law: RED → GREEN → REFACTOR.
---

# Test-Driven Development

**Iron Law**: **没有失败的测试，就不写实现代码**。一行都不写。

## 触发时机

- 实现新功能，spec 清晰
- 修一个有复现步骤的 bug
- 重构有测试覆盖的代码
- 添加 API endpoint / function / module

## 不触发（TDD 不合适）

- 探索性原型（边写边想要什么）
- 一次性脚本，跑完即弃
- UI 视觉调整（截图驱动更合适）
- spec 模糊 → 退回 [[brainstorming]]

## RED → GREEN → REFACTOR

### RED：先写一个**会失败**的测试

- 测试描述**期望的行为**，不是"实现细节"
- 跑测试，**确认它失败**（看到红）
- 失败原因必须是"功能不存在 / 行为不对"，**不是** typo / import 错误

红旗：测试没跑，或者跑了过了——你写的不是测试，是装饰。

### GREEN：**最小**实现让测试通过

- 写**够**让测试过的最少代码
- 不要"顺手把另一个功能也加上"
- 跑测试，**看到绿**
- 这一步不重构，不优化，**不美化**

红旗：你在 green 阶段写了 100 行 → 大概率没遵守"最小"。

### REFACTOR：清理，**保持绿**

- 重命名、抽函数、消重复
- 每次小改动**重跑测试**，保持绿
- 测试是安全网，让你大胆改

红旗：refactor 后没重跑测试 → 你不知道现在是绿是红。

## 修 Bug 的特化流程

1. 写一个测试**复现 bug**——它会失败
2. **不要先改实现**，先确认测试在 reproduce
3. 改实现让测试过
4. 测试留下，作为 regression guard

## 测试质量

- **一个测试一个断言主轴**（不要在一个 test 里测 5 件事）
- **测试名 = 行为描述**：`should reject empty username`，不是 `test1`
- **Arrange / Act / Assert** 三段清晰
- **独立**：任意顺序跑都过

## Red Flags

- 先写实现，后补测试 → **不是 TDD**，是"测试套娃"
- 测试在 implementation 之后才跑 → **错**，RED 阶段就应该跑
- 测试和实现写在一个 commit → 看不出 RED → GREEN 历史
- "这功能太简单不用测试" → 简单的功能更值得测（写测试也快）
- 测试一直绿（从没红过）→ 你测了个寂寞

## 集成到 plan 流程

[[writing-plans]] 里的每个任务，如果是新功能 / bug fix：

- 任务 N.a：写测试（verify：测试**失败**）
- 任务 N.b：写实现（verify：测试**通过**）
- 任务 N.c：refactor（verify：测试**仍然通过**）

这样 [[executing-plans]] 自动走 TDD。

## 何时跳过 RED

**几乎从不**。

可接受的例外：

- 改文档 / 改注释 / 改格式
- 改 config 且有别的方式验证（启动看日志）
- 一次性脚本（但建议至少跑一次手动验证）

## MUST

- 先写测试，跑到失败（RED）
- 最小实现到通过（GREEN）
- 重构时保持通过（REFACTOR）
- 修 bug 先写复现测试

## MUST NOT

- 不要先写实现再补测试
- 不要在 GREEN 阶段 over-engineer
- 不要在 REFACTOR 阶段不跑测试
- 不要"这太简单"绕过 TDD
