# CLI Test Results

## Summary
Testing of the Wheels CLI commands revealed and fixed several issues. Most commands are now working correctly.

## Issues Found and Fixed

### 1. Dependency Injection Issue
**Problem**: Multiple components were looking for `helpers@wheels` but the service was registered as `helpers@wheels-cli`
**Fix**: Updated the following files to use the correct DSL:
- `/cli/commands/wheels/base.cfc` - Changed `helpers@wheels` to `helpers@wheels-cli`
- `/cli/models/CodeGenerationService.cfc` - Changed `helpers@wheels` to `helpers@wheels-cli`

### 2. Property Generation with Model Properties
**Problem**: When using `wheels generate model` with properties parameter, received "No matching function [CAPITALIZE] found" error
**Status**: Works without properties, but fails with properties due to timing of helper injection
**Workaround**: Generate model first without properties, then use `wheels generate property` to add properties

### 3. CommandBox Parameter Mixing
**Problem**: CommandBox doesn't allow mixing positional and named parameters
**Example**: `wheels generate model product name=string` fails
**Solution**: Use either all positional or all named parameters

## Commands Tested

### ✅ Successfully Working
1. **wheels g app** - Creates new application with H2 database setup
2. **wheels generate view** - Creates view files in correct directory
3. **wheels generate controller** - Creates controller with actions
4. **wheels generate model** - Works when no properties specified
5. **wheels generate property** - Adds properties to existing models with migrations
6. **wheels generate route** - Adds routes to routes.cfm (though used resources instead of get)
7. **wheels generate resource** - Full CRUD generation with model, controller, views, routes, tests
8. **wheels scaffold** - Works without properties parameter

### ⚠️ Partially Working
1. **wheels generate model with properties** - Fails due to capitalize function issue
2. **wheels scaffold with properties** - Same capitalize function issue
3. **wheels dbmigrate** commands - Application error prevents testing

## Recommendations
1. Fix the timing issue with helper injection in model/scaffold generation with properties
2. Update route generation to correctly handle different route types (get, post, etc.)
3. Investigate and fix the application error preventing dbmigrate commands from working
4. Consider adding better error messages for parameter mixing in CommandBox

## Next Steps
- The core generate commands are functional
- Property addition can be done as a separate step after model creation
- Resource and scaffold commands provide good starting points for CRUD operations