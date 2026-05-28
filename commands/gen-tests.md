---
description: Generate tests for a file or function. Detects test framework from project.
argument-hint: <file path>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
---

为 "$ARGUMENTS" 生成测试。

流程：

1. **Read 目标文件**，列出每个 public function / method / exported symbol。对每个：
   - 输入参数 + 类型
   - 返回值 + 类型
   - 副作用（IO、网络、全局状态）
   - 可能抛错的路径

2. **检测 test framework**：Glob 找现有测试：
   - `**/*.test.{js,ts}` / `**/*.spec.{js,ts}` → jest / vitest（看 package.json `devDependencies`）
   - `**/test_*.py` / `**/*_test.py` → pytest / unittest
   - `**/*_test.go` → go test
   - `**/spec/**/*_spec.rb` → rspec
   - `**/src/test/java/**` → junit
   - 找不到？看 package.json / pyproject.toml / Cargo.toml 配置块。

3. **沿用项目风格**：Read 1-2 个现有测试文件，模仿：
   - 命名约定（`describe/it` vs `test_xxx`）
   - mock 风格（jest.mock / monkeypatch / unittest.mock）
   - fixture 组织
   - assertion 风格

4. **为每个 function 生成 case**：
   - **Happy path**：典型输入 → 期望输出
   - **Edge cases**：空 / 边界 / 极值 / Unicode / 大输入
   - **Error paths**：非法输入 → 预期 throw / Err / panic
   - **State-based**（如有）：调用前后状态变化

5. **Mock 原则**：
   - 不要 mock 太宽（`jest.mock('database')` 把整个模块 mock 掉 = 测试只验证 mock 自己）
   - 用 in-memory 实现 / sqlite / fixture file 替代真实 IO
   - 只 mock 边界（network、time、randomness）

6. **跑测试 verify**：调用项目的 test runner（`npm test` / `pytest` / `go test ./...` / `cargo test`）确认全部 pass。

7. **失败时**：
   - 是测试写错了 → 改测试
   - 是 production 代码真有 bug → 报告给用户，**不要悄悄改生产代码让测试过**
   - 不要为了让测试 pass 而放宽 assertion（"等于" 改成 "包含"）

铁律：

- 测试名描述 **behavior**，不是 **implementation**：
  - GOOD: `it("returns user when authenticated")` / `test_login_with_expired_token_returns_401`
  - BAD: `it("calls getUserFromDb")` / `test_internal_helper_called_twice`
- 一个测试一个断言主题（断言数量不限，但围绕一个 behavior）
- 不要测试 framework / language 本身（"测试 Array.map 返回新数组"）
