---
name: systematic-debugging
description: Use when diagnosing a bug. 4 phases: reproduce → isolate → fix → verify.
---

# Systematic Debugging

Bugs don't get fixed by staring at code. They get fixed by a disciplined loop. Skip a phase and you'll either fix the wrong thing or "fix" something that wasn't broken.

## Iron Law

**You cannot fix what you cannot reproduce.** If you cannot trigger the bug on demand, you are guessing — not debugging.

## The 4 Phases

### Phase 1: Reproduce

Goal: Get a minimal, deterministic trigger.

- Find the exact input / state / sequence that causes the failure
- Strip it down — remove every step that isn't required for the bug to appear
- Capture the failing command, the input data, and the expected vs. actual output
- If it's intermittent, find what makes it deterministic (seed, time, ordering, race condition)

**Red Flag**: "It happens sometimes" — keep reducing until it happens *always* under the minimal trigger, or you've identified the non-deterministic source.

### Phase 2: Isolate

Goal: Pin the bug to a single variable / line / commit / module.

- **Bisect**: cut the suspect range in half, test, repeat. Works on git history (`git bisect`), on inputs (binary search the data), on code paths (comment out half).
- Form ONE hypothesis at a time. "Maybe it's A or B or C" is not isolation — pick one, test, eliminate.
- Use logs, breakpoints, `Write-Host`, whatever lets you see actual state at the suspect point.
- Drive the suspect surface down to a single variable that you can flip to make the bug appear/disappear.

**Red Flag**: Changing 3 things at once. If the bug goes away, you don't know which change fixed it.

### Phase 3: Fix

Goal: Smallest change that eliminates the root cause.

- Apply [[root-cause-tracing]] before patching — fix the source, not the symptom.
- Minimal diff. Don't refactor while fixing. Don't rename. Don't reorganize.
- If the fix balloons, stop — you're either solving the wrong problem or scope-creeping. Open a new branch for the cleanup.

**Red Flag**: Wrapping the symptom in `if (x != null)` without understanding *why* `x` was null.

### Phase 4: Verify

Goal: Prove the bug is gone and nothing else broke.

- Run the exact Phase 1 reproducer. It must now pass.
- Run the existing test suite. Nothing red.
- Add a regression test that fails on the old code and passes on the new code. If you can't write one, you don't understand the bug well enough.
- Read the actual output, not "tests probably pass" — see [[verification-before-completion]].

**Red Flag**: "Looks fixed, moving on." You haven't verified until you've re-run the reproducer.

## Common Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| Skip Phase 1, start patching | You'll fix code that wasn't the bug |
| "Shotgun" debugging (change many things) | Can't tell what worked |
| Stop at first plausible cause | Symptom-fix, not root-cause-fix |
| Verify by reading the diff | Code that "looks right" still ships bugs |
| Add defensive guard, call it fixed | Bug still exists upstream — see [[defense-in-depth]] for when guards are appropriate |

## When the bug is in a system you don't own

Same loop, smaller scope:
1. Reproduce against the dependency in isolation (curl the API directly, run the lib with toy input).
2. Isolate which call / flag / version triggers it.
3. Either work around with a local fix (and file an upstream issue) or wait for a fix.
4. Verify your workaround actually triggers the corrected path.

## Cross-references

- [[root-cause-tracing]] — for Phase 3, getting from symptom to root.
- [[verification-before-completion]] — for Phase 4, what "verified" actually means.
- [[condition-based-waiting]] — for async / race-condition bugs in Phase 1 reproduction.
