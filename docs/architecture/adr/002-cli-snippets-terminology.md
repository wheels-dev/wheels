# ADR-002: CLI Snippets Terminology

Date: 2024-06-21
Status: Accepted and Implemented

## Context

The CLI module used the term "templates" for code generation files, which created confusion with:
- Framework-level project templates (complete application starters)
- View templates in the MVC pattern
- Other template concepts in web development

## Decision

Rename all CLI "templates" to "snippets" to clearly distinguish:
- **CLI Snippets**: Code generation templates for scaffolding individual files
- **Project Templates**: Complete application starter templates

## Implementation

1. Renamed `/cli/templates/` to `/cli/snippets/`
2. Updated all services and commands to use snippet terminology
3. Maintained CommandBox's `@VARIABLE@` placeholder syntax
4. Updated documentation and help text

## Consequences

### Positive
- Clear distinction between different template concepts
- Reduced confusion for new users
- Better alignment with industry terminology
- Easier to document and explain

### Negative
- Breaking change for anyone with custom templates
- Need to update all documentation
- Potential confusion during transition period

### Mitigation
- Clear migration guide for custom templates
- Prominent notice in release notes
- Support both terms temporarily with deprecation warnings