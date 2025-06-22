# Wheels Development Guide

This guide covers development workflows, testing strategies, CI/CD pipelines, and deployment processes for the Wheels framework.

## Development Setup

### Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/wheels.git`
3. Run setup script: `./tools/scripts/setup.sh` (or `tools\scripts\setup.bat` on Windows)
4. Make your changes
5. Run tests: `box task run test:all`
6. Submit a pull request

### Development Environment

#### Local Development

```bash
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
```

#### Docker Development

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

### Working on Documentation

```bash
cd docs
mkdocs serve  # Live preview at http://localhost:8000
```

## Testing Strategy

### Test Organization

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Component interaction tests
├── functional/     # Full application tests
└── fixtures/       # Test data and helpers
```

### Running Tests

```bash
# Test everything
box task run test:all

# Test specific component
box task run test:core
box task run test:cli
box task run test:templates

# Test with coverage
box testbox run --coverage --coverageReporter=html

# Test specific engine
CFENGINE=adobe@2021 box task run test:core
```

### Test Helpers

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

### Multi-Engine Testing

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

## Code Standards

### Formatting

- Use CFFormat for consistent code formatting
- Run `box task run format` before committing
- Check formatting: `box task run format:check`
- EditorConfig ensures consistent whitespace

### Coding Conventions

1. **Naming Conventions**
   - Components: PascalCase (e.g., `UserController.cfc`)
   - Functions: camelCase (e.g., `findAllUsers()`)
   - Variables: camelCase (e.g., `userCount`)
   - Constants: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)

2. **Component Structure**
   - Properties at top
   - Constructor/init methods
   - Public methods
   - Private methods

3. **Documentation**
   - JavaDoc style comments for components and functions
   - Inline comments for complex logic
   - Update documentation for any user-facing changes

## Build System

### Build Scripts

```json
{
    "name": "wheels-monorepo",
    "version": "3.0.0",
    "scripts": {
        "install:all": "box install && cd core && box install && cd ../cli && box install",
        "test:all": "task run test:core && task run test:cli && task run test:templates",
        "test:core": "cd core && box testbox run",
        "test:cli": "cd cli && box testbox run",
        "test:templates": "task run tools/scripts/test-project-templates.cfc",
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

### Component Independence

- Each component can be built independently
- Shared utilities in tools directory
- Common configuration in root
- Version synchronization across components

## CI/CD Pipeline

### GitHub Actions Workflow

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

## Release Process

### Version Management

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

### Release Workflow

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

### Changelog Management

Use conventional commits:

```bash
# Install commitizen globally
npm install -g commitizen
npm install -g cz-conventional-changelog

# Configure
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
```

## Deployment

### ForgeBox Publishing

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
}
```

### Docker Images

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

### Benchmark Suite

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

### Performance CI

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

## Security

### Security Testing

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

### Dependency Scanning

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

## Contributing

See [CONTRIBUTING.md](/CONTRIBUTING.md) for detailed contribution guidelines.

## Resources

- [Framework Overview](framework-overview.md)
- [Repository Architecture](repository-architecture.md)
- [User Documentation](/docs/src/)
- [API Documentation](/docs/src/api/)