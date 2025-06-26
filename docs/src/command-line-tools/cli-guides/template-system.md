# Template System

The Wheels CLI uses a powerful template system for code generation that allows you to customize the output to match your project's coding standards and conventions.

## Overview

The template system enables:
- **Consistent Code Generation** - All generated code follows the same patterns
- **Project Customization** - Override templates to match your project's needs
- **Markup Control** - Customize HTML, CSS frameworks, and JavaScript patterns
- **Convention Enforcement** - Ensure generated code follows your team's standards

## How It Works

### Template Resolution

When the CLI generates code, it looks for templates in this order:

1. **Application Templates** (`/app/snippets/`)
   - Project-specific templates that override defaults
   - Allows per-project customization
   
2. **CLI Templates** (`/cli/templates/`)
   - Default templates shipped with the CLI
   - Fallback when no app template exists

This hierarchy ensures that your customizations always take precedence over the defaults.

### Template Processing

Templates are processed through these steps:

1. **Template Loading** - The appropriate template file is loaded
2. **Placeholder Replacement** - Variables and placeholders are replaced with actual values
3. **Code Generation** - The processed content is written to the destination file

## Template Override System

### Purpose

The template override system allows you to:
- Customize generated markup to match your CSS framework (Bootstrap, Tailwind, etc.)
- Add project-specific code patterns and conventions
- Include custom comments, documentation, or boilerplate
- Modify the structure of generated files

### Creating Custom Templates

To override a CLI template:

1. **Identify the template** you want to customize
   ```bash
   # View available templates
   ls /path/to/wheels/cli/templates/
   ```

2. **Create the directory structure** in your app
   ```bash
   mkdir -p app/snippets/crud
   ```

3. **Copy the template** to your app
   ```bash
   cp /path/to/wheels/cli/templates/crud/_form.txt app/snippets/crud/
   ```

4. **Modify the template** to match your needs
   ```bash
   # Edit with your preferred editor
   code app/snippets/crud/_form.txt
   ```

### Example: Customizing Form Templates

Default form template (`/cli/templates/crud/_form.txt`):
```cfm
<!--- |ObjectNameSingularC| Form Contents --->
<cfoutput>
|FormFields|
<!--- CLI-Appends-Here --->
</cfoutput>
```

Custom Bootstrap 5 template (`/app/snippets/crud/_form.txt`):
```cfm
<!--- |ObjectNameSingularC| Form --->
<cfoutput>
<div class="card">
    <div class="card-body">
        #errorMessagesFor("|ObjectNameSingular|")#
        
        <div class="form-fields">
            |FormFields|
        </div>
        
        <div class="form-actions mt-3">
            #submitTag(value="Save", class="btn btn-primary")#
            #linkTo(text="Cancel", action="index", class="btn btn-secondary")#
        </div>
    </div>
</div>
<!--- CLI-Appends-Here --->
</cfoutput>
```

## Available Templates

### Model Templates
- `ModelContent.txt` - Base model structure
- `dbmigrate/*.txt` - Migration templates

### Controller Templates  
- `ControllerContent.txt` - Base controller structure
- `ApiControllerContent.txt` - API controller structure

### View Templates
- `ViewContent.txt` - Generic view template
- `crud/index.txt` - List/index view
- `crud/show.txt` - Show single record
- `crud/new.txt` - New record form
- `crud/edit.txt` - Edit record form
- `crud/_form.txt` - Form partial

### Test Templates
- `tests/model.txt` - Model test structure
- `tests/controller.txt` - Controller test structure
- `tests/view.txt` - View test structure

### Configuration Templates
- `ConfigAppContent.txt` - Application configuration
- `ConfigRoutes.txt` - Routes configuration
- `ConfigDataSourceH2Content.txt` - H2 database configuration

## Template Variables

### Object Name Variables
- `|ObjectNameSingular|` - Lowercase singular (e.g., "product")
- `|ObjectNamePlural|` - Lowercase plural (e.g., "products")
- `|ObjectNameSingularC|` - Capitalized singular (e.g., "Product")
- `|ObjectNamePluralC|` - Capitalized plural (e.g., "Products")

### Dynamic Content Variables
- `|FormFields|` - Generated form fields based on properties
- `|Actions|` - Generated controller actions
- `{{belongsTo}}` - Belongs-to relationship code
- `{{hasMany}}` - Has-many relationship code
- `{{validations}}` - Model validation code

### Marker Comments
- `<!--- CLI-Appends-Here --->` - Marker for future CLI additions
- `<!--- CLI-Appends-thead-Here --->` - Table header additions
- `<!--- CLI-Appends-tbody-Here --->` - Table body additions

## Best Practices

### 1. Version Control Templates
Always commit your custom templates to version control:
```bash
git add app/snippets/
git commit -m "Add custom templates for Bootstrap 5"
```

### 2. Document Customizations
Add comments explaining your customizations:
```cfm
<!--- 
    Custom template for Bootstrap 5 forms
    - Uses card layout
    - Includes form validation styles
    - Adds cancel button
--->
```

### 3. Maintain Placeholders
Keep important placeholders and markers:
- Always include `<!--- CLI-Appends-Here --->` for future additions
- Preserve variable placeholders you might need later

### 4. Test Generated Code
After customizing templates:
```bash
# Generate a test scaffold
wheels scaffold test properties=name:string

# Verify the output matches expectations
# Delete test files when done
```

### 5. Share Team Templates
Create a shared template repository for team consistency:
```bash
# Create template package
cd app/snippets
tar -czf project-templates.tar.gz *

# Share with team
```

## Advanced Customization

### Conditional Generation
Use CFML logic in templates:
```cfm
<cfif arrayLen(properties) GT 5>
    <!--- Use compact layout for many fields --->
    <div class="row">
        |FormFields|
    </div>
<cfelse>
    <!--- Standard layout --->
    |FormFields|
</cfif>
```

### Custom Placeholders
Add your own placeholders in templates:
```cfm
<!--- |ProjectName| - |GeneratedDate| --->
<!--- Version: |Version| --->
```

Then handle them in your custom generator commands.

### Framework-Specific Templates

Create template sets for different CSS frameworks:
```
app/snippets/
├── bootstrap5/
│   └── crud/
│       ├── _form.txt
│       └── index.txt
├── tailwind/
│   └── crud/
│       ├── _form.txt
│       └── index.txt
└── crud/  # Current active templates
    ├── _form.txt
    └── index.txt
```

Switch between them by copying to the active directory.

## Troubleshooting

### Templates Not Being Used
1. Check file paths - ensure templates are in `/app/snippets/`
2. Verify file names match exactly (case-sensitive)
3. Reload CommandBox if changes aren't picked up: `box reload`

### Generated Code Has Errors
1. Check for syntax errors in your template
2. Ensure all placeholders are properly closed
3. Test with a simple template first

### Placeholders Not Replaced
1. Verify placeholder syntax is exact
2. Check that the data is being passed to the template
3. Some placeholders only work in specific template types

## See Also

- [Creating Commands](creating-commands.md) - Build custom generators
- [Service Architecture](service-architecture.md) - Understand the template service
- [wheels scaffold](../commands/generate/scaffold.md) - Main scaffold documentation