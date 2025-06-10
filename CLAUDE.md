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

## CLI Commands

- Don't mix positional and named attribute when calling CLI commands
- Named attributes should use attribute=value syntax
- Boolean attributes can use --attribute as a shortcut instead of attribute=true
- Parameter syntax - CommandBox requires named attributes (name=value) instead of mixing positional and named parameters

## Testing the framework and the CLI go hand in hand

- The CLI is written in CFML and is packaged as a module for CommandBox
- If CLI commands have syntax errors in them, CommandBox will display errors when it is initially launched
- Launch CommandBox with `box` shell command
- Use the `workspace` directory as a sandbox to test wheels cli commands.
- To run the CLI commands we need to launch CommandBox.
- In Commandbox, use the `wheels` commands to run a particular CLI command.
- First create a app with the `wheels g app` command.
- Then start the web server with `server start` commandbox command.
- Then you can run various CLI commands and using poppeteer check to see if the desire results are achieved in the app without throwing any errors.
- In particular we want to test every attribute of every cli command.
- Diagnose and fix errors as they are discovered.
- To restart the webserver use `server restart` or `server stop` followed by `server start`.
- If changes are made to the CLI commands then reload Commandbox with `box reload` or `exit` followed by `box`.
- This way changes to the CLI commands can be validated and iteratively test every command.
- keep in mind that commandbox doesn't like to mix named attributes and positional attributes.
