# /wheels_validate - Validate Implementation

## Description
Verify that a Wheels application feature is correctly implemented. Runs tests, scans for anti-patterns, checks routes, verifies associations, and reports findings with file:line references.

## Usage
```
/wheels_validate                 # Validate entire app
/wheels_validate models          # Validate only models
/wheels_validate controllers     # Validate only controllers
/wheels_validate views           # Validate only views
/wheels_validate migrations      # Validate only migrations
```

## Workflow

### Step 1: Run the Test Suite

Detect available tools (check for `.mcp.json`).

**Run tests:**
```
mcp__wheels__wheels_test()    # MCP
wheels test run                # CLI
```

Report: number of tests run, passed, failed, errored. For any failures, include the test name and error message.

### Step 2: Scan for Anti-Patterns

Scan the codebase for the top 10 Wheels anti-patterns. Use Grep to search across files and report every match with the file path and line number.

#### Anti-Pattern 1: Mixed Argument Styles
Function calls that mix positional and named parameters.

**Search models for:**
```
Grep: hasMany\("[^"]+",\s*\w+= in app/models/*.cfc
Grep: belongsTo\("[^"]+",\s*\w+= in app/models/*.cfc
Grep: hasOne\("[^"]+",\s*\w+= in app/models/*.cfc
Grep: validatesPresenceOf\("[^"]+",\s*\w+= in app/models/*.cfc
```

**Fix:** Use all-named parameters when any named parameter is needed.

#### Anti-Pattern 2: Query/Array Confusion in Views
Using array functions on query objects or array loop syntax on queries.

**Search views for:**
```
Grep: ArrayLen\( in app/views/**/*.cfm
Grep: cfloop\s+array= in app/views/**/*.cfm
```

**Fix:** Use `.recordCount` for queries and `<cfloop query=...>` syntax.

#### Anti-Pattern 3: Missing cfparam Declarations
Views that use variables without declaring them with cfparam.

**Check each view file:**
Read the file, identify which variables are used in the template, verify each has a corresponding `<cfparam name="variableName">` at the top.

#### Anti-Pattern 4: Database-Specific SQL in Migrations
MySQL/PostgreSQL/MSSQL-specific functions in migration files.

**Search migrations for:**
```
Grep: DATE_SUB|DATE_ADD|NOW\(\)|CURDATE|GETDATE|DATEADD in app/migrator/migrations/*.cfc
Grep: AUTO_INCREMENT|SERIAL|IDENTITY in app/migrator/migrations/*.cfc
```

**Fix:** Use CFML date functions (`DateAdd()`, `Now()`, `DateFormat()`) with `TIMESTAMP` formatting.

#### Anti-Pattern 5: Missing CSRF Protection
Controllers that handle form submissions without CSRF protection.

**Check:** For each controller that has a `create`, `update`, or `delete` action, verify the `config()` function includes `protectsFromForgery()`.

```
Grep: protectsFromForgery in app/controllers/*.cfc
```

Controllers with form-handling actions but no `protectsFromForgery()` are flagged.

#### Anti-Pattern 6: Non-Private Filter Functions
Controller filter functions that are not marked as private.

**Search controllers for:**
Read each controller. Find functions referenced in `filters(through="functionName")`. Verify each referenced function has the `private` access modifier.

#### Anti-Pattern 7: String Boolean Values in Migrations
CLI-generated migrations often have boolean values as strings.

**Search migrations for:**
```
Grep: force='false'|force="false"|id='true'|id="true" in app/migrator/migrations/*.cfc
```

**Fix:** Remove these parameters entirely (defaults are correct) or use actual boolean values.

#### Anti-Pattern 8: Missing Error Handling in Controllers
Create/update actions that don't handle validation failures.

**Check:** For each `create()` and `update()` action, verify there's an `else` branch that calls `renderView()` to re-display the form with errors.

#### Anti-Pattern 9: N+1 Query Patterns
Loading associations inside loops instead of using `include` in the initial query.

**Search views for:**
```
Grep: model\("[^"]+"\)\.find in app/views/**/*.cfm
```

If model queries appear inside `cfloop` blocks, flag as potential N+1.

**Fix:** Use `include="association"` in the controller's `findAll()` call.

#### Anti-Pattern 10: Hardcoded URLs Instead of Route Helpers
Using hardcoded href paths instead of `linkTo()` or `urlFor()`.

**Search views for:**
```
Grep: href="/[a-z] in app/views/**/*.cfm
```

Exclude external URLs (https://) and anchor links (#). Flag internal hardcoded paths.

**Fix:** Use `linkTo()` or `urlFor()` helpers.

### Step 3: Verify Routes

Read `config/routes.cfm` and verify:
- Resource routes exist for all controllers that need them
- Root route is defined
- Route ordering is correct (resources before wildcard)
- No duplicate route definitions

If the server is running, test key URLs:
```bash
curl -s http://localhost:PORT/ -I
curl -s http://localhost:PORT/[resource] -I
curl -s http://localhost:PORT/[resource]/1 -I
curl -s http://localhost:PORT/[resource]/new -I
```

Report any URLs that return 404 or 500.

### Step 4: Verify Associations

For each model with associations:
1. Read the model file
2. For each `hasMany`/`belongsTo`/`hasOne`:
   - Verify the associated model file exists
   - Verify the foreign key column exists in the migration
   - Verify the reciprocal association exists (if `Post hasMany Comments`, verify `Comment belongsTo Post`)

Report any missing reciprocal associations or foreign keys.

### Step 5: Report Findings

Generate a summary report:

```
## Validation Results

### Test Suite
- Tests run: X
- Passed: X
- Failed: X
- [List any failures with details]

### Anti-Pattern Scan
- Issues found: X
- [List each issue with file:line reference and description]

### Routes
- Configured: X resource routes
- Working: X
- Broken: X
- [List any broken routes]

### Associations
- Models checked: X
- Issues: X
- [List any missing reciprocal associations or foreign keys]

### Overall: PASS / FAIL
[If FAIL, list the specific items that need fixing]
```

## What This Command Does NOT Do

- Does not fix issues (it only reports them)
- Does not generate code
- Does not modify files

If issues are found, the user can fix them manually or re-run `/wheels_build` after updating the spec.

## Quick Mode

If called with a specific scope (e.g., `/wheels_validate models`), only run the checks relevant to that scope:
- `models`: Anti-patterns 1, 9; association verification
- `controllers`: Anti-patterns 5, 6, 8; route verification
- `views`: Anti-patterns 2, 3, 10
- `migrations`: Anti-patterns 4, 7

## Integration with Other Commands

- **After /wheels_build**: Run `/wheels_validate` to verify the implementation
- **References /wheels_spec**: Can check the spec's test plan against actual test results
- **Standalone**: Can be run anytime to check codebase health
