# wheels generate property
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*


Add properties to existing model files.

## Synopsis

```bash
wheels generate property [name] [options]
wheels g property [name] [options]
```

## Description

The `wheels generate property` command generates a database migration to add a property to an existing model and scaffolds it into `_form.cfm` and `show.cfm` views.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Table name | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `column-name` | Name of column | Required |
| `data-type` | Type of column | `string` |
| `default` | Default value for column | |
| `--null` | Whether to allow null values | |
| `limit` | Character or integer size limit for column | |
| `precision` | Precision value for decimal columns | |
| `scale` | Scale value for decimal columns | |

## Property Syntax

### Basic Format
```
propertyName:type:option1:option2
```

### Data Type Options
- `biginteger` - Large integer
- `binary` - Binary data
- `boolean` - Boolean (true/false)
- `date` - Date only
- `datetime` - Date and time
- `decimal` - Decimal numbers
- `float` - Floating point
- `integer` - Integer
- `string` - Variable character (VARCHAR)
- `text` - Long text
- `time` - Time only
- `timestamp` - Timestamp
- `uuid` - UUID/GUID

## Examples

### String property
```bash
wheels generate property user column-name=firstname
```
Creates a string/textField property called `firstname` on the User model.

### Boolean property with default
```bash
wheels generate property user column-name=isActive data-type=boolean default=0
```
Creates a boolean/checkbox property with default value of 0 (false).

### Datetime property
```bash
wheels generate property user column-name=lastloggedin data-type=datetime
```
Creates a datetime property on the User model.

### Decimal property with precision
```bash
wheels generate property product column-name=price data-type=decimal precision=10 scale=2
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
`app/migrator/migrations/[timestamp]_add_properties_to_[model].cfc`:

```cfc
component extends="wheels.migrator.Migration" hint="Add properties to product" {

    function up() {
        transaction {
            addColumn(table="products", columnName="sku", columnType="string", limit=50, allowNull=false);
            addColumn(table="products", columnName="price", columnType="decimal", precision=10, scale=2, allowNull=false, default=0.00);
            addColumn(table="products", columnName="stock", columnType="integer", allowNull=true, default=0);
            
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
wheels dbmigrate latest

# Generate property tests
wheels generate test model user

# Run tests
wheels test
```

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels dbmigrate create column](../database/dbmigrate-create-column.md) - Create columns
- [wheels generate test](test.md) - Generate tests