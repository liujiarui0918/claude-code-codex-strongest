---
description: Multi-step research with synthesis. Returns structured report
argument-hint: "<topic>"
allowed-tools: WebSearch, WebFetch, Read, Grep, Agent
---

Research this topic in depth: "$ARGUMENTS"

Delegate to the `research-agent` subagent. Use a multi-step process:

1. DECOMPOSE — Break the topic into 3–6 concrete sub-questions. List them up front.
2. SEARCH IN PARALLEL — For each sub-question, run independent web searches and/or fetches. Pull from primary sources where possible (official docs, RFCs, original papers, vendor blogs) over secondary aggregators.
3. CROSS-VERIFY — For every non-trivial claim, confirm it appears in at least two independent sources, or flag it as single-sourced.
4. SYNTHESIZE — Reconcile contradictions explicitly. Note where sources disagree and why.

Final report structure:
- Key Findings — the 3–7 most important takeaways, each one sentence.
- Trade-offs — the genuine tensions, options, and what each choice costs.
- Recommendation — your concrete suggestion for the user's likely use case, with reasoning.
- Sources — full list of URLs as markdown links, grouped by which sub-question they informed.
