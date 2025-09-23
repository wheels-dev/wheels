# wheels generate property

Add properties to existing model files with database migrations and view updates.

## Synopsis

```bash
wheels generate property name=<modelName> columnName=<propertyName> [options]

#Can also be used as:
wheels g property name=<modelName> columnName=<propertyName> [options]
```

## Parameter Syntax

CommandBox supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=User`, `columnName=email`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--null` equals `null=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--dataType=boolean`)

**Note**: Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

## Description

The `wheels generate property` command generates a database migration to add a property to an existing model and scaffolds it into `_form.cfm` and `show.cfm` views.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Model name (table name) | Required |
| `columnName` | Name of column to add | Required |

## Options

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `dataType` | Type of column | `biginteger`, `binary`, `boolean`, `date`, `datetime`, `decimal`, `float`, `integer`, `string`, `text`, `time`, `timestamp`, `uuid` | `string` |
| `default` | Default value for column | Any valid default value | `""` |
| `null` | Whether to allow null values | `true`, `false` | `true` |
| `limit` | Character or integer size limit | Numeric value | `0` |
| `precision` | Precision for decimal columns | Numeric value | `0` |
| `scale` | Scale for decimal columns | Numeric value | `0` |

## Data Type Options

| Type | Database Type | Description |
|------|---------------|-------------|
| `biginteger` | BIGINT | Large integer values |
| `binary` | BLOB | Binary data |
| `boolean` | BOOLEAN | Boolean (true/false) values |
| `date` | DATE | Date only |
| `datetime` | DATETIME | Date and time |
| `decimal` | DECIMAL | Decimal numbers with precision/scale |
| `float` | FLOAT | Floating point numbers |
| `integer` | INTEGER | Integer values |
| `string` | VARCHAR | Variable character strings |
| `text` | TEXT | Long text content |
| `time` | TIME | Time only |
| `timestamp` | TIMESTAMP | Timestamp values |
| `uuid` | VARCHAR(35) | UUID/GUID strings |

## Examples

### Basic string property
```bash
wheels generate property name=User columnName=firstName
```
Creates a string property called `firstName` on the User model.

### Boolean property with default
```bash
wheels generate property name=User columnName=isActive --dataType=boolean --default=0
```
Creates a boolean property with default value of 0 (false).

### Datetime property
```bash
wheels generate property name=User columnName=lastLoggedIn --dataType=datetime
```
Creates a datetime property on the User model.

### Decimal property with precision
```bash
wheels generate property name=Product columnName=price --dataType=decimal --precision=10 --scale=2
```
Creates a decimal property with 10 total digits and 2 decimal places.

### String with character limit
```bash
wheels generate property name=User columnName=username --dataType=string --limit=50 --null=false
```
Creates a required string property with maximum 50 characters.

## What the Command Does

The `wheels generate property` command performs these actions:

1. **Creates Database Migration**: Generates a migration file to add the column to the database
2. **Updates Form View**: Adds the property to `_form.cfm` if it exists
3. **Updates Index View**: Adds the property to `index.cfm` table if it exists
4. **Updates Show View**: Adds the property to `show.cfm` if it exists
5. **Offers Migration**: Prompts to run the migration immediately

## Generated Files

### Database Migration
**File**: `app/migrator/migrations/[timestamp]_add_[columnName]_to_[tableName].cfc`

```cfc
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            addColumn(
                table = "users",
                columnName = "firstName",
                columnType = "string",
                limit = 255,
                allowNull = true
            );
        }
    }

    function down() {
        transaction {
            removeColumn(table = "users", columnName = "firstName");
        }
    }
}
```

### View Updates

When views exist, the command adds the new property to them:

**Form View** (`_form.cfm`): Adds appropriate input field
```cfm
<!-- Added to _form.cfm -->
#textField(objectName="user", property="firstName")#
```

**Index View** (`index.cfm`): Adds column to table
```cfm
<!-- Added to table header -->
<th>First Name</th>

<!-- Added to table body -->
<td>#user.firstName#</td>
```

**Show View** (`show.cfm`): Adds property display
```cfm
<!-- Added to show.cfm -->
<p><strong>First Name:</strong> #user.firstName#</p>
```

## Special Behaviors

### Boolean Default Values
When adding boolean properties without a default value, the command automatically sets `default=0`:
```bash
wheels generate property name=User columnName=isActive --dataType=boolean
# Automatically gets default=0
```

### Model File Check
The command checks if the corresponding model file exists and asks for confirmation if it doesn't:
```
Hold On! We couldn't find a corresponding Model at /app/models/User.cfc:
are you sure you wish to add the property 'email' to users? [y/n]
```

### Lowercase Column Names
Column names are automatically converted to lowercase in migrations (following Wheels conventions):
```bash
# Input: columnName=firstName
# Migration: columnName=firstname
```

## Command Workflow

1. **Validation**: Checks if model file exists (optional)
2. **Migration**: Creates database migration using `wheels dbmigrate create column`
3. **Form Update**: Adds form field to `_form.cfm` (if exists)
4. **Index Update**: Adds column to `index.cfm` table (if exists)
5. **Show Update**: Adds property display to `show.cfm` (if exists)
6. **Migration Prompt**: Asks if you want to run migration immediately

## Troubleshooting

### Property Not Added to Views
- Check that view files exist (`_form.cfm`, `index.cfm`, `show.cfm`)
- View files must be in `/app/views/[modelPlural]/` directory

### Migration Fails
- Ensure model name matches existing table
- Check that column doesn't already exist
- Verify database permissions

### Boolean Values
- Boolean properties automatically get `default=0` if no default specified
- Use `--default=1` for true default values

## Best Practices

1. **Run migrations immediately** when prompted to keep database in sync
2. **Use semantic names** for properties (firstName, not fname)
3. **Set appropriate defaults** for boolean and numeric fields
4. **Consider null constraints** based on business logic
5. **Add one property at a time** for better change tracking

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels dbmigrate create column](../database/dbmigrate-create-column.md) - Create columns
- [wheels generate test](test.md) - Generate tests