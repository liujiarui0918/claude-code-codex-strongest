---
description: Implement a feature with strict TDD: RED → GREEN → REFACTOR
argument-hint: "<feature description>"
allowed-tools: Read, Edit, Write, Bash, PowerShell, Glob, Grep, Agent
---

The user wants to implement this feature with strict TDD: "$ARGUMENTS"

Invoke the `test-driven-development` skill and follow the loop literally. No shortcuts.

For each behavior in the feature:

1. RED — Write the smallest failing test that captures the next behavior. Just one. Be specific about the assertion.
2. Run the test. Confirm it fails for the RIGHT reason (not import errors, not typos). Read the failure output.
3. GREEN — Write the minimum implementation to make that test pass. No extra fields, no extra branches, no speculative code.
4. Run the test. Confirm it passes. Run the full suite. Confirm nothing else broke.
5. REFACTOR — Clean up only what's now duplicated or unclear. Tests must stay green throughout.
6. VERIFY — Re-run the suite one more time. Observe actual output before claiming the cycle is done.

Then loop back to step 1 for the next behavior.

Do not write multiple tests at once. Do not write the implementation before the test. Do not skip the failure-confirmation step.
