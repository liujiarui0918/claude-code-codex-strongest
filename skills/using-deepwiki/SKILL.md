---
name: using-deepwiki
description: Use when needing to understand a GitHub repo: structure, design rationale, file purpose.
---

# Using DeepWiki

## What this is

DeepWiki is an MCP server that exposes AI-generated, context-grounded documentation for **public GitHub repositories**. It's how you understand a codebase you don't own — structure, design decisions, file purpose, internal APIs — without cloning it and reading thousands of files.

## When to use

- User points at a public repo and asks "how does this work?" (e.g., "look at fastapi's internals", "how does obra/superpowers implement SessionStart hooks")
- You need to understand a library/framework's architecture before integrating it
- You're investigating why a project made a specific design choice
- You're doing a deep dive on a repo for evaluation, comparison, or porting
- The user references a project by name and you don't know its internals

## When NOT to use

- Private repos behind authentication — DeepWiki can't access them (use GitHub MCP if it exists, or ask user to share code)
- You need to **write code** in or against the repo (use `gh`/git to clone and Read instead)
- You need a **diff**, file contents at a specific commit, or line-level detail (use git/GitHub directly)
- You need issue/PR data, releases, or contributor info (use the GitHub MCP/CLI)
- The user is asking about *using* a published library (use `context7` — it has docs, deepwiki has source-grounded explanation)

## Tools

| Tool | Purpose | When |
|---|---|---|
| `mcp__deepwiki__ask_question` | Direct Q&A grounded in the repo | **First choice** — try this first |
| `mcp__deepwiki__read_wiki_structure` | List of topics covered | When `ask_question` was vague or you want to browse |
| `mcp__deepwiki__read_wiki_contents` | Full wiki dump for the repo | When you need broad coverage and `ask_question` keeps missing context |

## Recommended workflow

1. **Start with `ask_question`**:
   ```
   mcp__deepwiki__ask_question
     repoName: "tiangolo/fastapi"
     question: "How does FastAPI's dependency injection system resolve dependencies at request time?"
   ```
   Most questions terminate here. Be specific in `question` — same rules as Context7 queries.

2. **If the answer is too shallow or off-topic**, list topics:
   ```
   mcp__deepwiki__read_wiki_structure
     repoName: "tiangolo/fastapi"
   ```
   Returns the topics DeepWiki has indexed. Use this to discover what's actually covered.

3. **If you need a topic's full text**, pull it:
   ```
   mcp__deepwiki__read_wiki_contents
     repoName: "tiangolo/fastapi"
   ```
   Returns the full wiki. Heavier on context — only use when `ask_question` repeatedly can't synthesize what you need.

## Multi-repo questions

`ask_question` accepts a **list of repos** (up to 10). Useful for comparisons:

```
mcp__deepwiki__ask_question
  repoName: ["fastapi/fastapi", "django/django", "pallets/flask"]
  question: "How do these three frameworks handle middleware ordering?"
```

Use sparingly — broader queries pull more context.

## Repo name format

Always `owner/repo`, exact spelling and casing as on GitHub:
- `facebook/react` (not `React` or `facebook/React`)
- `vercel/next.js` (the `.js` is part of the repo name)
- `obra/superpowers`

## Question writing — good vs bad

**Good**:
- "How does Next.js's app router resolve dynamic routes at build time?"
- "What's the role of `dispatch_handler` in this repo and where is it called?"
- "Why does FastAPI use Starlette instead of building from raw ASGI?"

**Bad**:
- "explain fastapi"
- "how does this work"
- "what is the main file"

## Red flags — use DeepWiki instead

- You're about to `WebFetch` a `github.com/<owner>/<repo>` page to understand the project (the rendered page is truncated, slow, low-quality for code understanding)
- You're about to grep through `node_modules` to figure out how a library works internally
- You're guessing at a library's internal design from its public docs
- The user asks "how does X repo implement Y" and you start guessing

## Combining with other tools

- **With `context7`**: Context7 tells you how to *use* React; DeepWiki tells you how React is *built*
- **With Read/git**: if DeepWiki gives you a file path, `git clone` + `Read` for line-level work
- **With `sequential-thinking`**: when comparing architectures across multiple repos, query each then reason

## Anti-patterns

- Don't `read_wiki_contents` first — it dumps the whole wiki and bloats context. Always try `ask_question` first.
- Don't ask DeepWiki about a private/internal repo. It will fail or return nothing useful.
- Don't ask DeepWiki to *write code* for the repo. It explains; it doesn't author PRs.

## One-liner reminder

If the user said a `owner/repo` and asked "how does it work", you're using DeepWiki, not `WebFetch`.
