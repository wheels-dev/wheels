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