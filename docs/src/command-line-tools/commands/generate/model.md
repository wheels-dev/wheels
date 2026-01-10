# wheels generate model

Generate a model with properties, validations, and associations.

## Synopsis

```bash
wheels generate model name=<modelName> [options]

#Can also be used as:
wheels g model name=<modelName> [options]
```

## CommandBox Parameter Syntax

- **Named parameters**: `param=value` (e.g., `name=User`, `properties=name:string,email:string`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--migration` equals `migration=true`)
- **Param with value**: `--param=value` equals `param=value` (e.g., `--primaryKey=uuid`)

**Recommended:** Use flags for options: `wheels generate model name=User --properties="name:string,email:string" --migration`

## Description

The `wheels generate model` command creates a new model CFC file with optional properties, associations, and database migrations. Models represent database tables and contain business logic, validations, and relationships.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Model name (singular) | Required |

### Model Name Validation
- Must be singular (User, not Users)
- Must be PascalCase (User, BlogPost)
- Cannot contain spaces or special characters
- Must be valid CFML component name

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

### Relationship Validation
- Relationship model names must follow model naming conventions
- Models referenced in relationships should exist or be created
- Comma-separated values cannot contain spaces around commas

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

**Important Validation Rules:**
- Model names must be singular and PascalCase (User, not Users or user)
- Property format: `name:type,name2:type2` (no spaces)
- Relationship names must be PascalCase (User, not user)
- Use valid property types from the table above

## Basic Model Examples

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

### Model with Properties and Validations
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

### Common Validation Methods

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

### Common Association Methods

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

### Common Callbacks

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
wheels generate test type=model name=User
```

## See Also

- [wheels dbmigrate create table](../database/dbmigrate-create-table.md) - Create migrations
- [wheels generate property](property.md) - Add properties to existing models
- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD