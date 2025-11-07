# wheels generate scaffold

Generate complete CRUD scaffolding for a resource including model, controller, views, tests, and migration.

## Synopsis

```bash
wheels generate scaffold name [options]
wheels g scaffold name [options]
```

## Description

The `wheels scaffold` command generates a complete CRUD (Create, Read, Update, Delete) implementation including model, controller, views, tests, and database migration. It's the fastest way to create a fully functional resource.

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate scaffold Product` (resource name)
- **Named parameters**: `name=value` (e.g., `name=Product`, `properties="name:string"`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--api` equals `api=true`)
- **Flag with value**: `--flag=value` (e.g., `--properties="name:string"`)

**Parameter Mixing Rules:**

**ALLOWED:**
- All positional: `wheels generate scaffold Product`
- All named: `name=Product properties="name:string"`
- Positional + flags: `wheels generate scaffold Product --api --migrate`

**NOT ALLOWED:**
- Positional + named: `wheels generate scaffold Product properties="name:string"` (causes error)

**Recommendation:** Use positional for resource name, flags for options: `wheels generate scaffold Product --properties="name:string" --api --migrate`

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Resource name (singular) | Required |

## Options

| Option | Description | Example | Default |
|--------|-------------|---------|---------|
| `--properties` | Model properties (format: name:type,name2:type2) | `--properties="name:string,price:decimal"` | |
| `--belongsTo` | Parent model relationships (comma-separated) | `--belongsTo=User,Category` | |
| `--hasMany` | Child model relationships (comma-separated) | `--hasMany=orders,comments` | |
| `--api` | Generate API-only scaffold (no views) | `--api=true` or `--api` | `false` |
| `--tests` | Generate test files | `--tests=false` | `true` |
| `--migrate` | Run migrations after scaffolding | `--migrate=true` or `--migrate` | `false` |
| `--force` | Overwrite existing files | `--force=true` or `--force` | `false` |

## Examples

### Basic Scaffold Examples

```bash
# Basic scaffold
wheels generate scaffold Product

# With properties
wheels generate scaffold Product --properties="name:string,price:decimal,stock:integer"

# With associations
wheels generate scaffold Order --properties="total:decimal,status:string" --belongsTo=User --hasMany=orderItems

# API-only scaffold (no views)
wheels generate scaffold Product --api --properties="name:string,price:decimal"

# With auto-migration
wheels generate scaffold Category --properties="name:string" --migrate
```

### Advanced Examples

```bash
# Complete e-commerce product
wheels generate scaffold Product --properties="name:string,description:text,price:decimal,inStock:boolean" --belongsTo=Category --hasMany=orderItems,reviews --migrate

# Blog system
wheels generate scaffold Post --properties="title:string,content:text,published:boolean" --belongsTo=User --hasMany=comments --api
```

### Parameter Details

**Properties Format:**
- Format: `--properties="name:type,name2:type2"`
- Types: `string`, `text`, `integer`, `decimal`, `boolean`, `date`, `datetime`, `time`
- Always use quotes around the entire properties string

**Associations:**
- `--belongsTo=Model1,Model2` (PascalCase parent models)
- `--hasMany=model1,model2` (camelCase plural child models)

**Resource Name:**
- Must be singular (e.g., `Product`, not `Products`)
- PascalCase recommended (e.g., `OrderItem`, `UserProfile`)

## What Gets Generated

### Standard Scaffold

1. **Model** (`/models/Product.cfc`) - Properties, validations, associations
2. **Controller** (`/controllers/Products.cfc`) - All CRUD actions (index, show, new, create, edit, update, delete)
3. **Views** (`/views/products/`) - index, show, new, edit, _form partial
4. **Migration** (`/app/migrator/migrations/[timestamp]_create_products.cfc`) - Table creation with indexes
5. **Tests** - Model, controller, and integration tests (if `--tests=true`)

### API Scaffold

1. **Model** - Same as standard
2. **API Controller** - JSON responses only, no views
3. **Migration** - Same as standard
4. **API Tests** - JSON response tests

## Generated Code Structure

For `wheels scaffold Product --properties="name:string,price:decimal"`:

**Model:** Properties with validations (presence, uniqueness, numerical)
**Controller:** Full CRUD actions with flash messages and error handling
**Views:** List, show, new/edit forms with proper encoding and form helpers
**Migration:** Table with columns, timestamps, and indexes

Run the command to see the complete generated code.

## Routes Configuration

Add to `/config/routes.cfm`:

```cfm
<cfset resources("products")>
```

This creates all RESTful routes (index, new, create, show, edit, update, delete).

## Post-Scaffold Steps

1. **Run migration** (if not using `--migrate`): `wheels dbmigrate latest`
2. **Add routes** to `/config/routes.cfm`: `<cfset resources("products")>`
3. **Reload application**: `wheels reload`
4. **Test**: Visit `/products` and test CRUD operations

## Common Customizations

**Search:**
```cfc
function index() {
    products = StructKeyExists(params, "search")
        ? model("Product").findAll(where="name LIKE :search", params={search: "%#params.search#%"})
        : model("Product").findAll();
}
```

**Pagination:**
```cfc
products = model("Product").findAll(page=params.page ?: 1, perPage=20);
```

**Authentication:**
```cfc
function init() {
    filters(through="authenticate", except="index,show");
}
```

## Template Customization

Customize generated code by overriding templates:

1. Copy templates from `/cli/templates/` to `/app/snippets/`
2. Modify templates to match your project style
3. CLI uses your custom templates automatically

**Available Templates:**
- `crud/index.txt`, `crud/show.txt`, `crud/new.txt`, `crud/edit.txt`, `crud/_form.txt`
- `ModelContent.txt`, `ControllerContent.txt`

**Template Placeholders:**
- `|ObjectNameSingular|`, `|ObjectNamePlural|` - Lowercase names
- `|ObjectNameSingularC|`, `|ObjectNamePluralC|` - Capitalized names
- `|FormFields|` - Generated form fields

## Troubleshooting

### Common Issues

#### Parameter Syntax Errors

❌ **Wrong:**
```bash
wheels generate scaffold Product properties="name:string"    # Positional + named (ERROR)
wheels generate scaffold Product --properties=name:string    # Missing quotes
wheels generate scaffold Comment --belongsTo=product         # Wrong case (should be Product)
```

✅ **Correct:**
```bash
wheels generate scaffold Product --properties="name:string,price:decimal"
wheels generate scaffold Comment --belongsTo=Product --hasMany=replies
```

**Rules:**
- Always use quotes around properties: `--properties="name:string"`
- Use PascalCase for belongsTo: `--belongsTo=User`
- Use camelCase plural for hasMany: `--hasMany=posts,comments`
- Never mix positional and named parameters

#### File Generation Issues

**Problem:** Files not created or partially generated

**Solutions:**
- Check directory permissions: `ls -la app/models app/controllers`
- Use `--force` to overwrite existing files
- Use singular PascalCase names (e.g., `Product`, not `products` or `product-item`)

#### Migration Issues

**Problem:** Migrations not created or contain errors

**Solutions:**
- Use valid property types: `string`, `text`, `integer`, `decimal`, `boolean`, `date`, `datetime`
- Check generated migration: `ls app/migrator/migrations/*create*`
- Foreign keys are auto-generated for associations

#### Route Issues

**Problem:** Routes not working

**Solution:** Add resources to `/config/routes.cfm`:
```cfm
<cfscript>
mapper()
    .resources("products")
    .wildcard()
.end();
</cfscript>
```

### Validation Checklist

**Before scaffolding:**
1. Verify Wheels directory structure exists
2. Check for naming conflicts
3. Plan properties and associations

**After scaffolding:**
1. Check files were created: `ls app/models/ app/controllers/ app/views/`
2. Run migrations: `wheels dbmigrate latest`
3. Add routes to `routes.cfm`
4. Test at `/products`

## Best Practices

1. **Plan First**: Define properties, associations, and validations before scaffolding
2. **Start Simple**: Begin with basic properties, add complexity later
3. **Use Templates**: Customize templates in `/app/snippets/` to match your project standards
4. **Test Immediately**: Run generated tests and visit the scaffold in browser
5. **Security**: Add authentication/authorization filters after generation
6. **Incremental**: Scaffold one resource at a time, test, then move to the next

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate resource](resource.md) - Generate REST resources
- [wheels dbmigrate latest](../database/dbmigrate-latest.md) - Run migrations