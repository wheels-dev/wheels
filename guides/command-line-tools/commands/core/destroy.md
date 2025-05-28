# wheels destroy

Remove generated code and files.

## Synopsis

```bash
wheels destroy [type] [name] [options]
```

## Description

The `wheels destroy` command reverses the actions of generator commands, removing files and code that were previously generated. It's useful for cleaning up mistakes or removing features.

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `type` | Type of resource to destroy | Yes |
| `name` | Name of the resource | Yes |

## Resource Types

- `controller` - Remove a controller and its views
- `model` - Remove a model
- `view` - Remove a specific view
- `scaffold` - Remove entire scaffolding
- `migration` - Remove a migration file
- `test` - Remove test files

## Options

| Option | Description |
|--------|-------------|
| `--force` | Skip confirmation prompts |
| `--dry-run` | Show what would be removed without doing it |
| `--help` | Show help information |

## Examples

### Remove a controller
```bash
wheels destroy controller users
```
Removes:
- `/controllers/Users.cfc`
- `/views/users/` directory and all views

### Remove a model
```bash
wheels destroy model user
```
Removes:
- `/models/User.cfc`
- Related test files

### Remove scaffolding
```bash
wheels destroy scaffold product
```
Removes:
- `/models/Product.cfc`
- `/controllers/Products.cfc`
- `/views/products/` directory
- All CRUD views
- Test files

### Remove a specific view
```bash
wheels destroy view users/edit
```
Removes:
- `/views/users/edit.cfm`

### Remove a migration
```bash
wheels destroy migration CreateUsersTable
```
Removes:
- Migration file from `/db/migrate/`

### Dry run to preview
```bash
wheels destroy scaffold order --dry-run
```
Shows what would be removed without deleting

### Force removal without confirmation
```bash
wheels destroy model tempdata --force
```

## Confirmation

By default, the command asks for confirmation:

```
The following files will be removed:
- /models/User.cfc
- /tests/models/UserTest.cfc

Are you sure you want to proceed? (y/N):
```

## Safety Features

1. **Confirmation Required**: Always asks unless `--force` is used
2. **Dry Run Mode**: Preview changes with `--dry-run`
3. **No Database Changes**: Only removes files, not database tables
4. **Git Awareness**: Warns if files have uncommitted changes

## What's NOT Removed

- Database tables or columns
- Routes (must be manually removed)
- References in other files
- Git history

## Best Practices

1. Always use `--dry-run` first
2. Commit changes before destroying
3. Check for file dependencies
4. Update routes manually
5. Remove database tables separately

## Common Workflows

### Undo a scaffold
```bash
# First, see what would be removed
wheels destroy scaffold product --dry-run

# If okay, proceed
wheels destroy scaffold product

# Remove the database table
wheels dbmigrate create remove_table products
wheels dbmigrate latest
```

### Clean up a mistake
```bash
# Accidentally created wrong controller
wheels generate controller userss  # Oops, typo!
wheels destroy controller userss   # Fix it
wheels generate controller users   # Create correct one
```

## Notes

- Cannot be undone - files are permanently deleted
- Does not remove custom code added to generated files
- Works only with files created by generators

## See Also

- [wheels generate controller](../generate/controller.md) - Generate controllers
- [wheels generate model](../generate/model.md) - Generate models
- [wheels scaffold](../generate/scaffold.md) - Generate scaffolding