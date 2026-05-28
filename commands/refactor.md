---
description: Safe refactor: preserve behavior, require test coverage first
argument-hint: "<file or pattern>"
allowed-tools: Read, Edit, Glob, Grep, Bash, PowerShell, Agent
---

Refactor target: "$ARGUMENTS"

Delegate to the `refactor-assistant` subagent.

Hard rule before any code is changed:
1. Check whether the target has meaningful test coverage. Use Glob/Grep to find existing tests; run them and observe pass/fail.
2. If coverage is missing or thin: STOP. Do not refactor. Instead, propose the tests that need to be added first (characterization tests pinning current behavior), and ask the user to confirm before proceeding.
3. Only once tests exist and are green do you start refactoring. Behavior must be preserved bit-for-bit — the same tests must stay green after every step.

During the refactor:
- Small steps. Run the tests after each step.
- No new behavior, no new features, no scope creep. If you find a bug, surface it separately — don't fix it inside the refactor.
- Keep the diff focused and reviewable.
