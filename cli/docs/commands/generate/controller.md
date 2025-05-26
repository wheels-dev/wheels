# wheels generate controller

Generate a controller with actions and optional views.

## Synopsis

```bash
wheels generate controller [name] [actions] [options]
wheels g controller [name] [actions] [options]
```

## Description

The `wheels generate controller` command creates a new controller CFC file with specified actions and optionally generates corresponding view files. It supports both traditional and RESTful controller patterns.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Controller name (singular or plural) | Required |
| `actions` | Comma-separated list of actions | `index` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--rest` | Generate RESTful actions | `false` |
| `--api` | Generate API controller (no views) | `false` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Examples

### Basic controller
```bash
wheels generate controller products
```
Creates:
- `/controllers/Products.cfc` with `index` action
- `/views/products/index.cfm`

### Controller with multiple actions
```bash
wheels generate controller products index,show,new,create,edit,update,delete
```
Creates controller with all CRUD actions and corresponding views.

### RESTful controller
```bash
wheels generate controller products --rest
```
Automatically generates all RESTful actions:
- `index` - List all products
- `show` - Show single product
- `new` - New product form
- `create` - Create product
- `edit` - Edit product form
- `update` - Update product
- `delete` - Delete product

### API controller
```bash
wheels generate controller api/products --api
```
Creates:
- `/controllers/api/Products.cfc` with JSON responses
- No view files

### Custom actions
```bash
wheels generate controller reports dashboard,monthly,yearly,export
```

## Generated Code

### Basic Controller
```cfc
component extends="Controller" {

    function init() {
        // Constructor
    }

    function index() {
        products = model("Product").findAll();
    }

}
```

### RESTful Controller
```cfc
component extends="Controller" {

    function init() {
        // Constructor
    }

    function index() {
        products = model("Product").findAll();
    }

    function show() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
        }
    }

    function new() {
        product = model("Product").new();
    }

    function create() {
        product = model("Product").new(params.product);
        if (product.save()) {
            flashInsert(success="Product created successfully");
            redirectTo(action="index");
        } else {
            renderView(action="new");
        }
    }

    function edit() {
        product = model("Product").findByKey(params.key);
        if (!IsObject(product)) {
            flashInsert(error="Product not found");
            redirectTo(action="index");
        }
    }

    function update() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.update(params.product)) {
            flashInsert(success="Product updated successfully");
            redirectTo(action="index");
        } else {
            renderView(action="edit");
        }
    }

    function delete() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.delete()) {
            flashInsert(success="Product deleted successfully");
        } else {
            flashInsert(error="Could not delete product");
        }
        redirectTo(action="index");
    }

}
```

### API Controller
```cfc
component extends="Controller" {

    function init() {
        provides("json");
    }

    function index() {
        products = model("Product").findAll();
        renderWith(products);
    }

    function show() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product)) {
            renderWith(product);
        } else {
            renderWith({error: "Product not found"}, status=404);
        }
    }

    function create() {
        product = model("Product").new(params.product);
        if (product.save()) {
            renderWith(product, status=201);
        } else {
            renderWith({errors: product.allErrors()}, status=422);
        }
    }

    function update() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.update(params.product)) {
            renderWith(product);
        } else {
            renderWith({errors: product.allErrors()}, status=422);
        }
    }

    function delete() {
        product = model("Product").findByKey(params.key);
        if (IsObject(product) && product.delete()) {
            renderWith({message: "Product deleted"});
        } else {
            renderWith({error: "Could not delete"}, status=400);
        }
    }

}
```

## View Generation

Views are automatically generated for non-API controllers:

### index.cfm
```cfm
<h1>Products</h1>

<p>#linkTo(text="New Product", action="new")#</p>

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <cfloop query="products">
            <tr>
                <td>#products.name#</td>
                <td>
                    #linkTo(text="Show", action="show", key=products.id)#
                    #linkTo(text="Edit", action="edit", key=products.id)#
                    #linkTo(text="Delete", action="delete", key=products.id, method="delete", confirm="Are you sure?")#
                </td>
            </tr>
        </cfloop>
    </tbody>
</table>
```

## Naming Conventions

- **Controller names**: PascalCase, typically plural (Products, Users)
- **Action names**: camelCase (index, show, createProduct)
- **File locations**: 
  - Controllers: `/controllers/`
  - Nested: `/controllers/admin/Products.cfc`
  - Views: `/views/{controller}/`

## Routes Configuration

Add routes in `/config/routes.cfm`:

### Traditional Routes
```cfm
<cfset get(name="products", to="products##index")>
<cfset get(name="product", to="products##show")>
<cfset post(name="products", to="products##create")>
```

### RESTful Resources
```cfm
<cfset resources("products")>
```

### Nested Resources
```cfm
<cfset namespace("api")>
    <cfset resources("products")>
</cfset>
```

## Testing

Generate tests alongside controllers:
```bash
wheels generate controller products --rest
wheels generate test controller products
```

## Best Practices

1. Use plural names for resource controllers
2. Keep controllers focused on single resources
3. Use `--rest` for standard CRUD operations
4. Implement proper error handling
5. Add authentication in `init()` method
6. Use filters for common functionality

## Common Patterns

### Authentication Filter
```cfc
function init() {
    filters(through="authenticate", except="index,show");
}

private function authenticate() {
    if (!session.isLoggedIn) {
        redirectTo(controller="sessions", action="new");
    }
}
```

### Pagination
```cfc
function index() {
    products = model("Product").findAll(
        page=params.page ?: 1,
        perPage=25,
        order="createdAt DESC"
    );
}
```

### Search
```cfc
function index() {
    if (StructKeyExists(params, "q")) {
        products = model("Product").findAll(
            where="name LIKE :search OR description LIKE :search",
            params={search: "%#params.q#%"}
        );
    } else {
        products = model("Product").findAll();
    }
}
```

## See Also

- [wheels generate model](model.md) - Generate models
- [wheels generate view](view.md) - Generate views
- [wheels scaffold](scaffold.md) - Generate complete CRUD
- [wheels generate test](test.md) - Generate controller tests