---
description: Generate a Keep-a-Changelog style entry from git history since a ref (default last tag)
argument-hint: [since-ref, default: last tag]
allowed-tools: Bash, PowerShell, Read
---

生成 changelog。

流程：

1. **确定 since-ref**：
   - 如果 `$ARGUMENTS` 非空 → 用它作为起点
   - 否则跑 `git describe --tags --abbrev=0` 拿最近的 tag
   - 如果仓库没 tag → fallback 到 `git rev-list --max-parents=0 HEAD`（首个 commit），并提示用户

2. **拉 commit 历史**：
   ```powershell
   git log <ref>..HEAD --pretty=format:"%h %s%n%b" --no-merges
   ```
   也可以 `--pretty=format:"%h|%an|%s"` 拿 author。

3. **分类**（按 [Keep a Changelog](https://keepachangelog.com/) 规范）：
   - **Added** — 新功能
   - **Changed** — 现有功能的变动
   - **Deprecated** — 即将移除
   - **Removed** — 已移除
   - **Fixed** — bug 修复
   - **Security** — 安全相关

   启发式（看 commit message）：
   - `feat:` / `add` / `new` → Added
   - `fix:` / `bug` / `resolve` → Fixed
   - `refactor:` / `change` / `update` → Changed
   - `remove` / `delete` → Removed
   - `deprecate` → Deprecated
   - `security` / CVE 编号 → Security
   - 看不出来 → 读 commit body / diff 判断

4. **写 markdown**：每条短行，**人类语言**，带 commit hash：

   ```markdown
   ## [Unreleased] - YYYY-MM-DD

   ### Added
   - 支持从 YAML config 加载主题 (`abc1234`)
   - 新增 `--dry-run` flag 给迁移命令 (`def5678`)

   ### Fixed
   - 修了 login 表单在 IE11 提交后清空的崩溃 (`ghi9012`)
   ```

5. **提示用户**：
   - 把 `[Unreleased]` 替换成下个版本号
   - 填日期（今天 = 2026-05-28）
   - 如果项目有 `CHANGELOG.md` → Read 它，把新 section 插到最上面（标题之后）

铁律：

- **写给人看，不是给机器看**：
  - GOOD: `修了 login 在 IE 上崩` / `导出 CSV 时正确处理 UTF-8 BOM`
  - BAD: `Fix issue #1234` / `bump version` / `cleanup`
- 一句 commit 信息 = 一行 changelog（不要把 commit body 整段塞进去）
- 不要包含 chore / docs-only / typo / formatting commit（除非影响用户）
- merge commit 跳过（`--no-merges` 已过滤）
- 不确定归类 → 倾向 `Changed`，宁可粗也不要错
