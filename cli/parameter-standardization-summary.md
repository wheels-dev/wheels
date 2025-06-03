# CFWheels CLI Parameter Standardization - Implementation Summary

## Overview
Successfully standardized all CLI command parameters from mixed naming conventions (camelCase, lowercase) to consistent kebab-case format.

## Changes Implemented

### 1. Created SharedParameters.cfc
- Central location for common parameter definitions
- Provides consistent parameter documentation
- Groups parameters by functionality (database, generation, testing, etc.)

### 2. Standardized Parameters

#### Model Generation
**File**: `commands/wheels/generate/model.cfc`
- Added: `primary-key` (default: "id")
- Added: `table-name`
- Updated: `belongs-to`, `has-many`, `has-one` (already kebab-case)

#### Property Generation
**File**: `commands/wheels/generate/property.cfc`
- `columnName` → `column-name`
- `columnType` → `data-type`

#### Database Migration Commands
**File**: `commands/wheels/dbmigrate/create/column.cfc`
- `columnName` → `column-name`
- `columnType` → `data-type`

**File**: `commands/wheels/dbmigrate/create/table.cfc`
- `primaryKey` → `primary-key`

#### Test Generation
**File**: `commands/wheels/generate/test.cfc`
- `objectname` → `target`

#### Test Execution
**File**: `commands/wheels/test.cfc`
- `servername` → `server-name`

**File**: `commands/wheels/test/run.cfc`
- `failfast` → `fail-fast`

#### View Generation
**File**: `commands/wheels/generate/view.cfc`
- `objectname` → `object-name`

#### Documentation
**File**: `commands/wheels/docs.cfc`
- `subcommand` → `sub-command`

## Parameter Naming Convention

### Adopted Standards:
1. **kebab-case** for all multi-word parameters
2. **Descriptive names** that clearly indicate purpose
3. **Consistent naming** across similar functionality

### Examples:
- Database columns: `column-name`, `data-type`, `primary-key`
- Relationships: `belongs-to`, `has-many`, `has-one`
- Configuration: `table-name`, `server-name`, `fail-fast`
- Targets: `target` (instead of `objectname`), `object-name`

## Benefits
1. **Consistency**: All parameters follow the same naming pattern
2. **Readability**: kebab-case is easier to read in command-line contexts
3. **Standards**: Aligns with common CLI tool conventions
4. **Clarity**: More descriptive parameter names improve usability

## Usage Examples

### Before:
```bash
wheels generate model User --primaryKey=user_id
wheels generate property user columnName=email columnType=string
wheels generate test model objectname=User
wheels test app servername=myapp
```

### After:
```bash
wheels generate model User --primary-key=user_id
wheels generate property user --column-name=email --data-type=string
wheels generate test model --target=User
wheels test app --server-name=myapp
```

## Files Modified
1. `/cli/models/SharedParameters.cfc` (created)
2. `/cli/commands/wheels/generate/model.cfc`
3. `/cli/commands/wheels/generate/property.cfc`
4. `/cli/commands/wheels/generate/test.cfc`
5. `/cli/commands/wheels/generate/view.cfc`
6. `/cli/commands/wheels/dbmigrate/create/column.cfc`
7. `/cli/commands/wheels/dbmigrate/create/table.cfc`
8. `/cli/commands/wheels/test.cfc`
9. `/cli/commands/wheels/test/run.cfc`
10. `/cli/commands/wheels/docs.cfc`

## Notes
- No backward compatibility maintained as the CLI is being introduced with the current framework version
- All parameter references within functions have been updated to use bracket notation for kebab-case parameters
- Documentation and examples within command files have been updated to reflect new parameter names