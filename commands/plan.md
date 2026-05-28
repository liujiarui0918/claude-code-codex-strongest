---
description: Start planning a non-trivial task: brainstorm + write a plan
argument-hint: "<task description>"
allowed-tools: Read, Glob, Grep, WebSearch, Agent, TaskCreate
---

The user wants to plan this task: "$ARGUMENTS"

Do NOT start writing code yet. Follow this planning flow strictly:

1. Invoke the `brainstorming` skill to run a Socratic clarification with the user. Surface ambiguities, hidden assumptions, success criteria, and out-of-scope items before anything else.

2. Explore the relevant code using Read / Glob / Grep (and WebSearch if external knowledge is needed). Map the existing surface area the task will touch.

3. Invoke the `writing-plans` skill to produce a written plan. The plan should include: goal, non-goals, approach, files to touch, risks, validation strategy, and rollback.

4. Use TaskCreate to materialize the plan as a concrete task list the user can track. Each task should be small enough to complete in one focused pass.

Only after the plan is written and tasks are created do you stop. Wait for the user's go-ahead before implementing.
