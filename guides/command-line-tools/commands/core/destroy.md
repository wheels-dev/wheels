# wheels destroy

Remove generated code and files associated with a model, controller, views, and tests.

## Synopsis

```bash
wheels destroy <name>
wheels d <name>
```

## Description

The `wheels destroy` command removes all files and code associated with a resource that was previously generated. It's useful for cleaning up mistakes or removing features completely. This command will also drop the associated database table and remove resource routes.

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `name` | Name of the resource to destroy | Yes |

## Options

This command has no additional options. It always prompts for confirmation before proceeding.

## What Gets Removed

When you destroy a resource, the following items are deleted:
- Model file (`/app/models/[Name].cfc`)
- Controller file (`/app/controllers/[Names].cfc`)
- Views directory (`/app/views/[names]/`)
- Model test file (`/tests/Testbox/specs/models/[Name].cfc`)
- Controller test file (`/tests/Testbox/specs/controllers/[Names].cfc`)
- View test directory (`/tests/Testbox/specs/views/[names]/`)
- Resource route entry in `/app/config/routes.cfm`
- Database table (if confirmed)

## Examples

### Basic destroy
```bash
wheels destroy user
```

This will prompt:
```
================================================
= Watch Out!                                   =
================================================
This will delete the associated database table 'users', and
the following files and directories:

/app/models/User.cfc
/app/controllers/Users.cfc
/app/views/users/
/tests/Testbox/specs/models/User.cfc
/tests/Testbox/specs/controllers/Users.cfc
/tests/Testbox/specs/views/users/
/app/config/routes.cfm
.resources("users")

Are you sure? [y/n]
```

### Using the alias
```bash
wheels d product
```

## Confirmation

The command always asks for confirmation and shows exactly what will be deleted:

```
================================================
= Watch Out!                                   =
================================================
This will delete the associated database table 'users', and
the following files and directories:

/app/models/User.cfc
/app/controllers/Users.cfc
/app/views/users/
/tests/Testbox/specs/models/User.cfc
/tests/Testbox/specs/controllers/Users.cfc
/tests/Testbox/specs/views/users/
/app/config/routes.cfm
.resources("users")

Are you sure? [y/n]
```

## Safety Features

1. **Confirmation Required**: Always asks for confirmation before proceeding
2. **Shows All Changes**: Lists all files and directories that will be deleted
3. **Database Migration**: Creates and runs a migration to drop the table
4. **Route Cleanup**: Automatically removes resource routes from routes.cfm

## What Gets Destroyed

1. **Files Deleted**:
   - Model file
   - Controller file 
   - Views directory and all view files
   - Test files (model, controller, and view tests)

2. **Database Changes**:
   - Creates a migration to drop the table
   - Runs `wheels dbmigrate latest` to execute the migration

3. **Route Changes**:
   - Removes `.resources("name")` from routes.cfm
   - Cleans up extra whitespace

## Best Practices

1. **Commit First**: Always commit your changes before destroying
2. **Review Carefully**: Read the confirmation list carefully
3. **Check Dependencies**: Make sure other code doesn't depend on what you're destroying
4. **Backup Database**: Have a database backup before running in production

## Common Workflows

### Undo a generated resource
```bash
# Generated the wrong name
wheels generate resource prduct  # Oops, typo!
wheels destroy prduct            # Remove it
wheels generate resource product # Create correct one
```

### Clean up after experimentation
```bash
# Try out a feature
wheels generate scaffold blog_post title:string content:text
# Decide you don't want it
wheels destroy blog_post
```

## Notes

- Cannot be undone - files are permanently deleted
- Database table is dropped via migration
- Resource routes are automatically removed from routes.cfm
- Only works with resources that follow Wheels naming conventions

## See Also

- [wheels generate resource](../generate/resource.md) - Generate resources
- [wheels generate scaffold](../generate/scaffold.md) - Generate scaffolding
- [wheels dbmigrate remove table](../database/dbmigrate-remove-table.md) - Remove database tables