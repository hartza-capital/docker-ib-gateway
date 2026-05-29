---
name: memory-init
description: >
  Initialize project memory by capturing non-obvious conventions, architectural
  patterns, and operational constraints that would waste time to rediscover.
  Writes project-scoped memory files to .claude/agent-memory/<agent>/. Use when
  starting work on a new project, after cloning a repo, or when essential context
  is missing from memory. Triggers on: "initialise la mémoire", "analyse le projet
  et met en mémoire", "bootstrap project memory", "capture project context",
  "init project memory", "mémorise ce projet", "enregistre le contexte du projet".
disable-model-invocation: true
allowed-tools: Read Bash Glob Grep Write
model: sonnet
---

# Initialize Project Memory

Capture durable, non-obvious knowledge from this project into your agent-scoped
project memory at `.claude/agent-memory/<your-agent-name>/`.

## What is worth saving

| Save this                                               | Not this                                   |
| ------------------------------------------------------- | ------------------------------------------ |
| Naming conventions with non-trivial rules or exceptions | Module paths, versions, dependency lists   |
| Deployment order and cross-component dependencies       | File locations and directory structure     |
| Custom module/library catalog with when-to-use guidance | Information already in CLAUDE.md           |
| Known exceptions to general patterns                    | Facts trivially readable from config files |
| Operational constraints, SLAs, compliance requirements  | Git history or recent changes              |
| Architectural decisions not visible in the code         | Ephemeral task context                     |

## Process

### 1. Scan

Identify your agent's domain (e.g. Go, Python, React, Terraform). Read only the
files relevant to that domain — source files, config, and entry points for your
stack. Do not scan or read files belonging to other domains. Use parallel reads.

### 2. Identify non-obvious patterns

Within your domain only, look for:

- Naming conventions — especially rules with exceptions or non-obvious logic
- Deployment order or sequencing constraints between components
- Custom modules, abstractions, or libraries with specific usage rules
- Anything that would surprise a developer new to this project
- Constraints not visible in the code (account isolation, security boundaries)

### 3. Ask targeted questions

For context the code cannot reveal (max 4 questions):

```
Before writing memory, a few things the code doesn't tell me:

1. What is the business purpose of this project?
2. What is the production deployment context (account, region, environment)?
3. Any operational constraints or past incidents worth remembering?
4. Anything non-obvious a new developer would get wrong?

(Leave blank for anything uncertain.)
```

Wait for answers before writing.

### 4. Write memory files

One file per coherent topic. Use the standard format:

```markdown
---
name: <descriptive-slug>
description: <one-line summary — used to decide relevance in future sessions>
metadata:
  type: project
---

<synthesized knowledge — not raw facts, but interpreted patterns with context>

**Why:** <why this is non-obvious or matters operationally>
**How to apply:** <concrete guidance for working on this project>
```

Link related files with `[[slug]]`. Keep each file under 100 lines.

### 5. Update MEMORY.md

Append entries — never overwrite existing lines. Format:
`- [Title](filename.md) — one-line hook` (under ~150 chars).

If MEMORY.md doesn't exist, create it with a header and the new entries.

## Rules

- Only capture patterns within your agent's domain — do not save knowledge from other stacks
- Never save information immediately readable from the current code files
- Never invent facts — mark uncertain items `[TBD]` and ask the user
- One file per topic — do not pack everything into a single file
- The memory path is `.claude/agent-memory/<your-agent-name>/` — create it if needed
