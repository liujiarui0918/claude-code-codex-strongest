---
description: Security audit on a path: OWASP, secrets, injections, auth
argument-hint: "[path, default: current project]"
allowed-tools: Read, Glob, Grep, Bash, PowerShell, Agent
---

Security scan target: "$ARGUMENTS" (if empty, scan the current project root).

Delegate to the `security-reviewer` subagent. Coverage must include:

- OWASP Top 10 (injection, broken auth, sensitive data exposure, XXE, broken access control, security misconfig, XSS, insecure deserialization, vulnerable components, insufficient logging).
- Secret leaks — API keys, tokens, passwords, private keys, .env files committed, hardcoded credentials.
- Injection vectors — SQL, NoSQL, command, LDAP, template, header injection. Trace all user input to sinks.
- Auth / authz — missing checks, IDOR, privilege escalation paths, session handling, JWT pitfalls.
- Unsafe deserialization — pickle, yaml.load, Java/.NET binary, eval-on-input patterns.
- Dependency CVEs if a lockfile is present.

Report format for each finding:
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- CWE: <id + name>
- Location: file:line
- Description: what's exploitable and how
- Suggested fix: concrete code change or mitigation
