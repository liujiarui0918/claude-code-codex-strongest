---
description: Clean dead code, unused imports, stale TODOs, console.log in current branch's diff
argument-hint:
allowed-tools: Read, Edit, Glob, Grep, Bash, PowerShell, Agent
---

清理本分支的 dead code / 噪音。

流程：

1. **拿本分支改动文件列表**：
   ```powershell
   git diff main --name-only
   # 找不到 main 试 master / 默认分支
   git diff (git symbolic-ref refs/remotes/origin/HEAD).Replace("refs/remotes/", "") --name-only
   ```
   只清理本分支动过的文件。**不扫整个 repo**。

2. **如果文件 >10 个** → 派 subagent 并行处理（每个 agent 拿一组文件），避免主上下文爆炸。

3. **逐文件 Read，找以下噪音**：

   - **未用 imports**：靠语言工具判断（不要凭目测）
     - JS/TS：跑 `eslint --rule 'no-unused-vars: error'` 或看 LSP 报告
     - Python：`ruff check --select F401`
     - Go：编译器会拒绝，已天然清理
     - Rust：`cargo check` 看 warning
   - **未用变量** / **未用 function**：同上工具判断
   - **debug 残留**：
     - JS: `console.log` / `debugger`
     - Python: `print()`（脚本入口除外）/ `breakpoint()` / `pdb.set_trace()`
     - Rust: `dbg!()` / `println!("DEBUG ...")`
     - Go: `fmt.Println("debug ...")`
   - **老 TODO**：`TODO:` 后跟 2023 或更早的日期，或 issue 编号已 close 的
   - **注释掉的代码块**（3+ 行连续被 `//` / `#` 注释，看起来是真代码不是说明）

4. **Edit 删除**。每条删除前在心里答两个问题：
   - "这个真的没用，还是只是我没找到使用点？" → Grep 全 repo 再确认
   - "删了会影响什么？" → 跑 tests

5. **跑测试**：
   ```
   npm test / pytest / go test ./... / cargo test
   ```
   有失败 → **立刻 revert 最后那次 Edit**，报告给用户。

6. **报告**：
   ```
   清理完成（文件 N 个）：
   - 删除未用 import：12 条
   - 删除 console.log：3 条
   - 删除老 TODO：2 条（2023-04 / 2022-11）
   - 删除注释代码：1 块（auth.ts:45-72）
   测试：18 pass / 0 fail
   ```

铁律：

- **不删 `console.error` / `logger.error`**（可能是生产监控信号）
- **不删别人加的 TODO，没问过本人前**（git blame 看作者）
- **没测试覆盖的文件，只删机械可证的东西**（未用 import、空白）；不删可能影响运行时的代码
- **`debugger` / `breakpoint()` 在测试文件里**也删（不只 prod 代码）
- **不重命名变量、不重构** —— 这是 `/refactor` 的事，不是 `/cleanup`
- **不删 third-party / vendored 代码**（`node_modules/`、`vendor/`、`.venv/`）
