# Wheels 3.0 Monorepo Structure

This document provides a comprehensive guide to understanding the Wheels 3.0 monorepo structure, how components relate to each other, and how the development and distribution workflow operates.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Core Components](#core-components)
- [Supporting Components](#supporting-components)
- [Package Distribution Flow](#package-distribution-flow)
- [Development Workflow](#development-workflow)
- [Component Relationships](#component-relationships)

## Overview

Wheels 3.0 uses a monorepo structure to maintain all framework components in a single repository. This approach provides:

- **Unified Versioning**: All components share the same version number (currently `3.0.0-rc.1`)
- **Simplified Development**: Changes across components can be developed and tested together
- **Atomic Commits**: Related changes across CLI, core, and templates happen in single commits
- **Easier Testing**: Cross-component integration testing without dependency management
- **Separate Distribution**: Components are still published as independent ForgeBox packages

## Directory Structure

```
wheels-monorepo/
├── cli/                          # Wheels CLI (CommandBox module)
├── core/                          # Framework core runtime
├── templates/                     # Application templates
│   └── base/                      # Base starter template
├── docs/                          # Documentation (MkDocs)
├── examples/                      # Example applications
├── tests/                         # Framework test suite
├── tools/                         # Build and development tools
│   ├── build/                     # Build scripts
│   ├── docker/                    # Docker test environments
│   ├── installer/                 # Installation tools
│   ├── scripts/                   # Utility scripts
│   ├── vscode-ext/                # VSCode extension
│   └── workspace/                 # Development workspace
├── design_docs/                   # Architecture and design docs
├── .github/                       # GitHub Actions and templates
├── compose.yml                    # Docker Compose configuration
└── [config files]                 # Project configuration
```

## Core Components

These components are published to ForgeBox and distributed to end users.

### 1. CLI Component (`/cli`)

**Published as:** `wheels-cli`
**Type:** CommandBox module
**Purpose:** Provides command-line tools for Wheels development

```
cli/
├── box.json                      # Package metadata
├── src/
│   ├── ModuleConfig.cfc          # CommandBox module configuration
│   ├── commands/                 # CLI command implementations
│   │   └── wheels/               # Hierarchical command structure
│   │       ├── new.cfc           # Create new app
│   │       ├── generate/         # Code generators
│   │       ├── db/               # Database commands
│   │       ├── routes/           # Routing commands
│   │       └── ...
│   ├── models/                   # Business logic (WireBox DI)
│   ├── templates/                # Code generation templates
│   ├── recipes/                  # Command recipes
│   └── interceptors/             # CommandBox interceptors
├── README.md                     # CLI documentation
└── CLAUDE.md                     # Development guidance
```

**Key Features:**
- Code generators for controllers, models, views, etc.
- Database migration tools
- Route inspection and management
- Template-based code generation using `{{variable}}` syntax
- WireBox dependency injection for business logic

**Installation:**
```bash
box install wheels-cli
```

### 2. Core Framework (`/core`)

**Published as:** `wheels-core`
**Type:** CFML framework library
**Purpose:** The actual MVC framework runtime

```
core/
├── box.json                      # Package metadata (v3.0.0-rc.1)
├── src/
│   └── wheels/                   # Framework code (27 directories)
│       ├── controller/           # Controller base class
│       ├── model/                # Model/ORM functionality
│       ├── view/                 # View rendering
│       ├── dispatch/             # Request routing
│       ├── global/               # Global helpers
│       └── ...
└── tests/                        # Framework tests (7 directories)
```

**Installation:**
```bash
box install wheels-core
```

**Runtime Location:** Installed to `/vendor/wheels/` in application projects

### 3. Base Template (`/templates/base`)

**Published as:** `wheels-base-template`
**Type:** Application scaffold
**Purpose:** Starting structure for new Wheels applications

```
templates/base/
├── box.json                      # Template package config
├── src/
│   ├── app/                      # Application code structure
│   │   ├── controllers/          # Controller directory
│   │   ├── models/               # Model directory
│   │   ├── views/                # View templates
│   │   ├── helpers/              # Helper functions
│   │   └── ...
│   ├── config/                   # Configuration files
│   │   ├── app.cfm               # Application settings
│   │   ├── database.cfm          # Database configuration
│   │   ├── environment.cfm       # Environment-specific config
│   │   ├── routes.cfm            # Route definitions
│   │   └── ...
│   ├── public/                   # Web-accessible assets
│   │   ├── assets/               # CSS, JS, images
│   │   ├── index.cfm             # Application entry point
│   │   └── ...
│   ├── tests/                    # Test files
│   │   ├── models/               # Model tests
│   │   ├── controllers/          # Controller tests
│   │   └── ...
│   └── box.json                  # App dependencies
├── routes.cfm                    # Route configuration
├── runner.cfm                    # Test runner
└── populate.cfm                  # Data population script
```

**Used by:** CLI command `wheels new myapp` downloads this template from ForgeBox

## Supporting Components

These components support development but are not distributed as packages.

### 4. Documentation (`/docs`)

**Published to:** https://wheels.dev/guides
**Format:** MkDocs (Markdown-based)

```
docs/
├── src/                          # Documentation source
│   ├── command-line-tools/       # CLI documentation
│   ├── database-interaction-through-models/
│   ├── displaying-views-to-users/
│   ├── handling-requests-with-controllers/
│   ├── introduction/
│   ├── plugins/
│   ├── working-with-wheels/
│   ├── upgrading/
│   └── ...
├── mkdocs.yml                    # MkDocs configuration
├── SUMMARY.md                    # Documentation structure
├── _layouts/                     # Layout templates
├── overrides/                    # MkDocs overrides
└── public/                       # Generated static site
```

**Build Process:** Automatically deployed to wheels.dev via GitHub Actions

### 5. Testing Infrastructure (`/tests`)

**Purpose:** Framework test suite for core functionality validation

```
tests/
├── runner.cfm                    # Test runner
├── specs/                        # Test specifications
├── _assets/                      # Test resources
├── README.md                     # Test setup instructions
└── CLAUDE.md                     # Test development guidance
```

**Integration:** Tests run against framework core with Docker support for multi-engine testing

### 6. Build & Development Tools (`/tools`)

**Purpose:** Build automation, testing environments, and development utilities

```
tools/
├── build/                        # Build and packaging
│   ├── base/                     # Base template build
│   ├── cli/                      # CLI build scripts
│   ├── core/                     # Core framework build
│   ├── lib/                      # Shared utilities
│   └── scripts/                  # Build automation (13 scripts)
├── docker/                       # Docker test environments
│   ├── testui/                   # Modern test UI
│   ├── lucee5/                   # Lucee 5.x engine
│   ├── lucee6/                   # Lucee 6.x engine
│   ├── lucee7/                   # Lucee 7.x engine
│   ├── adobe2018/                # Adobe CF 2018
│   ├── adobe2021/                # Adobe CF 2021
│   ├── adobe2023/                # Adobe CF 2023
│   ├── adobe2025/                # Adobe CF 2025
│   ├── boxlang/                  # BoxLang engine
│   ├── sqlserver/                # SQL Server
│   ├── mysql/                    # MySQL
│   ├── postgres/                 # PostgreSQL
│   └── Oracle/                   # Oracle
├── installer/                    # Installation tools
├── scripts/                      # Utility scripts
├── vscode-ext/                   # VSCode extension
└── workspace/                    # Development workspace
```

**Docker Testing:** Supports simultaneous testing across multiple CFML engines and databases using Docker Compose

### 7. Examples (`/examples`)

**Purpose:** Reference applications demonstrating Wheels patterns

```
examples/
└── starter-app/                  # Comprehensive example application
```

### 8. Design Documentation (`/design_docs`)

**Purpose:** Architecture decisions, specifications, and development notes

```
design_docs/
├── ai-specs/                     # AI integration specifications
├── architecture/                 # Architecture documentation
├── scratchpad/                   # Development notes
└── testing/                      # Testing documentation
```

## Package Distribution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Monorepo Repository                      │
│  ┌─────────┐  ┌──────────┐  ┌─────────────────┐            │
│  │   CLI   │  │   Core   │  │  Base Template  │            │
│  │ /cli/   │  │ /core/   │  │ /templates/base/│            │
│  └────┬────┘  └─────┬────┘  └────────┬────────┘            │
│       │             │                 │                      │
└───────┼─────────────┼─────────────────┼──────────────────────┘
        │             │                 │
        │    ┌────────▼─────────────────▼────────┐
        │    │   Build Scripts (/tools/build/)   │
        │    └────────┬─────────────────┬────────┘
        │             │                 │
        │    ┌────────▼─────────────────▼────────┐
        │    │      GitHub Actions CI/CD         │
        │    └────────┬─────────────────┬────────┘
        │             │                 │
┌───────▼─────────────▼─────────────────▼────────────────────┐
│                    ForgeBox Registry                        │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐   │
│  │ wheels-cli  │  │ wheels-core │  │ wheels-base-     │   │
│  │             │  │             │  │   template       │   │
│  └──────┬──────┘  └──────┬──────┘  └────────┬─────────┘   │
│         │                │                   │              │
└─────────┼────────────────┼───────────────────┼──────────────┘
          │                │                   │
          │                │                   │
    ┌─────▼────────────────▼───────────────────▼─────┐
    │           End User Installation                 │
    │                                                  │
    │  1. box install wheels-cli                      │
    │                                                  │
    │  2. wheels new myapp                            │
    │     ├─> Downloads wheels-base-template          │
    │     └─> Installs wheels-core as dependency      │
    │                                                  │
    │  3. Result: Working Wheels application          │
    │     myapp/                                       │
    │     ├── app/         (from base template)       │
    │     ├── config/      (from base template)       │
    │     ├── public/      (from base template)       │
    │     └── vendor/                                  │
    │         └── wheels/  (from wheels-core)         │
    └──────────────────────────────────────────────────┘
```

## Development Workflow

### Making Changes

1. **Clone the monorepo:**
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels
   ```

2. **Make changes in respective directories:**
   - CLI changes: `cli/src/`
   - Core changes: `core/src/wheels/`
   - Template changes: `templates/base/src/`
   - Documentation: `docs/src/`

3. **Test changes locally:**
   ```bash
   # Run framework tests
   cd tests && box testbox run

   # Or use Docker for multi-engine testing
   docker-compose up
   ```

4. **Build packages:**
   ```bash
   cd tools/build/scripts
   # Run appropriate build script
   ```

### Version Management

All components share the same version number defined in their `box.json` files. When releasing:

1. Update version in all `box.json` files:
   - `cli/box.json`
   - `core/box.json`
   - `templates/base/box.json`

2. Update `CHANGELOG.md` with release notes

3. Create git tag: `git tag v3.0.0`

4. Push and let CI/CD handle ForgeBox publishing

### Testing Across Engines

Use Docker Compose to test against multiple CFML engines simultaneously:

```bash
docker-compose up lucee5 lucee6 lucee7 adobe2021 adobe2023
```

Each service runs tests in isolation with proper database configurations.

## Component Relationships

### Dependency Graph

```
┌─────────────┐
│  wheels-cli │  (CommandBox module)
└──────┬──────┘
       │
       │ uses during 'wheels new'
       │
       ▼
┌──────────────────┐
│ wheels-base-     │
│   template       │
└──────┬───────────┘
       │
       │ depends on (via box.json)
       │
       ▼
┌─────────────┐
│ wheels-core │  (Installed to /vendor/wheels/)
└─────────────┘
```

### Runtime Relationships

```
User Application
├── /app
│   ├── controllers/
│   │   └── MyController.cfc  ──extends──> /vendor/wheels/Controller.cfc
│   ├── models/
│   │   └── MyModel.cfc       ──extends──> /vendor/wheels/Model.cfc
│   └── views/
│       └── myview.cfm        ──uses──> /vendor/wheels view helpers
├── /config
│   ├── app.cfm               ──configures──> Wheels settings
│   └── routes.cfm            ──defines──> URL routing
├── /public
│   └── index.cfm             ──bootstraps──> /vendor/wheels/
└── /vendor
    └── wheels/               (wheels-core package)
        ├── Controller.cfc
        ├── Model.cfc
        ├── Wheels.cfc
        └── ...
```

### Development vs. Distribution

**In Monorepo (Development):**
```
wheels/
├── cli/src/              → Source code
├── core/src/wheels/      → Source code
└── templates/base/src/   → Source code
```

**After Distribution:**
```
User's System:
├── ~/.CommandBox/modules/wheels-cli/     (from ForgeBox)

User's Application:
├── vendor/wheels/                        (from ForgeBox via dependency)
└── [app structure from base template]    (from ForgeBox via CLI download)
```

## Key Characteristics

1. **Version Synchronization**: All components share version `3.0.0-rc.1`
2. **CFML-Based**: Framework written in CFML with CommandBox module system
3. **Docker Testing**: Multi-engine and multi-database testing support
4. **Template-Based Generation**: CLI uses Handlebars-style `{{variable}}` syntax
5. **Automated Documentation**: MkDocs published to wheels.dev via CI/CD
6. **Custom Build System**: Uses CommandBox and custom scripts (not npm/pnpm workspaces)
7. **Separate Distribution**: Unified development, independent ForgeBox packages

## AI Assistance Integration

Wheels 3.0 includes comprehensive AI assistance configuration to help AI coding assistants (like Claude Code, GitHub Copilot, Cursor, etc.) work effectively with the framework.

### 9. AI Configuration (`/.ai` and `/.claude`)

#### The `.ai` Folder - Knowledge Base

**Location:** `/.ai`
**Purpose:** Comprehensive documentation structured specifically for AI assistants

```
.ai/
├── README.md                        # Knowledge base overview
├── CLAUDE.md                        # Wheels documentation index
├── QUICK_REFERENCE.md               # Quick reference guide
├── CONTRIBUTION_SUMMARY.md          # Contribution tracking
├── MCP-ENFORCEMENT.md               # MCP tool enforcement rules
├── cfml/                            # CFML language documentation
│   ├── README.md                    # CFML overview
│   ├── syntax/                      # Basic syntax, CFScript vs tags
│   ├── data-types/                  # Variables, arrays, structures, scopes
│   ├── control-flow/                # Conditionals, loops, exceptions
│   ├── components/                  # CFCs, functions, properties
│   ├── database/                    # Query basics
│   ├── advanced/                    # Closures, advanced features
│   └── best-practices/              # Modern patterns, performance
└── wheels/                          # Wheels framework documentation
    ├── README.md                    # Wheels overview
    ├── cli/                         # CLI generators and commands
    ├── configuration/               # App settings, environments
    ├── controllers/                 # Request handling, filters, rendering
    ├── core-concepts/               # MVC architecture, ORM, routing
    ├── database/                    # Migrations, associations, validations
    ├── views/                       # Templates, layouts, helpers
    ├── communication/               # Email, HTTP requests
    ├── files/                       # File handling, uploads
    ├── patterns/                    # Common patterns, best practices
    ├── security/                    # Authentication, CSRF, authorization
    ├── snippets/                    # Code examples
    └── workflows/                   # Implementation workflows
```

**Key Features:**

1. **Structured Documentation:** Organized by both language (CFML) and framework (Wheels) concerns
2. **Anti-Pattern Prevention:** Documents common mistakes and how to avoid them
3. **Code Templates:** Working examples for models, controllers, views, migrations
4. **Best Practices:** Modern CFML and Wheels development patterns
5. **Validation Templates:** Checklists for preventing common errors

**Example Content:**

```markdown
# From .ai/wheels/models/associations.md
## Critical Pattern
✅ CORRECT: hasMany(name="comments", dependent="delete")
❌ WRONG: hasMany("comments", dependent="delete")  // Mixed arguments
```

**Usage by AI Assistants:**
- AI tools read these files to understand framework conventions
- Prevents common errors before code is written
- Provides working code templates for consistent implementation
- Documents Wheels-specific patterns that differ from Rails/Laravel

#### The `.claude` Folder - Claude Code Configuration

**Location:** `/.claude`
**Purpose:** Claude Code-specific configuration and custom commands

```
.claude/
├── settings.local.json              # Permissions and tool configuration
└── commands/
    └── wheels_execute.md            # Custom slash command for development
```

**settings.local.json:**

Configures Claude Code permissions for the project:

```json
{
  "permissions": {
    "allow": [
      "Bash(box:*)",                 // CommandBox commands
      "Bash(wheels:*)",              // Wheels CLI commands
      "Bash(git:*)",                 // Git operations
      "Bash(docker:*)",              // Docker commands
      "WebFetch(domain:wheels.dev)", // Fetch documentation
      "WebFetch(domain:github.com)", // GitHub API access
      "mcp__puppeteer__*"            // Browser testing tools
    ],
    "deny": []
  }
}
```

**Custom Commands:**

The `wheels_execute.md` file defines a comprehensive development workflow:

```markdown
# /wheels_execute - Comprehensive Wheels Development Workflow

Execute complete, systematic Wheels development with:
- Spec-driven development (user approves plan first)
- Incremental implementation with testing
- Real-time progress tracking
- Comprehensive browser testing
- TestBox BDD test suite creation
- Anti-pattern prevention

Usage: /wheels_execute create a blog with posts and comments
```

**Workflow Features:**
1. **Pre-Flight Documentation Loading:** Loads relevant `.ai` docs before coding
2. **Specification Generation:** Creates detailed spec for user approval
3. **Task-Based Implementation:** Breaks work into trackable tasks
4. **Incremental Testing:** Tests each component immediately after creation
5. **Anti-Pattern Detection:** Prevents common Wheels errors during generation
6. **Comprehensive Reporting:** Provides evidence of working implementation

### Distribution of AI Configuration

**In Monorepo (Development):**
- `/.ai/` - Complete knowledge base (100+ markdown files)
- `/.claude/` - Claude Code configuration
- Root `CLAUDE.md` and `AGENTS.md` - AI guidance files

**In Base Template (User Projects):**
- `/.ai/` - Subset of documentation relevant to application development
- `/.claude/settings.local.json` - Project-specific permissions
- Root `CLAUDE.md` - Points to `.ai` documentation

**Benefits for Contributors:**

1. **Faster Onboarding:** AI assistants understand the codebase immediately
2. **Consistent Code Quality:** AI generates code following established patterns
3. **Error Prevention:** Common mistakes caught before code is written
4. **Documentation Access:** AI can reference official docs during development
5. **Custom Workflows:** Project-specific commands for common tasks

**Example AI Workflow:**

```bash
# User runs custom command
/wheels_execute create a blog with posts and comments

# Claude Code:
# 1. Loads .ai/wheels/troubleshooting/common-errors.md
# 2. Loads .ai/wheels/database/associations.md
# 3. Loads .ai/wheels/controllers/rendering.md
# 4. Generates specification with correct patterns
# 5. Gets user approval
# 6. Implements incrementally with testing
# 7. Prevents mixed argument styles
# 8. Uses proper query handling patterns
# 9. Tests each component before moving forward
# 10. Provides comprehensive results report
```

### MCP (Model Context Protocol) Integration

The `.ai/` folder also documents MCP tool enforcement:

**From `.ai/MCP-ENFORCEMENT.md`:**
- If `.mcp.json` exists in a project, MCP tools MUST be used
- CLI commands are forbidden when MCP is available
- Enforces consistent tool usage across projects

**Available MCP Tools:**
- `mcp__wheels__wheels_generate()` - Generate components
- `mcp__wheels__wheels_migrate()` - Run migrations
- `mcp__wheels__wheels_test()` - Execute tests
- `mcp__wheels__wheels_server()` - Manage dev server
- `mcp__wheels__wheels_analyze()` - Analyze codebase

## Getting Started with Development

### Prerequisites

- CommandBox CLI installed
- Docker and Docker Compose (for testing)
- Git
- (Optional) Claude Code or other AI coding assistant

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/wheels-dev/wheels.git
cd wheels

# Install dependencies
box install

# Start development server
box server start

# Run tests
cd tests
box testbox run
```

### Using AI Assistance

If using Claude Code or similar AI assistants:

1. The `.ai/` folder provides comprehensive framework documentation
2. The `.claude/` folder contains Claude Code-specific configuration
3. Custom commands like `/wheels_execute` provide guided development workflows
4. AI assistants will automatically prevent common errors using the knowledge base

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

### Questions?

- **Documentation:** https://wheels.dev/docs
- **Community:** https://github.com/wheels-dev/wheels/discussions
- **Issues:** https://github.com/wheels-dev/wheels/issues

---

**Last Updated:** 2025-10-20
**Version:** 3.0.0-rc.1
