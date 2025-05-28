# wheels generate property

Add properties to existing model files.

## Synopsis

```bash
wheels generate property [model] [properties] [options]
wheels g property [model] [properties] [options]
```

## Description

The `wheels generate property` command adds new properties to existing model files. It can add simple properties, associations, calculated properties, and validations while maintaining proper code formatting and structure.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `model` | Model name to add properties to | Required |
| `properties` | Property definitions (name:type:options) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--migrate` | Generate migration for database changes | `true` |
| `--validate` | Add validation rules | `true` |
| `--defaults` | Include default values | `false` |
| `--callbacks` | Generate property callbacks | `false` |
| `--force` | Overwrite without confirmation | `false` |
| `--help` | Show help information | |

## Property Syntax

### Basic Format
```
propertyName:type:option1:option2
```

### Supported Types
- `string` - VARCHAR(255)
- `text` - TEXT/CLOB
- `integer` - INT
- `float` - DECIMAL
- `boolean` - BIT/BOOLEAN
- `date` - DATE
- `datetime` - DATETIME
- `timestamp` - TIMESTAMP
- `binary` - BLOB

### Property Options
- `required` - Not null
- `unique` - Unique constraint
- `index` - Create index
- `default=value` - Default value
- `limit=n` - Character limit
- `precision=n` - Decimal precision
- `scale=n` - Decimal scale

## Examples

### Add single property
```bash
wheels generate property user email:string:required:unique
```

### Add multiple properties
```bash
wheels generate property product "sku:string:required:unique price:float:required stock:integer:default=0"
```

### Add text property with validation
```bash
wheels generate property post content:text:required:limit=5000
```

### Add association
```bash
wheels generate property order userId:integer:required:belongsTo=user
```

### Add calculated property
```bash
wheels generate property user "fullName:calculated"
```

## Generated Code Examples

### Basic Property Addition

Before:
```cfc
component extends="Model" {
    
    function init() {
        // Existing code
    }
    
}
```

After:
```cfc
component extends="Model" {
    
    function init() {
        // Existing code
        
        // Properties
        property(name="email", sql="email");
        
        // Validations
        validatesPresenceOf(properties="email");
        validatesUniquenessOf(properties="email");
        validatesFormatOf(property="email", regEx="^[^@\s]+@[^@\s]+\.[^@\s]+$");
    }
    
}
```

### Multiple Properties

Command:
```bash
wheels generate property product "name:string:required description:text price:float:required:default=0.00 inStock:boolean:default=true"
```

Generated:
```cfc
component extends="Model" {
    
    function init() {
        // Properties
        property(name="name", sql="name");
        property(name="description", sql="description");
        property(name="price", sql="price", default=0.00);
        property(name="inStock", sql="in_stock", default=true);
        
        // Validations
        validatesPresenceOf(properties="name,price");
        validatesNumericalityOf(property="price", allowBlank=false, greaterThanOrEqualTo=0);
    }
    
}
```

### Association Property

Command:
```bash
wheels generate property comment "userId:integer:required:belongsTo=user postId:integer:required:belongsTo=post"
```

Generated:
```cfc
component extends="Model" {
    
    function init() {
        // Associations
        belongsTo(name="user", foreignKey="userId");
        belongsTo(name="post", foreignKey="postId");
        
        // Properties
        property(name="userId", sql="user_id");
        property(name="postId", sql="post_id");
        
        // Validations
        validatesPresenceOf(properties="userId,postId");
    }
    
}
```

### Calculated Property

Command:
```bash
wheels generate property user fullName:calculated --callbacks
```

Generated:
```cfc
component extends="Model" {
    
    function init() {
        // Properties
        property(name="fullName", sql="", calculated=true);
    }
    
    // Calculated property getter
    function getFullName() {
        return this.firstName & " " & this.lastName;
    }
    
}
```

## Migration Generation

When `--migrate=true` (default), generates migration:

### Migration File
`db/migrate/[timestamp]_add_properties_to_[model].cfc`:

```cfc
component extends="wheels.migrator.Migration" hint="Add properties to product" {

    function up() {
        transaction {
            addColumn(table="products", columnName="sku", columnType="string", limit=50, null=false);
            addColumn(table="products", columnName="price", columnType="decimal", precision=10, scale=2, null=false, default=0.00);
            addColumn(table="products", columnName="stock", columnType="integer", null=true, default=0);
            
            addIndex(table="products", columnNames="sku", unique=true);
        }
    }
    
    function down() {
        transaction {
            removeIndex(table="products", columnNames="sku");
            removeColumn(table="products", columnName="stock");
            removeColumn(table="products", columnName="price");
            removeColumn(table="products", columnName="sku");
        }
    }

}
```

## Validation Rules

### Automatic Validations

Based on property type and options:

| Type | Validations Applied |
|------|-------------------|
| `string:required` | validatesPresenceOf, validatesLengthOf |
| `string:unique` | validatesUniquenessOf |
| `email` | validatesFormatOf with email regex |
| `integer` | validatesNumericalityOf(onlyInteger=true) |
| `float` | validatesNumericalityOf |
| `boolean` | validatesInclusionOf(list="true,false,0,1") |
| `date` | validatesFormatOf with date pattern |

### Custom Validations

Add custom validation rules:
```bash
wheels generate property user "age:integer:min=18:max=120"
```

Generated:
```cfc
validatesNumericalityOf(property="age", greaterThanOrEqualTo=18, lessThanOrEqualTo=120);
```

## Property Callbacks

Generate with callbacks:
```bash
wheels generate property user lastLoginAt:datetime --callbacks
```

Generated:
```cfc
function init() {
    // Properties
    property(name="lastLoginAt", sql="last_login_at");
    
    // Callbacks
    beforeUpdate("updateLastLoginAt");
}

private function updateLastLoginAt() {
    if (hasChanged("lastLoginAt")) {
        // Custom logic here
    }
}
```

## Complex Properties

### Enum-like Property
```bash
wheels generate property order "status:string:default=pending:inclusion=pending,processing,shipped,delivered"
```

Generated:
```cfc
property(name="status", sql="status", default="pending");
validatesInclusionOf(property="status", list="pending,processing,shipped,delivered");
```

### File Upload Property
```bash
wheels generate property user "avatar:string:fileField"
```

Generated:
```cfc
property(name="avatar", sql="avatar");

// In the init() method
afterSave("processAvatarUpload");
beforeDelete("deleteAvatarFile");

private function processAvatarUpload() {
    if (hasChanged("avatar") && isUploadedFile("avatar")) {
        // Handle file upload
    }
}
```

### JSON Property
```bash
wheels generate property user "preferences:text:json"
```

Generated:
```cfc
property(name="preferences", sql="preferences");

function getPreferences() {
    if (isJSON(this.preferences)) {
        return deserializeJSON(this.preferences);
    }
    return {};
}

function setPreferences(required struct value) {
    this.preferences = serializeJSON(arguments.value);
}
```

## Property Modifiers

### Encrypted Property
```bash
wheels generate property user "ssn:string:encrypted"
```

Generated:
```cfc
property(name="ssn", sql="ssn");

beforeSave("encryptSSN");
afterFind("decryptSSN");

private function encryptSSN() {
    if (hasChanged("ssn") && Len(this.ssn)) {
        this.ssn = encrypt(this.ssn, application.encryptionKey);
    }
}

private function decryptSSN() {
    if (Len(this.ssn)) {
        this.ssn = decrypt(this.ssn, application.encryptionKey);
    }
}
```

### Slugged Property
```bash
wheels generate property post "slug:string:unique:fromProperty=title"
```

Generated:
```cfc
property(name="slug", sql="slug");
validatesUniquenessOf(property="slug");

beforeValidation("generateSlug");

private function generateSlug() {
    if (!Len(this.slug) && Len(this.title)) {
        this.slug = createSlug(this.title);
    }
}

private function createSlug(required string text) {
    return reReplace(
        lCase(trim(arguments.text)),
        "[^a-z0-9]+",
        "-",
        "all"
    );
}
```

## Batch Operations

### Add Multiple Related Properties
```bash
wheels generate property user "
    profile.bio:text
    profile.website:string
    profile.twitter:string
    profile.github:string
" --nested
```

### Add Timestamped Properties
```bash
wheels generate property post "publishedAt:timestamp deletedAt:timestamp:nullable"
```

## Integration with Existing Code

### Preserve Existing Structure
The command intelligently adds properties without disrupting:
- Existing properties
- Current validations
- Defined associations
- Custom methods
- Comments and formatting

### Conflict Resolution
```bash
wheels generate property user email:string
> Property 'email' already exists. Options:
> 1. Skip this property
> 2. Update existing property
> 3. Add with different name
> Choice:
```

## Best Practices

1. Add properties incrementally
2. Always generate migrations
3. Include appropriate validations
4. Use semantic property names
5. Add indexes for query performance
6. Consider default values carefully
7. Document complex properties

## Common Patterns

### Soft Delete
```bash
wheels generate property model deletedAt:timestamp:nullable
```

### Versioning
```bash
wheels generate property document "version:integer:default=1 versionedAt:timestamp"
```

### Status Tracking
```bash
wheels generate property order "status:string:default=pending statusChangedAt:timestamp"
```

### Audit Fields
```bash
wheels generate property model "createdBy:integer:belongsTo=user updatedBy:integer:belongsTo=user"
```

## Testing

After adding properties:
```bash
# Run migration
wheels dbmigrate up

# Generate property tests
wheels generate test model user

# Run tests
wheels test
```

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels dbmigrate create column](../database/dbmigrate-create-column.md) - Create columns
- [wheels generate test](test.md) - Generate tests