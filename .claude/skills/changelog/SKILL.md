---
name: changelog
description:
  Generate clean, per-version changelog files from git history. Use when
  creating a changelog for a new release, generating release notes, preparing
  version documentation, or when the user says "changelog", "release notes", or
  "prepare release". Analyzes git commits since the last tag and categorizes
  them into Added/Changed/Fixed/Technical sections following Keep a Changelog
  format.
---

# Changelog Generator

Generate per-version changelog files by analyzing git commits and categorizing
them automatically.

---

## ⚠️ CRITICAL: No Speculation Policy

**DO NOT INVENT COMMIT MESSAGES OR CATEGORIZATIONS.**

Follow this policy strictly:

1. **Base on actual commits**: Only process commits that exist in the git history
2. **If uncertain about categorization**: Use WebSearch to find conventional commit standards (e.g., "Conventional Commits specification")
3. **If still uncertain**: Leave commits in their original form rather than miscategorizing them
4. **NEVER**: Make up commit messages, invent issue numbers, or create fictional changelog entries

A changelog with raw commits is better than one with invented content.

---

## ⚠️ CRITICAL: No Uncommitted Work Policy

**DO NOT COMMIT WORK UNLESS EXPLICITLY REQUESTED BY THE USER.**

Follow this policy strictly:

1. **Never auto-commit**: This skill should NEVER create git commits automatically
2. **User must request it**: Only commit when the user explicitly asks with phrases like "commit this", "create a commit"
3. **Prepare but don't commit**: Generate the changelog file but inform the user and ask if they want to commit
4. **NEVER**: Commit as part of the workflow, commit "to save progress", or commit without explicit user approval

---

## Process

When invoked, follow these steps in order:

### 1. Version Detection

- If a `VERSION` argument is provided, use it
- Otherwise, attempt auto-detection in order:
  1. `package.json` → `version` field
  2. `Cargo.toml` → `version` field under `[package]`
  3. `pyproject.toml` → `version` field
  4. `VERSION` file
  5. Latest git tag (strip `v` prefix)
- If no version found, ask the user
- Validate format: `X.Y.Z` or `X.Y.Z-beta.N` or `X.Y.Z-rc.N`

### 2. Setup Changelog Directory

- Check if `CHANGELOG/` directory exists at repo root
- If not, create it and initialize:
  - Copy `assets/unreleased.md` template to `CHANGELOG/unreleased.md`
  - Create `CHANGELOG.md` at repo root with this content:

```markdown
# Changelog

All notable changes are documented in version-specific files in the `CHANGELOG/`
directory.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

### 3. Analyze Git History

- Find the previous version tag:
  `git describe --tags --abbrev=0 HEAD^ 2>/dev/null`
- If no previous tag, use all commits: `git log --oneline --no-merges`
- Otherwise: `git log --oneline --no-merges {previous_tag}..HEAD`
- Categorize each commit into sections based on commit message prefix:

| Prefix pattern                                       | Section       |
| ---------------------------------------------------- | ------------- |
| `feat:`, `add:`, `feature:`                          | **Added**     |
| `change:`, `update:`, `refactor:`, `enhance:`        | **Changed**   |
| `fix:`, `bugfix:`, `hotfix:`                         | **Fixed**     |
| `chore:`, `ci:`, `docs:`, `test:`, `build:`, `perf:` | **Technical** |

- Commits without a recognized prefix: classify by analyzing the message content
- Rewrite each commit message as a clean, user-facing bullet point:
  - Remove prefix (e.g., `feat:`, `fix:`)
  - Capitalize first letter
  - Remove trailing period
  - Include issue/PR references if present (e.g., `#123`)
  - Group related commits into a single bullet when they address the same
    feature/fix

### 4. Generate Changelog File

- Create `CHANGELOG/{version}.md` using this exact format:

```markdown
# {version}

_{date in "Month Day, Year" format}_

## Added

- Clean bullet point for each new feature (#issue)

## Changed

- Clean bullet point for each change

## Fixed

- Clean bullet point for each fix

## Technical

- Clean bullet point for each technical improvement

---

_Brief 1-2 sentence summary of the release focus._
```

- Omit any section that has no entries (do not include empty sections)
- Display the generated changelog to the user for review

### 5. User Review

- Show the generated content
- Ask the user if they want to:
  1. Use as-is
  2. Edit specific entries
  3. Regenerate with different scope

### 6. Finalize

- Write the final `CHANGELOG/{version}.md` file
- If `CHANGELOG.md` exists at root, no modification needed (it points to the
  directory)
- Confirm creation with path and entry count

## Example Output

For version `0.7.2` with commits like:

```
fix: updater now uses native Tauri plugin (#269)
fix: macOS auto-updates use tar.gz format
docs: update CLAUDE.md with updater events
chore: work-on-issue skill enforces branch creation
```

Generated `CHANGELOG/0.7.2.md`:

```markdown
# 0.7.2

_February 6, 2026_

## Fixed

- Updater now uses native Tauri plugin for automatic installation and restart
  (#269)
- macOS auto-updates now use tar.gz format instead of DMG for native
  installation

## Technical

- Updated CLAUDE.md with updater events and tar.gz format documentation
- work-on-issue skill now enforces mandatory branch creation

---

_Patch release focused on updater improvements for macOS._
```

## Error Handling

- If `CHANGELOG/{version}.md` already exists, ask the user before overwriting
- If no commits found since last tag, warn and offer to create from template
- If git is not available or not a git repo, fall back to template-only mode
