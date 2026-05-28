---
description: Wrap up the branch: verify → present 4 options (merge/PR/keep/discard)
argument-hint: ""
allowed-tools: Read, Bash, PowerShell, Agent, Glob, Grep
---

Wrap up the current development branch.

Invoke the `finishing-a-development-branch` skill.

Steps:
1. Run the test suite. Run the linter. Run the build. Report each result.
2. Invoke the `verification-before-completion` skill — confirm the change actually does what it was supposed to do, with observed evidence, not vibes.
3. Show the user a concise summary: what's on this branch (commits, files touched, net diff size), test status, and any outstanding concerns.
4. Present these four options and STOP. Do not pick for the user.

   A) Merge into the base branch locally (fast-forward or merge commit).
   B) Push and open a PR.
   C) Keep the branch as-is for later — no action.
   D) Discard the branch (delete it after confirming nothing is lost).

Wait for the user to choose. Only then execute their choice.
