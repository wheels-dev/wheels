# wheels generate app

Create a new Wheels application from templates.

## Synopsis

```bash
wheels generate app [name] [template] [directory] [options]
wheels g app [name] [template] [directory] [options]
wheels new [name] [template] [directory] [options]
```

## Description

The `wheels generate app` command creates a new Wheels application with a complete directory structure, configuration files, and optionally sample code. It supports multiple templates for different starting points.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Application name | Required |
| `template` | Template to use | `Base` |
| `directory` | Target directory | `./{name}` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `reload-password` | Set reload password | `wheels` |
| `datasource-name` | Database datasource name | App name |
| `cfml-engine` | CFML engine (lucee/adobe) | `lucee` |
| `--use-bootstrap` | Include Bootstrap CSS | `false` |
| `--setup-h2` | Setup H2 embedded database | `false` |
| `--init` | Initialize as CLI-enabled app | `true` |
| `--force` | Overwrite existing directory | `false` |
| `--help` | Show help information | |

## Available Templates

### Base (Default)
```bash
wheels generate app myapp
```
- Minimal Wheels application
- Basic directory structure
- Essential configuration files

### Base@BE (Backend Edition)
```bash
wheels generate app myapp Base@BE
```
- Backend-focused template
- No view files
- API-ready configuration

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
wheels generate app blog
```

### Create with custom template
```bash
wheels generate app api Base@BE
```

### Create in specific directory
```bash
wheels generate app myapp Base ./projects/
```

### Create with Bootstrap
```bash
wheels generate app portfolio --use-bootstrap
```

### Create with H2 database
```bash
wheels generate app demo --setup-h2
```

### Create with all options
```bash
wheels generate app enterprise HelloDynamic ./apps/ \
  reload-password=secret \
  datasource-name=enterprise_db \
  cfml-engine=adobe \
  --use-bootstrap \
  --setup-h2
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
    "cfengine": "lucee@5"
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
wheels generate app myapp --setup-h2
```
- No external database needed
- Perfect for development
- Auto-configured datasource

### With External Database
1. Create application:
   ```bash
   wheels generate app myapp datasource-name=myapp_db
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