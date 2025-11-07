# wheels generate controller

Generate a controller with actions and optional views.

## Synopsis

```bash
wheels generate controller name=<controllerName> [options]

#Can also be used as:
wheels g controller name=<controllerName> [options]
```

## CommandBox Parameter Syntax

- **Positional parameters**: `wheels generate controller Products` (controller name)
- **Named parameters**: `param=value` (e.g., `name=Products`, `actions=index,show`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--crud` equals `crud=true`)
- **Params with value**: `--param=value` equals `param=value` (e.g., `--actions=index,show`)

**Recommended Format:**
- Positional for name: `wheels generate controller Products`
- Flags for options: `wheels generate controller Products --crud --force`

**Not Allowed:**
- Use `--actions` (plural) not `--action` (singular)
- Don't mix positional and named parameters (causes errors)

## Description

The `wheels generate controller` command creates a new controller CFC file with specified actions and optionally generates corresponding view files. It supports both traditional and RESTful controller patterns.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Name of the controller to create (usually plural) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `actions` | Actions to generate (comma-delimited) - **HIGHEST PRIORITY**, overrides `--crud` | `index` |
| `crud` | Generate CRUD controller with actions (index, show, new, create, edit, update, delete) **and scaffold-style views** (index, show, new, edit, _form) | `false` |
| `api` | Generate API controller (no views generated, only JSON/XML endpoints) | `false` |
| `noViews` | Skip view generation (only generate controller) | `false` |
| `description` | Controller description comment | `""` |
| `force` | Overwrite existing files | `false` |

## How It Works

### Decision Tree

```
ACTION GENERATION:
├─ Has --actions? → Use those actions ONLY (highest priority, overrides --crud)
├─ Has --api? → Generate 5 actions (index, show, create, update, delete)
├─ Has --crud? → Generate 7 actions (index, show, new, create, edit, update, delete)
└─ Default → Generate 1 action (index)

VIEW GENERATION:
├─ Has --api? → NO VIEWS (JSON/XML responses)
├─ Has --noViews? → NO VIEWS (explicitly skipped)
├─ Has --crud? → 5 VIEWS (index, show, new, edit, _form)
└─ Default → CREATE 1 VIEW PER ACTION
```

### Common Use Cases

| What You Want | Command | Actions | Views |
|---------------|---------|---------|-------|
| Traditional web app (scaffold-style) | `--crud` | 7 | 5 (index, show, new, edit, _form) |
| REST API (JSON/XML) | `--api` | 5 | None |
| Single page controller | (no flags) | 1 (index) | 1 (index) |
| Custom actions with views | `--actions=dashboard,export` | 2 | 2 (dashboard, export) |
| Controller only (no views) | `--crud --noViews` | 7 | None |

### --crud vs --api

| Aspect | --crud | --api |
|--------|--------|-------|
| Purpose | Traditional web application | API endpoints |
| Actions | 7 (includes new, edit forms) | 5 (no form actions) |
| Views | 5 scaffold-style views | None |
| Response | HTML pages with forms | JSON/XML data |
| Use Case | User-facing web apps | Mobile apps, SPAs, integrations |

## Examples

### Basic controller
```bash
wheels generate controller Products
```
Creates: `Products.cfc` with `index` action and `index.cfm` view

### Controller with custom actions
```bash
wheels generate controller Products --actions=dashboard,reports,export
```
Creates: `Products.cfc` with 3 custom actions and 3 views

### CRUD controller (scaffold-style)
```bash
wheels generate controller Products --crud
```
Creates: `Products.cfc` with 7 CRUD actions + 5 views (index, show, new, edit, _form)

### API controller (no views)
```bash
wheels generate controller Orders --api
```
Creates: `Orders.cfc` with 5 API actions, no views

### Controller without views
```bash
wheels generate controller Products --crud --noViews
```
Creates: `Products.cfc` with 7 actions, no views

### Priority override example
```bash
wheels generate controller Products --crud --actions=dashboard
```
Creates: `Products.cfc` with only `dashboard` action (--actions overrides --crud)

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
wheels generate controller name=products --crud
wheels generate test controller name=products
```

## Best Practices

1. Use plural names for resource controllers
2. Keep controllers focused on single resources
3. Use `--crud` for standard web app CRUD operations (with views and forms)
4. Use `--api` for API endpoints (JSON/XML, no views)
5. Use `--actions` when you need custom actions (HIGHEST PRIORITY - overrides `--crud`)
6. Implement proper error handling
7. Add authentication in `config()` method
8. Use filters for common functionality

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