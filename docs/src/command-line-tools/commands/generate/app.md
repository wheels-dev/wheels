# wheels generate app
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*


Create a new Wheels application from templates.

## Synopsis

```bash
wheels generate app [name] [template] [directory] [options]
wheels g app [name] [template] [directory] [options]
wheels new [name] [template] [directory] [options]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels generate app blog` (most common)
- **Named parameters**: `name=value` (e.g., `name=blog`, `template=HelloWorld`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--useBootstrap` equals `useBootstrap=true`)

**Parameter Mixing Rules:**

**ALLOWED:**
- All positional: `wheels generate app blog`
- All positional + flags: `wheels generate app blog --useBootstrap --init`
- All named: `name=blog template=HelloWorld --useBootstrap`

**NOT ALLOWED:**
- Positional + named: `wheels generate app blog name=myapp` (causes error)

**Recommendation:** Use positional for name/template, flags for options: `wheels generate app blog --useBootstrap --init`

## Description

The `wheels generate app` command creates a new Wheels application with a complete directory structure, configuration files, and optionally sample code. It supports multiple templates for different starting points.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Application name | `MyApp` |
| `template` | Template to use | `wheels-base-template@BE` |
| `directory` | Target directory | `./{name}` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `reloadPassword` | Set reload password | `''` (empty) |
| `datasourceName` | Database datasource name | App name |
| `cfmlEngine` | CFML engine (lucee/adobe/boxlang) | `lucee` |
| `--useBootstrap` | Include Bootstrap CSS | `false` |
| `--setupH2` | Setup H2 embedded database | `true` |
| `--init` | Initialize as CommandBox package | `false` |
| `--force` | Overwrite existing directory | `false` |

## Available Templates

### wheels-base-template@BE (Default)
```bash
wheels generate app myapp
```
- Backend Edition template
- Complete MVC structure
- Sample code and configuration
- H2 database setup by default

### HelloWorld
```bash
wheels generate app myapp HelloWorld
```
- Simple "Hello World" example
- One controller and view
- Great for learning

### HelloDynamic
```bash
wheels generate app myapp HelloDynamic
```
- Dynamic content example
- Database interaction
- Form handling

### HelloPages
```bash
wheels generate app myapp HelloPages
```
- Static pages example
- Layout system
- Navigation structure

## Examples

### Create basic application
```bash
# Positional (recommended)
wheels generate app blog

# OR all named
wheels g app name=blog
```

### Create with custom template
```bash
# Positional (recommended)
wheels generate app api HelloDynamic

# OR all named
wheels g app name=api template=HelloDynamic
```

### Create in specific directory
```bash
# Positional + named (recommended)
wheels generate app myapp --directory=./projects/

# OR all named
wheels g app name=myapp directory=./projects/
```

### Create with Bootstrap
```bash
# Positional + flag (recommended)
wheels generate app portfolio --useBootstrap

# OR all named
wheels g app name=portfolio useBootstrap=true
```

### Create with H2 database (default is true)
```bash
# Positional + flag (recommended)
wheels generate app demo --setupH2

# OR all named
wheels g app name=demo setupH2=true
```

### Create with all options
```bash
# Positional + flags (recommended)
wheels generate app enterprise --template=HelloDynamic --directory=./apps/ \
  --reloadPassword=secret \
  --datasourceName=enterprise_db \
  --cfmlEngine=adobe \
  --useBootstrap \
  --setupH2

# OR all named
wheels g app name=enterprise template=HelloDynamic directory=./apps/ \
  reloadPassword=secret \
  datasourceName=enterprise_db \
  cfmlEngine=adobe \
  useBootstrap=true \
  setupH2=true
```

## Generated Structure

```
myapp/
├── .wheels-cli.json      # CLI configuration
├── box.json              # Dependencies
├── server.json           # Server configuration
├── Application.cfc       # Application settings
├── config/
│   ├── app.cfm          # App configuration
│   ├── routes.cfm       # URL routes
│   └── settings.cfm     # Framework settings
├── controllers/
│   └── Main.cfc         # Default controller
├── models/
├── views/
│   ├── layout.cfm       # Default layout
│   └── main/
│       └── index.cfm    # Home page
├── public/
│   ├── stylesheets/
│   ├── javascripts/
│   └── images/
├── tests/
└── wheels/              # Framework files
```

## Configuration Files

### box.json
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "dependencies": {
    "wheels": "^2.5.0"
  }
}
```

### server.json
```json
{
  "web": {
    "http": {
      "port": 3000
    }
  },
  "app": {
    "cfengine": "lucee5"
  }
}
```

### .wheels-cli.json
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "framework": "wheels",
  "reload": "wheels"
}
```

## Database Setup

### With H2 (Embedded)
```bash
wheels generate app myapp
```
- H2 is setup by default (--setupH2=true)
- No external database needed
- Perfect for development
- Auto-configured datasource
- To disable: `--setupH2=false`

### With External Database
1. Create application:
   ```bash
   wheels generate app myapp datasourceName=myapp_db --setupH2=false
   ```

2. Configure in CommandBox:
   ```bash
   server set app.datasources.myapp_db={...}
   ```

## Post-Generation Steps

1. **Navigate to directory**
   ```bash
   cd myapp
   ```

2. **Install dependencies**
   ```bash
   box install
   ```

3. **Start server**
   ```bash
   box server start
   ```

4. **Open browser**
   ```
   http://localhost:3000
   ```

## Template Development

Create custom templates in `~/.commandbox/cfml/modules/wheels-cli/templates/apps/`:

```
mytemplate/
├── config/
├── controllers/
├── models/
├── views/
└── template.json
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
