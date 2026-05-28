---
description: "Onboard to current project: explore structure, identify stack, find key files, summarize"
argument-hint:
allowed-tools: Read, Glob, Grep, Bash, PowerShell, Agent
---

You have just been invoked in an unfamiliar project. Get oriented fast and brief the user.

## Steps

1. **Dispatch an `explore` subagent** (single call) to investigate the project. The subagent's task:

   - List root-level files and top-level directories.
   - Detect tech stack by presence of marker files:
     - `package.json` -> Node/JS/TS (record `name`, `scripts`, top deps)
     - `pyproject.toml` / `requirements.txt` / `setup.py` -> Python (record name, deps, build backend)
     - `Cargo.toml` -> Rust
     - `go.mod` -> Go
     - `pom.xml` / `build.gradle*` -> Java/Kotlin
     - `Gemfile` -> Ruby
     - `composer.json` -> PHP
     - `*.csproj` / `*.sln` -> .NET
     - `Dockerfile`, `docker-compose.yml` -> containerized
     - `.github/workflows/*` -> CI hints
   - Find entry points: `src/main.*`, `cmd/*/main.go`, `bin/*`, `index.*`, `app.*`, `main.*`.
   - Note presence of `README*`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING*`, `.cursorrules`, `LICENSE`.
   - Sample directory structure to depth 2.
   - Return: stack summary, entry points, top-level layout, list of doc files worth reading.

   Make this a single Agent call — do **not** explore by hand from the main thread.

2. **Wait** for the subagent's findings.

3. **Read** any doc files the subagent flagged, in this priority order — and stop once you have a clear picture:
   - `CLAUDE.md` (project-specific instructions — highest priority)
   - `AGENTS.md`
   - `README.md`
   - `CONTRIBUTING.md`
   - the first 50 lines of any obvious entry point

4. **Summarize** in ≤ 300 words, using this exact structure:

   ```
   ## Stack
   <language(s), framework(s), build tool, package manager>

   ## How to run
   <best-guess commands: build, test, dev, lint — copy from package.json scripts / Makefile / README>

   ## Key files
   - <path>: <why it matters, 1 line>
   - ...

   ## Open questions
   <2-4 things you couldn't determine from a quick read>
   ```

5. **Suggest next moves** in one or two lines, e.g.:
   - "Run `/plan` if you want to start a feature."
   - "Ask me 'how does X work' to drill into a subsystem."
   - Or a specific question worth asking based on open questions (e.g., "Which env vars does the dev server need?").

Constraints:
- Do not modify any files during onboarding.
- Do not run build / test commands without asking — the user just opened this; don't kick off long-running jobs.
- Keep the final summary tight. Use bullets, not paragraphs.
