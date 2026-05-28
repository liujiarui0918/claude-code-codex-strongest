---
description: "Audit project dependencies: outdated, vulnerable, unused"
argument-hint:
allowed-tools: Read, Glob, Grep, Bash, PowerShell
---

依赖审计。

流程：

1. **识别 package manager**：Glob 找 manifest：
   - `package.json` + `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` → Node
   - `pyproject.toml` / `requirements.txt` / `Pipfile` → Python
   - `Cargo.toml` + `Cargo.lock` → Rust
   - `go.mod` + `go.sum` → Go
   - `pom.xml` → Maven / Java
   - `build.gradle` → Gradle
   - `Gemfile.lock` → Ruby
   - `composer.json` → PHP
   - 多个并存（monorepo）→ 逐个跑

2. **跑审计命令**：

   **Node**:
   ```powershell
   npm outdated --json
   npm audit --json
   # 或 pnpm outdated / pnpm audit
   # depcheck 找未用依赖
   npx depcheck --json
   ```

   **Python**:
   ```powershell
   pip list --outdated --format=json
   pip-audit --format json    # 如装；没装提示 pip install pip-audit
   # 未用：pipreqs 对比 实际 import vs 声明
   ```

   **Rust**:
   ```powershell
   cargo outdated --format json   # 需要 cargo-outdated subcommand
   cargo audit --json             # 需要 cargo-audit
   # 未用：cargo machete 或 cargo udeps（nightly）
   ```

   **Go**:
   ```powershell
   go list -u -m -json all
   govulncheck -json ./...
   ```

   **Java/Maven**:
   ```powershell
   mvn versions:display-dependency-updates
   mvn org.owasp:dependency-check-maven:check
   ```

   **失败 fallback**：工具没装 → 报告"建议装 X：`<install cmd>`"，跳过该项不阻塞其他。

3. **分类输出**：

   ```markdown
   ## CRITICAL — 立即处理（已知 CVE）
   - `lodash@4.17.15` → 4.17.21  CVE-2021-23337（命令注入）
     升级：`npm i lodash@4.17.21`

   ## MAJOR — 大版本落后（需评估 breaking changes）
   - `react@17.0.2` → 18.3.1（concurrent rendering、自动 batching；hooks API 兼容）
     **不主动升级**，建议先读 migration guide

   ## MINOR / PATCH — 安全升级
   - `axios@1.6.2` → 1.7.9
     升级：`npm i axios@^1.7`

   ## UNUSED — 声明了但代码没用
   - `moment`（depcheck 报告）—— 确认后 `npm un moment`
   - `@types/node-fetch`（如已删 node-fetch）

   ## MISSING — 用了但没声明
   - `chalk` 在 src/cli.ts 用了但不在 package.json
   ```

4. **每条带可执行命令**。

铁律：

- **MAJOR 升级不主动跑**，只列出来 + 链接到 changelog / migration guide。让用户决定（可能有 breaking changes）
- **PATCH/MINOR 也只列命令，不主动跑** —— `npm i` 会改 lock 文件，是 destructive op
- CVE 严重度按 CVSS：≥7.0 = CRITICAL；4.0-6.9 = HIGH；< 4.0 = MEDIUM
- `depcheck` 经常误报（dynamic require、CLI bin、postinstall script）→ 标 "请人工确认" 而非"可删"
- monorepo 的 workspace dep（`workspace:*` / `file:`）跳过，不当外部依赖审
- dev-only 漏洞（`devDependencies` 里的）单独标，严重度降一级（不进生产）
