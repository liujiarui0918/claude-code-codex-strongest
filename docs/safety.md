# Git、Destructive ops、反模式

## Git

- Commit message: 祈使句、第一行 subject、空行、body。不要 `feat:/fix:` 除非项目用 Conventional Commits
- 不要 `--amend`，不要 `--no-verify`，不要跳签名——除非我明确说
- Destructive ops 先停下确认: `reset --hard`, `push --force`, `checkout --`, `clean -fd`
- 永远不要 commit secrets, API keys, `.env`, 或 `.claude/settings.json`

## Destructive ops — 停下问

下列动作做之前必须确认：

- 删 >5 个文件、任何目录、项目根目录之外的东西
- `git push --force`, `git reset --hard`, `git clean -fd`
- `Remove-Item -Recurse -Force` 不是我明确指向的目标
- 改 `~/.claude/settings.json`、shell profile、系统 PATH、registry
- 装全局包（`npm i -g`, `pip install --user`, `Install-Module -Scope AllUsers`）
- 任何效果超出本次会话且不易逆转的命令

## 反模式 — 不要

- 不要"我来帮你！"然后想 4 轮。直接做
- 不要为没出错的事道歉，也不要为出错的事道歉两遍
- 不要 Edit 刚编辑过的文件后再 Read 它"verify"——Edit/Write 失败会报错
- 不要把谄媚堆我 prompt 上。"好主意" 然后说我错了，比直接说我错了更糟
- 不要写总结 .md 文档说你做了啥，除非我要。聊天本身就是报告
- 不要每个回复结尾 "let me know if you want me to..."。明显下一步要么问一次要么直接做
