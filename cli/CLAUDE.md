# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is the Wheels CLI, a CommandBox module that provides command-line tools for Wheels framework applications.

## Commands
- **Test**: `wheels test [type] [servername] [reload] [debug]`
  - Types: core, app, plugin
- **Run Application**: Use CommandBox's server start functionality
- **Initialize**: `wheels init [name] [path] [reload] [version] [createFolders]`

## Code Style Guidelines
- **Language**: CFML (ColdFusion Markup Language)
- **Architecture**: Component-based with CFC files inheriting from base.cfc
- **Naming**: CamelCase for component names, functions, and variables
- **Organization**:
  - Commands in /commands directory, grouped by functionality
  - Templates for code generation in /templates
- **Error Handling**: Use try/catch blocks with appropriate error messages
- **Code Generation**: Follow existing template patterns when modifying or creating new templates

## Development Notes
- This is a CommandBox module that integrates with Wheels framework
- Follow MVC pattern when creating new features
- Maintain backward compatibility when possible
- Refer to CLI-IMPROVEMENTS.md for planned enhancements and architectural goals
- To run the CLI commands we need to launch CommandBox with the `box` command
- The CLI is installed with `box install wheels-cli` command
- Then use the `wheels` commands to run a particular CLI command
- First create an app with the `wheels g app` command.
- Then start the web server with `server start` commandbox command

## Monorepo Integration

The Wheels CLI is part of a larger monorepo ecosystem:

### CLI's Role in the Ecosystem
- **Source**: `/cli/src/` contains CLI source code (commands, models, templates)
- **Build**: `tools/build/scripts/build-cli.sh` packages CLI for distribution
- **Distribution**: Published to ForgeBox as `wheels-cli` CommandBox module
- **Integration**: Works with base templates and generates code following framework patterns

### Key Dependencies
- **ForgeBox Integration**: Downloads `wheels-base-template` package from ForgeBox during `wheels g app`
- **Template Snippets**: Uses base template snippets from `/templates/base/src/app/snippets/`
- **Core Patterns**: Generates code that follows core framework conventions (`$` prefix, `config()` methods)
- **Version Sync**: Shares version numbers with other monorepo components

### Development Workflow
1. Modify CLI source in `/cli/src/`
2. Test in monorepo `/workspace/` directory
3. Reload CommandBox: `box reload` after changes
4. Build process handles packaging and ForgeBox distribution via GitHub Actions

### Package Structure
- `ModuleConfig.cfc` - CommandBox module configuration
- `commands/wheels/` - Hierarchical command structure extending `base.cfc`
- `models/` - Business logic with WireBox dependency injection
- `templates/` - Code generation templates using `{{variable}}` syntax
- `box.json` - Package metadata with `type: "commandbox-modules"`

For complete monorepo architecture details, see the main repository's `CLAUDE.md` file.

## Things to remember
- Don't add the Claude signature to commit messages
- Don't add the Claude signature to PR reviews
