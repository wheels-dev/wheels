# ADR-001: Monorepo Migration

Date: 2024-06-22
Status: Proposed

## Context

The Wheels framework repository has grown organically over time, resulting in:
- Core framework code in the vendor directory
- Build scripts scattered across multiple directories
- Mixed application and framework files
- Difficulty coordinating changes across components

## Decision

We will migrate to a monorepo structure with clear separation of:
- Core framework (`/core/`)
- CLI module (`/cli/`)
- Project templates (`/templates/`)
- Documentation (`/docs/`)
- Development tools (`/tools/`)

## Consequences

### Positive
- Single source of truth for all components
- Easier to coordinate changes across framework, CLI, and templates
- Better organization and discoverability
- Simplified release process
- Improved testing across components

### Negative
- Initial migration effort required
- Contributors need to learn new structure
- Temporary compatibility layer needed
- Risk of breaking existing workflows

### Mitigation
- Phased migration approach
- Maintain backward compatibility for 2-3 versions
- Comprehensive migration documentation
- Community communication plan