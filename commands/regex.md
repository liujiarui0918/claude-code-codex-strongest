---
description: Write a regex from description with test cases, in your project's regex flavor
argument-hint: <what to match>
allowed-tools: Read, Glob, Grep, Agent
---

写正则匹配："$ARGUMENTS"

如果 `regex-expert` agent 已配置 → 派给它。否则继续。

流程：

1. **确定 regex flavor**（重要：不同 flavor 语法不一样）：
   - Read `package.json` → JS regex (ECMAScript)
   - Read `pyproject.toml` / `requirements.txt` → Python `re` 模块
   - Read `Cargo.toml` → Rust `regex` crate（无 lookbehind）
   - Read `go.mod` → RE2（无 backreference / lookaround）
   - `.gitignore` / `.rgignore` / ripgrep 使用 → RE2
   - PowerShell `-match` → .NET regex
   - `grep` 默认 BRE / `grep -E` ERE / `grep -P` PCRE
   - 找不到 → 问用户，或默认 PCRE 并明确标注

2. **列测试用例**（写正则前先列）：
   - **3+ 正例**（应该匹配）—— 涵盖典型、边界
   - **3+ 反例**（不应匹配）—— 涵盖容易误伤的相似输入
   - 给出每例的"为什么"

3. **写正则**，**分段解释**：

   ```
   ^(?P<area>\d{3})-(?P<num>\d{4})$
   │ │       │     │ │     │  │
   │ │       │     │ │     │  └─ 行尾锚
   │ │       │     │ │     └──── 4 位数字（命名组 num）
   │ │       │     │ └────────── 分隔符
   │ │       │     └──────────── 命名组结束
   │ │       └────────────────── 3 位数字（命名组 area）
   │ └────────────────────────── 命名组开始
   └──────────────────────────── 行首锚
   ```

4. **运行验证**：
   - **PowerShell**: `'input' -match 'pattern'` （flavor: .NET）
   - **PCRE**: `echo 'input' | grep -P 'pattern'`
   - **JS**: `node -e "console.log(/pattern/.test('input'))"`
   - **Python**: `python -c "import re; print(re.match(r'pattern', 'input'))"`
   - **Go/RE2**: `echo 'input' | rg 'pattern'`

   每个测试用例都跑一遍，输出 `input → matched/not` 表格。

5. **catastrophic backtracking 检查**：
   - 警惕嵌套量词：`(a+)+` / `(a*)*` / `(a|a)+`
   - 重叠 alternation：`(a|ab)+`
   - 看到这类结构 → 警告 + 给出**等价无回溯重写**（如用 atomic group `(?>...)` / possessive `++` / 直接用 RE2 风格的扁平模式）

铁律：

- 永远先列测试用例，再写 pattern
- 永远跑验证（不要凭脑子说"这个应该能匹配"）
- 永远标 flavor（同样语法在不同 engine 行为可能不同）
- 复杂模式 → 用 `(?x)` extended mode + 注释拆行，可读性优先
