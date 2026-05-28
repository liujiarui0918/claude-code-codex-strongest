---
description: Create a git worktree for an isolated feature branch
argument-hint: "<feature-name>"
allowed-tools: PowerShell, Bash, Read
---

Open a git worktree for: "$ARGUMENTS"

Invoke the `using-git-worktrees` skill.

Steps:
1. Confirm we're inside a git repo and the working tree is clean enough to branch from (or branch from origin/<default> if not).
2. Run: `git worktree add ../$ARGUMENTS -b feature/$ARGUMENTS`
3. Report the absolute path of the new worktree.
4. Tell the user to `cd` into that path to start working — the new branch `feature/$ARGUMENTS` is checked out there in isolation from the current directory.
5. Remind them how to clean up later: `git worktree remove <path>` then `git branch -D feature/$ARGUMENTS` if abandoning.
