---
description: Systematic debugging: reproduce → isolate → fix → verify
argument-hint: "<bug symptom>"
allowed-tools: Read, Edit, Glob, Grep, Bash, PowerShell, Agent
---

Debug this symptom: "$ARGUMENTS"

Invoke the `systematic-debugging` skill. Walk all four phases — do NOT skip any, even if you think you "know" the answer.

Phase 1 — REPRODUCE
- Get a minimal, deterministic reproducer. Exact command, exact input, exact observed output.
- If you can't reproduce, the bug isn't fixed yet — keep digging at this phase.

Phase 2 — ISOLATE
- Invoke `root-cause-tracing` skill. Trace from symptom back to the line that's actually wrong.
- Bisect, log, diff against a known-good state. Name the root cause in one sentence before moving on.
- Distinguish symptom from cause. "Variable X is null" is a symptom; "function Y returns null when input is empty" is closer to the cause.

Phase 3 — FIX
- Minimal change that addresses the root cause, not the symptom.
- If the fix is large, consider whether the design is the real problem.

Phase 4 — VERIFY
- Re-run the reproducer. Confirm the symptom is gone.
- Run the full test suite. Confirm nothing regressed.
- Add a regression test if one doesn't already cover this.
