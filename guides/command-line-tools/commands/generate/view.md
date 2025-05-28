# wheels generate view

Generate view files for controllers.

## Synopsis

```bash
wheels generate view [controller] [actions] [options]
wheels g view [controller] [actions] [options]
```

## Description

The `wheels generate view` command creates view files for specified controller actions. It can generate individual views, sets of views for RESTful actions, or custom view templates with various layout options.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `controller` | Controller name (singular or plural) | Required |
| `actions` | Comma-separated list of actions | `index` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--template` | View template to use | `default` |
| `--layout` | Include layout wrapper | `true` |
| `--partial` | Generate as partial (prefix with _) | `false` |
| `--format` | File format (cfm, htm, html) | `cfm` |
| `--rest` | Generate RESTful views | `false` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Examples

### Basic view
```bash
wheels generate view products index
```
Creates: `/views/products/index.cfm`

### Multiple views
```bash
wheels generate view products index,show,new,edit
```
Creates multiple view files in `/views/products/`

### RESTful views
```bash
wheels generate view products --rest
```
Generates all RESTful views:
- `index.cfm` - List view
- `show.cfm` - Detail view
- `new.cfm` - Create form
- `edit.cfm` - Edit form
- `_form.cfm` - Shared form partial

### Partial view
```bash
wheels generate view products sidebar --partial
```
Creates: `/views/products/_sidebar.cfm`

### Custom template
```bash
wheels generate view reports dashboard --template=dashboard
```

## Generated Code Examples

### Default Template (index.cfm)
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