# wheels generate model

Generate a model with properties, validations, and associations.

## Synopsis

```bash
wheels generate model name=<modelName> [options]

#Can also be used as:
wheels g model name=<modelName> [options]
```

## Parameter Syntax

CommandBox supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=User`, `properties=name:string,email:string`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--migration` equals `migration=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--primaryKey=uuid`)

**Note**: Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

## Description

The `wheels generate model` command creates a new model CFC file with optional properties, associations, and database migrations. Models represent database tables and contain business logic, validations, and relationships.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Model name (singular) | Required |

## Options

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `properties` | Model properties (format: name:type,name2:type2) | Property format: `name:type[,name2:type2]` where type is valid column type | `""` |
| `belongsTo` | Parent model relationships (comma-separated) | Valid model names (PascalCase), comma-separated | `""` |
| `hasMany` | Child model relationships (comma-separated) | Valid model names (PascalCase), comma-separated | `""` |
| `hasOne` | One-to-one relationships (comma-separated) | Valid model names (PascalCase), comma-separated | `""` |
| `primaryKey` | Primary key column name(s) | Valid column name (alphanumeric, underscore) | `id` |
| `tableName` | Custom database table name | Valid table name (alphanumeric, underscore) | `""` |
| `description` | Model description | Any descriptive text | `""` |
| `migration` | Generate database migration | `true`, `false` | `true` |
| `force` | Overwrite existing files | `true`, `false` | `false` |

## Parameter Validation

### Required Parameters
- **`name`**: Cannot be empty, must be valid CFML component name (alphanumeric, starts with letter)

### Property Types Validation
Valid property types for the `properties` parameter:

| Type | Database Type | Validation |
|------|---------------|------------|
| `string` | VARCHAR(255) | Default string type |
| `text` | TEXT | For longer text content |
| `integer` | INTEGER | Whole numbers |
| `biginteger` | BIGINT | Large whole numbers |
| `float` | FLOAT | Decimal numbers |
| `decimal` | DECIMAL(10,2) | Precise decimal numbers |
| `boolean` | BOOLEAN | true/false values |
| `date` | DATE | Date values |
| `datetime` | DATETIME | Date and time values |
| `timestamp` | TIMESTAMP | Timestamp values |
| `binary` | BLOB | Binary data |
| `uuid` | VARCHAR(35) | UUID strings |

### Model Name Validation
- Must be singular (User, not Users)
- Must be PascalCase (User, BlogPost)
- Cannot contain spaces or special characters
- Must be valid CFML component name

### Relationship Validation
- Relationship model names must follow model naming conventions
- Models referenced in relationships should exist or be created
- Comma-separated values cannot contain spaces around commas

## Examples

### Basic model
```bash
wheels generate model name=User
```
Creates:
- `/models/User.cfc`
- Migration file (if enabled)

### Model with properties
```bash
wheels generate model name=User --properties="firstName:string,lastName:string,email:string,age:integer"
```

### Model with associations
```bash
wheels generate model name=Post --belongsTo="User" --hasMany="Comments"
```

### Model without migration
```bash
wheels generate model name=Setting --migration=false
```

### Complex model
```bash
wheels generate model name=Product --properties="name:string,price:decimal,stock:integer,active:boolean" --belongsTo="Category,Brand" --hasMany="Reviews,OrderItems"
```

## Validation Examples

### ✅ Valid Examples
```bash
# Valid model name and properties
wheels generate model name=User --properties="firstName:string,lastName:string,email:string,age:integer"

# Valid relationships
wheels generate model name=Post --belongsTo="User,Category" --hasMany="Comments,Tags"

# Valid property types
wheels generate model name=Product --properties="name:string,description:text,price:decimal,inStock:boolean,createdAt:datetime"
```

### ❌ Invalid Examples and Errors

#### Invalid Model Names
```bash
# Error: Model name cannot be empty
wheels generate model name=""
# Result: Invalid model name error

# Error: Model name should be singular
wheels generate model name=Users
# Result: Warning about plural name

# Error: Invalid characters
wheels generate model name="Blog Post"
# Result: Invalid model name error
```

#### Invalid Property Types
```bash
# Error: Invalid property type
wheels generate model name=User --properties="name:varchar,age:int"
# Result: Use 'string' instead of 'varchar', 'integer' instead of 'int'

# Error: Missing property type
wheels generate model name=User --properties="name,email:string"
# Result: Property format must be 'name:type'
```

#### Invalid Relationships
```bash
# Error: Invalid model name format
wheels generate model name=Post --belongsTo="user,blog_category"
# Result: Use PascalCase: 'User,BlogCategory'

# Error: Spaces in comma-separated values
wheels generate model name=Post --belongsTo="User, Category"
# Result: Remove spaces: 'User,Category'
```

## Property Types

| Type | Database Type | CFML Type |
|------|---------------|-----------|
| `string` | VARCHAR(255) | string |
| `text` | TEXT | string |
| `integer` | INTEGER | numeric |
| `biginteger` | BIGINT | numeric |
| `float` | FLOAT | numeric |
| `decimal` | DECIMAL(10,2) | numeric |
| `boolean` | BOOLEAN | boolean |
| `date` | DATE | date |
| `datetime` | DATETIME | date |
| `timestamp` | TIMESTAMP | date |
| `binary` | BLOB | binary |
| `uuid` | VARCHAR(35) | string |

## Generated Code

### Basic Model
```cfc
component extends="Model" {

    function init() {
        // Table name (optional if following conventions)
        table("users");
        
        // Validations
        validatesPresenceOf("email");
        validatesUniquenessOf("email");
        validatesFormatOf("email", regex="^[^@]+@[^@]+\.[^@]+$");
        
        // Callbacks
        beforeCreate("setDefaultValues");
    }
    
    private function setDefaultValues() {
        if (!StructKeyExists(this, "createdAt")) {
            this.createdAt = Now();
        }
    }

}
```

### Model with Properties
```cfc
component extends="Model" {

    function init() {
        // Properties
        property(name="firstName", label="First Name");
        property(name="lastName", label="Last Name");
        property(name="email", label="Email Address");
        property(name="age", label="Age");
        
        // Validations
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf("email");
        validatesFormatOf("email", regex="^[^@]+@[^@]+\.[^@]+$");
        validatesNumericalityOf("age", onlyInteger=true, greaterThan=0, lessThan=150);
    }

}
```

### Model with Associations
```cfc
component extends="Model" {

    function init() {
        // Associations
        belongsTo("user");
        hasMany("comments", dependent="deleteAll");
        
        // Nested properties
        nestedProperties(associations="comments", allowDelete=true);
        
        // Validations
        validatesPresenceOf("title,content,userId");
        validatesLengthOf("title", maximum=255);
    }

}
```

## Validations

Common validation methods:

```cfc
// Presence
validatesPresenceOf("name,email");

// Uniqueness
validatesUniquenessOf("email,username");

// Format
validatesFormatOf("email", regex="^[^@]+@[^@]+\.[^@]+$");
validatesFormatOf("phone", regex="^\d{3}-\d{3}-\d{4}$");

// Length
validatesLengthOf("username", minimum=3, maximum=20);
validatesLengthOf("bio", maximum=500);

// Numerical
validatesNumericalityOf("age", onlyInteger=true, greaterThan=0);
validatesNumericalityOf("price", greaterThan=0);

// Inclusion/Exclusion
validatesInclusionOf("status", list="active,inactive,pending");
validatesExclusionOf("username", list="admin,root,system");

// Confirmation
validatesConfirmationOf("password");

// Custom
validate("customValidation");
```

## Associations

### Belongs To
```cfc
belongsTo("user");
belongsTo(name="author", modelName="user", foreignKey="authorId");
```

### Has Many
```cfc
hasMany("comments");
hasMany(name="posts", dependent="deleteAll", orderBy="createdAt DESC");
```

### Has One
```cfc
hasOne("profile");
hasOne(name="address", dependent="delete");
```

### Many to Many
```cfc
hasMany("categorizations");
hasMany(name="categories", through="categorizations");
```

## Callbacks

Lifecycle callbacks:

```cfc
// Before callbacks
beforeCreate("method1,method2");
beforeUpdate("method3");
beforeSave("method4");
beforeDelete("method5");
beforeValidation("method6");

// After callbacks
afterCreate("method7");
afterUpdate("method8");
afterSave("method9");
afterDelete("method10");
afterValidation("method11");
afterFind("method12");
afterInitialization("method13");
```

## Generated Migration

When `--migration` is enabled:

```cfc
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            t = createTable("users");
            t.string("firstName");
            t.string("lastName");
            t.string("email");
            t.integer("age");
            t.timestamps();
            t.create();
            
            addIndex(table="users", columnNames="email", unique=true);
        }
    }

    function down() {
        transaction {
            dropTable("users");
        }
    }

}
```

## Common Validation Errors

### Model Name Errors
- **Empty name**: `name=""` → Provide a valid model name
- **Plural names**: `name=Users` → Use singular form: `name=User`
- **Invalid characters**: `name="Blog Post"` → Use PascalCase: `name=BlogPost`
- **Lowercase**: `name=user` → Use PascalCase: `name=User`

### Property Format Errors
- **Missing colon**: `properties="name,email:string"` → `properties="name:string,email:string"`
- **Invalid types**: `properties="name:varchar"` → `properties="name:string"`
- **Extra spaces**: `properties="name: string"` → `properties="name:string"`
- **Missing type**: `properties="name:"` → `properties="name:string"`

### Boolean Parameter Errors
- **Invalid boolean**: `--migration=yes` → `--migration=true` or `--migration=false`
- **Mixed syntax**: `migration=true --force` → `--migration=true --force`

### Relationship Format Errors
- **Lowercase models**: `belongsTo="user"` → `belongsTo="User"`
- **Extra spaces**: `belongsTo="User, Category"` → `belongsTo="User,Category"`
- **Invalid separators**: `belongsTo="User;Category"` → `belongsTo="User,Category"`

## Best Practices

1. **Naming**: Use singular names (User, not Users)
2. **Properties**: Define all database columns with correct types
3. **Validations**: Add comprehensive validations in model code
4. **Associations**: Define all relationships using PascalCase
5. **Callbacks**: Use for automatic behaviors
6. **Indexes**: Add to migration for performance
7. **Validation**: Always validate parameters before running command

## Common Patterns

### Soft Deletes
```cfc
function init() {
    softDeletes();
}
```

### Calculated Properties
```cfc
function init() {
    property(name="fullName", sql="firstName + ' ' + lastName");
}
```

### Scopes
```cfc
function scopeActive() {
    return where("active = ?", [true]);
}

function scopeRecent(required numeric days=7) {
    return where("createdAt >= ?", [DateAdd("d", -arguments.days, Now())]);
}
```

### Default Values
```cfc
function init() {
    beforeCreate("setDefaults");
}

private function setDefaults() {
    if (!StructKeyExists(this, "status")) {
        this.status = "pending";
    }
    if (!StructKeyExists(this, "priority")) {
        this.priority = 5;
    }
}
```

## Testing

Generate model tests:
```bash
wheels generate model name=User --properties="email:string,name:string"
wheels generate test model name=User
```

## Troubleshooting

### Command Fails with "Invalid model name"
1. Check that name is not empty: `name=User`
2. Ensure PascalCase format: `name=User` (not `name=user`)
3. Use singular form: `name=User` (not `name=Users`)
4. Remove special characters: `name=BlogPost` (not `name="Blog Post"`)

### Properties Not Generated in Migration
1. Check property format: `properties="name:string,email:string"`
2. Ensure valid property types (see Property Types table above)
3. Remove extra spaces: `name:string` (not `name: string`)
4. Use comma separators: `name:string,email:string`

### Relationships Not Working
1. Use PascalCase model names: `belongsTo="User"` (not `belongsTo="user"`)
2. Remove spaces after commas: `belongsTo="User,Category"`
3. Ensure referenced models exist or will be created

### Migration Not Generated
1. Check `--migration=false` wasn't set
2. Ensure you have write permissions in the directory
3. Verify migration directory exists: `/app/migrator/migrations/`

### Boolean Parameters Not Working
1. Use `--flag` for `flag=true`: `--force` equals `force=true`
2. Use `--flag=false` for false values: `--migration=false`
3. Don't mix syntaxes: Use all flags or all named parameters

## See Also

- [wheels dbmigrate create table](../database/dbmigrate-create-table.md) - Create migrations
- [wheels generate property](property.md) - Add properties to existing models
- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD