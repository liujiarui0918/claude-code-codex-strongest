---
description: Search the auto-memory store for past learnings
argument-hint: <keyword or topic>
allowed-tools: Read, Glob, Grep
---

Search the auto-memory store under `~/.claude/projects/*/memory/` for `$ARGUMENTS`.

## Steps

1. Validate the query — if `$ARGUMENTS` is empty/whitespace, respond:

   > Usage: `/memory-search <keyword or topic>` — give me something to search for.

   ...and stop.

2. Grep recursively for the query (case-insensitive) across all `.md` files in the memory directory:

   - Path: `~/.claude/projects/*/memory/`
   - Pattern: `$ARGUMENTS` (treat as literal substring; if it looks like regex the user wrote it on purpose)
   - Flags: `-i` (case-insensitive), `-n` (line numbers), `-C 2` (two lines of context)
   - Glob: `**/*.md`

   Use the Grep tool with `output_mode: "content"`, `-i: true`, `-n: true`, `-C: 2`, `glob: "**/*.md"`, `path` set to the memory dir.

3. If there are zero hits, respond exactly:

   > no memory matches for "<query>"

   ...and stop.

4. Otherwise, group hits by file. For each file with hits, output:

   ```
   ### <relative-path-from-memory-root>
   <1-line description: project name / topic inferred from path or first heading>

   - L<line>: <matched line trimmed>
       <context lines indented>
   ```

   Cap at 10 files and 5 hits per file to keep output lean. If there are more, append `(N more hits in M more files — narrow the query)`.

5. End with a short suggestion: "To pull an entire memory file into context, ask me to read it."

Query: `$ARGUMENTS`
