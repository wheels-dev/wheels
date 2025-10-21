# Scaffold Generation

## Description
Generate complete MVC structure including model, controller, views, and migration for rapid application development.

## Key Points
- Use `wheels g scaffold` to generate complete resource
- Creates model, controller, views, and migration
- Includes full CRUD interface with forms and validation
- Automatic route configuration
- Production-ready starting point

## Code Sample
```bash
# Complete scaffold generation
wheels g scaffold Product name:string:required,price:decimal:required,description:text,category_id:integer:foreign_key,active:boolean:default=true

# This generates:
# - /app/models/Product.cfc
# - /app/controllers/Products.cfc
# - /app/views/products/*.cfm (index, show, new, edit)
# - /app/migrator/migrations/[timestamp]_create_products_table.cfc
# - Route resource in /config/routes.cfm

# Generated model: /app/models/Product.cfc
component extends="Model" {
    function config() {
        validatesPresenceOf("name,price");
        belongsTo("category");

        property(name="active", defaultValue=true);
    }
}

# Generated controller: /app/controllers/Products.cfc
component extends="Controller" {
    function config() {
        verifies(params="key", paramsTypes="integer", only="show,edit,update,delete");
    }

    function index() {
        products = model("Product").findAll(order="name");
    }

    function show() {
        product = model("Product").findByKey(params.key);
    }

    function new() {
        product = model("Product").new();
        categories = model("Category").findAll();
    }

    function create() {
        product = model("Product").new(params.product);

        if (product.save()) {
            redirectTo(route="product", key=product.id, success="Product created!");
        } else {
            categories = model("Category").findAll();
            renderView(action="new");
        }
    }
    // ... other CRUD actions
}
```

## Usage
1. Run `wheels g scaffold ResourceName attribute:type:constraint`
2. Review generated files and customize as needed
3. Run `wheels dbmigrate latest` to create database table
4. Add route resource to `/config/routes.cfm` if not done automatically
5. Customize views, add validation, and implement business logic

## Related
- [Model Generation](./models.md)
- [Controller Generation](./controllers.md)
- [Migration Generation](./migrations.md)
- [Resource Routing](../../core-concepts/routing/resources.md)

## Important Notes
- Scaffolds provide starting point - customize for production
- Include all necessary attributes in initial generation
- Review and enhance generated validation rules
- Customize views to match application design
- Add authentication and authorization as appropriate