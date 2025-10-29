# wheels generate view

Generate view files for controllers.

## Synopsis

```bash
wheels generate view [objectName] [name] [template]
wheels g view [objectName] [name] [template]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate view user show` (most common for this command)
- **Named parameters**: `objectName=value name=value` (e.g., `objectName=user name=show`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--force` equals `force=true`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- All positional: `wheels generate view user show`
- All positional + flags: `wheels generate view user show --force`
- All named: `objectName=user name=show template=crud/show`

❌ **NOT ALLOWED:**
- Positional + named: `wheels generate view user name=show` (causes error)

**Recommendation:** Use positional parameters for objectName and name, flags for options: `wheels generate view user show --force`

## Description

The `wheels generate view` command creates view files for controllers. It can generate individual views using templates or create blank view files.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `objectName` | View path folder (e.g., user) | Required |
| `name` | Name of the file to create (e.g., edit) | Required |
| `template` | Optional template to use | |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--force` | Overwrite existing code | `false` |

## Template Options

Available templates:
- `crud/_form` - Form partial for new/edit views
- `crud/edit` - Edit form view
- `crud/index` - List/index view
- `crud/new` - New form view
- `crud/show` - Show/detail view

## Examples

### Basic view (no template)
```bash
# Positional (recommended)
wheels generate view user show

# OR all named
wheels g view objectName=user name=show
```
Creates: `/views/users/show.cfm` with empty content

### View with CRUD template
```bash
# Positional with template (recommended)
wheels generate view user show crud/show

# OR all named
wheels g view objectName=user name=show template=crud/show
```
Creates: `/views/users/show.cfm` using the show template

### Edit form with template
```bash
# Positional (recommended)
wheels generate view user edit crud/edit
```
Creates: `/views/users/edit.cfm` using the edit template

### Form partial
```bash
# Positional (recommended)
wheels generate view user _form crud/_form
```
Creates: `/views/users/_form.cfm` using the form partial template

### Index view
```bash
# Positional (recommended)
wheels generate view product index crud/index
```
Creates: `/views/products/index.cfm` using the index template

### Force overwrite existing file
```bash
# Positional + flag (recommended)
wheels generate view user show --force

# OR all named
wheels g view objectName=user name=show force=true
```
Overwrites existing `/views/users/show.cfm`

## Generated Code Examples

### Without Template (blank file)
```cfm
<!--- View file created by wheels generate view --->
```

### With CRUD Index Template
```cfm
<h1>Products</h1>

<p>
    #linkTo(text="New Product", action="new", class="btn btn-primary")#
</p>

<cfif products.recordCount>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Created</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfoutput query="products">
                <tr>
                    <td>#products.id#</td>
                    <td>#products.name#</td>
                    <td>#dateFormat(products.createdAt, "mm/dd/yyyy")#</td>
                    <td>
                        #linkTo(text="View", action="show", key=products.id, class="btn btn-sm btn-info")#
                        #linkTo(text="Edit", action="edit", key=products.id, class="btn btn-sm btn-warning")#
                        #linkTo(text="Delete", action="delete", key=products.id, method="delete", confirm="Are you sure?", class="btn btn-sm btn-danger")#
                    </td>
                </tr>
            </cfoutput>
        </tbody>
    </table>
<cfelse>
    <p class="alert alert-info">No products found.</p>
</cfif>
```

### Form View (new.cfm)
```cfm
<h1>New Product</h1>

#includePartial("/products/form")#
```

### Form Partial (_form.cfm)
```cfm
#startFormTag(action=formAction)#

    <cfif product.hasErrors()>
        <div class="alert alert-danger">
            <h4>Please correct the following errors:</h4>
            #errorMessagesFor("product")#
        </div>
    </cfif>

    <div class="form-group">
        #textFieldTag(name="product[name]", value=product.name, label="Name", class="form-control")#
    </div>

    <div class="form-group">
        #textAreaTag(name="product[description]", value=product.description, label="Description", class="form-control", rows=5)#
    </div>

    <div class="form-group">
        #numberFieldTag(name="product[price]", value=product.price, label="Price", class="form-control", step="0.01")#
    </div>

    <div class="form-group">
        #selectTag(name="product[categoryId]", options=categories, selected=product.categoryId, label="Category", class="form-control", includeBlank="-- Select Category --")#
    </div>

    <div class="form-group">
        #checkBoxTag(name="product[isActive]", checked=product.isActive, label="Active", value=1)#
    </div>

    <div class="form-actions">
        #submitTag(value=submitLabel, class="btn btn-primary")#
        #linkTo(text="Cancel", action="index", class="btn btn-secondary")#
    </div>

#endFormTag()#
```

### Show View (show.cfm)
```cfm
<h1>Product Details</h1>

<div class="card">
    <div class="card-body">
        <h2 class="card-title">#product.name#</h2>
        
        <dl class="row">
            <dt class="col-sm-3">Description</dt>
            <dd class="col-sm-9">#product.description#</dd>
            
            <dt class="col-sm-3">Price</dt>
            <dd class="col-sm-9">#dollarFormat(product.price)#</dd>
            
            <dt class="col-sm-3">Category</dt>
            <dd class="col-sm-9">#product.category.name#</dd>
            
            <dt class="col-sm-3">Status</dt>
            <dd class="col-sm-9">
                <cfif product.isActive>
                    <span class="badge badge-success">Active</span>
                <cfelse>
                    <span class="badge badge-secondary">Inactive</span>
                </cfif>
            </dd>
            
            <dt class="col-sm-3">Created</dt>
            <dd class="col-sm-9">#dateTimeFormat(product.createdAt, "mmm dd, yyyy h:nn tt")#</dd>
            
            <dt class="col-sm-3">Updated</dt>
            <dd class="col-sm-9">#dateTimeFormat(product.updatedAt, "mmm dd, yyyy h:nn tt")#</dd>
        </dl>
    </div>
    <div class="card-footer">
        #linkTo(text="Edit", action="edit", key=product.id, class="btn btn-primary")#
        #linkTo(text="Delete", action="delete", key=product.id, method="delete", confirm="Are you sure?", class="btn btn-danger")#
        #linkTo(text="Back to List", action="index", class="btn btn-secondary")#
    </div>
</div>
```

## View Templates

### Available Templates

| Template | Description | Use Case |
|----------|-------------|----------|
| `default` | Standard HTML structure | General purpose |
| `bootstrap` | Bootstrap 5 components | Modern web apps |
| `tailwind` | Tailwind CSS classes | Utility-first design |
| `ajax` | AJAX-enabled views | Dynamic updates |
| `mobile` | Mobile-optimized | Responsive design |
| `print` | Print-friendly layout | Reports |
| `email` | Email template | Notifications |

### Template Structure

Templates are located in:
```
~/.commandbox/cfml/modules/wheels-cli/templates/views/
├── default/
│   ├── index.cfm
│   ├── show.cfm
│   ├── new.cfm
│   ├── edit.cfm
│   └── _form.cfm
├── bootstrap/
└── custom/
```

## Partial Views

### Naming Convention
Partials start with underscore:
- `_form.cfm` - Form partial
- `_item.cfm` - List item partial
- `_sidebar.cfm` - Sidebar partial

### Generate Partials
```bash
wheels generate view shared header,footer,navigation --partial
```

### Using Partials
```cfm
<!--- In layout or view --->
#includePartial("/shared/header")#
#includePartial("/products/form", product=product)#
#includePartial(partial="item", query=products)#
```

## Layout Integration

### With Layout (default)
```cfm
<!--- Generated view assumes layout wrapper --->
<h1>Page Title</h1>
<p>Content here</p>
```

### Without Layout
```bash
wheels generate view products standalone --layout=false
```

```cfm
<!DOCTYPE html>
<html>
<head>
    <title>Standalone View</title>
</head>
<body>
    <h1>Products</h1>
    <!-- Complete HTML structure -->
</body>
</html>
```

## Custom Formats

### HTML Format
```bash
wheels generate view products index --format=html
```
Creates: `/views/products/index.html`

### Custom Extensions
```bash
wheels generate view emails welcome --format=txt
```
Creates: `/views/emails/welcome.txt`

## Ajax Views

### Generate AJAX View
```bash
wheels generate view products search --template=ajax
```

### AJAX Template Example
```cfm
<cfif isAjax()>
    <!--- Return just the content --->
    <cfoutput query="products">
        <div class="search-result">
            <h3>#products.name#</h3>
            <p>#products.description#</p>
        </div>
    </cfoutput>
<cfelse>
    <!--- Include full page structure --->
    <div id="search-results">
        <cfinclude template="_results.cfm">
    </div>
</cfif>
```

## Form Helpers

### Standard Form
```cfm
#startFormTag(action="create", method="post", class="needs-validation")#
    #textField(objectName="product", property="name", label="Product Name", class="form-control", required=true)#
    #textArea(objectName="product", property="description", label="Description", class="form-control", rows=5)#
    #select(objectName="product", property="categoryId", options=categories, label="Category", class="form-control")#
    #submitTag(value="Save Product", class="btn btn-primary")#
#endFormTag()#
```

### File Upload Form
```cfm
#startFormTag(action="upload", multipart=true)#
    #fileFieldTag(name="productImage", label="Product Image", accept="image/*", class="form-control")#
    #submitTag(value="Upload", class="btn btn-primary")#
#endFormTag()#
```

## Responsive Design

### Mobile-First Template
```bash
wheels generate view products index --template=mobile
```

```cfm
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3">Products</h1>
        </div>
    </div>
    
    <div class="row">
        <cfoutput query="products">
            <div class="col-12 col-md-6 col-lg-4 mb-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title">#products.name#</h5>
                        <p class="card-text">#products.description#</p>
                        #linkTo(text="View", action="show", key=products.id, class="btn btn-primary btn-sm")#
                    </div>
                </div>
            </div>
        </cfoutput>
    </div>
</div>
```

## Localization

### Generate Localized Views
```bash
wheels generate view products index --locale=es
```
Creates: `/views/products/index_es.cfm`

### Localized Content
```cfm
<h1>#l("products.title")#</h1>
<p>#l("products.description")#</p>

#linkTo(text=l("buttons.new"), action="new", class="btn btn-primary")#
```

## Testing Views

### Generate View Tests
```bash
wheels generate view products index
wheels generate test view products/index
```

### View Test Example
```cfc
component extends="wheels.Test" {
    
    function test_index_displays_products() {
        products = model("Product").findAll(maxRows=5);
        result = renderView(view="/products/index", products=products, layout=false);
        
        assert(Find("<h1>Products</h1>", result));
        assert(Find("New Product", result));
        assertEquals(products.recordCount, ListLen(result, "<tr>") - 1);
    }
    
}
```

## Performance Optimization

### Caching Views
```cfm
<cfcache action="cache" timespan="#CreateTimeSpan(0,1,0,0)#">
    <!--- Expensive view content --->
    #includePartial("products/list", products=products)#
</cfcache>
```

### Lazy Loading
```cfm
<div class="products-container" data-lazy-load="/products/more">
    <!--- Initial content --->
</div>

<script>
// Implement lazy loading
</script>
```

## Best Practices

1. Keep views simple and focused on presentation
2. Use partials for reusable components
3. Move complex logic to helpers or controllers
4. Follow naming conventions consistently
5. Use semantic HTML markup
6. Include accessibility attributes
7. Optimize for performance with caching
8. Test views with various data states

## Common Patterns

### Empty State
```cfm
<cfif products.recordCount>
    <!--- Show products --->
<cfelse>
    <div class="empty-state">
        <h2>No products found</h2>
        <p>Get started by adding your first product.</p>
        #linkTo(text="Add Product", action="new", class="btn btn-primary")#
    </div>
</cfif>
```

### Loading State
```cfm
<div class="loading-spinner" style="display: none;">
    <i class="fa fa-spinner fa-spin"></i> Loading...
</div>
```

### Error State
```cfm
<cfif structKeyExists(variables, "error")>
    <div class="alert alert-danger">
        <strong>Error:</strong> #error.message#
    </div>
</cfif>
```

## See Also

- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD
- [wheels generate test](test.md) - Generate view tests