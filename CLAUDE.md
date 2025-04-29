# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Test Commands

- Run a single test: `wheels test app TestName`
- Run a test package: `wheels test app testBundles=controllers`
- Run a specific test spec: `wheels test app testBundles=controllers&testSpecs=testCaseOne`
- Format code: `box run-script format` (uses cfformat)
- Check formatting: `box run-script format:check`
- Reload application: `wheels reload [development|testing|maintenance|production]`

## Code Style Guidelines

- Use camelCase for variable/function names and CapitalizedCamelCase for CFC names
- Indent with tabs, 2 spaces per tab
- Max line length: 120 characters
- Function parameters use camelCase
- Scoped variables use lowercase.camelCase (e.g., application.myVar)
- Pascal case for built-in CF functions (e.g., IsNumeric(), Trim())
- Use `local` scope for function variables (not var-scoped)
- Prefix "private" methods with `$` (e.g., `$query()`) for internal use
- Follow Wheels validation/callback patterns in models
- Use transactions for database tests
- Use TestBox for writing tests with describe/it syntax