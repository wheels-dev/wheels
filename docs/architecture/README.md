# Wheels Architecture Documentation

This directory contains architectural documentation for the Wheels framework, including design decisions, development guidelines, and technical specifications.

## Document Organization

### Core Documentation

- **[Framework Overview](framework-overview.md)** - What is Wheels, core philosophy, and roadmap
- **[Repository Architecture](repository-architecture.md)** - Repository structure and monorepo migration strategy
- **[Development Guide](development-guide.md)** - Contributor guidelines, testing strategies, and CI/CD workflows

### Technical Specifications

- **[Component Architecture](component-architecture.md)** - Deep dive into framework components
- **[Request Lifecycle](request-lifecycle.md)** - How CFWheels processes requests
- **[CLI Architecture](cli-architecture.md)** - CommandBox module design and implementation

### Design Decisions

Architecture Decision Records (ADRs) documenting important technical decisions:

- **[ADR-001: Monorepo Migration](adr/001-monorepo-migration.md)** - Moving to a monorepo structure
- **[ADR-002: CLI Snippets Terminology](adr/002-cli-snippets-terminology.md)** - Renaming templates to snippets

## Quick Links

- [Main README](/README.md)
- [Contributing Guide](/CONTRIBUTING.md)
- [User Documentation](/docs/src/)
- [API Documentation](/docs/src/api/)

## Contributing to Architecture Docs

When adding new architectural documentation:

1. Place documents in the appropriate subdirectory
2. Update this README with a link and description
3. Follow the established format for consistency
4. Include diagrams where helpful (store in `/docs/architecture/diagrams/`)
5. For design decisions, use the ADR template in `/docs/architecture/adr/`