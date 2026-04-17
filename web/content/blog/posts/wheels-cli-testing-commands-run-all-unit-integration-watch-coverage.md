---
title: 'Wheels CLI Testing Commands: run, all, unit, integration, watch & coverage'
slug: wheels-cli-testing-commands-run-all-unit-integration-watch-coverage
publishedAt: '2026-03-09T18:34:28.516Z'
updatedAt: '2026-03-09T18:43:04.889Z'
author: Zain Ul Abideen
tags:
  - wheels-3-0
  - wheels-cli
  - cli-commands
categories:
  - CLI
excerpt: >-
  Introduction In previous articles, we explored how the Wheels CLI helps you
  manage environments, configuration, and databases safely in Wheels 3.x. Now
  we’re stepping into one of the most critical ...
coverImage: null
legacyId: '1156663438686814212'
---
# Introduction
In previous articles, we explored how the Wheels CLI helps you manage environments, configuration, and databases safely in Wheels 3.x.

Now we’re stepping into one of the most critical parts of modern development:
# Testing automation.
Writing tests is important. Running them consistently, efficiently, and intelligently is even more important.
Whether you're:
* Fixing a bug
* Refactoring a model
* Building a new feature
* Reviewing a pull request
* Preparing for deployment
* Running CI/CD pipelines

You need fast, reliable test execution. That’s where the Wheels CLI testing commands come in:
```
wheels test run
wheels test all
wheels test unit
wheels test integration
wheels test watch
wheels test coverage
```

These commands transform testing from a manual step into a structured development workflow.

# Why CLI-Based Testing Matters
Without proper CLI testing tools, developers often:
* Run tests inconsistently
* Forget to run certain test suites
* Skip integration tests
* Manually check coverage
* Run full test suites unnecessarily
* Waste time rerunning everything

The Wheels CLI standardizes test execution. It makes testing:
* Repeatable
* Targeted
* Automated
* CI-friendly
* Developer-friendly

Testing becomes part of your daily workflow — not a separate task.

# wheels test run
Run Tests Quickly
`wheels test run`

This is your primary test execution command. It runs your default configured test suite. Use it when:
* You’ve made changes
* You’re about to commit
* You’re verifying a bug fix
* You’re checking regression impact

It’s your go-to command for daily development.

# wheels test all
**Execute Everything**
`wheels test all`

This runs:
* Unit tests
* Integration tests
* Full application tests

Use it when:
* Preparing for deployment
* Running CI builds
* Verifying a major refactor
* Ensuring full system stability

This gives you complete confidence before shipping.

# wheels test unit
**Fast, Focused Feedback**
`wheels test unit`

Unit tests are:
* Fast
* Isolated
* Focused on small pieces of logic

They test:
* Models
* Services
* Helpers
* Utility functions

Run this when:
* Refactoring business logic
* Updating model behavior
* Testing validation rules
* Working on isolated components

Unit tests provide rapid feedback. They should run in seconds.

# wheels test integration
**Test Real Interactions**
`wheels test integration`

Integration tests validate how components work together.
They typically cover:
* Controller → Model interactions
* Database queries
* API endpoints
* Authentication flows
* Request lifecycles

These tests are slower than unit tests — but far more comprehensive.
Use them when:
* Updating controllers
* Modifying routes
* Changing database behavior
* Adjusting authentication
* Testing real request flows

Integration tests protect against system-level regressions.

# wheels test watch
**Continuous Testing During Development**
`wheels test watch`

This command monitors your project files. When changes are detected, Tests automatically rerun. This creates a powerful development loop:
1. Edit code
2. Save
3. Tests rerun instantly
4. See failures immediately

It encourages:
* Test-driven development (TDD)
* Faster debugging
* Immediate feedback
* Higher code quality

No more manually re-running tests after every change.

# wheels test coverage
**Measure Code Coverage**
`wheels test coverage`

Running tests is good. Knowing what they actually cover is better. This command generates a coverage report showing:
* Percentage of code covered
* Untested files
* Uncovered lines
* Weak testing areas

Coverage helps you:
* Identify missing test cases
* Improve test completeness
* Strengthen critical components
* Enforce quality standards

It transforms testing from reactive to strategic.

# How These Commands Work Together
Here’s a modern development workflow:
**Daily Development**
`wheels test unit`

Fast feedback while coding.

**After Feature Completion**
`wheels test integration`

Validate system behavior.

**Before Commit**
`wheels test run`

Quick verification.

**Before Deployment**
```
wheels test all
wheels test coverage
```

Full confidence check.

**During Active Development**
`wheels test watch`

Continuous feedback loop. Each command serves a specific purpose. Together, they create a complete testing ecosystem.

# CI/CD Integration
These commands are designed to work seamlessly in pipelines:

**wheels test all || exit 1**

If tests fail, deployment stops.

Add coverage thresholds for quality enforcement:
* Require minimum coverage percentage
* Block deployment if below standard
* Track coverage trends over time

This makes testing not just a developer tool — but a deployment safeguard.

# The Bigger Picture
Older CLI tools focused mainly on scaffolding and generation.
Wheels 3.x CLI emphasizes:
* Observability
* Environment safety
* Configuration validation
* Database lifecycle management
* Automated testing

Testing commands elevate the CLI into a full development companion.
Modern development requires:
* Fast iteration
* Automated validation
* Confidence before release
* Clear quality metrics

These testing commands deliver exactly that.

# What This Means for Wheels Developers
With **run**, **all**, **unit**, **integration**, **watch**, and **coverage**, you gain:
* Faster debugging cycles
* Stronger code quality
* Safer refactoring
* CI-ready workflows
* Continuous feedback
* Measurable quality standards

Testing stops being optional. It becomes integrated. And when testing becomes effortless, quality naturally improves.

# Conclusion
The Wheels CLI testing commands in 3.x bring structure and power to your development workflow:
* `test run` → Quick verification
* `test all` → Full system validation
* `test unit` → Fast, focused checks
* `test integration` → Real-world confidence
* `test watch` → Continuous feedback
* `test coverage` → Quality measurement

If database commands help you manage data…
If environment commands help you deploy safely…

Testing commands help you build with confidence. And in modern development, confidence is everything.

Stay tuned — more Wheels CLI deep dives are coming.

https://youtu.be/L2Z5bxcgVwE
