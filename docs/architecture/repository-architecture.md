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
├── docker/                # Docker configurations
└── workspace/             # Development workspace
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

## Next Steps

1. Review and approve the monorepo structure
2. Create detailed migration scripts
3. Set up test environment for migration
4. Begin Phase 1 implementation
5. Document progress and issues

For questions or concerns about this migration, please open an issue in the repository or contact the maintainers.