# wheels generate controller

Generate a controller with actions and optional views.

## Synopsis

```bash
wheels generate controller name=<controllerName> [options]
wheels g controller name=<controllerName> [options]
```

## Parameter Syntax

CommandBox supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=Products`, `actions=index,show`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--rest` equals `rest=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--actions=index,show`)

**Note**: Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

## Description

The `wheels generate controller` command creates a new controller CFC file with specified actions and optionally generates corresponding view files. It supports both traditional and RESTful controller patterns.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Name of the controller to create (usually plural) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `actions` | Actions to generate (comma-delimited) | `index` |
| `rest` | Generate RESTful controller with CRUD actions | `false` |
| `api` | Generate API controller (no view-related actions) | `false` |
| `description` | Controller description comment | `""` |
| `force` | Overwrite existing files | `false` |

## Examples

### Basic controller
```bash
wheels generate controller name=Products
```
Creates:
- `app/controllers/Products.cfc` with `index` action

### Controller with description
```bash
wheels generate controller name=Users --description="Handles user management operations"
```
Creates controller with description comment at the top.

### Controller with multiple actions
```bash
wheels generate controller name=Products --actions=index,show,new,create
```
Creates controller with specified actions.

### RESTful controller
```bash
wheels generate controller name=Products --rest
```
Automatically generates all RESTful actions and views:
- `index`, `show`, `new`, `create`, `edit`, `update`, `delete`

### API controller
```bash
wheels generate controller name=Orders --api --description="API endpoint for order processing"
```
Creates:
- `app/controllers/Orders.cfc` with JSON responses
- No view files generated

### Custom actions with description
```bash
wheels generate controller name=Reports --actions=dashboard,monthly,export --description="Reporting controller"
```

## Generated Code

### Basic Controller
```cfc
component extends="Controller" {

  /**
	* Controller config settings
	**/
	function config() {

	}

    /**
     * index action
     */
    function index() {
        // TODO: Implement index action
    }
}
```

### Controller with Description
```cfc
/**
 * Handles user management operations
 */
component extends="Controller" {

  /**
	* Controller config settings
	**/
	function config() {

	}

    /**
     * index action
     */
    function index() {
        // TODO: Implement index action
    }
}
```

### RESTful Controller
```cfc
component extends="Controller" {

	function config() {
		verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
	}

	/**
	* View all Products
	**/
	function index() {
		products=model("product").findAll();
	}

	/**
	* View Product
	**/
	function show() {
		product=model("product").findByKey(params.key);
	}

	/**
	* Add New Product
	**/
	function new() {
		product=model("product").new();
	}

	/**
	* Create Product
	**/
	function create() {
		product=model("product").create(params.product);
		if(product.hasErrors()){
			renderView(action="new");
		} else {
			redirectTo(action="index", success="Product successfully created");
		}
	}

	/**
	* Edit Product
	**/
	function edit() {
		product=model("product").findByKey(params.key);
	}

	/**
	* Update Product
	**/
	function update() {
		product=model("product").findByKey(params.key);
		if(product.update(params.product)){
			redirectTo(action="index", success="Product successfully updated");
		} else {
			renderView(action="edit");
		}
	}

	/**
	* Delete Product
	**/
	function delete() {
		product=model("product").deleteByKey(params.key);
		redirectTo(action="index", success="Product successfully deleted");
	}

	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	function objectNotFound() {
		redirectTo(action="index", error="That Product wasn't found");
	}

}
```

### API Controller
```cfc
/**
 * API endpoint for order processing
 */
component extends="wheels.Controller" {

    function init() {
        provides("json");
		filters(through="setJsonResponse");
    }

    /**
     * GET /orders
     * Returns a list of all orders
     */
    function index() {
        local.orders = model("order").findAll();
        renderWith(data={ orders=local.orders });
    }

    /**
     * GET /orders/:key
     * Returns a specific order by ID
     */
    function show() {
        local.order = model("order").findByKey(params.key);

        if (IsObject(local.order)) {
            renderWith(data={ order=local.order });
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * POST /orders
     * Creates a new order
     */
    function create() {
        local.order = model("order").new(params.order);

        if (local.order.save()) {
            renderWith(data={ order=local.order }, status=201);
        } else {
            renderWith(data={ error="Validation failed", errors=local.order.allErrors() }, status=422);
        }
    }

    /**
     * PUT /orders/:key
     * Updates an existing order
     */
    function update() {
        local.order = model("order").findByKey(params.key);

        if (IsObject(local.order)) {
            local.order.update(params.order);

            if (local.order.hasErrors()) {
                renderWith(data={ error="Validation failed", errors=local.order.allErrors() }, status=422);
            } else {
                renderWith(data={ order=local.order });
            }
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

    /**
     * DELETE /orders/:key
     * Deletes a order
     */
    function delete() {
        local.order = model("order").findByKey(params.key);

        if (IsObject(local.order)) {
            local.order.delete();
            renderWith(data={}, status=204);
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }

	/**
	* Set Response to JSON
	*/
	private function setJsonResponse() {
		params.format = "json";
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
<cfscript>
mapper()
    .get(name="products", to="products##index")
    .get(name="product", to="products##show")
    .post(name="products", to="products##create")
    .wildcard()
.end();
</cfscript>
```

### RESTful Resources
```cfm
<cfscript>
mapper()
    .resources("products")
    .wildcard()
.end();
</cfscript>
```

## Testing

Generate tests alongside controllers:
```bash
wheels generate controller name=products --rest
wheels generate test controller name=products
```

## Best Practices

1. Use plural names for resource controllers
2. Keep controllers focused on single resources
3. Use `--rest` for standard CRUD operations
4. Implement proper error handling
5. Add authentication in `config()` method
6. Use filters for common functionality

## Common Patterns

### Authentication Filter
```cfc
function config() {
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