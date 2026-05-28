---
name: using-mcp-memory
description: Use when working with a knowledge graph: entities, relations, observations. Distinct from auto-memory.
---

# Using MCP Memory (Knowledge Graph)

## What this is

The `memory` MCP exposes a **knowledge graph**: nodes (entities), edges (relations), and attached facts (observations). It's a structured store for *relationships between things*, not just flat key-value notes.

## Critical: this is NOT auto-memory

| | auto-memory | memory MCP |
|---|---|---|
| Storage | Markdown files on disk | In-memory graph (per-process) |
| Persistence | Survives sessions | Session-scoped by default — may not persist |
| Shape | Free-form prose | Typed entities + relations + observations |
| When | "remember this preference" / project facts | Structured relationships within current task |
| Owned by | The harness automatically | You explicitly call MCP tools |

**Use auto-memory for**: user preferences, project conventions, "next time we do X, remember Y" — anything you want to remember **across sessions**.

**Use MCP memory for**: building a structured model of something **within the current task** — a codebase's module graph, character relationships in a document, stakeholder maps, dependency trees. Treat persistence as best-effort.

## When to use MCP memory

- Analyzing a codebase: model modules as entities, `imports`/`calls` as relations, "exports `parseUser`" as observations
- Analyzing a document or story: characters as entities, `knows`/`distrusts`/`married-to` as relations
- Project stakeholder mapping: people/teams/systems as entities, `owns`/`depends-on`/`escalates-to` as relations
- Any task where you need to query "which X relates to Y how" repeatedly during the session

## When NOT to use

- "Remember the user prefers dark mode" → that's an auto-memory user fact, not a graph entity
- A single fact ("the API key is in `.env.local`") → just say it; don't make a graph
- Cross-session persistence requirements → auto-memory or files on disk
- Temporary tracking inside one tool call's reasoning → use sequential-thinking or a TodoList

## Tools

| Tool | Purpose |
|---|---|
| `mcp__memory__search_nodes` | Search by query string (entity names, types, observations) |
| `mcp__memory__open_nodes` | Fetch specific entities by name |
| `mcp__memory__read_graph` | Dump the whole graph |
| `mcp__memory__create_entities` | Create nodes with type + observations |
| `mcp__memory__create_relations` | Connect entities with directed, active-voice relations |
| `mcp__memory__add_observations` | Append observations to existing entities |
| `mcp__memory__delete_entities` | Remove entities and their relations |
| `mcp__memory__delete_observations` | Remove specific observations |
| `mcp__memory__delete_relations` | Remove specific edges |

## Data model

- **Entity** = `{name, entityType, observations[]}`. `name` is the key — must be unique. Pick stable, descriptive names.
- **Relation** = `{from, to, relationType}`. Active voice: `imports`, `calls`, `owns`, `knows`. Not `is imported by`.
- **Observation** = a string of factual content attached to an entity. Many per entity.

## Standard workflow

```
1. search_nodes(query="ModuleA")                   → check if it exists already
2. if not, create_entities([{name, entityType, observations}])
3. add_observations(...)                           → enrich as you learn more
4. create_relations([{from, to, relationType}])    → wire up structure
5. search_nodes / open_nodes                       → query when reasoning
```

**Always search first.** Creating a duplicate-named entity with slightly different casing fragments the graph.

## Examples

### Modeling a codebase analysis

```
create_entities([
  {name: "src/auth/login.ts", entityType: "Module",
   observations: ["Exports loginUser function", "Uses bcrypt for hashing"]},
  {name: "src/db/users.ts", entityType: "Module",
   observations: ["Exports findUserByEmail", "Uses Prisma client"]}
])

create_relations([
  {from: "src/auth/login.ts", to: "src/db/users.ts", relationType: "imports"}
])
```

Later: `search_nodes(query="login")` to recall what login.ts does.

### Modeling a story's character graph

```
create_entities([
  {name: "Alice", entityType: "Character",
   observations: ["Lead investigator", "Distrusts authority"]},
  {name: "Bob", entityType: "Character",
   observations: ["Alice's brother", "Works at TechCorp"]}
])

create_relations([
  {from: "Alice", to: "Bob", relationType: "is sibling of"},
  {from: "Bob", to: "TechCorp", relationType: "works at"}
])
```

## Active-voice relations

Good:
- `imports`, `calls`, `extends`, `implements`
- `owns`, `manages`, `escalates to`
- `knows`, `distrusts`, `is sibling of`

Bad (passive — flip the direction instead):
- `is imported by`
- `is owned by`
- `is known to`

Passive relations make queries asymmetric and confusing. Flip the `from`/`to`.

## Anti-patterns

- **Using it for user preferences**: "User likes dark mode" → that's `auto-memory`, not a graph entity. The shape is wrong and it won't persist across sessions reliably.
- **One-off facts**: don't build a 2-entity graph for a fact you'll use once — just state it.
- **Duplicating entities**: `User`, `user`, `Users` are three nodes. Search before create. Pick a casing convention up front.
- **Vague observations**: `"important"` is not an observation. `"Handles token refresh on 401 responses"` is.
- **Passive relations**: see above.

## Red flags

- You're about to `create_entities` without `search_nodes` first → stop, search
- You're creating a graph for something the user said once ("remember I'm in PST") → that's auto-memory
- Your observations are single words → write actual facts
- Your graph has 1 entity → you don't need a graph

## Combining with other tools

- **With `deepwiki`**: query DeepWiki for repo structure, populate the MCP memory graph with what you learned, then reason
- **With `sequential-thinking`**: build the graph first, then reason about it in structured thoughts
- **With auto-memory**: cross-session facts → auto-memory; in-session structure → MCP memory

## One-liner reminder

Auto-memory = file on disk for next session. MCP memory = graph in RAM for this session's structure.
