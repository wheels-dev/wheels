# Wheels 3.0 Architecture Guide

## Overview

This guide outlines the comprehensive architecture for Wheels 3.0, focusing on repository structure, contributor experience, testing strategies, and release workflows. The goal is to create a modern, maintainable framework that minimizes friction for both users and contributors.

## Repository Architecture

### Monorepo Structure

We recommend a monorepo approach to reduce complexity and improve coordination between components:

```
wheels/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # Main CI pipeline
│   │   ├── release.yml         # Release automation
│   │   └── docs.yml            # Documentation build
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       ├── feature_request.md
│       └── documentation.md
├── core/                       # Core framework
│   ├── src/
│   │   ├── wheels/
│   │   │   ├── Controller.cfc
│   │   │   ├── Model.cfc
│   │   │   ├── migrator/
│   │   │   ├── view/
│   │   │   └── ...
│   │   └── box.json           # Framework package info
│   └── tests/
│       ├── specs/
│       └── Application.cfc
├── cli/                        # CLI module
│   ├── src/
│   │   ├── ModuleConfig.cfc
│   │   ├── commands/
│   │   └── box.json
│   └── tests/
├── templates/                  # Project templates
│   ├── default/               # Default web app template
│   │   ├── app/
│   │   ├── config/
│   │   ├── box.json
│   │   └── server.json
│   ├── api/                   # API-only template
│   └── spa/                   # SPA template
├── docs/                      # Documentation
│   ├── src/
│   │   ├── getting-started/
│   │   ├── guides/
│   │   ├── api/
│   │   └── cli/
│   ├── build/
│   └── mkdocs.yml            # MkDocs config
├── examples/                  # Example applications
│   ├── blog/
│   ├── todo/
│   └── README.md
├── tools/                     # Development tools
│   ├── docker/
│   ├── scripts/
│   └── fixtures/
├── .gitignore
├── .editorconfig
├── box.json                   # Root package file
├── CONTRIBUTING.md
├── README.md
└── LICENSE
```

### Benefits of Monorepo

1. **Single Source of Truth**: All components versioned together
2. **Atomic Changes**: Can update framework, CLI, and templates in one commit
3. **Easier Testing**: Test integration between components
4. **Simplified Releases**: One release process for everything
5. **Better Discoverability**: Contributors can see the whole picture

## Reducing Contributor Friction

### 1. Development Setup

#### Quick Start Script
```bash
# tools/scripts/setup.sh
#!/bin/bash

echo "Setting up Wheels development environment..."

# Install CommandBox if not present
if ! command -v box &> /dev/null; then
    echo "Installing CommandBox..."
    # Platform-specific installation
fi

# Install dependencies
box install

# Setup test databases
box task run tools/scripts/setup-test-databases

# Run initial tests to verify setup
box task run test:core

echo "Setup complete! See CONTRIBUTING.md for next steps."
```

#### Docker Development Environment
```dockerfile
# tools/docker/Dockerfile.dev
FROM ortussolutions/commandbox:latest

# Install development dependencies
RUN box install commandbox-cfformat,commandbox-docbox

# Set up watches for auto-testing
COPY tools/docker/server.json /app/server.json

WORKDIR /app
CMD ["box", "server", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  wheels-dev:
    build:
      context: .
      dockerfile: tools/docker/Dockerfile.dev
    volumes:
      - .:/app
      - commandbox_home:/root/.CommandBox
    ports:
      - "8080:8080"
      - "8443:8443"
    environment:
      - WHEELS_ENV=development
      - DB_TYPE=sqlite

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: wheels
      MYSQL_DATABASE: wheels_test
    ports:
      - "3306:3306"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: wheels
      POSTGRES_DB: wheels_test
    ports:
      - "5432:5432"

volumes:
  commandbox_home:
```

### 2. Contributor Guidelines

#### CONTRIBUTING.md Structure
```markdown
# Contributing to Wheels

## Quick Start
1. Fork the repository
2. Run `./tools/scripts/setup.sh` (or `tools\scripts\setup.bat` on Windows)
3. Make your changes
4. Run tests: `box task run test:all`
5. Submit a pull request

## Development Workflow

### Working on Core Framework
```bash
cd core
box task run test:watch  # Auto-run tests on file changes
```

### Working on CLI
```bash
cd cli
box task run test:watch
```

### Testing Your Changes
```bash
# Test everything
box task run test:all

# Test specific component
box task run test:core
box task run test:cli
box task run test:templates
```

## Code Style
- We use CFFormat for consistent formatting
- Run `box task run format` before committing
- EditorConfig ensures consistent whitespace

## Documentation
- Update docs for any user-facing changes
- Run `box task run docs:preview` to see changes
```

### 3. Task Automation

#### box.json (root level)
```json
{
    "name": "wheels-monorepo",
    "version": "3.0.0",
    "scripts": {
        "test:all": "task run test:core && task run test:cli && task run test:templates",
        "test:core": "cd core && box testbox run",
        "test:cli": "cd cli && box testbox run",
        "test:templates": "task run tools/scripts/test-templates.cfc",
        "format": "cfformat run core/src/,cli/src/ --overwrite",
        "format:check": "cfformat check core/src/,cli/src/",
        "build:all": "task run build:core && task run build:cli",
        "build:core": "cd core && box package",
        "build:cli": "cd cli && box package",
        "docs:build": "cd docs && mkdocs build",
        "docs:preview": "cd docs && mkdocs serve",
        "release:prepare": "task run tools/scripts/prepare-release.cfc",
        "release:publish": "task run tools/scripts/publish-release.cfc"
    }
}
```

## Local Testing Strategy

### 1. Test Harness

Create a test harness that sets up a complete Wheels environment:

```javascript
// tools/test-harness/Application.cfc
component {
    this.name = "WheelsTestHarness";

    // Point to local development version
    this.mappings["/wheels"] = expandPath("../../core/src/wheels");

    // Test-specific settings
    this.datasource = "wheels_test";
}
```

### 2. Integration Testing

#### Template Testing
```javascript
// tools/scripts/test-templates.cfc
component {
    function run() {
        var templates = directoryList("templates", false, "path");

        for (var template in templates) {
            print.boldLine("Testing template: #template#");

            // Create temp directory
            var testDir = getTempDirectory() & createUUID();

            // Copy template
            directoryCopy(template, testDir);

            // Install dependencies
            command("install").inWorkingDirectory(testDir).run();

            // Run template tests
            command("testbox run").inWorkingDirectory(testDir).run();

            // Cleanup
            directoryDelete(testDir, true);
        }
    }
}
```

### 3. Multi-Engine Testing

```yaml
# .github/workflows/test-engines.yml
name: Multi-Engine Tests

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        cfengine: ["lucee5", "adobe2018", "adobe2021", "adobe2023"]
        db: ["sqlite", "mysql", "postgresql"]

    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup CommandBox
        uses: Ortus-Solutions/setup-commandbox@v2.0.1

      - name: Install Dependencies
        run: box install

      - name: Start Test Server
        run: |
          box server start \
            cfengine=${{ matrix.cfengine }} \
            name=test-${{ matrix.cfengine }}-${{ matrix.db }}

      - name: Run Tests
        run: box task run test:all
        env:
          DB_TYPE: ${{ matrix.db }}
```

## CI/CD Pipeline

### 1. GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - run: box install commandbox-cfformat
      - run: box task run format:check

  test-core:
    needs: format
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cfengine: ["lucee5", "adobe2021"]
    steps:
      - uses: actions/checkout@v3
      - uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - run: box install
      - run: box task run test:core
        env:
          CFENGINE: ${{ matrix.cfengine }}

  test-cli:
    needs: format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - run: box install
      - run: box task run test:cli

  test-templates:
    needs: format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - run: box install
      - run: box task run test:templates

  build-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.x'
      - run: pip install mkdocs mkdocs-material
      - run: box task run docs:build
      - uses: actions/upload-artifact@v4
        with:
          name: docs
          path: docs/build/

  integration:
    needs: [test-core, test-cli, test-templates]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Ortus-Solutions/setup-commandbox@v2.0.1
      - run: box install
      - name: Integration Tests
        run: |
          # Test creating a new app with local framework
          ./tools/scripts/integration-test.sh
```

### 2. Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: Ortus-Solutions/setup-commandbox@v2.0.1

      - name: Prepare Release
        run: box task run release:prepare

      - name: Publish Core to ForgeBox
        run: |
          cd core
          box publish
        env:
          FORGEBOX_TOKEN: ${{ secrets.FORGEBOX_TOKEN }}

      - name: Publish CLI to ForgeBox
        run: |
          cd cli
          box publish
        env:
          FORGEBOX_TOKEN: ${{ secrets.FORGEBOX_TOKEN }}

      - name: Update Templates
        run: box task run release:update-templates

      - name: Deploy Documentation
        run: |
          box task run docs:build
          # Deploy to GitHub Pages or other hosting

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            core/artifacts/*.zip
            cli/artifacts/*.zip
          body_path: CHANGELOG.md
```

## Documentation Strategy

### 1. Documentation Structure

```
docs/
├── src/
│   ├── index.md                 # Home page
│   ├── getting-started/
│   │   ├── installation.md
│   │   ├── quick-start.md
│   │   └── tutorials/
│   ├── guides/
│   │   ├── models/
│   │   ├── controllers/
│   │   ├── views/
│   │   ├── routing/
│   │   └── migrations/
│   ├── cli/
│   │   ├── commands/
│   │   └── extending.md
│   ├── api/
│   │   ├── model.md
│   │   ├── controller.md
│   │   └── ...
│   └── contributing/
│       ├── setup.md
│       ├── guidelines.md
│       └── architecture.md
├── mkdocs.yml
└── requirements.txt
```

### 2. Documentation Generation

```yaml
# mkdocs.yml
site_name: Wheels Documentation
site_url: https://docs.wheels.org
repo_url: https://github.com/wheels/wheels

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - search.suggest
    - content.code.copy

plugins:
  - search
  - macros

nav:
  - Home: index.md
  - Getting Started:
    - Installation: getting-started/installation.md
    - Quick Start: getting-started/quick-start.md
  - Guides:
    - Models: guides/models/index.md
    - Controllers: guides/controllers/index.md
  - CLI Reference: cli/index.md
  - API Reference: api/index.md
```

### 3. API Documentation

Use DocBox for automatic API documentation:

```javascript
// tools/scripts/generate-api-docs.cfc
component {
    function run() {
        var docbox = new docbox.DocBox();

        docbox.generate(
            source = expandPath("../../core/src/wheels"),
            mapping = "wheels",
            output = expandPath("../../docs/src/api")
        );
    }
}
```

## Version Management

### 1. Coordinated Releases

All components share the same version number:

```javascript
// tools/scripts/bump-version.cfc
component {
    function run(required string version) {
        var files = [
            "core/src/box.json",
            "cli/src/box.json",
            "templates/default/box.json",
            "templates/api/box.json",
            "templates/spa/box.json"
        ];

        for (var file in files) {
            var content = deserializeJSON(fileRead(file));
            content.version = arguments.version;
            fileWrite(file, serializeJSON(content, false, false));
        }

        print.greenLine("Version bumped to #arguments.version#");
    }
}
```

### 2. Changelog Management

Use conventional commits and generate changelogs automatically:

```bash
# Install commitizen globally
npm install -g commitizen
npm install -g cz-conventional-changelog

# Configure
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
```

## Testing Best Practices

### 1. Test Organization

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Component interaction tests
├── functional/     # Full application tests
└── fixtures/       # Test data and helpers
```

### 2. Test Helpers

```javascript
// tests/helpers/TestBase.cfc
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        // Setup test database
        setupTestDatabase();

        // Load framework
        application.wheels = createObject("component", "wheels.core.Wheels").init();
    }

    function setupTestDatabase() {
        // Create SQLite test database
        var dbPath = expandPath("/tests/db/test.db");
        if (fileExists(dbPath)) {
            fileDelete(dbPath);
        }
    }

    function createTestApp(struct options = {}) {
        // Helper to create test applications
        var testApp = duplicate(application.wheels);
        structAppend(testApp.settings, arguments.options);
        return testApp;
    }
}
```

### 3. Continuous Testing

```javascript
// tools/scripts/watch.cfc
component {
    function run() {
        print.line("Watching for changes...");

        var watcher = createObject("java", "java.nio.file.WatchService");

        while (true) {
            var changes = watcher.poll();
            if (!isNull(changes)) {
                print.yellowLine("Changes detected, running tests...");
                runTests();
            }
            sleep(1000);
        }
    }
}
```

## Deployment Strategy

### 1. ForgeBox Publishing

Automated publishing from CI:

```javascript
// tools/scripts/publish-release.cfc
component {
    function run() {
        // Publish core framework
        command("publish")
            .inWorkingDirectory("core")
            .params(message = "Release v#getVersion()#")
            .run();

        // Publish CLI
        command("publish")
            .inWorkingDirectory("cli")
            .params(message = "Release v#getVersion()#")
            .run();

        // Update template dependencies
        updateTemplateDependencies();
    }

    function updateTemplateDependencies() {
        var version = getVersion();
        var templates = directoryList("templates", false, "path");

        for (var template in templates) {
            var boxJsonPath = template & "/box.json";
            var boxJson = deserializeJSON(fileRead(boxJsonPath));

            // Update wheels dependency
            boxJson.dependencies.cfwheels = "^#version#";

            fileWrite(boxJsonPath, serializeJSON(boxJson, false, false));
        }
    }
}
```

### 2. Docker Images

```dockerfile
# tools/docker/Dockerfile.production
FROM ortussolutions/commandbox:alpine

# Install specific Wheels version
ARG WHEELS_VERSION=3.0.0
RUN box install wheels@${WHEELS_VERSION}

# Copy application template
COPY templates/default /app

WORKDIR /app
EXPOSE 8080

CMD ["box", "server", "start", "--console", "--production"]
```

## Performance Monitoring

### 1. Benchmark Suite

```javascript
// tools/benchmarks/run.cfc
component {
    function run() {
        var suite = new BenchmarkSuite();

        suite.add("Model Creation", function() {
            model("User").new();
        });

        suite.add("Simple Query", function() {
            model("User").findAll(maxrows = 10);
        });

        suite.add("View Rendering", function() {
            renderView(view = "users/index", layout = false);
        });

        suite.run(iterations = 1000);
    }
}
```

### 2. Performance CI

Add performance regression tests to CI:

```yaml
performance:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: Ortus-Solutions/setup-commandbox@v2.0.1
    - run: box task run benchmarks
    - uses: benchmark-action/github-action-benchmark@v1
      with:
        tool: 'customSmallerIsBetter'
        output-file-path: benchmarks/output.json
        github-token: ${{ secrets.GITHUB_TOKEN }}
        auto-push: true
```

## Security Considerations

### 1. Security Testing

```javascript
// tests/security/SqlInjectionTest.cfc
component extends="TestBase" {
    function testSqlInjection() {
        var maliciousInput = "1'; DROP TABLE users; --";

        // This should be safe
        var result = model("User").findAll(where = "id = :id", params = {id = maliciousInput});

        // Verify table still exists
        expect(model("User").count()).toBeGT(0);
    }
}
```

### 2. Dependency Scanning

```yaml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Run security scan
      run: |
        # Scan for known vulnerabilities
        box audit
```

## Conclusion

This architecture provides:

1. **Low Friction for Contributors**: Easy setup, clear structure, automated testing
2. **Maintainable Codebase**: Monorepo with clear separation of concerns
3. **Quality Assurance**: Comprehensive testing at multiple levels
4. **Modern Tooling**: Docker, CI/CD, automated releases
5. **Great Documentation**: Auto-generated API docs, comprehensive guides

The monorepo approach with strong automation ensures that Wheels remains accessible to new contributors while maintaining high quality standards. The investment in tooling and automation pays dividends in reduced maintenance burden and improved developer experience.

## Recommendations for 3.0

While the proposed architecture is robust, the following enhancements could further improve the project's quality and maintainability for the 3.0 release.

### 1. Enhance Developer Experience (DX)

#### Pre-commit Hooks
To ensure code quality and consistency *before* code is committed, integrate pre-commit hooks. Tools like **Husky** can automatically run `cfformat` and other checks on staged files. This prevents improperly formatted code from ever entering the repository.

```json
// package.json (for Husky setup)
{
  "husky": {
    "hooks": {
      "pre-commit": "box task run format:check && box task run test:core"
    }
  }
}
```

#### VS Code Integration
To provide a consistent environment for developers using Visual Studio Code, we can include recommended settings and extensions.

*   **`.vscode/extensions.json`**: Recommend extensions for CFML, EditorConfig, Docker, and CFFormat.
*   **`.vscode/settings.json`**: Configure default formatter settings to align with the project's coding standards.

### 2. Strengthen CI/CD Pipeline

#### CI Caching
To significantly speed up build times, implement caching for dependencies in the GitHub Actions workflows. Cache the `.CommandBox` directory and any `node_modules` directories used for development tooling.

```yaml
# .github/workflows/ci.yml (example step)
- name: Cache CommandBox dependencies
  uses: actions/cache@v3
  with:
    path: ~/.CommandBox
    key: ${{ runner.os }}-commandbox-${{ hashFiles('**/box.json') }}
    restore-keys: |
      ${{ runner.os }}-commandbox-
```

#### Enforce Conventional Commits
While the guide suggests `commitizen`, we should enforce this standard on Pull Requests. A GitHub Action like **commitlint** can check PR titles, ensuring a clean and readable git history, which is vital for automated changelog generation.

#### Draft Releases
Instead of publishing directly, the `release.yml` workflow should first create a **Draft Release** on GitHub. This provides a crucial manual review step, allowing maintainers to verify the changelog and attached artifacts before making the release public.

### 3. Improve Documentation Workflow

#### Live Documentation Previews
Enhance the CI process to automatically build and deploy documentation from pull requests to a temporary preview URL (e.g., using Netlify, Vercel, or GitHub Pages). This allows reviewers to see rendered documentation changes directly, improving the quality of feedback.

### 4. Bolster Security

#### Secret Scanning
In addition to dependency scanning, add a secret scanning step to the CI pipeline. Tools like **TruffleHog** or GitHub's native secret scanning can prevent sensitive information like API keys from being accidentally committed to the repository.

```yaml
# .github/workflows/ci.yml (example job)
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0 # Required for full history scan
    - name: TruffleHog Scan
      uses: trufflesecurity/trufflehog@main
      with:
        path: ./
        base: ${{ github.event.pull_request.base.sha }}
        head: ${{ github.event.pull_request.head.sha }}
```
