---
name: github-issue-worker
description: >
  Work on an existing GitHub issue by its number. Use when user asks to "work on
  issue #123", "implement issue 45", "fix issue #67", "start working on #12",
  "travailler sur l'issue #8", "implementer le ticket #5", or "prendre en charge
  l'issue". Reads the issue, analyzes context, creates a feature branch,
  dispatches to the appropriate specialized agent, and prepares a pull request.
  Complements the github-issue skill (which creates issues).
---

# GitHub Issue Worker

Work on an existing GitHub issue end-to-end: read it, analyze it, branch,
implement via the right specialized agent, and prepare the PR. All code,
commits, and PR content MUST be in English.

---

## ⚠️ CRITICAL: No Speculation Policy

**DO NOT INVENT SOLUTIONS OR IMPLEMENTATION DETAILS.**

Follow this policy strictly:

1. **Base on actual issue content**: Only implement what is explicitly described in the issue
2. **If uncertain about approach**: Use WebSearch to find established patterns or best practices
3. **If still uncertain**: Ask the user for clarification before delegating to the specialized agent
4. **NEVER**: Make up requirements, invent features not in the issue, or guess at implementation details

This policy must be passed to all specialized agents via their prompts.

---

## ⚠️ CRITICAL: No Uncommitted Work Policy

**DO NOT COMMIT WORK UNLESS EXPLICITLY REQUESTED BY THE USER.**

Follow this policy strictly:

1. **Never auto-commit**: This skill should NEVER create git commits automatically during implementation
2. **User must request it**: Only commit when the user explicitly asks
3. **Prepare but don't commit**: The specialized agent will implement changes, but commits should only be created on user request
4. **NEVER**: Commit as part of the workflow, commit "to save progress", or commit without explicit user approval

This policy must be passed to all specialized agents via their prompts.

---

## Step 1: Fetch and Analyze the Issue

**Goal:** Retrieve the issue and extract actionable requirements.

1. Extract the issue number from the user's request
2. Use `mcp__github__get_issue` to fetch the full issue (title, body, labels,
   assignees, milestone)
3. If MCP is unavailable, fall back to
   `gh issue view <number> --json title,body,labels,assignees,milestone`
4. Parse the issue body to extract:
   - **Objective**: What needs to be done
   - **Acceptance criteria**: Checkboxes or criteria listed
   - **Technical hints**: File paths, function names, error messages mentioned
   - **Labels**: Technology/domain indicators

5. Present a summary to the user:

```
Issue #<number>: <title>
Labels: <labels>
Assignee: <assignee>

Objective: <one-sentence summary>

Acceptance Criteria:
- [ ] <criterion 1>
- [ ] <criterion 2>

Technical context:
- Files mentioned: <list>
- Technologies: <list>
```

**Validation gate:** Issue was fetched successfully and objective is clear. Ask
the user to confirm the understanding before proceeding.

---

## Step 2: Identify Target Repository and Context

**Goal:** Determine which repo to work in and gather codebase context.

1. Check if the current working directory is the target repository. If the issue
   references a different repo, ask the user to confirm.
2. Use `Glob` and `Grep` to locate files and code areas mentioned in the issue
3. Read relevant files to understand the current state
4. Identify the base branch (usually `main` or `develop`) via
   `git branch -r --list 'origin/main' 'origin/develop'`

**Validation gate:** Target repo and affected files are identified.

---

## Step 3: Select Specialized Agent

**Goal:** Dispatch the work to the right Hartza Capital agent.

1. Read `references/agent-mapping.md` for the mapping rules
2. Analyze the issue's labels, technologies, and affected files to determine the
   best agent match
3. Present the recommendation to the user:

```
Recommended agent: <agent-name>
Reason: <brief justification based on issue domain>
```

4. If the issue spans multiple domains, propose a multi-agent plan with
   execution order
5. Wait for user confirmation before dispatching

**Validation gate:** User confirms the agent selection.

---

## Step 4: Create Feature Branch

**Goal:** Set up the working branch following Hartza conventions.

1. Ensure the working tree is clean (`git status`). If not, warn the user.
2. Fetch latest from remote: `git fetch origin`
3. Create and checkout the feature branch from the base branch:

```
git checkout -b feature/<issue-number>-<short-description> origin/<base-branch>
```

- `<issue-number>`: The GitHub issue number
- `<short-description>`: 2-4 words from the issue title, kebab-case

Example: `feature/42-add-dark-mode`

**Validation gate:** Branch created and checked out successfully.

---

## Step 5: Implement via Specialized Agent

**Goal:** Hand off implementation to the selected agent with full context.

**Call `advisor()` before dispatching** — With the issue content, affected files from Step 2, and selected agent from Step 3 in your context, call `advisor()` to validate the implementation approach and surface architectural considerations before the agent writes code.

Launch the agent via the Task tool (`subagent_type: 'general-purpose'`,
`model: 'sonnet'`). For `qa-test-engineer` validation, also use
`model: 'sonnet'`.

Provide the agent with:

1. **Advisor tool:** You have access to an `advisor` tool backed by a stronger reviewer model. Call `advisor()` before writing or modifying files (after initial exploration), and when you believe the implementation is complete. Give the advice serious weight.
2. The complete issue content (title, body, acceptance criteria)
3. The list of affected files identified in Step 2
4. The branch name and base branch
5. Clear instruction to write tests for all changes
6. Instruction to follow Hartza Capital coding conventions

The agent workflow:

1. Implement the changes described in the issue
2. Write/update tests covering the changes
3. Run tests to verify they pass
4. Stage and commit changes with descriptive commit messages referencing the
   issue:
   ```
   feat: <description> (#<issue-number>)
   ```
   or
   ```
   fix: <description> (#<issue-number>)
   ```

If multi-agent collaboration is needed, execute agents sequentially:

1. First agent implements their portion
2. Second agent builds on top
3. `qa-test-engineer` validates the final result

**Validation gate:** All changes are committed, tests pass.

---

## Step 6: Prepare Pull Request

**Goal:** Create a well-structured PR linking back to the issue.

1. Push the feature branch: `git push -u origin <branch-name>`
2. Create the PR using `mcp__github__create_pull_request` or `gh pr create`
   with:

**Title:** Same prefix convention as commits (`feat:` or `fix:`) + concise
description

**Body template:**

```markdown
## Summary

Closes #<issue-number>

<2-3 sentences describing what was implemented and why>

## Changes

- <bullet list of key changes>

## Test Plan

- [ ] <test scenarios covering acceptance criteria>

## Agent

Implemented by: `<agent-name>`
```

3. Add the same labels from the issue to the PR
4. Request review from the issue's assignee (if different from current user)
5. Present the PR URL to the user

**Validation gate:** PR is created and linked to the issue.

---

## Error Handling

- **Issue not found:** Verify the issue number and repository. List recent open
  issues if helpful.
- **MCP GitHub unavailable:** Fall back to `gh` CLI for all GitHub operations.
- **Dirty working tree:** Ask the user whether to stash changes or abort.
- **Agent not identifiable:** Ask the user to specify the domain or agent
  manually.
- **Tests fail:** Report failures to the user. Do not create the PR until tests
  pass.
- **Push rejected:** Pull latest changes, rebase, and retry. Ask user before
  force operations.

If any step fails:

1. Report the error clearly
2. Suggest corrective action
3. Allow retry or abort

---

## Important Rules

- **Language:** All code, commits, branch names, and PR content MUST be in
  English.
- **Never merge:** Create the PR but NEVER merge it. Leave merging to the
  reviewer.
- **Never force push** without explicit user approval.
- **Issue linking:** Always reference the issue number in commits and PR body
  using `#<number>`.
- **MCP first:** Prefer MCP GitHub tools over CLI. Fall back to `gh` CLI only if
  MCP is unavailable.
- **User confirmation:** Ask for confirmation at each validation gate before
  proceeding.
