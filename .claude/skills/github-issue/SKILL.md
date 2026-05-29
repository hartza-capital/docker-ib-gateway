---
name: github-issue
description: >
  Create GitHub issues using repository issue templates. Use when user asks to
  "create an issue", "open a ticket", "report a bug", "request a feature",
  "creer une issue", "ouvrir un ticket", or "signaler un bug". Reads templates
  from .github/ISSUE_TEMPLATE/, collects information, and creates issues via
  GitHub MCP with proper labels and assignees.
---

# GitHub Issue Creator

You are a GitHub issue creation assistant. Guide the user through creating a
well-structured GitHub issue using the repository's existing templates. All
issue content MUST be written in English regardless of the user's language.

---

## ⚠️ CRITICAL: No Speculation Policy

**DO NOT INVENT ISSUE TEMPLATES OR REPOSITORY INFORMATION.**

Follow this policy strictly:

1. **Base on actual templates**: Only use templates that exist in `.github/ISSUE_TEMPLATE/`
2. **If uncertain about template structure**: Read the actual template file, do NOT guess fields
3. **If uncertain about labels**: Use the MCP GitHub tools to fetch actual repository labels
4. **If still uncertain**: Ask the user for clarification rather than inventing information
5. **NEVER**: Make up template fields, invent labels that don't exist, or create fictional assignees

Use actual repository data only.

---

## ⚠️ CRITICAL: No Uncommitted Work Policy

**DO NOT COMMIT WORK UNLESS EXPLICITLY REQUESTED BY THE USER.**

Follow this policy strictly:

1. **Never auto-commit**: This skill should NEVER create git commits automatically
2. **User must request it**: Only commit when the user explicitly asks
3. **This skill creates GitHub issues only**: No local commits are needed for issue creation
4. **NEVER**: Commit as part of the workflow or commit without explicit user approval

---

## Step 1: Discover Templates

**Goal:** Find and present available issue templates from the current
repository.

1. Use `Glob` to find all templates in `.github/ISSUE_TEMPLATE/` directory
2. Use `Read` to read each template file and extract:
   - Template name (from YAML frontmatter `name` field)
   - Template description (from YAML frontmatter `about` field)
   - Default labels (from YAML frontmatter `labels` field)
   - Title prefix (from YAML frontmatter `title` field)
3. Present the available templates to the user in a clear list

**Validation gate:** At least one template file was found and read successfully.
Do NOT proceed until this validation passes.

---

## Step 2: Select Template and Gather Context

**Goal:** Let the user choose a template and collect the information needed to
fill it.

1. If the user's request clearly indicates a type (e.g., "bug" or "feature"),
   auto-select the matching template. Otherwise, ask the user to choose.
2. Read the selected template carefully to identify all sections that need to be
   filled.
3. Ask the user for the required information based on the template sections:

**For Bug Report:**

- Description (observed vs expected behavior)
- Steps to reproduce
- Technical analysis (files involved, probable cause, suggested solution)
- Additional context (logs, screenshots references)

**For Feature Request:**

- Feature description
- Problem statement
- Proposed solution
- Affected areas (files to modify, new files to create)
- User stories
- Acceptance criteria
- Technical considerations

4. The user may provide all information at once or incrementally. Adapt
   accordingly.

**Validation gate:** All required sections of the template have sufficient
information. Do NOT proceed until this validation passes.

---

## Step 3: Fetch Labels and Assignees

**Goal:** Retrieve available labels from the repository and confirm assignee.

1. Use `mcp__github__list_labels` (or equivalent MCP tool) to fetch all
   available labels from the repository
2. Present the labels to the user alongside the default label from the template
3. Ask the user if they want to add additional labels beyond the template
   default
4. Ask the user who should be assigned to this issue (or leave unassigned)
5. Use `mcp__github__list_assignees` (or equivalent MCP tool) to validate the
   assignee exists

**Validation gate:** Labels and assignee (if any) are confirmed by the user. Do
NOT proceed until this validation passes.

---

## Step 4: Generate and Create the Issue

**Goal:** Build the issue body from the template and create it on GitHub.

1. Generate the complete issue body in **English** following the template
   structure exactly
2. Apply the title prefix from the template (e.g., `Bug: ` or `feat: `)
3. Present the complete issue (title + body) to the user for review
4. Once approved, create the issue using `mcp__github__create_issue` with:
   - `title`: The prefixed title
   - `body`: The formatted markdown body
   - `labels`: The selected labels (as array)
   - `assignees`: The selected assignees (as array, if any)
5. Return the issue URL to the user

---

## Error Handling

- **No templates found:** Check if `.github/ISSUE_TEMPLATE/` directory exists.
  If not, inform the user and offer to create an issue with a basic format.
- **MCP GitHub unavailable:** Fall back to `gh issue create` via Bash tool.
  Construct the equivalent command with all parameters.
- **Invalid assignee:** Inform the user the assignee username is not valid for
  this repository. List available assignees if possible.
- **Label not found:** Offer to create the label via MCP or proceed without it.

If a step fails:

1. Report the error clearly to the user
2. Suggest corrective action
3. Allow the user to retry the step or abort the workflow

---

## Important Rules

- **Language:** ALL issue content (title, body, labels) MUST be written in
  English, even if the user communicates in another language. Translate the
  user's input to English when generating the issue.
- **Template fidelity:** Follow the template structure exactly. Do not skip
  sections or add sections that are not in the template.
- **Review before creation:** ALWAYS show the complete issue to the user for
  approval before creating it on GitHub.
- **MCP first:** Always prefer MCP GitHub tools over CLI commands. Only fall
  back to `gh` CLI if MCP is unavailable.

---

## Summary

When the issue is created, provide:

- The issue number and URL
- The labels applied
- The assignee (if any)
- A brief confirmation of what was created
