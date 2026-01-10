# wheels generate view

Generate view files for controllers.

## Synopsis

```bash
wheels generate view [objectName] [name] [template]
wheels g view [objectName] [name] [template]
```

## CommandBox Parameter Syntax

- **Positional parameters**: `wheels generate view user show` (most common for this command)
- **Named parameters**: `objectName=value name=value` (e.g., `objectName=user name=show`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--force` equals `force=true`)

**Recommended:** Use positional parameters: `wheels generate view user show`
**With template:** `wheels generate view user show crud/show`

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
# Positional
wheels generate view user show

# Named Parameters
wheels g view objectName=user name=show
```
Creates: `/views/users/show.cfm` with empty content

### View with CRUD template
```bash
wheels generate view user show crud/show
```
Creates: `/views/users/show.cfm` using the show template

### Edit form with template
```bash
wheels generate view user edit crud/edit
```
Creates: `/views/users/edit.cfm` using the edit template

### Form partial
```bash
wheels generate view user _form crud/_form
```
Creates: `/views/users/_form.cfm` using the form partial template

### Index view
```bash
wheels generate view product index crud/index
```
Creates: `/views/products/index.cfm` using the index template

### Force overwrite existing file
```bash
wheels generate view user show --force
```
Overwrites existing `/views/users/show.cfm`

## Generated Code Examples

### Without Template (blank file)
```cfm
<!--- View file created by wheels generate view --->
```

### With CRUD Index Template
```cfm
<!--- Product Index --->
<cfparam name="products">
<cfoutput>
	<h1>Products index</h1>
	<p>#linkTo(route="newProduct", text="Create New Product", class="btn btn-default")#</p>

	<cfif products.recordcount>
		<table class="table">
			<thead>
				<tr>
					<th>ID</th>
                    <!--- CLI-Appends-thead-Here --->
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="products">
				<tr>
					<td>
						#id#
					</td>
                    <!--- CLI-Appends-tbody-Here --->
					<td>
						<div class="btn-group">
							#linkTo(route="Product", key=id, text="View", class="btn btn-xs btn-info", encode=false)#
							#linkTo(route="editProduct", key=id, text="Edit", class="btn btn-xs btn-primary", encode=false)#
						</div>
						#buttonTo(route="Product", method="delete", key=id, text="Delete", class="pull-right", inputClass="btn btn-danger btn-xs", encode=false)#
					</td>
				</tr>
				</cfloop>
			</tbody>
		</table>
	<cfelse>
		<p>Sorry, there are no Products yet</p>
	</cfif>
</cfoutput>

```

### With CRUD New Template
```cfm
<!--- Product Creation Form --->
<cfparam name="product">
<cfoutput>
<h1>Create New Product</h1>
#errorMessagesFor("product")#
#startFormTag(id="productNewForm", action="create")#
	#includePartial("form")#
	#submitTag(value="Create Product")#
#endFormTag()#
</cfoutput>
```

### With CRUD Show Template
```cfm
<!--- Product Show --->
<cfparam name="product">
<cfoutput>
<h1>View Product</h1>
<!--- CLI-Appends-Here --->
</cfoutput>
```

### With CRUD Form Partial Template
```cfm
<!--- Product Form Contents --->
<cfoutput>
|FormFields|
<!--- CLI-Appends-Here --->
</cfoutput>
```

## Partial Views

Partials Views start with underscore (_form.cfm, _item.cfm):

### Naming Convention
Partials start with underscore:
- `_form.cfm` - Form partial
- `_item.cfm` - List item partial
- `_sidebar.cfm` - Sidebar partial

```cfm
<!--- In layout or view --->
#includePartial("/shared/header")#
#includePartial("/products/form", product=product)#
```

## Best Practices

1. Keep views simple and focused on presentation
2. Use partials for reusable components
3. Move complex logic to helpers or controllers
4. Follow naming conventions (partials start with _)
5. Use semantic HTML markup

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

### Error Display
```cfm
<cfif product.hasErrors()>
    <div class="alert alert-danger">
        #errorMessagesFor("product")#
    </div>
</cfif>
```

## See Also

- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD
- [wheels generate test](test.md) - Generate view tests