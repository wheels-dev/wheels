# wheels generate resource

Generate a complete RESTful resource with model, controller, views, and routes.

## Synopsis

```bash
wheels generate resource [name] [properties] [options]
wheels g resource [name] [properties] [options]
```

## Description

The `wheels generate resource` command creates a complete RESTful resource including model, controller with all CRUD actions, views, routes, and optionally database migrations and tests. It's a comprehensive generator that sets up everything needed for a functioning resource.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Resource name (singular) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--api` | Generate API-only resource (no views) | `false` |
| `--tests` | Generate associated tests | `true` |
| `--migration` | Generate database migration | `true` |
| `belongs-to` | Parent model relationships (comma-separated) | |
| `has-many` | Child model relationships (comma-separated) | |
| `attributes` | Model attributes (name:type,email:string) | |
| `--open` | Open generated files | `false` |
| `--scaffold` | Generate with full CRUD operations | `true` |

## Examples

### Basic Resource
```bash
wheels generate resource product attributes="name:string,price:float,description:text"
```

Generates:
- Model: `/models/Product.cfc`
- Controller: `/controllers/Products.cfc`
- Views: `/views/products/` (index, show, new, edit, _form)
- Route: `resources("products")` in `/config/routes.cfm`
- Migration: `/db/migrate/[timestamp]_create_products.cfc`
- Tests: `/tests/models/ProductTest.cfc`, `/tests/controllers/ProductsTest.cfc`

### API Resource
```bash
wheels generate resource product attributes="name:string,price:float" --api
```

Generates:
- Model: `/models/Product.cfc`
- Controller: `/controllers/api/Products.cfc` (JSON responses only)
- Route: `resources(name="products", except="new,edit")` in API namespace
- Migration: `/db/migrate/[timestamp]_create_products.cfc`
- Tests: API-focused test files

### Resource with Associations
```bash
wheels generate resource comment attributes="content:text,approved:boolean" belongs-to="post,user"
```

Generates nested structure with proper associations and routing.

## Generated Files

### Model
`/models/Product.cfc`:
```cfc
component extends="Model" {
    
    function init() {
        // Properties
        property(name="name", sql="name");
        property(name="price", sql="price");
        property(name="description", sql="description");
        
        // Validations
        validatesPresenceOf(properties="name,price");
        validatesNumericalityOf(property="price", greaterThan=0);
        validatesLengthOf(property="name", maximum=255);
        
        // Callbacks
        beforeSave("sanitizeInput");
    }
    
    private function sanitizeInput() {
        this.name = Trim(this.name);
        if (StructKeyExists(this, "description")) {
            this.description = Trim(this.description);
        }
    }
    
}
```

### Controller
`/controllers/Products.cfc`:
```cfc
component extends="Controller" {
    
    function init() {
        // Filters
        filters(through="findProduct", only="show,edit,update,delete");
    }
    
    function index() {
        products = model("Product").findAll(order="createdAt DESC");
    }
    
    function show() {
        // Product loaded by filter
    }
    
    function new() {
        product = model("Product").new();
    }
    
    function create() {
        product = model("Product").new(params.product);
        
        if (product.save()) {
            flashInsert(success="Product was created successfully.");
            redirectTo(route="product", key=product.id);
        } else {
            renderView(action="new");
        }
    }
    
    function edit() {
        // Product loaded by filter
    }
    
    function update() {
        if (product.update(params.product)) {
            flashInsert(success="Product was updated successfully.");
            redirectTo(route="product", key=product.id);
        } else {
            renderView(action="edit");
        }
    }
    
    function delete() {
        if (product.delete()) {
            flashInsert(success="Product was deleted successfully.");
        } else {
            flashInsert(error="Product could not be deleted.");
        }
        redirectTo(route="products");
    }
    
    // Filters
    private function findProduct() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found.");
            redirectTo(route="products");
        }
    }
    
}
```

### Views

`/views/products/index.cfm`:
```cfm
<h1>Products</h1>

<p>
    #linkTo(route="newProduct", text="New Product", class="btn btn-primary")#
</p>

<cfif products.recordCount>
    <table class="table table-striped">
        <thead>
            <tr>
                <th>Name</th>
                <th>Price</th>
                <th>Created</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfoutput query="products">
                <tr>
                    <td>#linkTo(route="product", key=products.id, text=products.name)#</td>
                    <td>#dollarFormat(products.price)#</td>
                    <td>#dateFormat(products.createdAt, "mmm dd, yyyy")#</td>
                    <td>
                        #linkTo(route="editProduct", key=products.id, text="Edit", class="btn btn-sm btn-secondary")#
                        #linkTo(route="product", key=products.id, text="Delete", method="delete", confirm="Are you sure?", class="btn btn-sm btn-danger")#
                    </td>
                </tr>
            </cfoutput>
        </tbody>
    </table>
<cfelse>
    <p class="alert alert-info">No products found. #linkTo(route="newProduct", text="Create one now")#!</p>
</cfif>
```

`/views/products/_form.cfm`:
```cfm
#errorMessagesFor("product")#

#startFormTag(route=formRoute, key=formKey, class="needs-validation")#
    
    <div class="mb-3">
        #textField(objectName="product", property="name", label="Product Name", class="form-control", required=true)#
    </div>
    
    <div class="mb-3">
        #numberField(objectName="product", property="price", label="Price", class="form-control", step="0.01", min="0", required=true)#
    </div>
    
    <div class="mb-3">
        #textArea(objectName="product", property="description", label="Description", class="form-control", rows=5)#
    </div>
    
    <div class="mb-3">
        #submitTag(value=submitValue, class="btn btn-primary")#
        #linkTo(route="products", text="Cancel", class="btn btn-secondary")#
    </div>
    
#endFormTag()#
```

### Migration
`/db/migrate/[timestamp]_create_products.cfc`:
```cfc
component extends="wheels.migrator.Migration" hint="Create products table" {
    
    function up() {
        transaction {
            createTable(name="products", force=true) {
                t.increments("id");
                t.string("name", limit=255, null=false);
                t.decimal("price", precision=10, scale=2, null=false);
                t.text("description");
                t.timestamps();
                t.index("name");
            };
        }
    }
    
    function down() {
        transaction {
            dropTable("products");
        }
    }
    
}
```

### Routes
Added to `/config/routes.cfm`:
```cfm
<cfset resources("products")>
```

## API Resource Generation

### API Controller
`/controllers/api/Products.cfc`:
```cfc
component extends="Controller" {
    
    function init() {
        provides("json");
        filters(through="findProduct", only="show,update,delete");
    }
    
    function index() {
        products = model("Product").findAll(
            order="createdAt DESC",
            page=params.page ?: 1,
            perPage=params.perPage ?: 25
        );
        
        renderWith({
            data: products,
            meta: {
                page: products.currentPage,
                totalPages: products.totalPages,
                totalRecords: products.totalRecords
            }
        });
    }
    
    function show() {
        renderWith(product);
    }
    
    function create() {
        product = model("Product").new(params.product);
        
        if (product.save()) {
            renderWith(data=product, status=201);
        } else {
            renderWith(
                data={errors: product.allErrors()},
                status=422
            );
        }
    }
    
    function update() {
        if (product.update(params.product)) {
            renderWith(product);
        } else {
            renderWith(
                data={errors: product.allErrors()},
                status=422
            );
        }
    }
    
    function delete() {
        if (product.delete()) {
            renderWith(data={message: "Product deleted successfully"});
        } else {
            renderWith(
                data={error: "Could not delete product"},
                status=400
            );
        }
    }
    
    private function findProduct() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            renderWith(
                data={error: "Product not found"},
                status=404
            );
        }
    }
    
}
```

## Nested Resources

### Generate Nested Resource
```bash
wheels generate resource review rating:integer comment:text parent=product
```

### Nested Model
Includes association:
```cfc
component extends="Model" {
    
    function init() {
        belongsTo("product");
        
        property(name="rating", sql="rating");
        property(name="comment", sql="comment");
        property(name="productId", sql="product_id");
        
        validatesPresenceOf(properties="rating,comment,productId");
        validatesNumericalityOf(property="rating", greaterThanOrEqualTo=1, lessThanOrEqualTo=5);
    }
    
}
```

### Nested Routes
```cfm
<cfset resources("products")>
    <cfset resources("reviews")>
</cfset>
```

## Property Types

### Supported Types
| Type | Database Type | Validation |
|------|--------------|------------|
| `string` | VARCHAR(255) | Length validation |
| `text` | TEXT | None by default |
| `integer` | INT | Numerical validation |
| `float` | DECIMAL | Numerical validation |
| `decimal` | DECIMAL | Numerical validation |
| `boolean` | BOOLEAN | Boolean validation |
| `date` | DATE | Date format validation |
| `datetime` | DATETIME | DateTime validation |
| `time` | TIME | Time validation |
| `binary` | BLOB | None |

### Property Options
```bash
wheels generate resource user \
  email:string:required:unique \
  age:integer:min=18:max=120 \
  bio:text:limit=1000 \
  isActive:boolean:default=true
```

## Advanced Options

### Skip Components
```bash
# Generate only model and migration
wheels generate resource product name:string --skip-controller --skip-views --skip-route

# Generate only controller and views
wheels generate resource product --skip-model --skip-migration
```

### Namespace Resources
```bash
wheels generate resource admin/product name:string namespace=admin
```

Creates:
- `/controllers/admin/Products.cfc`
- `/views/admin/products/`
- Namespaced routes

### Custom Templates
```bash
wheels generate resource product name:string template=custom
```

## Testing

### Generated Tests

Model Test (`/tests/models/ProductTest.cfc`):
```cfc
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        model("Product").deleteAll();
    }
    
    function test_valid_product_saves() {
        product = model("Product").new(
            name="Test Product",
            price=19.99,
            description="Test description"
        );
        
        assert(product.save());
        assert(product.id > 0);
    }
    
    function test_requires_name() {
        product = model("Product").new(price=19.99);
        
        assert(!product.save());
        assert(ArrayLen(product.errorsOn("name")) > 0);
    }
    
    function test_requires_positive_price() {
        product = model("Product").new(name="Test", price=-10);
        
        assert(!product.save());
        assert(ArrayLen(product.errorsOn("price")) > 0);
    }
    
}
```

Controller Test (`/tests/controllers/ProductsTest.cfc`):
```cfc
component extends="wheels.Test" {
    
    function test_index_returns_products() {
        products = createProducts(3);
        
        result = processRequest(route="products", method="GET");
        
        assert(result.status == 200);
        assert(Find("Products", result.body));
        assert(FindNoCase(products[1].name, result.body));
    }
    
    function test_create_valid_product() {
        params = {
            product: {
                name: "New Product",
                price: 29.99,
                description: "New product description"
            }
        };
        
        result = processRequest(route="products", method="POST", params=params);
        
        assert(result.status == 302);
        assert(model("Product").count() == 1);
    }
    
}
```

## Best Practices

1. **Use singular names**: `product` not `products`
2. **Define all properties**: Include types and validations
3. **Add indexes**: For frequently queried fields
4. **Include tests**: Don't skip test generation
5. **Use namespaces**: For admin or API resources
6. **Follow conventions**: Stick to RESTful patterns

## Common Patterns

### Soft Delete Resource
```bash
wheels generate resource product name:string deletedAt:datetime:nullable
```

### Publishable Resource
```bash
wheels generate resource post title:string content:text publishedAt:datetime:nullable status:string:default=draft
```

### User-Owned Resource
```bash
wheels generate resource task title:string userId:integer:belongsTo=user completed:boolean:default=false
```

### Hierarchical Resource
```bash
wheels generate resource category name:string parentId:integer:nullable:belongsTo=category
```

## Customization

### Custom Resource Templates
Create in `~/.wheels/templates/resources/`:
```
custom-resource/
├── model.cfc
├── controller.cfc
├── views/
│   ├── index.cfm
│   ├── show.cfm
│   ├── new.cfm
│   ├── edit.cfm
│   └── _form.cfm
└── migration.cfc
```

### Template Variables
Available in templates:
- `${resourceName}` - Singular name
- `${resourceNamePlural}` - Plural name
- `${modelName}` - Model class name
- `${controllerName}` - Controller class name
- `${tableName}` - Database table name
- `${properties}` - Array of property definitions

## See Also

- [wheels scaffold](scaffold.md) - Interactive CRUD generation
- [wheels generate model](model.md) - Generate models only
- [wheels generate controller](controller.md) - Generate controllers only
- [wheels generate api-resource](api-resource.md) - Generate API resources
- [wheels generate route](route.md) - Generate routes only