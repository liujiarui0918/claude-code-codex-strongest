---
description: Run a code review on a path (or current diff)
argument-hint: "[file or dir, default: git diff]"
allowed-tools: Read, Glob, Grep, Bash, PowerShell, Agent
---

The user wants a code review on: "$ARGUMENTS"

If $ARGUMENTS is empty, review the current `git diff` (uncommitted + staged changes on the working branch).

Flow:
1. Invoke the `requesting-code-review` skill first to run a self-check pass — catch the obvious stuff (style, naming, dead code, missed edge cases) before bothering the deeper reviewer.
2. Then delegate to the `code-reviewer` subagent for a deeper pass focused on correctness, security, and design.

Report findings grouped by severity:
- CRITICAL — bugs, data loss risks, security holes, broken contracts. Must fix before merge.
- WARNING — design smells, missing tests, error handling gaps, footguns. Should fix.
- NIT — style, naming, micro-readability. Optional.

For each finding include: file:line, what's wrong, why it matters, and a concrete suggested fix.
