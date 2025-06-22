# Wheels 3.0 Architecture Guide

## Overview

This guide outlines the comprehensive architecture for Wheels 3.0, focusing on repository structure, contributor experience, testing strategies, and release workflows. The goal is to create a modern, maintainable framework that minimizes friction for both users and contributors.

## Current Repository State

The current Wheels repository structure has evolved organically over time, resulting in some organizational challenges:

### Existing Structure
```
wheels/
├── vendor/wheels/          # Core framework (installed dependency)
├── cli/                    # Original CLI implementation
├── cli-new/               # New CLI implementation (CommandBox module)
├── app/                   # Sample application files
├── config/                # Application configuration
├── build/                 # Build scripts and templates
│   ├── base/
│   ├── cli/
│   ├── core/
│   └── scripts/
├── examples/              # Example applications
├── tests/                 # Mixed framework and application tests
├── guides/                # Documentation
├── docker/                # Docker configurations
└── workspace/             # Development workspace
```

### Current Challenges

1. **Scattered Components**: Core framework in vendor directory makes it less discoverable
2. **Duplicate CLI Implementations**: Both `/cli/` and `/cli-new/` directories create confusion
3. **Mixed Concerns**: Application files mixed with framework development
4. **Complex Build Process**: Build scripts separated from their components
5. **Test Organization**: Framework tests mixed with application tests
6. **Documentation Fragmentation**: Guides separate from component documentation

## Repository Architecture

### Proposed Monorepo Structure

We recommend transitioning to a clean monorepo approach to reduce complexity and improve coordination between components:

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
6. **Eliminates Duplication**: Single CLI implementation, clear ownership
7. **Improved Organization**: Each component has its own space with tests and docs
8. **Cleaner Root**: Framework development separated from example applications

## Migration Strategy

### Phase 1: Repository Restructuring

1. **Move Core Framework**
   ```bash
   # Move vendor/wheels to core/src/wheels
   mkdir -p core/src
   mv vendor/wheels core/src/
   
   # Create core-specific files
   mv build/core/box.json core/src/
   ```

2. **Consolidate CLI**
   ```bash
   # Use cli-new as the base for new CLI
   mkdir -p cli/src
   cp -r cli-new/* cli/src/
   
   # Archive old CLI for reference
   mv cli cli-legacy
   ```

3. **Organize Templates**
   ```bash
   # Extract templates from CLI
   mkdir -p templates
   mv cli/src/templates/* templates/
   
   # Create template structures
   mkdir -p templates/{default,api,spa}
   ```

4. **Separate Tests**
   ```bash
   # Move framework tests
   mkdir -p core/tests
   mv vendor/wheels/tests/* core/tests/
   
   # Move CLI tests
   mkdir -p cli/tests
   mv cli-new/tests/* cli/tests/
   ```

### Phase 2: Build System Updates

1. **Update Root box.json**
   - Remove vendor dependencies
   - Add workspace configuration
   - Update scripts for monorepo structure

2. **Component-Specific Builds**
   - Each component gets its own box.json
   - Shared version management
   - Independent publishing capability

3. **Consolidate Build Scripts**
   ```bash
   # Move build scripts to tools
   mkdir -p tools/scripts
   mv build/scripts/* tools/scripts/
   ```

### Phase 3: Git History Preservation

1. **Use git-filter-repo for History**
   ```bash
   # Preserve history when moving files
   git filter-repo --path vendor/wheels --path-rename vendor/wheels:core/src/wheels
   ```

2. **Tag Pre-Migration State**
   ```bash
   git tag pre-monorepo-migration
   ```

### Phase 4: Update Development Workflow

1. **Update Installation Instructions**
   - Document new development setup
   - Update contribution guidelines
   - Revise quick start guides

2. **CI/CD Migration**
   - Update GitHub Actions for new structure
   - Adjust build paths
   - Update test commands

### Phase 5: Community Transition

1. **Communication Plan**
   - Blog post explaining changes
   - Migration guide for contributors
   - Timeline for transition

2. **Gradual Transition**
   - Maintain compatibility layer
   - Provide migration tools
   - Support period for old structure

## Compatibility Considerations

### Backward Compatibility

1. **Vendor Directory Support**
   ```javascript
   // Compatibility mapping in Application.cfc
   this.mappings["/wheels"] = expandPath("vendor/wheels");
   ```

2. **Package Publishing**
   - Continue publishing to ForgeBox as separate packages
   - Users won't see immediate changes
   - Gradual adoption path

3. **CLI Compatibility**
   ```bash
   # Provide alias for old CLI commands
   alias wheels-old="box wheels-legacy"
   ```

### Version Alignment

1. **Synchronized Versions**
   - All components share version numbers
   - Clear compatibility matrix
   - Single changelog

2. **Transition Period**
   - Support both structures for 2-3 versions
   - Clear deprecation notices
   - Migration tools provided

## Implementation Timeline

### Immediate Actions (Week 1-2)
1. Create migration branch
2. Set up new directory structure
3. Move cli-new to cli/src
4. Archive old CLI

### Short Term (Week 3-4)
1. Migrate core framework
2. Update build scripts
3. Create compatibility layer
4. Update CI/CD pipelines

### Medium Term (Month 2)
1. Migrate documentation
2. Update all references
3. Test migration process
4. Create contributor guides

### Long Term (Month 3+)
1. Community communication
2. Gradual deprecation
3. Remove legacy code
4. Full monorepo benefits

## Tooling Updates

### Build Script Modifications

1. **Root-Level Commands**
   ```json
   {
     "scripts": {
       "install:all": "box install && cd core && box install && cd ../cli && box install",
       "test:all": "npm run test:core && npm run test:cli && npm run test:integration",
       "build:all": "npm run build:core && npm run build:cli && npm run build:templates",
       "publish:all": "npm run publish:core && npm run publish:cli"
     }
   }
   ```

2. **Component Independence**
   - Each component can be built independently
   - Shared utilities in tools directory
   - Common configuration in root

3. **Development Helpers**
   ```bash
   # tools/scripts/dev-setup.sh
   #!/bin/bash
   echo "Setting up Wheels monorepo development..."
   
   # Install all dependencies
   box install
   
   # Link CLI for local development
   cd cli && box package link
   
   # Set up test databases
   cd ../core && box task run setup:test-db
   ```

### CI/CD Updates

1. **Matrix Testing**
   ```yaml
   strategy:
     matrix:
       component: [core, cli, templates]
       cfengine: [lucee@5, adobe@2021]
   ```

2. **Conditional Builds**
   - Only build changed components
   - Dependency graph awareness
   - Parallel execution where possible

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
        cfengine: ["lucee@5", "adobe@2018", "adobe@2021", "adobe@2023"]
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
        cfengine: ["lucee@5", "adobe@2021"]
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
      - uses: actions/upload-artifact@v3
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

## Migration Benefits Summary

### For Contributors
- **Clearer Structure**: Easy to find and understand components
- **Unified Development**: Single repository to clone and set up
- **Better Testing**: Run all tests from one place
- **Consistent Tooling**: Same commands work everywhere

### For Maintainers
- **Simplified Releases**: Coordinate versions easily
- **Reduced Duplication**: Single source for each component
- **Better CI/CD**: Unified pipeline configuration
- **Easier Refactoring**: See all impacts immediately

### For Users
- **No Immediate Changes**: Packages continue to work
- **Better Documentation**: Unified and comprehensive
- **Faster Bug Fixes**: Easier to test across components
- **More Features**: Reduced maintenance overhead

## Conclusion

This architecture transition provides:

1. **Low Friction for Contributors**: Easy setup, clear structure, automated testing
2. **Maintainable Codebase**: Monorepo with clear separation of concerns
3. **Quality Assurance**: Comprehensive testing at multiple levels
4. **Modern Tooling**: Docker, CI/CD, automated releases
5. **Great Documentation**: Auto-generated API docs, comprehensive guides
6. **Smooth Migration**: Phased approach with compatibility
7. **Community First**: Minimal disruption to existing users

The monorepo approach with strong automation ensures that Wheels remains accessible to new contributors while maintaining high quality standards. The investment in tooling and automation pays dividends in reduced maintenance burden and improved developer experience.

By addressing the current structural challenges and providing a clear migration path, we can modernize the Wheels framework repository while maintaining stability for the existing community. The phased approach ensures that we can realize the benefits of a monorepo structure without disrupting ongoing development or breaking existing installations.