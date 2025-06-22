# Wheels Repository Architecture

This document describes the current repository structure and the planned migration to a monorepo architecture.

## Current Repository State

The current Wheels repository structure has evolved organically over time, resulting in some organizational challenges:

### Existing Structure
```
wheels/
├── vendor/wheels/          # Core framework (installed dependency)
├── cli/                    # CLI implementation (CommandBox module)
│   ├── commands/          # CLI command structure
│   ├── models/            # Services and business logic
│   ├── snippets/          # Code generation snippets (formerly templates)
│   └── tests/
├── app/                   # Sample application files
├── config/                # Application configuration
├── build/                 # Build scripts
│   ├── base/
│   ├── cli/
│   ├── core/
│   └── scripts/
├── examples/              # Example applications
├── tests/                 # Mixed framework and application tests
├── guides/                # Documentation
└── docker/                # Docker configurations
```

### Current Challenges

1. **Scattered Components**: Core framework in vendor directory makes it less discoverable
2. **Mixed Concerns**: Application files mixed with framework development
3. **Complex Build Process**: Build scripts separated from their components
4. **Test Organization**: Framework tests mixed with application tests
5. **Documentation Fragmentation**: Guides separate from component documentation

## Proposed Monorepo Structure

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
│   │   ├── snippets/           # Code generation snippets
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
│   ├── architecture/          # Architecture documentation
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
2. **Atomic Changes**: Can update framework, CLI, and project templates in one commit
3. **Easier Testing**: Test integration between components
4. **Simplified Releases**: One release process for everything
5. **Better Discoverability**: Contributors can see the whole picture
6. **Clear Ownership**: Single implementation for each component
7. **Improved Organization**: Each component has its own space with tests and docs
8. **Cleaner Root**: Framework development separated from example applications

### Important Terminology Distinction

**CLI Snippets vs Project Templates**:
- **CLI Snippets** (`/cli/snippets/`): Code generation templates for scaffolding individual files (models, controllers, views, migrations). These use CommandBox's `@VARIABLE@` placeholder syntax and remain within the CLI module.
- **Project Templates** (`/templates/`): Complete application starter templates (default, api, spa) that provide the full structure for new Wheels applications.

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

2. **Organize Project Templates**
   ```bash
   # Note: CLI snippets (code generation templates) stay within CLI
   # Only move project templates to root templates directory
   mkdir -p templates
   
   # Create project template structures
   mkdir -p templates/{default,api,spa}
   ```

3. **Separate Tests**
   ```bash
   # Move framework tests
   mkdir -p core/tests
   mv vendor/wheels/tests/* core/tests/
   
   # CLI tests already in place
   # cli/tests/
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

## Practical Migration Examples

### Example 1: Migrating a Controller

**Before (Old Structure)**:
```bash
# Controller was in vendor/wheels
vendor/wheels/controller/rendering.cfc
```

**After (New Structure)**:
```bash
# Controller now in core/src
core/src/wheels/controller/rendering.cfc
```

**Migration Script**:
```bash
#!/bin/bash
# Migrate controller components
mkdir -p core/src/wheels/controller
git mv vendor/wheels/controller/*.cfc core/src/wheels/controller/
```

### Example 2: Migrating CLI Snippets

**Before**:
```bash
# Snippets scattered in build directory
build/base/app/snippets/ControllerContent.txt
```

**After**:
```bash
# Centralized in CLI module
cli/src/snippets/controller.txt
```

**Migration with History Preservation**:
```bash
# Use git filter-repo to maintain history
git filter-repo --path build/base/app/snippets/ \
    --path-rename build/base/app/snippets/:cli/src/snippets/
```

### Example 3: Test Migration

**Before**:
```bash
# Mixed tests in vendor
vendor/wheels/tests/controller/
vendor/wheels/tests/model/
```

**After**:
```bash
# Organized by component
core/tests/specs/controller/
core/tests/specs/model/
cli/tests/specs/commands/
```

## Detailed Migration Checklist

### Pre-Migration Validation
- [ ] **Backup Current State**
  ```bash
  git tag pre-migration-backup
  git push origin pre-migration-backup
  ```
- [ ] **Document Current Structure**
  ```bash
  find . -type f -name "*.cfc" | sort > pre-migration-files.txt
  ```
- [ ] **Run Full Test Suite**
  ```bash
  box testbox run
  ```
- [ ] **Check Dependencies**
  ```bash
  box list --system
  ```

### Phase 1: Core Framework Migration
- [ ] **Create Core Structure**
  ```bash
  mkdir -p core/{src/wheels,tests/specs}
  ```
- [ ] **Move Framework Files**
  ```bash
  # Controllers
  git mv vendor/wheels/controller core/src/wheels/
  
  # Models
  git mv vendor/wheels/model core/src/wheels/
  
  # Base components
  git mv vendor/wheels/*.cfc core/src/wheels/
  ```
- [ ] **Update Mappings**
  ```cfc
  // In core/src/Application.cfc
  this.mappings["/wheels"] = expandPath("./wheels");
  ```
- [ ] **Validate Core Tests**
  ```bash
  cd core && box testbox run
  ```

### Phase 2: CLI Module Organization
- [ ] **Verify CLI Structure**
  ```bash
  ls -la cli/src/commands/wheels/
  ```
- [ ] **Consolidate Snippets**
  ```bash
  # Move any remaining snippets
  find . -name "*Content.txt" -o -name "*template.txt" | \
    xargs -I {} git mv {} cli/src/snippets/
  ```
- [ ] **Update CLI References**
  ```cfc
  // In cli/src/models/TemplateService.cfc
  property name="snippetPath" default="/cli/src/snippets";
  ```

### Phase 3: Build System Updates
- [ ] **Create Component box.json Files**
  ```bash
  # Core package
  cat > core/box.json << 'EOF'
  {
    "name": "wheels-core",
    "version": "3.0.0",
    "type": "modules",
    "slug": "wheels-core"
  }
  EOF
  
  # CLI package
  cat > cli/box.json << 'EOF'
  {
    "name": "wheels-cli",
    "version": "3.0.0",
    "type": "commandbox-modules",
    "slug": "wheels-cli"
  }
  EOF
  ```
- [ ] **Update Root box.json**
  ```json
  {
    "name": "wheels-monorepo",
    "private": true,
    "workspaces": ["core", "cli", "templates/*"]
  }
  ```

### Phase 4: Documentation Migration
- [ ] **Move API Docs**
  ```bash
  git mv vendor/wheels/public/docs docs/api/
  ```
- [ ] **Update Doc References**
  ```bash
  find docs -name "*.md" -exec sed -i 's|vendor/wheels|core/src/wheels|g' {} \;
  ```

### Post-Migration Validation
- [ ] **Structure Verification**
  ```bash
  tree -d -L 3 --gitignore
  ```
- [ ] **Run Integration Tests**
  ```bash
  # Test all components
  box task run test:all
  ```
- [ ] **Build Verification**
  ```bash
  # Build all packages
  box task run build:all
  ```
- [ ] **Installation Test**
  ```bash
  # Test fresh installation
  cd /tmp && box install wheels-cli
  wheels new testapp && cd testapp
  server start
  ```

## Risk Assessment and Mitigation

### High-Risk Areas

1. **Git History Loss**
   - **Risk**: Important commit history could be lost during file moves
   - **Mitigation**: Use `git filter-repo` instead of simple `git mv`
   - **Validation**: 
     ```bash
     git log --follow core/src/wheels/Model.cfc
     ```

2. **Breaking Existing Applications**
   - **Risk**: Applications depending on vendor/wheels structure fail
   - **Mitigation**: Maintain compatibility mappings
   - **Code**:
     ```cfc
     // Application.cfc compatibility layer
     if (directoryExists(expandPath("vendor/wheels"))) {
         this.mappings["/wheels"] = expandPath("vendor/wheels");
     } else if (directoryExists(expandPath("core/src/wheels"))) {
         this.mappings["/wheels"] = expandPath("core/src/wheels");
     }
     ```

3. **CI/CD Pipeline Failures**
   - **Risk**: Automated builds break due to path changes
   - **Mitigation**: Update gradually with fallbacks
   - **Example**:
     ```yaml
     # .github/workflows/ci.yml
     - name: Find Wheels Path
       run: |
         if [ -d "vendor/wheels" ]; then
           echo "WHEELS_PATH=vendor/wheels" >> $GITHUB_ENV
         else
           echo "WHEELS_PATH=core/src/wheels" >> $GITHUB_ENV
         fi
     ```

### Medium-Risk Areas

1. **Plugin Compatibility**
   - **Risk**: Third-party plugins may hardcode paths
   - **Mitigation**: Provide migration guide for plugin authors
   - **Detection Script**:
     ```bash
     # Find potential hardcoded paths in plugins
     grep -r "vendor/wheels" app/plugins/ || echo "No hardcoded paths found"
     ```

2. **Documentation Links**
   - **Risk**: Dead links in documentation
   - **Mitigation**: Automated link checking
   - **Tool**: Use `linkchecker` in CI

### Low-Risk Areas

1. **Development Workflow Changes**
   - **Risk**: Developer confusion
   - **Mitigation**: Clear documentation and tooling
   - **Solution**: Provide shell aliases and helper scripts

## Common Migration Scenarios

### Scenario 1: Migrating Custom Database Adapter

**Original Location**:
```
vendor/wheels/model/adapters/CustomDB.cfc
```

**New Location**:
```
core/src/wheels/model/adapters/CustomDB.cfc
```

**Migration Steps**:
```bash
# 1. Create directory if needed
mkdir -p core/src/wheels/model/adapters

# 2. Move with history
git filter-repo --path vendor/wheels/model/adapters/CustomDB.cfc \
    --path-rename vendor/wheels:core/src/wheels

# 3. Update references
sed -i 's|vendor\.wheels|core\.src\.wheels|g' CustomDB.cfc
```

### Scenario 2: Migrating Application Configuration

**Original Structure**:
```
app/config/
├── routes.cfm
├── settings.cfm
└── development/
    └── settings.cfm
```

**New Structure**:
```
config/
├── routes.cfm
├── settings.cfm
└── environments/
    └── development.cfm
```

**Migration Script**:
```bash
#!/bin/bash
# Migrate config with environment rename
git mv app/config config
git mv config/development config/environments
find config/environments -name "settings.cfm" -exec rename 's/settings\.cfm$/.cfm/' {} \;
```

### Scenario 3: Migrating Build Scripts

**Before**:
```
build/
├── scripts/
│   ├── build-core.sh
│   └── build-cli.sh
└── base/
    └── box.json
```

**After**:
```
tools/
├── scripts/
│   ├── build.sh
│   └── release.sh
└── templates/
    └── box.json.template
```

## Troubleshooting Guide

### Issue: "Mapping /wheels not found"

**Symptom**: Application throws error about missing /wheels mapping

**Solution**:
```cfc
// Add to Application.cfc
this.mappings["/wheels"] = expandPath("core/src/wheels");
```

### Issue: "CLI commands not found"

**Symptom**: `wheels` command not recognized after migration

**Solution**:
```bash
# Reinstall CLI module
box uninstall wheels-cli --system
box install wheels-cli --system
box reload
```

### Issue: "Tests failing with path errors"

**Symptom**: Test suite can't find test files

**Solution**:
```json
// Update testbox.json
{
  "testBundles": ["core.tests.specs", "cli.tests.specs"],
  "directory": {
    "mapping": "/",
    "recurse": true
  }
}
```

### Issue: "Git history missing for moved files"

**Symptom**: `git log` doesn't show history for migrated files

**Solution**:
```bash
# Use --follow flag
git log --follow core/src/wheels/Model.cfc

# Or configure Git to always follow renames
git config diff.renames true
git config diff.renameLimit 999999
```

## Next Steps

1. **Review and approve** the monorepo structure and migration plan
2. **Create migration branch**: `git checkout -b feature/monorepo-migration`
3. **Run migration scripts** in test environment first
4. **Validate all components** work correctly
5. **Update CI/CD pipelines** for new structure
6. **Document progress** in migration log
7. **Communicate changes** to community

For questions or concerns about this migration, please open an issue in the repository or contact the maintainers.