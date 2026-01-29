# wheels generate app
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*


Create a new Wheels application from templates.

## Synopsis

```bash
wheels generate app [name] [template] [directory] [options]
wheels g app [name] [template] [directory] [options]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate app blog` (most common)
- **Named parameters**: `name=value` (e.g., `name=blog`, `template=WheelsBaseTemplate`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--useBootstrap` equals `useBootstrap=true`)

**Parameter Mixing Rules:**

**ALLOWED:**
- All positional: `wheels generate app blog`
- All positional + flags: `wheels generate app blog --useBootstrap --init`
- All named: `name=blog template=WheelsBaseTemplate --useBootstrap`

**NOT ALLOWED:**
- Positional + named: `wheels generate app blog name=myapp` (causes error)

**Recommendation:** Use positional for name/template, flags for options: `wheels generate app blog --useBootstrap --init`

## Description

The `wheels generate app` command creates a new Wheels application with a complete directory structure, configuration files, and optionally sample code. It supports multiple templates for different starting points.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Application name | `MyApp` |
| `template` | Template to use | `wheels-base-template@^3.0.0` |
| `directory` | Target directory | `./{name}` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `reloadPassword` | Set reload password | (empty) |
| `datasourceName` | Database datasource name | App name |
| `cfmlEngine` | CFML engine (lucee/adobe/boxlang) | `lucee` |
| `--useBootstrap` | Include Bootstrap CSS | `false` |
| `--setupH2` | Setup H2 embedded database | `true` |
| `--init` | Initialize as CommandBox package | `false` |
| `--force` | Overwrite existing directory | `false` |

## Available Templates

### wheels-base-template@^3.0.0 (stable)
```bash
wheels generate app myapp
```
- Backend Edition default template
- Complete MVC structure with proven, production-ready defaults
- Sample code with minimal, predictable configuration
- H2 database setup by default

### BleedingEdge
```bash
wheels generate app myapp BleedingEdge
```
- Backend Edition template
- Complete MVC structure
- Sample code and configuration
- H2 database setup by default

### WheelsStarterApp
```bash
wheels generate app myapp WheelsStarterApp
```
- Starter user management and authentication application built with Wheels 3.0
- Demonstrates best practices for security, conventions, and MVC architecture
- Full authentication & authorization flow (registration, verification, RBAC, admin panel)
- Built-in security features: CSRF protection, audit logging, bcrypt passwords, role checks
- Modern, responsive UI using Bootstrap with Wheels helpers
- Multi-database support with easy setup via CommandBox (MySQL, PostgreSQL, MSSQL, Oracle, H2)

### WheelsTemplateHTMX
```bash
wheels generate app myapp WheelsTemplateHTMX
```
- Blank starter application for Wheels
- Full MVC structure pre-configured
- htmx integrated for server-side AJAX interactions
- Alpine.js included for lightweight client-side interactivity
- simple.css bundled for clean, minimal styling
- Ready-to-extend layout with sample configuration

### WheelsTodoMVCHTMX
```bash
wheels generate app myapp WheelsTodoMVCHTMX
```
- Reference TodoMVC implementation built with CFWheels
- Uses HTMX for server-driven interactivity
- Demonstrates real-world MVC and CRUD patterns
- Quick setup using CommandBox, CFWheels CLI, and H2

## Examples

### Create basic application
```bash
# Positional (recommended)
wheels generate app blog

# OR all named
wheels g app name=blog
```

### Create in specific directory
```bash
# Positional + named (recommended)
wheels generate app myapp --directory=./projects/
```

### Create with Bootstrap
```bash
# Positional + flag (recommended)
wheels generate app portfolio --useBootstrap
```

### Create with H2 database (default is true)
```bash
# Positional + flag (recommended)
wheels generate app demo --setupH2
```

### Create with all options
```bash
# Positional + flags (recommended)
wheels generate app enterprise --template=HelloDynamic --directory=./apps/ --reloadPassword=secret --datasourceName=enterprise_db --cfmlEngine=adobe --useBootstrap --setupH2
```

## Generated Structure

```
myapp/
├── .gitignore              # Github gitignore file
├── box.json                # Dependencies
├── server.json             # Server configuration
├── README.md               # Description about application
├── config/
│   ├── development/
│   │   └── settings.cfm    # Environment specific settings
│   ├── maintenance/
│   │   └── settings.cfm    # Environment specific settings
│   ├── production/
│   │   └── settings.cfm    # Environment specific settings
│   ├── testing/
│   │   └── settings.cfm    # Environment specific settings
│   ├── app.cfm             # App configuration
│   ├── routes.cfm          # URL routes
│   ├── environment.cfm     # Environment
│   └── settings.cfm        # Framework settings
├── app/
│   ├── controllers/
│   │   └── Controller.cfc  # Default controller
│   ├── events/             # Default event handlers
│   ├── migrator/           # Contains migrations
│   ├── models/
│   │   └── Model.cfc       # Default model
│   ├── snippets/
│   ├── views/
│   │   ├── helpers.cfm     # Default helpers
│   │   └── layout.cfm       # Default layout
├── public/
│   ├── files/
│   ├── stylesheets/
│   ├── javascripts/
│   ├── images/
│   ├── miscellaneous/
│   ├── Application.cfc     # Application settings
│   ├── index.cfm           # Home page
│   └── urlrewrite.xml       
├── plugins/
├── tests/
└── vendor/                 # Framework files
    ├── testbox/
    ├── wheels/
    └── wirebox/
```

## Configuration Files

### box.json
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "author": "Wheels Core Team and Community",
  "installPaths": {
    "wheels-core": "vendor/wheels/",
    "wirebox": "vendor/wirebox/",
    "testbox": "vendor/testbox/"
  },
  "dependencies": {
    "wheels-core": "3.0.0",
    "wirebox": "^7",
    "testbox": "^6",
  }
}
```

### server.json
```json
{
    "name":"myapp",
    "web":{
        "host":"localhost",
        "webroot":"public",
        "rewrites":{
            "enable":true,
            "config":"public/urlrewrite.xml"
        }
    },
    "app":{
        "cfengine":"lucee",
        "libDirs":"app/lib"
    }
}
```

### Configure Custom Port in server.json
```json
{
  "web": {
    "http": {
      "enable":true,
      "port":"3000"
    }
  }
}
```

## Best Practices

1. Use descriptive application names
2. Choose appropriate template for project type
3. Set secure reload password for production
4. Configure datasource before starting
5. Run tests after generation

## Common Issues

- **Directory exists**: Use `--force` or choose different name
- **Template not found**: Check available templates with `wheels info`
- **Datasource errors**: Configure database connection
- **Port conflicts**: Change port in `server.json`

## See Also

- [wheels init](../core/init.md) - Initialize existing application
- [wheels generate app-wizard](app-wizard.md) - Interactive app creation
- [wheels scaffold](scaffold.md) - Generate CRUD scaffolding
