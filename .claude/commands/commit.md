---
name: commit
description: >
  Create a normalized git commit following Conventional Commits specification.
  Use whenever the user says "commit", "fait un commit", "fais un commit",
  "commit ça", "commit les changements", "commite", "crée un commit",
  "create a commit", "stage and commit", "push a commit", or any variation
  asking to record current changes in git history. Handles staging, commit
  message generation, and conventional format enforcement automatically.
allowed-tools: Bash(git *)
model: haiku
---

# Commit

Create a well-formed git commit from the current working tree changes, following
the Conventional Commits specification.

---

## Process

### 1. Inspect the working tree

Run `git status --short` and `git diff --stat HEAD` to understand what changed.
Collect:

- All modified/added/deleted files
- Whether changes are already staged or unstaged

### 2. Group changes by topic

Before staging anything, read the diff of every changed file and assign each
file to a **topic group**. A topic group is a coherent unit of intent — changes
that belong together because they serve the same purpose.

Signals that files belong together:

- Same directory or package
- Same Conventional Commit type (all `chore`, all `feat`, etc.)
- One file is a direct consequence of another (e.g., a new function + its test)
- The user mentioned them together ("le fix du login")

Signals that files belong in separate commits:

- Different types mixed together (a new feature alongside a refactor)
- Changes to unrelated subsystems (e.g., `agents/` edits alongside `skills/` edits alongside CI config)
- One group is optional or speculative relative to the other

**Single group (≤ ~5 files or all same type):** proceed as one commit.

**Multiple groups (large or mixed changeset):** split into one commit per group.
Present the proposed split to the user before doing anything:

```
I found 3 topic groups in your changes:

  Commit 1 — refactor(agents): ...
    M  agents/go-expert.md
    M  agents/python-expert.md
    M  agents/rust-expert.md

  Commit 2 — chore(skills): ...
    M  skills/release/SKILL.md
    M  skills/qa-orchestrator/SKILL.md

  Commit 3 — chore(ci): ...
    M  .github/workflows/sync.yml

Proceed in this order? (adjust before I start)
```

Wait for confirmation unless the user said "maintenant" or equivalent — then
proceed immediately with the inferred split.

### 3. Commit type reference

| Type       | When to use                                             |
| ---------- | ------------------------------------------------------- |
| `feat`     | New feature or capability visible to users              |
| `fix`      | Bug fix                                                 |
| `refactor` | Code restructure with no behavior change                |
| `chore`    | Maintenance, config, deps, tooling — no production code |
| `docs`     | Documentation only                                      |
| `test`     | Tests added or corrected                                |
| `perf`     | Performance improvement                                 |
| `ci`       | CI/CD pipeline changes                                  |
| `build`    | Build system or dependency changes                      |
| `style`    | Formatting, whitespace — no logic change                |

If the user already provided a message, extract the intent and reformat it into
conventional structure — don't discard what they wrote.

### 4. Commit message format

```
<type>(<scope>): <short description>

[optional body — only when the why is non-obvious]
```

Subject line rules:

- Lowercase, no trailing period
- Imperative mood: "add", "fix", "remove" — not "added", "fixes", "removed"
- Max 72 characters
- Use `<scope>` when it adds clarity (module, package, or feature area)

Body rules (add only when necessary):

- Explain **why**, not what — the diff already shows what
- Wrap at 72 characters
- Separate from subject with a blank line

### 5. Execute each commit in sequence

For each topic group (one if single, several if split):

1. Stage the group's files: `git add <files>`
2. Stage `.claude/` files normally — CLAUDE.md, memory files, settings, and
   other Claude configuration are legitimate project artifacts. Use
   `chore(.claude)` as type/scope when the group is confined to `.claude/`.
3. Never stage `.env`, `*.secret`, `*credentials*`, `*token*` files — warn and exclude
4. Run the commit:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short description>

[body if needed]
EOF
)"
```

### 6. Confirm

After all commits, run `git log --oneline -<N>` (where N = number of commits
created) and display the result so the user can see the full sequence.

---

## What this command does NOT do

- **No push** unless the user explicitly asks to push
- **No branch creation** — that's for `github-issue-worker`
- **No PR** — use `release` or `github-issue-worker` for that
- **No force-push or amend** of already-pushed commits

---

## Examples

**User:** "commit"
→ Read the diff, group files by topic. If one coherent group → single commit.
If mixed (e.g., new feature + doc updates + CI tweak) → present the proposed
split, wait for confirmation, then commit in sequence.

**User:** "fais un commit pour le fix du login"
→ Stage only login-related files, write `fix(auth): fix login flow`, confirm, commit.

**User:** "commit les fichiers agents/ avec le message refactor agents"
→ Stage `agents/` only, write `refactor(agents): <description from diff>`, confirm, commit.

**User:** "commit ça maintenant"
→ No confirmation for either the split plan or individual commits — infer
grouping and execute immediately in sequence.

**User:** "commit tout" with 12 files across 4 subsystems
→ Propose 4 commits grouped by subsystem, wait for confirmation, commit each.
