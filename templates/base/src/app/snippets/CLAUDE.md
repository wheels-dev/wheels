# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code snippets in a Wheels application.

## Overview

The `/app/snippets` directory contains code templates used by the Wheels CLI generators to create consistent, well-structured application components. These snippets serve as blueprints for controllers, models, views, migrations, tests, and configuration files, using a template variable system to generate customized code. They ensure consistency across generated code and provide a foundation for rapid application development.

## Directory Structure and Purpose

### Snippet Organization
```
app/snippets/
├── ActionContent.txt            (Individual controller action template)
├── ApiControllerContent.txt     (REST API controller template)
├── ControllerContent.txt        (Basic controller template)
├── CRUDContent.txt             (Full CRUD controller template)
├── ModelContent.txt            (Basic model template)
├── ViewContent.txt             (Basic view template)
├── BoxJSON.txt                 (Application box.json template)
├── WheelsBoxJSON.txt           (Wheels metadata template)
├── ServerJSON.txt              (CommandBox server config template)
├── ConfigAppContent.txt        (Application.cfc config template)
├── ConfigDataSourceH2Content.txt (H2 database config template)
├── ConfigReloadPasswordContent.txt (Reload password config template)
├── ConfigRoutes.txt            (Routes configuration template)
├── DBMigrate.txt               (Migration base template)
├── bootstrap/                   (Bootstrap framework templates)
│   ├── layout.cfm              (Bootstrap layout template)
│   └── settings.cfm            (Bootstrap settings template)
├── crud/                       (CRUD view templates)
│   ├── _form.txt               (Shared form partial template)
│   ├── index.txt               (List view template)
│   ├── show.txt                (Detail view template)
│   ├── new.txt                 (Create form template)
│   └── edit.txt                (Edit form template)
├── dbmigrate/                  (Database migration templates)
│   ├── blank.txt               (Empty migration template)
│   ├── create-table.txt        (Create table migration)
│   ├── create-column.txt       (Add column migration)
│   ├── remove-column.txt       (Remove column migration)
│   ├── change-column.txt       (Modify column migration)
│   ├── rename-column.txt       (Rename column migration)
│   ├── create-index.txt        (Add index migration)
│   ├── remove-index.txt        (Remove index migration)
│   ├── rename-table.txt        (Rename table migration)
│   ├── remove-table.txt        (Drop table migration)
│   ├── create-record.txt       (Insert data migration)
│   ├── update-record.txt       (Update data migration)
│   ├── remove-record.txt       (Delete data migration)
│   ├── execute.txt             (SQL execution migration)
│   └── announce.txt            (Announcement migration)
└── tests/                      (Test templates)
    ├── controller.txt          (Controller test template)
    ├── model.txt               (Model test template)
    └── view.txt                (View test template)
```

## Template Variable System

### Variable Syntax
Snippets use two types of template variables:

**Pipe Delimited Variables**: `|VariableName|`
- Used for simple string replacements
- Common in basic templates

**Double Brace Variables**: `{{variableName}}`
- Used for more complex replacements
- Often used for conditional content or arrays

### Common Template Variables

**Application Variables:**
- `|appName|` - Application name
- `|version|` - Application version
- `|datasourceName|` - Database datasource name
- `|reloadPassword|` - Application reload password

**Object Variables:**
- `|ObjectNameSingular|` - Singular form (e.g., "user")
- `|ObjectNamePlural|` - Plural form (e.g., "users") 
- `|ObjectNameSingularC|` - Capitalized singular (e.g., "User")
- `|ObjectNamePluralC|` - Capitalized plural (e.g., "Users")
- `|objectNameSingular|` - Lowercase singular (e.g., "user")
- `|objectNamePlural|` - Lowercase plural (e.g., "users")

**Action Variables:**
- `|Action|` - Action name
- `|ActionHint|` - Action description/hint
- `|Actions|` - Collection of actions

**Database Variables:**
- `|tableName|` - Database table name
- `|primaryKey|` - Primary key column name
- `|force|` - Force flag for migrations
- `|id|` - Include ID flag

**Migration Variables:**
- `|DBMigrateExtends|` - Migration base class
- `|DBMigrateDescription|` - Migration description

**Relationship Variables:**
- `{{belongsToRelationships}}` - BelongsTo relationships
- `{{hasManyRelationships}}` - HasMany relationships

## Core Templates

### Controller Templates

**Basic Controller (`ControllerContent.txt`):**
```cfm
component extends="Controller" {

  /**
	* Controller config settings
	**/
	function config() {

	}
|Actions|
}
```

**CRUD Controller (`CRUDContent.txt`):**
```cfm
component extends="Controller" {

	function config() {
		verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
	}

	/**
	* View all |ObjectNamePluralC|
	**/
	function index() {
		|ObjectNamePlural|=model("|ObjectNameSingular|").findAll();
	}

	/**
	* View |ObjectNameSingularC|
	**/
	function show() {
		|ObjectNameSingular|=model("|ObjectNameSingular|").findByKey(params.key);
	}

	// ... additional CRUD methods
}
```

**API Controller (`ApiControllerContent.txt`):**
```cfm
component extends="wheels.Controller" {

    function init() {
        provides("json");
		filters(through="setJsonResponse");
    }

    /**
     * GET /#objectNamePlural#
     * Returns a list of all #objectNamePlural#
     */
    function index() {
        local.#objectNamePlural# = model("|ObjectNameSingular|").findAll();
        renderWith(data={ #objectNamePlural#=local.#objectNamePlural# });
    }

    /**
     * GET /#objectNamePlural#/:key
     * Returns a specific #objectNameSingular# by ID
     */
    function show() {
        local.#objectNameSingular# = model("|ObjectNameSingular|").findByKey(params.key);

        if (IsObject(local.#objectNameSingular#)) {
            renderWith(data={ #objectNameSingular#=local.#objectNameSingular# });
        } else {
            renderWith(data={ error="Record not found" }, status=404);
        }
    }
    
    // ... additional API methods
}
```

### Model Templates

**Basic Model (`ModelContent.txt`):**
```cfm
component extends="Model" {

	function config() {
		{{belongsToRelationships}}
		{{hasManyRelationships}}
	}

}
```

### View Templates

**Basic View (`ViewContent.txt`):**
```cfm
<cfoutput>
// CLI-Appends-Here
</cfoutput>
```

**CRUD Index View (`crud/index.txt`):**
```cfm
<cfparam name="|ObjectNamePlural|">
<cfoutput>
<h1>|ObjectNamePluralC|</h1>

<p>
	#linkTo(route="new|ObjectNameSingular|", text="New |ObjectNameSingularC|", class="btn btn-primary")#
</p>

<cfif |ObjectNamePlural|.recordcount>
	<table class="table">
		<thead>
			<tr>
				<th>ID</th>
				<th>Actions</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="|ObjectNamePlural|">
			<tr>
				<td>#|ObjectNamePlural|.id#</td>
				<td>
					#linkTo(route="|ObjectNameSingular|", key=|ObjectNamePlural|.id, text="View", class="btn btn-info")#
					#linkTo(route="edit|ObjectNameSingular|", key=|ObjectNamePlural|.id, text="Edit", class="btn btn-primary")#
					#buttonTo(route="|ObjectNameSingular|", method="delete", key=|ObjectNamePlural|.id, text="Delete", class="btn btn-danger", confirm="Are you sure?")#
				</td>
			</tr>
			</cfloop>
		</tbody>
	</table>
<cfelse>
	<p>No |ObjectNamePlural| found.</p>
</cfif>
</cfoutput>
```

## Database Migration Templates

### Create Table Migration (`dbmigrate/create-table.txt`)

**Template Structure:**
```cfm
/*
  |----------------------------------------------------------------------------------------------|
	| Parameter  | Required | Type    | Default | Description                                      |
  |----------------------------------------------------------------------------------------------|
	| name       | Yes      | string  |         | table name, in pluralized form                   |
	| force      | No       | boolean | false   | drop existing table of same name before creating |
	| id         | No       | boolean | true    | if false, defines a table with no primary key    |
	| primaryKey | No       | string  | id      | overrides default primary key name               |
  |----------------------------------------------------------------------------------------------|

    EXAMPLE:
      t = createTable(name='employees', force=false, id=true, primaryKey='empId');
			t.string(columnNames='firstName,lastName', default='', null=true, limit='255');
			t.text(columnNames='bio', default='', null=true);
			t.timestamps();
			t.create();
*/
component extends="|DBMigrateExtends|" hint="|DBMigrateDescription|" {

	function up() {
		transaction {
			try {
				t = createTable(name = '|tableName|', force='|force|', id='|id|', primaryKey='|primaryKey|');
				t.timestamps();
				t.create();
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				dropTable('|tableName|');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}
}
```

### Add Column Migration (`dbmigrate/create-column.txt`)

**Template Features:**
- Complete parameter documentation
- Transaction handling with rollback
- Error handling and exception management
- Up and down migration methods

## Configuration Templates

### Application Configuration (`ConfigAppContent.txt`)

```cfm
<cfscript>
	/*
		Place settings that should go in the Application.cfc's "this" scope here.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/

	// Added via Wheels CLI
	this.name = "|appName|";
	// CLI-Appends-Here
</cfscript>
```

### Database Configuration (`ConfigDataSourceH2Content.txt`)

```cfm
<cfscript>
	// Added via Wheels CLI
	set(dataSourceName="|datasourceName|");
	set(URLRewriting="On");
	// Reload your application with ?reload=true&password=|reloadPassword|
	set(reloadPassword="|reloadPassword|");
	// CLI-Appends-Here
</cfscript>
```

### Routes Configuration (`ConfigRoutes.txt`)

```cfm
<cfscript>
	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/docs/routing for more info.

	mapper()
		// CLI-Appends-Here
		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		// You can, for example, change "wheels##wheels" to "home##index" to call the "index" action on the "home" controller instead.
		.root(to="wheels##wheels", method="get")
	.end();
</cfscript>
```

## Test Templates

### Controller Test Template (`tests/controller.txt`)

```cfm
component extends="testbox.system.BaseSpec" {

	function run() {

		// Write the name for your test suite in the "" in describe function. You can create mutiple suites by writing multiple describes.
		describe("", () => {

			beforeEach(() => {
				
			})

			afterEach(() => {
				
			})

			// Your controller tests here:

		})
	}
}
```

### Model Test Template (`tests/model.txt`)

```cfm
component extends="testbox.system.BaseSpec" {

	function run() {

		// Write the name for your test suite in the "" in describe function. You can create mutiple suites by writing multiple describes.
		describe("", () => {

			beforeEach(() => {
				
			})

			afterEach(() => {
				
			})

			// Your model tests here:

		})
	}
}
```

## Package Configuration Templates

### Application Box.json (`BoxJSON.txt`)

```json
{
    "name":"|appName|",
    "version":"1.0.0",
    "author":"Wheels Core Team and Community, repackaged by Peter Amiri",
    "shortDescription":"Wheels MVC Framework Base Template",
    "slug":"myapp",
    "type":"wheels-templates",
    "keywords":[
        "mvc",
        "rails",
        "wheels",
        "core"
    ],
    "homepage":"https://wheels.dev/",
    "documentation":"https://docs.wheels.dev/",
    "dependencies":{
        "wheels":"|version|",
        "orgh213172lex":"lex:https://ext.lucee.org/org.h2-1.3.172.lex"
    },
    "installPaths":{
        "wheels":"wheels/"
    }
}
```

### Server Configuration (`ServerJSON.txt`)

```json
{
	"name": "|appName|",
	"port": 60001,
	"host": "localhost",
	"directoryBrowsing": false,
	"openbrowser": false
}
```

## Bootstrap Framework Templates

### Bootstrap Layout (`bootstrap/layout.cfm`)

**Features:**
- Complete HTML5 document structure
- Bootstrap 3.x integration
- Social media meta tags (Twitter, Facebook)
- Responsive viewport settings
- CSRF protection integration
- CDN-based asset loading

**Template Structure:**
```cfm
<cfoutput>
<!DOCTYPE html>
<html lang="en">
  <head>
  	<meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <cfoutput>#csrfMetaTags()#</cfoutput>
    <title>|appName|</title>
    
    <!--- Bootstrap CSS --->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    
  </head>
<body>
<header>
    <div class="container">
	   <h1 class="site-title">#linkTo(route="root", text="|appName|")#</h1>
    </div>
</header>

<div id="content" class="container">
    #flashMessages()#
	<section>
	    #includeContent()#
	</section>
</div>

#javascriptIncludeTag("https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js,https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js")#
</body>
</html>
</cfoutput>
```

## CLI Integration

### How Snippets Are Used

**Generator Commands:**
```bash
# Generate controller with snippet
wheels generate controller Users index,show,new,create,edit,update,delete

# Generate model with snippet
wheels generate model User name:string,email:string,active:boolean

# Generate CRUD scaffold
wheels generate scaffold Product name:string,price:decimal,inStock:boolean

# Generate API controller
wheels generate api-resource Users

# Generate migration
wheels generate migration CreateUsersTable
```

### Template Processing Flow

1. **CLI Command Execution**: User runs generator command
2. **Snippet Selection**: CLI selects appropriate template file
3. **Variable Extraction**: CLI extracts variables from command parameters
4. **Template Processing**: CLI replaces template variables with actual values
5. **File Generation**: CLI writes processed template to target location
6. **Post-Processing**: CLI may perform additional formatting or validation

### Variable Resolution Examples

**Controller Generation:**
```bash
wheels generate controller Users index,show
```

**Variable Mapping:**
- `|ObjectNameSingular|` → "User"
- `|ObjectNamePlural|` → "Users"  
- `|objectNameSingular|` → "user"
- `|objectNamePlural|` → "users"
- `|Actions|` → Generated action methods

## Customizing Snippets

### Creating Custom Templates

**Custom Snippet Structure:**
```cfm
component extends="Controller" {
    
    /**
     * Custom controller for |ObjectNameSingular| management
     * Generated by Custom Template v1.0
     */
    function config() {
        // Custom configuration
        filters(through="authenticate", except="index");
        provides("html,json");
    }
    
    /**
     * List all |ObjectNamePluralC| with pagination
     */
    function index() {
        param name="params.page" default="1";
        param name="params.perPage" default="10";
        
        |ObjectNamePlural| = model("|ObjectNameSingular|").findAll(
            page = params.page,
            perPage = params.perPage,
            order = "createdAt DESC"
        );
    }
}
```

### Snippet Best Practices

**Template Design:**
1. **Consistent Formatting**: Use consistent indentation and spacing
2. **Comprehensive Comments**: Include helpful comments and documentation  
3. **Error Handling**: Include appropriate try/catch blocks
4. **Parameter Validation**: Use `cfparam` for expected variables
5. **Security Considerations**: Include CSRF protection and validation

**Variable Naming:**
- Use descriptive variable names
- Follow established naming conventions
- Provide fallback values where appropriate
- Document expected variable types and formats

### Advanced Template Features

**Conditional Content:**
```cfm
<cfif isDefined("includeValidation") and includeValidation>
    // Validation code here
</cfif>
```

**Loop Generation:**
```cfm
<cfloop array="#properties#" item="property">
    #property.name# = #property.type#;
</cfloop>
```

**Dynamic Method Generation:**
```cfm
<cfloop list="#actionList#" item="action">
    function #action#() {
        // Generated action method
    }
</cfloop>
```

## Integration with IDE and Editors

### Code Completion Support

**Template Variables:**
- IDEs can provide code completion for template variables
- Snippet previews show expected output
- Variable documentation available in IDE tooltips

### Syntax Highlighting

**Template Syntax:**
- Template variables highlighted differently from code
- Comments and documentation properly formatted
- CFML and HTML syntax preserved in mixed templates

## Troubleshooting Snippets

### Common Issues

**Variable Replacement Problems:**
```cfm
// Check variable name spelling
|ObjectNameSingular| // Correct
|ObjectNameSinguar| // Incorrect - typo

// Verify variable scope
|appName| // Application level
|Action| // Action level
{{belongsToRelationships}} // Complex variable
```

**Template Syntax Errors:**
```cfm
// Missing closing pipe
|ObjectNameSingular

// Incorrect brace style  
{ObjectNameSingular} // Wrong - should be {{}}

// Mixed variable types
|ObjectName{{Singular}}| // Invalid syntax
```

### Debugging Template Generation

**Variable Inspection:**
```cfm
// Add debug output to templates during development
<cfdump var="#variables#" label="Template Variables">
<cfabort>
```

**Generated Code Validation:**
```cfm
// Verify generated code compiles
try {
    generatedComponent = new path.to.GeneratedComponent();
} catch (any e) {
    writeOutput("Generation Error: " & e.message);
}
```

The snippets directory provides the foundation for rapid, consistent code generation in Wheels applications, ensuring that generated components follow established patterns and best practices while remaining customizable for specific project needs.