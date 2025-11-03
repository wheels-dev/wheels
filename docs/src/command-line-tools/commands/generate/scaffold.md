# wheels generate scaffold

Generate complete CRUD scaffolding for a resource including model, controller, views, tests, and migration.

## Synopsis

```bash
wheels generate scaffold name
#can also be used as:
wheels g scaffold name

# With properties and options
wheels generate scaffold Product --properties="name:string,price:decimal"
wheels generate scaffold Comment --belongsTo=Product --api=true
```

## Description

The `wheels scaffold` command generates a complete CRUD (Create, Read, Update, Delete) implementation including model, controller, views, tests, and database migration. It's the fastest way to create a fully functional resource.

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate scaffold Product` (resource name)
- **Named parameters**: `name=value` (e.g., `name=Product`, `properties="name:string,price:decimal"`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--api` equals `api=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--properties="name:string"`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- All positional: `wheels generate scaffold Product`
- All named: `name=Product properties="name:string"`
- Positional + flags: `wheels generate scaffold Product --api --migrate`

❌ **NOT ALLOWED:**
- Positional + named: `wheels generate scaffold Product properties="name:string"` (causes error)

**Recommendation:** Use positional for resource name, flags for options: `wheels generate scaffold Product --properties="name:string" --api --migrate`

**Note:** Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

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

### Basic scaffold
```bash
wheels generate scaffold Product
```

### Scaffold with properties
```bash
wheels generate scaffold Product --properties="name:string,price:decimal,stock:integer"
```

### Scaffold with associations
```bash
wheels scaffold Order --properties="total:decimal,status:string" \
  --belongsTo=User --hasMany=orderItems
```

### API scaffold
```bash
wheels generate scaffold Product --api=true --properties="name:string,price:decimal"
```

### Scaffold with auto-migration
```bash
wheels generate scaffold Category --properties="name:string" --migrate=true
```

## Detailed Parameter Usage

### Command Line Parameter Formats

Building on CommandBox's parameter syntax, Wheels scaffold generation supports:

#### 1. Positional Parameters (Basic)
```bash
wheels generate scaffold Product          # Resource name (required)
wheels g scaffold User                    # Short alias with resource name
```

#### 2. Named Parameters with Flags (Recommended)
```bash
wheels generate scaffold Product --properties="name:string,price:decimal"
wheels generate scaffold Comment --belongsTo=Product --properties="content:text"
wheels generate scaffold User --hasMany=posts,comments --api=true
```

#### 3. Positional + Flags (Valid)
```bash
wheels generate scaffold Order --properties="total:decimal" --belongsTo=User --migrate
wheels g scaffold Product --properties="name:string" --api --tests=false --force
```

### Parameter Validation Rules

#### Resource Name (Required)
- **Format**: Singular noun (e.g., `Product`, `User`, `Comment`)
- **Conventions**: PascalCase recommended
- **Examples**: `Product`, `OrderItem`, `UserProfile`

#### Properties Parameter
- **Format**: `--properties="name:type,name2:type2,name3:type3"`
- **Types**: `string`, `text`, `integer`, `decimal`, `boolean`, `date`, `datetime`, `time`
- **Separator**: Comma (`,`) between properties
- **Quotes**: Always use quotes around the entire properties string

#### Association Parameters
- **belongsTo**: `--belongsTo=Model1,Model2` (comma-separated parent models)
- **hasMany**: `--hasMany=model1,model2` (comma-separated child models - lowercase plural)
- **Format**: Model names in PascalCase for belongsTo, camelCase plural for hasMany

#### Boolean Parameters
- **Short flags**: `--api`, `--migrate`, `--force` (equals `true`)
- **Explicit**: `--api=true`, `--tests=false`, `--migrate=true`
- **Default values**: `api=false`, `tests=true`, `migrate=false`, `force=false`

### Parameter Examples by Type

#### String Parameters (Properties)
```bash
# Basic properties
wheels generate scaffold Product --properties="name:string,description:text"

# Complex properties with various types
wheels generate scaffold Order --properties="total:decimal,status:string,orderDate:datetime,shipped:boolean"

# Properties with foreign keys (use belongsTo instead)
wheels generate scaffold Comment --properties="content:text,rating:integer" --belongsTo=Product,User
```

#### Association Parameters
```bash
# Single associations
wheels generate scaffold Post --belongsTo=User
wheels generate scaffold User --hasMany=posts

# Multiple associations
wheels generate scaffold Order --belongsTo=User,ShippingAddress --hasMany=orderItems,payments
wheels generate scaffold Product --hasMany=reviews,orderItems,images
```

#### Boolean Flag Parameters
```bash
# API-only scaffold (no views)
wheels generate scaffold Product --api --properties="name:string,price:decimal"

# Skip tests generation
wheels generate scaffold Comment --tests=false --belongsTo=Post

# Force overwrite existing files
wheels generate scaffold User --force --properties="name:string,email:string"

# Auto-run migrations
wheels generate scaffold Category --migrate --properties="name:string,slug:string"
```

#### Combined Parameter Examples
```bash
# Complete e-commerce product
wheels generate scaffold Product \
  --properties="name:string,description:text,price:decimal,inStock:boolean,sku:string" \
  --belongsTo=Category \
  --hasMany=orderItems,reviews \
  --migrate

# Blog post with API
wheels generate scaffold Post \
  --properties="title:string,content:text,published:boolean,publishedAt:datetime" \
  --belongsTo=User \
  --hasMany=comments \
  --api=true \
  --migrate

# User profile with relationships
wheels generate scaffold User \
  --properties="firstName:string,lastName:string,email:string,active:boolean" \
  --hasMany=posts,comments,orders \
  --tests=true \
  --migrate
```

### Common Parameter Mistakes

❌ **Wrong property format:**
```bash
wheels generate scaffold Product properties=name:string,price:decimal  # Missing --
wheels generate scaffold Product --properties=name string price decimal  # Wrong separator
```

❌ **Wrong association format:**
```bash
wheels generate scaffold Comment belongs-to=Product  # Wrong parameter name
wheels generate scaffold Order --belongsTo=user      # Should be User (PascalCase)
wheels generate scaffold User --hasMany=Posts        # Should be posts (camelCase plural)
```

❌ **Wrong boolean format:**
```bash
wheels generate scaffold Product api=true            # Missing --
wheels generate scaffold Product --api true          # Should be --api=true or --api
```

❌ **Mixing positional and named parameters:**
```bash
wheels generate scaffold Product properties="name:string"     # Positional + named (ERROR)
wheels generate scaffold name=Product --api=true             # Named + flag (inconsistent)
```

✅ **Correct formats:**
```bash
wheels generate scaffold Product --properties="name:string,price:decimal"  # Positional + flags
wheels generate scaffold Comment --belongsTo=Product                       # Positional + flags
wheels generate scaffold User --hasMany=posts,comments                     # Positional + flags
wheels generate scaffold Product --api=true    # or just --api             # Positional + flags

# OR all named parameters:
wheels generate scaffold name=Product properties="name:string"             # All named
```

### Advanced Parameter Usage

#### Complex Data Types
```bash
# Different column types
wheels generate scaffold Event --properties="name:string,description:text,eventDate:date,startTime:time,duration:integer,price:decimal,active:boolean"

# Text fields for large content
wheels generate scaffold Article --properties="title:string,summary:text,content:text,publishedAt:datetime"

# Decimal fields with precision
wheels generate scaffold Product --properties="price:decimal,weight:decimal,dimensions:string"
```

#### Multi-level Associations
```bash
# Blog system
wheels generate scaffold User --hasMany=posts,comments
wheels generate scaffold Post --belongsTo=User --hasMany=comments
wheels generate scaffold Comment --belongsTo=User,Post

# E-commerce system
wheels generate scaffold Category --hasMany=products
wheels generate scaffold Product --belongsTo=Category --hasMany=orderItems,reviews
wheels generate scaffold Order --belongsTo=User --hasMany=orderItems
wheels generate scaffold OrderItem --belongsTo=Order,Product
```

#### API-First Development
```bash
# API-only resources
wheels generate scaffold ApiUser --api --properties="name:string,email:string,apiKey:string"
wheels generate scaffold ApiToken --api --belongsTo=ApiUser --properties="token:string,expiresAt:datetime"

# Mobile app backend
wheels generate scaffold MobileUser --api --properties="deviceId:string,pushToken:string"
wheels generate scaffold Notification --api --belongsTo=MobileUser --properties="message:text,sent:boolean"
```

### Parameter Processing Details

#### Command Line Processing
1. **Resource Name**: First positional argument, converted to proper case variants
2. **Properties**: Parsed into individual property definitions with types
3. **Associations**: Split by comma and processed into relationship configurations
4. **Boolean Flags**: Converted to boolean values for scaffold options
5. **Validation**: Checked for required parameters and valid formats

#### Internal Parameter Handling
1. **reconstructArgs()**: Processes CommandBox parameter format
2. **validateScaffold()**: Validates resource name and checks for conflicts
3. **generateScaffold()**: Coordinates generation of all components
4. **Template Processing**: Applies parameters to code generation templates
5. **File Creation**: Creates model, controller, views, tests, and migration

## What Gets Generated

### Standard Scaffold

1. **Model** (`/models/Product.cfc`)
   - Properties and validations
   - Associations
   - Business logic

2. **Controller** (`/controllers/Products.cfc`)
   - All CRUD actions
   - Flash messages
   - Error handling

3. **Views** (`/views/products/`)
   - `index.cfm` - List all records
   - `show.cfm` - Display single record
   - `new.cfm` - New record form
   - `edit.cfm` - Edit record form
   - `_form.cfm` - Shared form partial

4. **Migration** (`/app/migrator/migrations/[timestamp]_create_products.cfc`)
   - Create table
   - Add indexes
   - Define columns

5. **Tests** (if enabled)
   - Model tests
   - Controller tests
   - Integration tests

### API Scaffold

1. **Model** - Same as standard
2. **API Controller** - JSON responses only
3. **Migration** - Same as standard
4. **API Tests** - JSON response tests
5. **No Views** - API doesn't need views

## Generated Files Example

For `wheels scaffold Product --properties="name:string,price:decimal,stock:integer"`:

### Model: `/models/Product.cfc`
```cfc
component extends="Model" {

    function init() {
        // Properties
        property(name="name", label="Product Name");
        property(name="price", label="Price");
        property(name="stock", label="Stock Quantity");
        
        // Validations
        validatesPresenceOf("name,price,stock");
        validatesUniquenessOf("name");
        validatesNumericalityOf("price", greaterThan=0);
        validatesNumericalityOf("stock", onlyInteger=true, greaterThanOrEqualTo=0);
    }

}
```

### Controller: `/controllers/Products.cfc`
```cfc
component extends="Controller" {

    function init() {
        // Filters
    }

    function index() {
        products = model("Product").findAll(order="name");
    }

    function show() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found.");
            redirectTo(action="index");
        }
    }

    function new() {
        product = model("Product").new();
    }

    function create() {
        product = model("Product").new(params.product);
        if (product.save()) {
            flashInsert(success="Product was created successfully.");
            redirectTo(action="index");
        } else {
            flashInsert(error="There was an error creating the product.");
            renderView(action="new");
        }
    }

    function edit() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found.");
            redirectTo(action="index");
        }
    }

    function update() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.update(params.product)) {
            flashInsert(success="Product was updated successfully.");
            redirectTo(action="index");
        } else {
            flashInsert(error="There was an error updating the product.");
            renderView(action="edit");
        }
    }

    function delete() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.delete()) {
            flashInsert(success="Product was deleted successfully.");
        } else {
            flashInsert(error="Product could not be deleted.");
        }
        redirectTo(action="index");
    }

}
```

### View: `/views/products/index.cfm`
```cfm
<h1>Products</h1>

#flashMessages()#

<p>#linkTo(text="New Product", action="new", class="btn btn-primary")#</p>

<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <cfloop query="products">
            <tr>
                <td>#encodeForHtml(products.name)#</td>
                <td>#dollarFormat(products.price)#</td>
                <td>#products.stock#</td>
                <td>
                    #linkTo(text="Show", action="show", key=products.id)#
                    #linkTo(text="Edit", action="edit", key=products.id)#
                    #linkTo(text="Delete", action="delete", key=products.id, 
                            method="delete", confirm="Are you sure?")#
                </td>
            </tr>
        </cfloop>
    </tbody>
</table>
```

### Form Partial: `/views/products/_form.cfm`
```cfm
#errorMessagesFor("product")#

#textField(objectName="product", property="name", label="Product Name")#
#textField(objectName="product", property="price", label="Price")#
#textField(objectName="product", property="stock", label="Stock Quantity")#
```

### Migration: `/app/migrator/migrations/[timestamp]_create_products.cfc`
```cfc
component extends="wheels.migrator.Migration" {

    function up() {
        transaction {
            t = createTable("products");
            t.string("name");
            t.decimal(columnNames="price", precision=10, scale=2);
            t.integer("stock");
            t.timestamps();
            t.create();
            
            addIndex(table="products", columnNames="name", unique=true);
        }
    }

    function down() {
        transaction {
            dropTable("products");
        }
    }

}
```

## Routes Configuration

Add to `/config/routes.cfm`:

```cfm
<cfset resources("products")>
```

This creates all RESTful routes:
- GET /products - index
- GET /products/new - new
- POST /products - create
- GET /products/[key] - show
- GET /products/[key]/edit - edit
- PUT/PATCH /products/[key] - update
- DELETE /products/[key] - delete

## Post-Scaffold Steps

1. **Run migration** (if not using `--migrate`):
   ```bash
   wheels dbmigrate latest
   ```

2. **Add routes** to `/config/routes.cfm`:
   ```cfm
   <cfset resources("products")>
   ```

3. **Restart application**:
   ```bash
   wheels reload
   ```

4. **Test the scaffold**:
   - Visit `/products` to see the index
   - Create, edit, and delete records
   - Run generated tests

## Customization

### Adding Search
In controller's `index()`:
```cfc
function index() {
    if (StructKeyExists(params, "search")) {
        products = model("Product").findAll(
            where="name LIKE :search",
            params={search: "%#params.search#%"}
        );
    } else {
        products = model("Product").findAll();
    }
}
```

### Adding Pagination
```cfc
function index() {
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=20,
        order="createdAt DESC"
    );
}
```

### Adding Filters
```cfc
function init() {
    filters(through="authenticate", except="index,show");
}
```

## Template Customization

The scaffold command uses templates to generate code. You can customize these templates to match your project's coding standards and markup preferences.

### Template Override System

The CLI uses a template override system that allows you to customize the generated code:

1. **CLI Templates** - Default templates are located in the CLI module at `/cli/templates/`
2. **App Templates** - Custom templates in your application at `/app/snippets/` **override** the CLI templates

This means you can modify the generated code structure by creating your own templates in the `/app/snippets/` directory.

### How It Works

When generating code, the CLI looks for templates in this order:
1. First checks `/app/snippets/[template-name]`
2. Falls back to `/cli/templates/[template-name]` if not found in app

### Customizing Templates

To customize scaffold output:

1. **Copy the template** you want to customize from `/cli/templates/` to `/app/snippets/`
2. **Modify the template** to match your project's needs
3. **Run scaffold** - it will use your custom template

Example for customizing the form template:
```bash
# Create the crud directory in your app
mkdir -p app/snippets/crud

# Copy the form template
cp /path/to/wheels/cli/templates/crud/_form.txt app/snippets/crud/

# Edit the template to match your markup
# The CLI will now use your custom template
```

### Available Templates

Templates used by scaffold command:
- `crud/index.txt` - Index/list view
- `crud/show.txt` - Show single record view  
- `crud/new.txt` - New record form view
- `crud/edit.txt` - Edit record form view
- `crud/_form.txt` - Form partial shared by new/edit
- `ModelContent.txt` - Model file structure
- `ControllerContent.txt` - Controller file structure

### Template Placeholders

Templates use placeholders that get replaced during generation:
- `|ObjectNameSingular|` - Lowercase singular name (e.g., "product")
- `|ObjectNamePlural|` - Lowercase plural name (e.g., "products")
- `|ObjectNameSingularC|` - Capitalized singular name (e.g., "Product")
- `|ObjectNamePluralC|` - Capitalized plural name (e.g., "Products")
- `|FormFields|` - Generated form fields based on properties
- `<!--- CLI-Appends-Here --->` - Marker for future CLI additions

## Troubleshooting

### Common Issues and Solutions

#### 1. Parameter Syntax Errors

**Issue**: `"Missing argument"`, `"positional and named parameters"`, or parameter parsing errors

❌ **Incorrect:**
```bash
wheels generate scaffold Product properties=name:string,price:decimal  # Missing --
wheels generate scaffold Comment belongs-to=Product                    # Wrong parameter name
wheels generate scaffold User api=true                                 # Missing --
wheels generate scaffold Product properties="name:string"              # Positional + named (ERROR)
```

✅ **Correct:**
```bash
wheels generate scaffold Product --properties="name:string,price:decimal"  # Positional + flags
wheels generate scaffold Comment --belongsTo=Product                      # Positional + flags
wheels generate scaffold User --api=true                                  # Positional + flags
wheels generate scaffold name=Product properties="name:string"            # All named
```

**Solution**:
- Use `--flag=value` format with proper parameter names and quotes for complex values
- **Never mix positional and named parameters** - use either all named (`name=value`) or positional with flags (`Product --flag`)

#### 2. Association Parameter Issues

**Issue**: Relationships not generated correctly

❌ **Common Mistakes:**
```bash
wheels generate scaffold Comment --belongsTo=product    # Lowercase, should be Product
wheels generate scaffold User --hasMany=Posts           # Should be posts (lowercase plural)
wheels generate scaffold Order --belongsTo=user,User    # Inconsistent case
```

✅ **Correct Usage:**
```bash
wheels generate scaffold Comment --belongsTo=Product    # PascalCase for belongsTo
wheels generate scaffold User --hasMany=posts           # camelCase plural for hasMany
wheels generate scaffold Order --belongsTo=User         # Consistent PascalCase
```

#### 3. Properties Format Issues

**Issue**: Properties not parsed or generated incorrectly

❌ **Problematic:**
```bash
# Missing quotes around properties
wheels generate scaffold Product --properties=name:string,price:decimal

# Wrong separator
wheels generate scaffold Product --properties="name string, price decimal"

# Invalid property types
wheels generate scaffold Product --properties="name:varchar,price:money"
```

✅ **Solutions:**
```bash
# Always quote properties
wheels generate scaffold Product --properties="name:string,price:decimal"

# Use colon separator and comma between properties
wheels generate scaffold Product --properties="name:string,price:decimal,stock:integer"

# Use valid Wheels property types
wheels generate scaffold Product --properties="name:string,price:decimal,description:text,active:boolean"
```

#### 4. File Generation Issues

**Issue**: Files not created or partially generated

**Possible Causes:**
- Insufficient permissions in target directories
- Existing files blocking generation (use `--force`)
- Invalid resource names
- Template processing errors

**Solutions:**
```bash
# Check directory permissions
ls -la app/models app/controllers app/views

# Force overwrite existing files
wheels generate scaffold Product --force --properties="name:string"

# Use valid resource names (singular, PascalCase)
wheels generate scaffold ProductCategory  # ✅ Good
wheels generate scaffold product-item     # ❌ Invalid characters
```

#### 5. Migration Issues

**Issue**: Migrations not created or contain errors

**Common Problems:**
- Properties with invalid SQL types
- Association foreign keys missing
- Migration syntax errors

**Solutions:**
```bash
# Check generated migration file
ls app/migrator/migrations/*create*

# Use valid property types that map to SQL
wheels generate scaffold Product --properties="name:string,price:decimal,inStock:boolean"

# For associations, foreign keys are auto-generated
wheels generate scaffold Comment --belongsTo=Product  # Creates productId foreign key
```

#### 6. Route Integration Issues

**Issue**: Generated routes not working

**Problem**: Routes not added to routes.cfm or placed incorrectly

**Solution:**
```cfm
<!-- Check routes.cfm for resources route -->
<cfscript>
mapper()
    .resources("products")    // Added by scaffold
    // CLI-Appends-Here
    .wildcard()
    .root(to="home##index")
.end();
</cfscript>
```

### Validation and Testing

#### Pre-Generation Checklist
Before generating scaffolds:

```bash
# 1. Verify Wheels app directory
ls config/routes.cfm app/models app/controllers app/views

# 2. Check for naming conflicts
ls app/models/Product.cfc      # Should not exist (or use --force)
ls app/controllers/Products.cfc

# 3. Plan your associations
# Know which models depend on others
```

#### Post-Generation Validation
After scaffolding:

```bash
# 1. Check all files were created
ls app/models/Product.cfc
ls app/controllers/Products.cfc
ls app/views/products/
ls app/migrator/migrations/*products*

# 2. Run migrations
wheels dbmigrate up

# 3. Test the scaffold
# Start server and visit /products
server start
```

#### Testing Generated Code

```bash
# 1. Run generated tests
wheels test

# 2. Manual testing
# Visit each CRUD action:
# GET    /products        (index)
# GET    /products/new    (new)
# POST   /products        (create)
# GET    /products/1      (show)
# GET    /products/1/edit (edit)
# PUT    /products/1      (update)
# DELETE /products/1      (delete)
```

### Error Reference

#### Common Error Messages

**"Cannot scaffold '[name]':"**
- **Cause**: Resource name validation failed or conflicts exist
- **Solution**: Use singular, valid identifier name and check for existing files

**"Scaffolding failed!"**
- **Cause**: Template processing or file creation error
- **Solution**: Check file permissions and template syntax

**"Missing argument name"**
- **Cause**: Parameter syntax error in command
- **Solution**: Use proper `--flag=value` format

### Best Practices for Avoiding Issues

#### 1. Parameter Planning
```bash
# Plan your scaffold before running
# 1. Resource name (singular, PascalCase)
# 2. Properties (all needed fields)
# 3. Associations (belongsTo and hasMany)
# 4. Options (api, migrate, tests)

# Example planning:
# Product: name:string, price:decimal, description:text, active:boolean
# Belongs to Category, has many OrderItems and Reviews
wheels generate scaffold Product \
  --properties="name:string,price:decimal,description:text,active:boolean" \
  --belongsTo=Category \
  --hasMany=orderItems,reviews \
  --migrate
```

#### 2. Incremental Development
```bash
# Start simple, add complexity
# 1. Basic scaffold first
wheels generate scaffold Product --properties="name:string"

# 2. Add associations later if needed
# (modify generated files manually or re-scaffold with --force)
```

#### 3. Template Customization
```bash
# Customize templates before scaffolding
# 1. Copy templates to app/snippets/
mkdir -p app/snippets/crud
cp /path/to/cli/templates/crud/* app/snippets/crud/

# 2. Modify templates to match project style
# 3. Run scaffold - uses custom templates
```

## Best Practices

1. **Properties**: Define all needed properties upfront
2. **Associations**: Include relationships in initial scaffold
3. **Validation**: Add custom validations after generation
4. **Testing**: Always generate and run tests
5. **Routes**: Use RESTful resources when possible
6. **Security**: Add authentication/authorization
7. **Templates**: Customize templates in `/app/snippets/` to match your project standards
8. **Planning**: Design your data model before scaffolding
9. **Incremental**: Start simple, add complexity gradually

## Comparison with Individual Generators

Scaffold generates everything at once:

```bash
# Scaffold does all of this:
wheels generate model product properties="name:string,price:decimal"
wheels generate controller products --rest
wheels generate view products index,show,new,edit,_form
wheels generate test model product
wheels generate test controller products
wheels dbmigrate create table products
```

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate resource](resource.md) - Generate REST resources
- [wheels dbmigrate latest](../database/dbmigrate-latest.md) - Run migrations