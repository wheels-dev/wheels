# wheels generate model
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*


Generate a model with properties, validations, and associations.

## Synopsis

```bash
wheels generate model [name] [options]
wheels g model [name] [options]
```

## Description

The `wheels generate model` command creates a new model CFC file with optional properties, associations, and database migrations. Models represent database tables and contain business logic, validations, and relationships.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Model name (singular) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--migration` | Generate database migration | `true` |
| `properties` | Model properties (format: name:type,name2:type2) | |
| `belongs-to` | Parent model relationships (comma-separated) | |
| `has-many` | Child model relationships (comma-separated) | |
| `has-one` | One-to-one relationships (comma-separated) | |
| `primary-key` | Primary key column name(s) | `id` |
| `table-name` | Custom database table name | |
| `description` | Model description | |
| `--force` | Overwrite existing files | `false` |

## Examples

### Basic model
```bash
wheels generate model user
```
Creates:
- `/models/User.cfc`
- Migration file (if enabled)

### Model with properties
```bash
wheels generate model user properties="firstName:string,lastName:string,email:string,age:integer"
```

### Model with associations
```bash
wheels generate model post belongs-to="user" has-many="comments"
```

### Model without migration
```bash
wheels generate model setting --migration=false
```

### Complex model
```bash
wheels generate model product \
  properties="name:string,price:decimal,stock:integer,active:boolean" \
  belongs-to="category,brand" \
  has-many="reviews,orderItems"
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

## Best Practices

1. **Naming**: Use singular names (User, not Users)
2. **Properties**: Define all database columns
3. **Validations**: Add comprehensive validations
4. **Associations**: Define all relationships
5. **Callbacks**: Use for automatic behaviors
6. **Indexes**: Add to migration for performance

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
wheels generate model user properties="email:string,name:string"
wheels generate test model user
```

## See Also

- [wheels dbmigrate create table](../database/dbmigrate-create-table.md) - Create migrations
- [wheels generate property](property.md) - Add properties to existing models
- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD