# Issue Writing Guide

Guidelines for writing high-quality GitHub issues in English.

---

## General Principles

- Write in clear, concise English
- Use active voice ("The button does not respond" not "The button is not
  responded to")
- Be specific with technical details (file paths, function names, error
  messages)
- Include code blocks with proper language tags for any code snippets

## Bug Report Best Practices

### Title

- Start with `Bug: ` prefix
- Be specific: "Bug: Login form crashes on empty email" not "Bug: Login broken"

### Description

- Observed behavior: What actually happens (with exact error messages if any)
- Expected behavior: What should happen instead
- Include environment details if relevant (OS, browser, version)

### Steps to Reproduce

- Number each step
- Be specific enough that someone unfamiliar can reproduce
- Include test data or configuration if needed

### Technical Analysis

- Link to specific files and line numbers
- Reference relevant logs or stack traces
- Propose a root cause if known

## Feature Request Best Practices

### Title

- Start with `feat: ` prefix
- Describe the feature concisely: "feat: Add dark mode toggle to settings"

### Problem Statement

- Explain WHY this feature is needed
- Reference user feedback or business requirements if available

### Proposed Solution

- Describe the solution at a high level
- Include technical approach if known
- Mention alternatives considered

### User Stories

- Format: "As a [role], I want to [action] so that [benefit]"
- Cover the primary use case and 1-2 secondary cases

### Acceptance Criteria

- Use checkboxes for testable criteria
- Each criterion should be independently verifiable
- Include edge cases and error scenarios
