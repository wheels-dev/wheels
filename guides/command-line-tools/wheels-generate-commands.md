# Generation Commands

The Wheels CLI provides powerful code generation commands that accelerate development by creating boilerplate code following Wheels conventions. All generation commands can be invoked with either `wheels generate` or the shorter alias `wheels g`.

## Overview

Generation commands follow consistent patterns:
- Support `--force` flag to overwrite existing files
- Provide `--dry-run` option to preview changes
- Follow Wheels naming conventions automatically
- Generate associated test files when appropriate

## wheels generate app

Create a new Wheels application with a single command.

### Syntax

```bash
wheels generate app [name] [options]
# Alias: wheels g app
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Application name |
| --template | string | No | Base | Application template |
| --directory | string | No | ./{name} | Target directory |
| --datasourceName | string | No | {name} | Database name |
| --setupH2 | boolean | No | true | Setup H2 database |
| --useBootstrap | boolean | No | false | Include Bootstrap CSS |

### Templates

- `Base` - Minimal Wheels application
- `Rest` - RESTful API template
- `HelloWorld` - Simple starter with example
- `Todos` - Todo application example
- `UserManagement` - User authentication system

### Description

Creates a complete Wheels application structure including:
- Application skeleton (controllers, models, views directories)
- Configuration files (routes.cfm, settings.cfm)
- Database configuration (with optional H2 setup)
- CommandBox configuration (box.json, server.json)
- Test structure

### Examples

Create basic application:
```bash
wheels g app myapp
```

Create with specific template:
```bash
wheels g app blog --template=UserManagement --useBootstrap=true
```

Create in specific directory:
```bash
wheels g app myapp --directory=/projects/wheels-apps/myapp
```

### Notes

- Automatically initializes Git repository
- Sets up H2 embedded database for quick start
- Creates .gitignore with sensible defaults
- Generates README.md with setup instructions

---

## wheels generate app-wizard

Interactive wizard for creating a new Wheels application.

### Syntax

```bash
wheels generate app-wizard
# Aliases: wheels g app-wizard, wheels new
```

### Description

Launches an interactive wizard that guides you through creating a new application by prompting for:
1. Application name
2. Directory location
3. Template selection
4. Database configuration
5. Additional features (Bootstrap, jQuery, etc.)

### Examples

```bash
wheels new
```

The wizard will prompt:
```
? Enter your application name: myapp
? Choose a template: (Use arrow keys)
❯ Base - Minimal Wheels application
  Rest - RESTful API template
  HelloWorld - Simple starter
  Todos - Todo application
  UserManagement - With authentication
? Setup H2 database? (Y/n)
? Include Bootstrap CSS? (y/N)
```

### Notes

- Recommended for beginners
- Validates inputs before proceeding
- Shows preview of actions before execution
- Calls `wheels g app` internally with selected options

---

## wheels generate controller

Generate a controller file with optional actions.

### Syntax

```bash
wheels generate controller [name] [options]
# Alias: wheels g controller
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Controller name |
| --actions | string | No | index | Comma-separated action names |
| --rest | boolean | No | false | Generate RESTful actions |
| --api | boolean | No | false | Generate API controller |
| --force | boolean | No | false | Overwrite existing |

### Description

Creates a controller file at `app/controllers/{Name}.cfc` with:
- Proper component structure
- Specified actions as functions
- RESTful actions if requested
- API response formatting if API mode

### Examples

Basic controller:
```bash
wheels g controller Products
```

Controller with custom actions:
```bash
wheels g controller Products --actions=index,show,search
```

RESTful controller:
```bash
wheels g controller Products --rest
```
Generates: index, show, new, edit, create, update, delete

API controller:
```bash
wheels g controller Products --api --rest
```

### Generated Code Example

```cfm
component extends="Controller" {
    
    function index() {
        products = model("Product").findAll();
    }
    
    function show() {
        product = model("Product").findByKey(params.key);
    }
    
    // Additional actions...
}
```

---

## wheels generate model

Generate a model file with optional properties and migration.

### Syntax

```bash
wheels generate model [name] [options]
# Alias: wheels g model
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Model name |
| --properties | string | No | - | Properties definition |
| --migration | boolean | No | true | Generate migration |
| --belongsTo | string | No | - | Parent relationships |
| --hasMany | string | No | - | Child relationships |
| --force | boolean | No | false | Overwrite existing |

### Property Format

Properties use the format: `name:type,name:type`

Supported types:
- `string` - VARCHAR(255)
- `text` - TEXT
- `integer` - INTEGER
- `biginteger` - BIGINT
- `float` - FLOAT
- `decimal` - DECIMAL
- `boolean` - BOOLEAN
- `date` - DATE
- `datetime` - DATETIME
- `time` - TIME
- `binary` - BLOB

### Description

Creates:
- Model file at `app/models/{Name}.cfc`
- Database migration if enabled
- Relationship definitions
- Validation rules based on types

### Examples

Simple model:
```bash
wheels g model Product
```

Model with properties:
```bash
wheels g model Product --properties=name:string,price:decimal,inStock:boolean
```

Model with relationships:
```bash
wheels g model Product --belongsTo=category --hasMany=orderItems
```

Complex model:
```bash
wheels g model BlogPost \
  --properties=title:string,content:text,publishedAt:datetime,views:integer \
  --belongsTo=author,category \
  --hasMany=comments,tags
```

### Generated Model Example

```cfm
component extends="Model" {
    
    function config() {
        // Relationships
        belongsTo("category");
        hasMany("orderItems");
        
        // Validations
        validates("name", presence=true);
        validates("price", numericality=true);
    }
}
```

---

## wheels scaffold

Generate a complete CRUD resource with model, controller, views, and migration.

### Syntax

```bash
wheels scaffold [name] [options]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Resource name |
| --properties | string | No | - | Model properties |
| --api | boolean | No | false | API-only scaffold |
| --tests | boolean | No | true | Generate tests |
| --migrate | boolean | No | false | Run migration |
| --force | boolean | No | false | Overwrite existing |

### Description

Generates a complete CRUD resource:
1. Model with validations
2. Controller with all CRUD actions
3. Views (index, show, new, edit, _form partial)
4. Database migration
5. Routes entry
6. Test files

### Examples

Basic scaffold:
```bash
wheels scaffold Article
```

Scaffold with properties:
```bash
wheels scaffold Article --properties=title:string,content:text,author:string
```

API scaffold:
```bash
wheels scaffold Article --properties=title:string,content:text --api
```

Scaffold and migrate:
```bash
wheels scaffold Product --properties=name:string,price:decimal --migrate
```

### Generated Files

For `wheels scaffold Article`:
- `app/models/Article.cfc`
- `app/controllers/Articles.cfc`
- `app/views/articles/index.cfm`
- `app/views/articles/show.cfm`
- `app/views/articles/new.cfm`
- `app/views/articles/edit.cfm`
- `app/views/articles/_form.cfm`
- `db/migrate/{timestamp}_create_articles.cfc`
- Updates to `config/routes.cfm`
- `tests/models/ArticleTest.cfc`
- `tests/controllers/ArticlesTest.cfc`

---

## wheels generate view

Generate view files with optional templates.

### Syntax

```bash
wheels generate view [name] [options]
# Alias: wheels g view
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | View/controller name |
| --action | string | No | index | Action name |
| --controller | string | No | {name} | Controller name |
| --template | string | No | - | View template |
| --force | boolean | No | false | Overwrite existing |

### Templates

- `crud` - CRUD form template
- `table` - Table listing template
- `blank` - Empty view file

### Description

Creates view files in the appropriate directory with:
- Proper file naming convention
- Basic HTML structure
- Template content if specified
- Helper function examples

### Examples

Single view:
```bash
wheels g view products --action=search
```

Multiple views:
```bash
wheels g view products --action=index,show
```

With template:
```bash
wheels g view products --action=index --template=table
```

Different controller:
```bash
wheels g view reports --controller=admin --action=sales
```

---

## wheels generate property

Add a property to an existing model with migration.

### Syntax

```bash
wheels generate property [model] [name] [type] [options]
# Alias: wheels g property
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| model | string | Yes | - | Model name |
| name | string | Yes | - | Property name |
| type | string | Yes | string | Property type |
| --default | string | No | - | Default value |
| --null | boolean | No | true | Allow nulls |

### Description

Adds a property to an existing model by:
1. Creating a migration to add the column
2. Updating model validations
3. Updating form views if they exist

### Examples

Add simple property:
```bash
wheels g property Product color string
```

Add with constraints:
```bash
wheels g property Product featured boolean --default=false --null=false
```

Add numeric property:
```bash
wheels g property Product weight decimal --default=0.0
```

### Notes

- Requires existing model
- Creates migration automatically
- Updates scaffolded views if present
- Adds appropriate validation rules

---

## wheels generate route

Add routes to the routes configuration file.

### Syntax

```bash
wheels generate route [name] [options]
# Alias: wheels g route
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Route name |
| pattern | string | No | /{name} | URL pattern |
| controller | string | No | {name} | Controller |
| action | string | No | index | Action |
| --methods | string | No | GET | HTTP methods |

### Description

Adds route entries to `config/routes.cfm`:
- Resource routes for CRUD operations
- Custom routes with specific patterns
- HTTP method constraints
- Named routes for URL helpers

### Examples

Resource route:
```bash
wheels g route products
```
Adds: `resources("products")`

Custom route:
```bash
wheels g route search --pattern="/search" --controller=products --action=search
```

API routes:
```bash
wheels g route api/products --methods=GET,POST
```

### Generated Routes

```cfm
// Resource route
resources("products");

// Custom route
get(route="search", pattern="/search", controller="products", action="search");

// Multiple methods
match(name="api/products", pattern="/api/products", methods="GET,POST");
```

---

## wheels generate test

Generate test files for models, controllers, or views.

### Syntax

```bash
wheels generate test [type] [name] [options]
# Alias: wheels g test
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| type | string | Yes | - | Test type (model/controller/view) |
| name | string | Yes | - | Component name |
| --methods | string | No | - | Test methods to generate |
| --crud | boolean | No | false | Generate CRUD tests |
| --mock | boolean | No | false | Include mock data |

### Description

Creates TestBox test files with:
- Proper test structure
- Setup and teardown methods
- Test stubs for specified methods
- CRUD test suite if requested
- Mock data helpers

### Examples

Model test:
```bash
wheels g test model Product
```

Controller test with CRUD:
```bash
wheels g test controller Products --crud
```

Custom test methods:
```bash
wheels g test model User --methods=authenticate,authorize
```

### Generated Test Example

```cfm
component extends="Test" {
    
    function setup() {
        super.setup();
        model = model("Product").new();
    }
    
    function teardown() {
        super.teardown();
    }
    
    function test_product_valid() {
        model.name = "Test Product";
        model.price = 99.99;
        assert(model.valid());
    }
    
    // Additional tests...
}
```

---

## wheels generate resource

Generate a complete RESTful resource (model, controller, views, routes, tests).

### Syntax

```bash
wheels generate resource [name] [options]
# Alias: wheels g resource
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Resource name |
| --properties | string | No | - | Model properties |
| --api | boolean | No | false | API-only resource |
| --scaffold | boolean | No | true | Full scaffolding |

### Description

Combines multiple generators to create:
- Model with properties and migration
- RESTful controller
- All CRUD views (unless --api)
- Resource routes
- Complete test suite

### Examples

Basic resource:
```bash
wheels g resource Article
```

Resource with properties:
```bash
wheels g resource Article --properties=title:string,content:text,publishedAt:datetime
```

API resource:
```bash
wheels g resource Article --api --properties=title:string,content:text
```

### Notes

- Equivalent to running scaffold command
- Most comprehensive generator
- Follows RESTful conventions
- Creates full test coverage

---

## wheels generate api-resource

Generate an API-only resource without views.

### Syntax

```bash
wheels generate api-resource [name] [options]
# Alias: wheels g api-resource
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Resource name |
| --properties | string | No | - | Model properties |
| --version | string | No | v1 | API version |

### Description

Creates API-specific components:
- Model with properties
- API controller with JSON responses
- Versioned routes
- API-specific tests
- No view files

### Examples

Basic API resource:
```bash
wheels g api-resource Product
```

Versioned API:
```bash
wheels g api-resource Product --version=v2
```

### Notes

- Currently disabled due to CFML parsing issues
- Use `wheels g resource --api` as alternative
- Generates JSON-only responses
- Includes API authentication hooks

---

## wheels generate frontend

Generate frontend components for modern JavaScript frameworks.

### Syntax

```bash
wheels generate frontend [name] [options]
# Alias: wheels g frontend
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Component name |
| --framework | string | No | vue | Frontend framework |
| --template | string | No | - | Component template |

### Frameworks

- `vue` - Vue.js components
- `react` - React components
- `angular` - Angular components

### Description

Creates frontend components that integrate with Wheels backend:
- Component files in appropriate format
- API service connectors
- State management setup
- Basic styling

### Examples

Vue component:
```bash
wheels g frontend ProductList --framework=vue
```

React component:
```bash
wheels g frontend UserProfile --framework=react
```

### Notes

- Requires frontend framework setup
- Generates in public/js/components
- Includes API integration code

---

## wheels generate snippets

Generate reusable code snippets.

### Syntax

```bash
wheels generate snippets [type] [options]
# Alias: wheels g snippets
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| type | string | No | all | Snippet type |
| --output | string | No | ./snippets | Output directory |

### Description

Generates commonly used code snippets:
- Form helpers
- Validation rules
- Query examples
- Configuration samples

### Examples

Generate all snippets:
```bash
wheels g snippets
```

Specific snippet type:
```bash
wheels g snippets forms --output=./references
```

---

## Generation Best Practices

### Naming Conventions

1. **Models**: Singular PascalCase (e.g., `Product`, `BlogPost`)
2. **Controllers**: Plural PascalCase (e.g., `Products`, `BlogPosts`)
3. **Properties**: camelCase (e.g., `firstName`, `publishedAt`)
4. **Routes**: Plural lowercase (e.g., `products`, `blog-posts`)

### Property Types Guide

Choose appropriate types for data:
- `string` - Names, titles, short text (max 255 chars)
- `text` - Long content, descriptions
- `integer` - Counts, IDs, whole numbers
- `decimal` - Prices, percentages, precise numbers
- `boolean` - Flags, on/off states
- `datetime` - Timestamps, scheduling
- `date` - Date only fields

### Workflow Examples

#### Building a Blog

```bash
# 1. Generate User model for authors
wheels g model User --properties=email:string,password:string,name:string

# 2. Generate Post scaffold
wheels scaffold Post --properties=title:string,content:text,publishedAt:datetime,authorId:integer

# 3. Generate Comment resource
wheels g resource Comment --properties=content:text,postId:integer,authorName:string

# 4. Add category
wheels g model Category --properties=name:string,slug:string
wheels g property Post categoryId integer

# 5. Run migrations
wheels dbmigrate latest
```

#### Building an API

```bash
# 1. Generate API resources
wheels g resource Product --api --properties=name:string,sku:string,price:decimal
wheels g resource Order --api --properties=total:decimal,status:string
wheels g resource OrderItem --api --properties=orderId:integer,productId:integer,quantity:integer

# 2. Add authentication
wheels g controller Auth --api --actions=login,logout,refresh

# 3. Run migrations
wheels dbmigrate latest
```

### Common Issues and Solutions

**Overwriting Files**: Use `--force` flag carefully. Always backup before forcing overwrites.

**Property Types**: If unsure about a type, check your database documentation or use `string` as a safe default.

**Naming Conflicts**: Avoid using reserved words like `class`, `type`, `order` as model names.

**Missing Migrations**: Generation commands create migrations by default. Run them with `wheels dbmigrate latest`.

## Summary

The Wheels generation commands provide a complete toolkit for rapidly building applications:

- **Start with** `wheels new` for interactive setup
- **Use** `wheels scaffold` for complete CRUD resources
- **Leverage** individual generators for granular control
- **Follow** naming conventions for consistency
- **Run** migrations after generating models

These generators dramatically reduce boilerplate code and ensure your application follows Wheels best practices from the start.