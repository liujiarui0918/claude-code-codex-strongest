---
description: Verify a claim by running real commands and reading output
argument-hint: "[what to verify]"
allowed-tools: Read, Bash, PowerShell, Glob, Grep
---

The user wants to verify: "$ARGUMENTS"

Invoke the `verification-before-completion` skill.

Rules:
- Run actual commands. Read the actual output. Quote the exact lines that prove or disprove the claim.
- "Looks right" does NOT count. "The code seems to handle it" does NOT count. Only observed behavior counts.
- If the claim involves a build, run the build. If it involves tests, run the tests. If it involves a runtime behavior, exercise it.
- If you can't verify something with the tools available, say so explicitly — do not paper over it.

Report format:
- Claim: <restate>
- Evidence: <commands run + relevant output excerpts>
- Verdict: VERIFIED / FALSIFIED / INCONCLUSIVE (+ why)
