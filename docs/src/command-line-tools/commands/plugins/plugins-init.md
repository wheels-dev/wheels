# wheels plugin init (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Initialize a new Wheels plugin project with scaffolding.

## Synopsis

```bash
wheels plugin init <name> [--author=<name>] [--description=<text>] [--version=<version>] [--license=<type>]
```

## Description

The `wheels plugin init` command creates a new Wheels plugin project with a complete directory structure, configuration files, and example code. It follows Wheels plugin conventions and prepares the plugin for development and distribution on ForgeBox.

## Arguments

### name (required)
Name of the plugin. Will be prefixed with 'wheels-' if not already present.

## Options

### --author
Plugin author name.
- **Default**: Empty string
- **Example**: `--author="John Doe"`

### --description
Plugin description.
- **Default**: Empty string
- **Example**: `--description="Authentication system for Wheels"`

### --version
Initial version number.
- **Default**: `1.0.0`
- **Example**: `--version=0.1.0`

### --license
License type for the plugin.
- **Default**: `MIT`
- **Options**: `MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, `ISC`, `Proprietary`

## Examples

### Basic plugin initialization
```bash
wheels plugin init my-plugin
```

### With metadata
```bash
wheels plugin init authentication \
  --author="Jane Smith" \
  --description="Complete auth system" \
  --version="0.1.0" \
  --license=MIT
```

### Quick start
```bash
wheels plugin init wheels-api-tools --author="DevTeam"
```

## Generated Structure

```
wheels-my-plugin/
├── box.json              # Package configuration
├── ModuleConfig.cfc      # CommandBox module configuration
├── README.md             # Documentation template
├── .gitignore           # Git ignore file
├── commands/            # CLI commands directory
│   └── hello.cfc        # Example command
├── models/              # Service components
├── templates/           # File templates
└── tests/               # Test suite
    └── MainTest.cfc     # Example test
```

## File Contents

### box.json
```json
{
  "name": "wheels-my-plugin",
  "version": "1.0.0",
  "author": "John Doe",
  "type": "commandbox-modules,cfwheels-plugins",
  "keywords": "cfwheels,wheels,cli,plugin",
  "shortDescription": "Plugin description",
  "license": [{
    "type": "MIT",
    "URL": ""
  }]
}
```

### ModuleConfig.cfc
```cfml
component {
    this.title = "wheels-my-plugin";
    this.author = "John Doe";
    this.version = "1.0.0";
    this.description = "Plugin description";
    
    function configure() {
        // Module settings
        settings = {};
    }
    
    function onLoad() {
        // Register commands
    }
}
```

### Example Command
```cfml
component extends="commandbox.system.BaseCommand" {
    function run() {
        print.greenLine("Hello from wheels-my-plugin!");
    }
}
```

## Development Workflow

After initialization:

1. **Navigate to directory**
   ```bash
   cd wheels-my-plugin
   ```

2. **Initialize Git**
   ```bash
   git init
   git add .
   git commit -m "Initial plugin structure"
   ```

3. **Install dependencies**
   ```bash
   box install
   ```

4. **Link for local development**
   ```bash
   box package link
   ```

5. **Test example command**
   ```bash
   wheels hello
   ```

## Plugin Development

### Adding Commands
Create new commands in the `commands/` directory:
```cfml
// commands/mycommand.cfc
component extends="commandbox.system.BaseCommand" {
    function run(required string name) {
        print.line("Hello, #arguments.name#!");
    }
}
```

### Adding Services
Create service components in `models/`:
```cfml
// models/MyService.cfc
component singleton {
    function processData(data) {
        // Service logic
    }
}
```

### Adding Templates
Place template files in `templates/`:
```
templates/
├── controller.txt
├── model.txt
└── view.txt
```

## Publishing

When ready to publish:

1. **Update version**
   ```bash
   box bump --minor
   ```

2. **Login to ForgeBox**
   ```bash
   box login
   ```

3. **Publish**
   ```bash
   box package publish
   ```

## Best Practices

1. **Naming**: Always prefix with `wheels-`
2. **Versioning**: Start with 0.1.0 for initial development
3. **Documentation**: Update README.md with usage instructions
4. **Testing**: Add comprehensive tests in `/tests/`
5. **Examples**: Include working examples
6. **Dependencies**: Minimize external dependencies

## Plugin Types

Common plugin categories:
- **Authentication & Security**
- **API Development**
- **Database Tools**
- **Development Helpers**
- **Testing Utilities**
- **Performance Tools**
- **UI Components**

## Configuration Options

The generated ModuleConfig.cfc supports:
- Settings management
- Event interceptors
- Custom injection bindings
- Command registration
- Lifecycle hooks

## Testing

Run tests with:
```bash
box testbox run
```

## Notes

- Plugin name automatically prefixed with 'wheels-'
- Creates git-ready project structure
- Includes CommandBox module configuration
- Ready for ForgeBox publishing
- Example command demonstrates basic functionality

## See Also

- [wheels generate plugin](../generate/plugin.md) - Alternative plugin generator
- [wheels plugin install](plugins-install.md) - Install plugins
- [Plugin Development Guide](../../plugin-development.md)
- [Publishing to ForgeBox](https://forgebox.io/publishing)