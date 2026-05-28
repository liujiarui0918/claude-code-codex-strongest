---
name: finishing-a-development-branch
description: Use when wrapping up a feature branch. Tests pass → present 4 options: merge / PR / keep / discard.
---

# Finishing a Development Branch

The end of a branch is a decision point, not an autopilot. The same finished work might want to be merged immediately, pushed for review, parked, or thrown away — and only the human can tell which.

## Iron Law

**Do not push, merge, or discard the branch on your own initiative.** Present the four options. Let the user choose.

## Red Flags

- Running `git push` because the work "feels done."
- `git merge` into main without explicit instruction.
- Deleting the branch because tests pass.
- Auto-opening a PR because that's "the usual flow."

The user owns the decision. Your job is to make the decision easy.

## The Wrap-Up Flow

### Step 1: Run the gates

Before presenting options, the branch MUST pass:

- [ ] All tests green (run them — see [[verification-before-completion]])
- [ ] Self-review done ([[requesting-code-review]])
- [ ] Lint / typecheck clean
- [ ] Commit history sensible (squash / reword if needed)
- [ ] No leftover debug code, stash entries, untracked junk
- [ ] Branch is up-to-date with base (`git fetch && git rebase origin/main` if needed)

If any gate fails, stop. Fix it. Do not present options on a broken branch.

### Step 2: Summarize for the user

Tell the user:
- What the branch does (1-2 sentences)
- What files / areas changed
- What was verified, how
- Any known limitations or follow-ups

### Step 3: Present exactly 4 options

```
The feature branch is ready. How would you like to proceed?

  1. Merge — fast-forward / squash into main locally now.
  2. PR     — push branch to origin and open a pull request for review.
  3. Keep   — leave the branch as-is for now (resume / re-evaluate later).
  4. Discard — abandon the work; delete branch and worktree.
```

### Step 4: Act on the chosen option

#### 1. Merge
```powershell
git checkout main
git merge --ff-only feature/x   # or --squash, ask if unclear
git push origin main
# then cleanup per option-specific dance
```

#### 2. PR
```powershell
git push -u origin feature/x
# open PR via gh CLI or web; include the summary from Step 2 as PR description
```

#### 3. Keep
- Leave branch + worktree intact.
- Note the resume point (which task / what's next).

#### 4. Discard
- Confirm with user: "discard means losing all commits on feature/x — confirm?"
- Then:
  ```powershell
  git worktree remove ../repo-feature-x
  git branch -D feature/x
  git worktree prune
  ```

### Step 5: Cleanup (when applicable)

After merge or discard, clean the worktree per [[using-git-worktrees]]. Don't leave orphan directories.

## What NOT to do

- Don't merge into main without ff-only or explicit squash instruction — silent merge commits clutter history.
- Don't force-push without flagging it.
- Don't delete commits the user hasn't seen.
- Don't open a PR before the user picks option 2 — drafts also count.

## MUST

- MUST run gates before presenting options.
- MUST present all 4 options, not the "obviously right" subset.
- MUST get explicit user choice before any destructive or push action.

## Cross-references

- [[using-git-worktrees]] — for the worktree lifecycle that this skill closes.
- [[verification-before-completion]] — gate 1 before options are even on the table.
- [[requesting-code-review]] — gate 2, the self-review pass.
