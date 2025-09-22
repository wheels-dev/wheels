# wheels generate app-wizard

Interactive wizard for creating a new Wheels application with guided setup.

## Synopsis

```bash
wheels generate app-wizard [options]

#Can also be used as:
wheels g app-wizard [options]
wheels new [options]
```

## Parameter Syntax

CommandBox supports multiple parameter formats:

- **Named parameters**: `name=value` (e.g., `name=MyApp`, `template=wheels-base-template@BE`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--expert` equals `expert=true`)
- **Flag with value**: `--flag=value` equals `flag=value` (e.g., `--skipInstall=true`)

**Note**: Flag syntax (`--flag`) avoids positional/named parameter conflicts and is recommended for boolean options.

## Description

The `wheels generate app-wizard` command provides an interactive, step-by-step wizard for creating a new Wheels application. It guides you through configuration options with helpful prompts, making it ideal for beginners or when you want to explore available options.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Application name (optional - will prompt if not provided) | Prompted |

## Options

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `template` | App template to use | ForgeBox endpoint or slug | `wheels-base-template@BE` |
| `directory` | Directory to create app in | Valid directory path | `{current directory}/{name}` |
| `reloadPassword` | Reload password for the app | Any string | `changeMe` |
| `datasourceName` | Database datasource name | Valid datasource name | `{app name}` |
| `cfmlEngine` | CFML engine for server.json | `lucee`, `adobe`, `lucee6`, `lucee5`, `adobe2023`, etc. | `lucee` |
| `useBootstrap` | Add Bootstrap to the app | `true`, `false` | `false` |
| `setupH2` | Setup H2 database for development | `true`, `false` | `true` |
| `init` | Initialize directory as a package | `true`, `false` | `false` |
| `force` | Force installation into non-empty directory | `true`, `false` | `false` |
| `nonInteractive` | Run without prompts using defaults | `true`, `false` | `false` |
| `expert` | Show advanced configuration options | `true`, `false` | `false` |
| `skipInstall` | Skip dependency installation after creation | `true`, `false` | `false` |

## Interactive Wizard Steps

### Step 1: Application Name
```
Please enter a name for your application: MyWheelsApp
```
- Validates name format (alphanumeric, underscores, hyphens)
- Checks for reserved names
- Creates directory with this name

### Step 2: Template Selection
```
Which Wheels Template shall we use?
❯ 3.0.x - Wheels Base Template - Bleeding Edge
  2.5.x - Wheels Base Template - Stable Release
  Wheels Template - HTMX - Alpine.js - Simple.css
  Wheels Starter App
  Wheels - TodoMVC - HTMX - Demo App
  Enter a custom template endpoint
```

### Step 3: Reload Password
```
Please enter a 'reload' password for your application: changeMe
```
- Used for `?reload=true&password=xxx` functionality
- Secures application reload via URL

### Step 4: Database Configuration
```
Please enter a datasource name if different from MyWheelsApp: MyWheelsApp
```
- Sets datasource name in configuration files
- You'll configure the actual datasource in your CFML server admin

### Step 5: CFML Engine Selection
```
Please select your preferred CFML engine?
❯ Lucee (Latest)
  Adobe ColdFusion (Latest)
  Lucee 6.x
  Lucee 5.x
  Adobe ColdFusion 2023
  Adobe ColdFusion 2021
  Adobe ColdFusion 2018
  Enter a custom engine endpoint
```

### Step 6: H2 Database Setup (Lucee Only, if skipInstall=false)
```
H2 Java embedded SQL database for development? [y,n]
```
- Only shown when using Lucee engine
- Only asked if `skipInstall=false`
- Sets up embedded H2 database for development

### Step 7: Dependencies (if skipInstall=false)
```
========= Dependencies ======================
Configure dependencies and plugins for your application.

Would you like us to setup some default Bootstrap settings? [y/n]
```
- Only shown if `skipInstall=false`
- Configures Bootstrap CSS framework
- Additional dependencies may be added here

### Step 8: Package Initialization
```
Finally, shall we initialize your application as a package
by creating a box.json file? [y,n]
```
- Creates box.json for ForgeBox package management
- Always asked regardless of `skipInstall` setting

### Step 9: Expert Mode (if expert=true)
```
========= Expert Mode: Advanced Configuration ==========
Configure advanced options for your application.

Custom server port (leave empty for default 8080): 8080
Custom JVM settings (e.g. -Xmx512m -Xms256m):
Setup custom environment configurations (dev, staging, production)? [y,n]
Enable advanced routing features (nested resources, constraints)? [y,n]
Custom plugin repositories (comma-separated URLs):
Build tool integration? [None/Apache Ant/Gradle/Maven/NPM Scripts]
```

### Step 10: Configuration Review
```
+-----------------------------------------------------------------------------------+
| Great! Think we're all good to go. We're going to create a Wheels application for |
| you with the following parameters.                                                |
+-----------------------+-----------------------------------------------------------+
| Template              | wheels-base-template@BE                                   |
| Application Name      | MyWheelsApp                                              |
| Install Directory     | D:\path\to\MyWheelsApp                                   |
| Reload Password       | changeMe                                                 |
| Datasource Name       | MyWheelsApp                                              |
| CF Engine             | lucee                                                    |
| Setup H2 Database     | true                                                     | (if applicable)
| Setup Bootstrap       | false                                                    | (if applicable)
| Initialize as Package | true                                                     |
| Force Installation    | false                                                    |
| Skip Dependency Install | false                                                  |
+-----------------------+-----------------------------------------------------------+

Sound good? [y/n]
```

## skipInstall Parameter Behavior

The `skipInstall` parameter significantly changes the wizard experience:

### When skipInstall=false (default)
- ✅ Asks about H2 database setup (if using Lucee)
- ✅ Asks about Bootstrap dependencies
- ✅ Shows "Dependencies" section
- ✅ Includes dependency settings in summary table
- ✅ Installs dependencies after app creation

### When skipInstall=true
- ❌ **Skips** H2 database question (even with Lucee)
- ❌ **Skips** Bootstrap dependency question
- ✅ Shows "Dependencies Skipped" message with explanation
- ✅ Excludes dependency settings from summary table
- ✅ Still asks about package initialization (`box.json` creation)
- ✅ Still asks about core configuration (name, template, passwords, etc.)
- ❌ **Skips** dependency installation after app creation

### Dependencies Skipped Message
```
========= Dependencies Skipped ================
Dependency installation is disabled (skipInstall=true).
Dependencies like Bootstrap and H2 database will not be configured or installed.
```

## Examples

### Basic Interactive Wizard
```bash
wheels generate app-wizard
```
Runs full interactive wizard with all prompts.

### Pre-configured App Name
```bash
wheels generate app-wizard name=MyApp
```
Skips name prompt, asks for other configuration.

### Skip All Dependencies
```bash
wheels generate app-wizard --skipInstall
```
Runs wizard but skips H2 database and Bootstrap questions.

### Expert Mode
```bash
wheels generate app-wizard --expert
```
Includes advanced configuration options like custom ports and JVM settings.

### Non-Interactive Mode
```bash
wheels generate app-wizard --nonInteractive
```
Uses all defaults, no prompts. Creates app immediately.

### Fully Configured
```bash
wheels generate app-wizard name=MyApp template=wheels-base-template@BE --skipInstall --expert --force
```
Pre-configured with expert mode and skipped dependencies.

## Expert Mode Options

When `--expert` is enabled, additional configuration options are available:

### Server Configuration
- **Custom server port**: Override default port 8080
- **JVM settings**: Custom memory and performance settings

### Environment Setup
- **Custom environment configurations**: Setup dev, staging, production configs
- **Advanced routing features**: Enable nested resources and route constraints

### Development Tools
- **Custom plugin repositories**: Additional ForgeBox endpoints
- **Build tool integration**: Ant, Gradle, Maven, or NPM integration

## Non-Interactive Mode

Use `--nonInteractive` to bypass all prompts:

### Default Values Used
- **Name**: `MyWheelsApp`
- **Template**: `wheels-base-template@BE`
- **Reload Password**: `changeMe`
- **Datasource Name**: Same as app name
- **CFML Engine**: `lucee`
- **Directory**: `{current directory}/{name}`

### Override Defaults
```bash
wheels generate app-wizard --nonInteractive name=CustomApp template=wheels-starter-app --cfmlEngine=adobe
```

## Post-Creation Steps

After successful creation:

```
Model generation complete!

Next steps:
   1. cd MyWheelsApp
   2. Review generated configuration files
   3. Configure your datasource in CFML server admin
   4. box server start (to start development server)
   5. Visit http://localhost:8080

Additional commands:
   - wheels generate model User name:string,email:string
   - wheels generate controller Users
   - wheels dbmigrate up (run database migrations)
   - wheels test run (run tests)
```

## Validation Rules

### Application Name
- Must start with a letter
- Can contain letters, numbers, underscores, and hyphens
- Cannot contain spaces or special characters
- Cannot exceed 50 characters
- Cannot be a reserved name (con, prn, aux, nul, wheels, etc.)

### Directory Path
- Must be a valid file system path
- Parent directory must exist and be writable
- Will warn if target directory is not empty (unless `--force` used)

## Error Handling

### Common Issues and Solutions

**Invalid application name**:
```
'123app' is not valid. Application name must start with a letter.
Please try again: MyApp
```

**Directory not empty**:
```
Target directory is not empty. Use --force to overwrite, or choose a different location.
```

**Missing dependencies**:
```
Warning: Some dependencies could not be installed.
Run 'box install' in your application directory to install them manually.
```

## Best Practices

1. **Use descriptive names**: Choose clear, project-specific application names
2. **Review configuration**: Check the summary table before confirming
3. **Consider skipInstall**: Use `--skipInstall` for custom dependency management
4. **Expert mode for production**: Use `--expert` for production-ready configurations
5. **Save time with non-interactive**: Use `--nonInteractive` in automated scripts
6. **Template selection**: Choose templates that match your project requirements

## Common Patterns

### API-Only Application
```bash
wheels generate app-wizard name=MyAPI template=wheels-base-template@BE --skipInstall --expert
```

### Full-Stack Web Application
```bash
wheels generate app-wizard name=MyWebApp --useBootstrap --setupH2
```

### Team Development Setup
```bash
wheels generate app-wizard --nonInteractive name=TeamProject template=wheels-starter-app --cfmlEngine=lucee --force
```

### CI/CD Pipeline
```bash
wheels generate app-wizard --nonInteractive --skipInstall name=BuildApp template=wheels-base-template@BE
```

## Troubleshooting

### Wizard Hangs or Freezes
1. Check terminal compatibility
2. Try `--nonInteractive` mode
3. Ensure adequate system resources

### Installation Failures
1. Verify internet connection for template downloads
2. Check CommandBox version compatibility
3. Try `--skipInstall` and install dependencies manually
4. Check file permissions in target directory

### Configuration Issues
1. Review generated `server.json` file
2. Verify datasource configuration in CFML admin
3. Check application settings in `/config/app.cfm`

## See Also

- [wheels generate app](app.md) - Non-interactive app generation
- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [wheels scaffold](scaffold.md) - Generate complete CRUD