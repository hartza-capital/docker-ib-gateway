---
name: release
description:
  Orchestrate the full release process for any project using Makefile targets —
  changelog generation (via the changelog skill), version bump, git tagging,
  build, artifact upload, and GitHub Release creation. Use when the user says
  "release", "publish version", "cut a release", "ship it", "make a release", or
  wants to prepare and publish a new stable or beta version. Requires a Makefile
  at project root. Argument is the target version (e.g., "1.2.3" or
  "1.2.3-beta.1").
---

# Release

Orchestrate a complete release via Makefile targets: changelog, version bump,
git tag, build, publish, and GitHub Release creation.

**Important:** Changelog generation is delegated to the `changelog` skill. Do
NOT duplicate changelog logic — invoke `/changelog {version}` as part of step 3.

---

## ⚠️ CRITICAL: No Speculation Policy

**DO NOT INVENT MAKEFILE TARGETS OR RELEASE PROCEDURES.**

Follow this policy strictly:

1. **Base on actual Makefile**: Only use targets that exist in the project's Makefile
2. **If uncertain about target behavior**: Read the Makefile to understand what each target does
3. **If uncertain about versioning strategy**: Use WebSearch for semantic versioning best practices
4. **If still uncertain**: Ask the user which target to use rather than guessing
5. **NEVER**: Make up Makefile targets, invent build commands, or create fictional release procedures

---

## ⚠️ CRITICAL: No Uncommitted Work Policy

**DO NOT COMMIT WORK UNLESS EXPLICITLY REQUESTED BY THE USER.**

Follow this policy strictly:

1. **Release process includes commits**: The release process naturally involves version bump commits and tags
2. **User must request release**: Only perform the release (including commits) when the user explicitly invokes this skill
3. **Confirm before tagging**: Ask the user to confirm before creating and pushing git tags
4. **NEVER**: Start a release automatically without user invocation or push tags without confirmation

Note: Unlike other skills, release inherently involves git operations (version commits, tags). The user invoking `/release` is considered explicit approval for these git operations.

---

## Execution Budget

| Resource                 | Limit  | On exceeded                                                |
| ------------------------ | ------ | ---------------------------------------------------------- |
| Total workflow steps     | 8      | N/A — sequential by design                                 |
| Makefile command timeout | 30 min | Stop, report which step hung, ask user to proceed manually |
| GitHub API calls         | 10     | Stop, provide manual `gh` commands                         |
| git push retries         | 3      | Stop, report network issue, ask user to push manually      |

If a step exceeds its timeout: report the step name, what was completed before it, and provide the equivalent manual command so the user can continue independently.

---

## Pre-requisite

A `Makefile` must exist at the project root. Run `make help` or
`grep -E '^[a-zA-Z_-]+:' Makefile` to discover available targets before
proceeding. The skill adapts to whatever targets the project exposes.

## Process

Follow these steps in order. Stop and report on failure at any step.

### 1. Pre-flight Checks

- Verify `Makefile` exists at project root — abort if missing
- Discover available make targets: `grep -E '^[a-zA-Z_-]+:' Makefile`
- Confirm current branch is `main`, `master`, or `develop` (warn if on a feature
  branch)
- Verify working tree is clean: `git status --porcelain` must be empty
- If dirty, ask user to commit or stash before continuing

### 2. Version Resolution

- If a `VERSION` argument is provided, use it
- Otherwise, auto-detect current version from (in order):
  1. `package.json` → `version` field
  2. `Cargo.toml` → `version` under `[package]`
  3. `pyproject.toml` → `version` field
  4. `VERSION` file
  5. Latest git tag (strip `v` prefix)
- If no version found, ask the user
- Validate format: `X.Y.Z` or `X.Y.Z-beta.N` or `X.Y.Z-rc.N`
- Determine channel: **stable** (no suffix) or **beta** (`-beta.N`) or **rc**
  (`-rc.N`)
- Display: `Releasing version {version} on {channel} channel`

### 3. Changelog Generation (delegated)

- If `CHANGELOG/{version}.md` already exists, skip and inform the user
- Otherwise, **invoke the `changelog` skill**: `/changelog {version}`
- Wait for changelog completion before proceeding

### 4. Version Bump

Use the Makefile target that matches (first match wins):

| Target                  | Command                                        |
| ----------------------- | ---------------------------------------------- |
| `update-version-commit` | `make update-version-commit VERSION={version}` |
| `update-version`        | `make update-version VERSION={version}`        |
| `version`               | `make version VERSION={version}`               |
| `bump`                  | `make bump VERSION={version}`                  |

If no matching target found, ask the user which target to use.

### 5. Git Tagging

**Validation gate:** Before creating any tag, present and wait for confirmation:

```
⚠️  Validation gate — Step 5: Git tag
    About to: create annotated tag v{version} and push to origin
    Impact:   permanent tag on remote — triggers CI release workflow
    Confirm:  [yes, tag and push] [no, abort]
```

- Check if tag `v{version}` already exists: `git tag -l "v{version}"`
- If it exists, ask user: delete and recreate, or abort?
- Create annotated tag: `git tag -a v{version} -m "release: {version}"`
- Push tag to remote: `git push origin v{version}`

### 6. Build and Publish

**Validation gate:** Before running build/publish:

```
⚠️  Validation gate — Step 6: Build and publish
    About to: run make {target} VERSION={version}
    Impact:   builds artifacts and publishes to registry/CDN
    Confirm:  [yes, build and publish] [skip build, tag only] [abort]
```

Use the Makefile target that matches the channel (first match wins):

**Stable channel:**

| Target           | Command                                 |
| ---------------- | --------------------------------------- |
| `release-stable` | `make release-stable VERSION={version}` |
| `release`        | `make release VERSION={version}`        |
| `publish`        | `make publish VERSION={version}`        |
| `deploy`         | `make deploy VERSION={version}`         |

**Beta channel:**

| Target         | Command                               |
| -------------- | ------------------------------------- |
| `release-beta` | `make release-beta VERSION={version}` |
| `release`      | `make release VERSION={version}`      |
| `publish`      | `make publish VERSION={version}`      |

If no matching target found, skip build and inform user that only tagging was
performed.

### 7. GitHub Release Creation

**Validation gate:** Before creating the GitHub Release:

```
⚠️  Validation gate — Step 7: GitHub Release
    About to: create public GitHub Release v{version} ({channel})
    Notes:    {first 3 lines of changelog}
    Impact:   visible to all repo collaborators, triggers release notifications
    Confirm:  [yes, create release] [abort]
```

Create a GitHub Release using the changelog as release notes:

- Read `CHANGELOG/{version}.md` content
- Determine if pre-release: beta/rc channels are pre-releases
- Create the release using `gh` CLI:

```bash
gh release create v{version} \
  --title "v{version}" \
  --notes-file CHANGELOG/{version}.md \
  --target $(git rev-parse HEAD) \
  {--prerelease if beta/rc channel}
```

- If `gh` is not available or MCP GitHub tools are available, use MCP to create
  the release via the GitHub API:
  - `POST /repos/{owner}/{repo}/releases` with:
    - `tag_name`: `v{version}`
    - `name`: `v{version}`
    - `body`: content of `CHANGELOG/{version}.md`
    - `prerelease`: `true` if beta/rc, `false` if stable
    - `target_commitish`: current HEAD SHA

### 8. Verification and Summary

- Confirm tag exists: `git tag -l "v{version}"`
- Confirm tag is on remote: `git ls-remote --tags origin "v{version}"`
- Confirm GitHub Release exists: `gh release view v{version}` or MCP equivalent
- Display summary:

```
Release {version} ({channel}) completed:
  - Changelog:      CHANGELOG/{version}.md
  - Version:        {version} (bumped in config files)
  - Git tag:        v{version} (pushed to origin)
  - Build:          {status}
  - GitHub Release: https://github.com/{owner}/{repo}/releases/tag/v{version}
```

## Error Handling

- **No Makefile:** abort, this skill requires a Makefile
- **Dirty working tree:** ask user to commit/stash, do not proceed
- **Tag already exists:** ask user whether to delete and recreate or abort
- **Version update fails:** stop immediately, do not tag
- **Build fails:** warn that tag was pushed, suggest
  `git push --delete origin v{version}` to clean up
- **Changelog file exists:** skip changelog generation, use existing file
- **GitHub Release fails:** warn user, provide the `gh release create` command
  to run manually
