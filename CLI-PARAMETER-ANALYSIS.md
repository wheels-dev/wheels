# CLI Parameter Structure Analysis

## Overview
This document provides a comprehensive analysis of parameter naming conventions used across all CFWheels CLI commands.

## Parameter Naming Patterns

### Commands Using Kebab-Case Parameters

1. **wheels generate resource**
   - `belongs-to` (Parent model relationships)
   - `has-many` (Child model relationships)

2. **wheels scaffold**
   - `belongs-to` (Parent model relationships)
   - `has-many` (Child model relationships)

### Commands Using CamelCase Parameters

All other commands use camelCase parameter naming. This includes:

## Commands by Directory

### /analyze
- **analyze/code.cfc**
  - path, fix, format, severity, report (all camelCase)
- **analyze/performance.cfc**
  - target, duration, report, threshold, profile (all camelCase)

### /dbmigrate
- **dbmigrate/create/blank.cfc**
  - name (camelCase)
- **dbmigrate/create/column.cfc**
  - name, dataType, columnName, default, null, limit, precision, scale (all camelCase)
- **dbmigrate/create/table.cfc**
  - name, force, id, primaryKey (all camelCase)
- **dbmigrate/exec.cfc**
  - version (camelCase)

### /docs
- **docs.cfc**
  - subCommand (camelCase)
- **docs/generate.cfc**
  - output, format, template, include, serve, verbose (all camelCase)
- **docs/serve.cfc**
  - root, port, open, watch (all camelCase)

### /env
- **env/list.cfc**
  - format (camelCase)
- **env/setup.cfc**
  - environment, template, database, force (all camelCase)
- **env/switch.cfc**
  - environment (camelCase)

### /generate
- **generate/controller.cfc**
  - name, actions, rest, api, description, force (all camelCase)
- **generate/model.cfc**
  - name, migration, properties, belongsTo, hasMany, hasOne, primaryKey, tableName, description, force (all camelCase)
- **generate/property.cfc**
  - name, columnName, dataType, default, null, limit, precision, scale (all camelCase)
- **generate/resource.cfc** ⚠️ **USES KEBAB-CASE**
  - name, api, tests, migration, scaffold, open (camelCase)
  - `belongs-to`, `has-many` (kebab-case)
  - attributes (camelCase)
- **generate/test.cfc**
  - type, target, name, crud, mock, open (all camelCase)
- **generate/view.cfc**
  - objectName, name, template (all camelCase)

### /optimize
- **optimize/performance.cfc**
  - cache, assets, database, analysis, apply (all camelCase)

### /plugins
- **plugins/install.cfc**
  - name, dev, global, version (all camelCase)
- **plugins/list.cfc**
  - global, format, available (all camelCase)
- **plugins/remove.cfc**
  - name, global, force (all camelCase)

### /security
- **security/scan.cfc**
  - path, fix, report, severity, output (all camelCase)

### /test
- **test.cfc**
  - type, serverName, reload, debug, format, adapter (all camelCase)
- **test/run.cfc**
  - filter, group, coverage, reporter, watch, verbose, failFast (all camelCase)

### Root Level Commands
- **destroy.cfc**
  - name (camelCase)
- **reload.cfc**
  - mode (camelCase)
- **scaffold.cfc** ⚠️ **USES KEBAB-CASE**
  - name, properties, api, tests, migrate, force (camelCase)
  - `belongs-to`, `has-many` (kebab-case)
- **watch.cfc**
  - reload, tests, migrations, command, debounce (all camelCase)

## Summary

### Inconsistency Found
Only 2 commands use kebab-case parameters:
1. `wheels generate resource` - uses `belongs-to` and `has-many`
2. `wheels scaffold` - uses `belongs-to` and `has-many`

However, the `wheels generate model` command uses camelCase for the same concepts:
- `belongsTo` (instead of `belongs-to`)
- `hasMany` (instead of `has-many`)
- `hasOne` (no kebab-case equivalent in other commands)

### Recommendation
For consistency across the CLI, all parameters should follow the same naming convention. The predominant pattern is camelCase, which aligns with:
- ColdFusion/CFML conventions
- The rest of the CFWheels codebase
- 98% of existing CLI parameters

The kebab-case parameters in `generate resource` and `scaffold` commands should be changed to camelCase for consistency.