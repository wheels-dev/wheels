# wheels scaffold
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*


Generate complete CRUD scaffolding for a resource.

## Synopsis

```bash
wheels generate scaffold name=[resourceName] [options]
```
## Alias

```bash
wheels g scaffold name=[resourceName] [options]
```

## Description

The `wheels scaffold` command generates a complete CRUD (Create, Read, Update, Delete) implementation including model, controller, views, tests, and database migration. It's the fastest way to create a fully functional resource.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Resource name (singular) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `properties` | Model properties (format: name:type,name2:type2) | |
| `belongs-to` | Parent model relationships (comma-separated) | |
| `has-many` | Child model relationships (comma-separated) | |
| `--api` | Generate API-only scaffold (no views) | `false` |
| `--tests` | Generate test files | `true` |
| `--migrate` | Run migrations after scaffolding | `false` |
| `--force` | Overwrite existing files | `false` |

## Examples

### Basic scaffold
```bash
wheels generate scaffold name=product
```

### Scaffold with properties
```bash
wheels generate scaffold name=product properties=name:string,price:decimal,stock:integer
```

### Scaffold with associations
```bash
wheels scaffold name=order properties=total:decimal,status:string \
  belongsTo=user hasMany=orderItems
```

### API scaffold
```bash
wheels generate scaffold name=product api=true properties=name:string,price:decimal
```

### Scaffold with auto-migration
```bash
wheels generate scaffold name=category properties=name:string migrate=true
```

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

For `wheels scaffold name=product properties=name:string,price:decimal,stock:integer`:

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

## Best Practices

1. **Properties**: Define all needed properties upfront
2. **Associations**: Include relationships in initial scaffold
3. **Validation**: Add custom validations after generation
4. **Testing**: Always generate and run tests
5. **Routes**: Use RESTful resources when possible
6. **Security**: Add authentication/authorization
7. **Templates**: Customize templates in `/app/snippets/` to match your project standards

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