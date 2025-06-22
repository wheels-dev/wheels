# Monorepo Migration Summary

This document summarizes the monorepo migration performed on the Wheels framework repository.

## What Was Done

### 1. Repository Structure Reorganization

The repository has been restructured into a clean monorepo layout:

```
wheels/
├── core/                       # Core framework (already in place)
│   ├── src/
│   │   └── wheels/            # Framework source code
│   └── tests/                 # Framework tests (moved from src/wheels/tests)
├── cli/                        # CLI module (already in place)
├── templates/                  # Project templates (new)
│   ├── default/               # Default web app template
│   ├── api/                   # API-only template
│   └── spa/                   # SPA template
├── tools/                      # Development tools (new)
│   ├── docker/                # Docker configs (moved from root)
│   └── scripts/               # Build scripts (moved from build/scripts)
└── Application.cfc            # Root application with mappings
```

### 2. Core Framework
- Core framework was already at `core/src/wheels/`
- Moved framework tests from `core/src/wheels/tests/` to `core/tests/`
- Added `core/src/box.json` from build directory

### 3. Project Templates
- Created `templates/` directory structure
- Moved default application files:
  - `build/base/*` → `templates/default/`
  - `app/` → `templates/default/app/`
  - `config/` → `templates/default/config/`
- Created placeholder structures for `api` and `spa` templates

### 4. Tools and Scripts
- Created `tools/` directory
- Moved `docker/` → `tools/docker/`
- Moved `build/scripts/` → `tools/scripts/`

### 5. Configuration Updates
- Updated root `box.json`:
  - Changed to monorepo configuration
  - Added workspaces support
  - Updated scripts for monorepo structure
- Created root `Application.cfc` with:
  - Monorepo mappings
  - Backward compatibility mapping for `/vendor/wheels`
- Updated `.gitignore` for new structure

### 6. Documentation
- Updated `README.md` with monorepo structure information
- Created this migration summary

## What Still Needs to Be Done

### 1. Git History Preservation
- Use `git filter-repo` to preserve file history during moves
- Tag the pre-monorepo state

### 2. CI/CD Updates
- Update GitHub Actions workflows for new paths
- Adjust test commands for monorepo structure

### 3. Build System
- Update build scripts in `tools/scripts/` for new paths
- Test the build process

### 4. Template Development
- Complete the API template implementation
- Complete the SPA template implementation
- Add template-specific documentation

### 5. Community Communication
- Create migration guide for contributors
- Update development setup documentation
- Announce changes to community

## Backward Compatibility

The following measures ensure backward compatibility:

1. **Mapping in Application.cfc**: `/vendor/wheels` maps to `/core/src/wheels`
2. **Package Publishing**: Continue publishing individual packages to ForgeBox
3. **Gradual Transition**: Support both structures during transition period

## Benefits Achieved

1. **Clearer Structure**: Each component has its own space
2. **Better Organization**: Tests, docs, and tools properly separated
3. **Unified Development**: Single repository for all components
4. **Easier Maintenance**: Related files grouped together
5. **Better Discoverability**: Clear separation of concerns

## Next Steps

1. Test the new structure thoroughly
2. Update CI/CD pipelines
3. Complete template implementations
4. Create contributor documentation
5. Plan community communication