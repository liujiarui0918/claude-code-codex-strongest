# AGENTS.md - Claude Code Codex Strongest rules for claude-code-codex-strongest

Claude Code Codex Strongest keeps the combined Claude Code + Codex workflow in one package while keeping Codex runtime state separate under `~/.codex`.

## Core workflow

- Prefer small, verifiable changes.
- Read a file before editing it.
- Preserve existing behavior unless the user explicitly asks to change it.
- Do not add dependencies without asking.
- Run real verification before claiming completion.
- If a command would install software globally, modify credentials, delete state, or force-push/reset git history, stop and ask first.

## Secrets and runtime state

Never read, print, copy, modify, or commit:

- `auth.json`
- `.credentials.json`
- `*.token`
- `*.key`
- `.env` files
- session, history, log, tmp, cache, runtime, backup, or shell-snapshot directories

Codex authentication must be created by the user with `codex login`. Installers may prompt the user to run it, but must not write tokens or credentials.

## Claude compatibility

This repository remains a Claude Code configuration bundle first. Codex may read the docs, skills, agents, and commands as workflow reference material, but Codex must not assume Claude-specific hooks or credentials are available.
