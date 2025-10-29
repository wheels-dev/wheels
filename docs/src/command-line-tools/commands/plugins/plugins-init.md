# wheels plugin init

Initialize a new CFWheels plugin in the `/plugins` directory.

## Usage

```bash
wheels plugin init <name> [--author=<name>] [--description=<text>] [--version=<version>] [--license=<type>]
```

## Parameters

| Parameter     | Required | Type   | Options                                                   | Default | Description                                    |
|---------------|----------|--------|-----------------------------------------------------------|---------|------------------------------------------------|
| `name`        | Yes      | string | -                                                         | -       | Plugin name (will be prefixed with 'wheels-')  |
| `author`      | No       | string | -                                                         | ""      | Plugin author name                             |
| `description` | No       | string | -                                                         | ""      | Plugin description                             |
| `version`     | No       | string | -                                                         | "1.0.0" | Initial version number                         |
| `license`     | No       | string | MIT, Apache-2.0, GPL-3.0, BSD-3-Clause, ISC, Proprietary | MIT     | License type                                   |

## Description

The `plugin init` command creates a new CFWheels plugin following the standard CFWheels plugin structure. The plugin is created directly in your application's `/plugins` directory and includes all necessary files to get started.

### Features

- Creates plugin in `/plugins` directory
- Follows CFWheels plugin conventions
- Includes `mixin="global"` for framework-wide availability
- Generates documentation files
- Includes test suite
- Ready for ForgeBox publishing

## Examples

### Basic plugin initialization

```bash
wheels plugin init my-helper
```

**Output:**
```
===========================================================
  Initializing Wheels Plugin: wheels-my-helper
===========================================================

Creating plugin in /plugins/myHelper/...

===========================================================

[OK] Plugin created successfully in /plugins/myHelper/

Files Created:
  myHelper.cfc      Main plugin component
  index.cfm         Documentation page
  box.json          Package metadata
  README.md         Project documentation

Next Steps:
  1. Edit myHelper.cfc to add your plugin functions
  2. Update index.cfm and README.md with usage examples
  3. Test: wheels reload (then call your functions)
  4. Publish: box login && box publish
```

### With full metadata

```bash
wheels plugin init authentication \
  --author="Jane Smith" \
  --description="Authentication and authorization system" \
  --version="0.1.0" \
  --license=MIT
```

### Quick initialization

```bash
wheels plugin init api-tools --author="DevTeam"
```

## Generated Structure

The command creates the following structure in `/plugins/pluginName/`:

```
plugins/
└── myHelper/
    ├── box.json           Package configuration
    ├── myHelper.cfc       Main plugin component (mixin="global")
    ├── index.cfm          Plugin documentation page
    ├── README.md          Project documentation
    ├── .gitignore         Git ignore file
    └── tests/             Test suite
        └── myHelperTest.cfc   TestBox tests
```

## File Templates

### myHelper.cfc (Main Plugin Component)

```cfml
component hint="wheels-my-helper" output="false" mixin="global" {

    public function init() {
        this.version = "1.0.0";
        return this;
    }

    /**
     * Example function - Add your plugin methods here
     *
     * [section: Plugins]
     * [category: myHelper]
     *
     * @param1 Description of parameter
     */
    public function myHelperExample(required string param1) {
        // Your plugin logic here
        return arguments.param1;
    }

}
```

**Key Features:**
- `mixin="global"` makes functions available everywhere in Wheels
- Functions documented with Wheels doc format `[section: Plugins]`
- Version tracking via `this.version`

### index.cfm (Documentation Page)

```html
<h1>wheels-my-helper</h1>
<p>Plugin description</p>

<h3>Installation</h3>
<pre>
wheels plugin install wheels-my-helper
</pre>

<h3>Usage</h3>
<h4>Example Function</h4>
<pre>
// Call the example function
result = myHelperExample("test");
</pre>
```

### box.json (Package Metadata)

```json
{
    "name": "wheels-my-helper",
    "version": "1.0.0",
    "author": "Your Name",
    "slug": "wheels-my-helper",
    "type": "cfwheels-plugins",
    "keywords": "cfwheels,wheels,plugin",
    "homepage": "",
    "shortDescription": "Plugin description",
    "private": false
}
```

## Development Workflow

### 1. Initialize Plugin

```bash
wheels plugin init my-helper --author="Your Name"
```

### 2. Add Your Functions

Edit `/plugins/myHelper/myHelper.cfc` and add your plugin methods:

```cfml
public function formatCurrency(required numeric amount) {
    return dollarFormat(arguments.amount);
}

public function slugify(required string text) {
    return lCase(reReplace(arguments.text, "[^a-zA-Z0-9]+", "-", "all"));
}
```

### 3. Update Documentation

Edit `index.cfm` and `README.md` with usage examples and function descriptions.

### 4. Test Your Plugin

```bash
wheels reload
```

Then in your Wheels application:
```cfml
// Your functions are now available everywhere
formatted = formatCurrency(1234.56);  // Returns "$1,234.56"
slug = slugify("My Blog Post");       // Returns "my-blog-post"
```

### 5. Add Tests

Edit `/plugins/myHelper/tests/myHelperTest.cfc`:

```cfml
it("should format currency correctly", function() {
    var plugin = createObject("component", "myHelper").init();
    var result = plugin.formatCurrency(1234.56);
    expect(result).toInclude("1,234");
});
```

Run tests:
```bash
box testbox run
```

### 6. Publish to ForgeBox

```bash
cd plugins/myHelper
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/username/wheels-my-helper.git
git push -u origin main

box login
box publish
```

## Plugin Types

Common CFWheels plugin categories:

- **Data Helpers** - String manipulation, date formatting, validation
- **Authentication** - User authentication, session management, encryption
- **API Tools** - REST helpers, JSON formatting, API clients
- **Database** - Query helpers, soft delete, auditing
- **UI Components** - Form helpers, tables, pagination
- **Email** - Email formatting, templates, sending
- **Caching** - Cache management, warming, invalidation
- **Testing** - Test helpers, fixtures, mocking

## Best Practices

1. **Naming Convention**: Always prefix with `wheels-` (automatic)
2. **Function Naming**: Use clear, descriptive names
3. **Documentation**: Document all public functions with Wheels format
4. **Testing**: Include comprehensive test coverage
5. **Versioning**: Follow semantic versioning (MAJOR.MINOR.PATCH)
6. **Dependencies**: Minimize external dependencies
7. **Compatibility**: Test with supported Wheels versions

## How Plugin Loading Works

1. Wheels scans `/plugins` directory on startup
2. Each plugin's main CFC is instantiated
3. With `mixin="global"`, functions become available in:
   - Controllers
   - Models
   - Views
   - Other plugins
4. Call `wheels reload` to reload plugins after changes

## Error Handling

### Plugin Already Exists

```
[ERROR] Plugin already exists

Plugin 'myHelper' already exists in /plugins folder
```

**Solution**: Choose a different name or remove the existing plugin first.

### No Wheels Application

The command must be run from within a Wheels application directory.

## Notes

- Plugin is created directly in `/plugins` directory
- Plugin name automatically prefixed with `wheels-` if not present
- Folder name uses simple plugin name (without `wheels-` prefix)
- Use `mixin="global"` to make functions available everywhere
- Restart or reload Wheels after creating plugin
- Plugin functions documented with `[section: Plugins]` format
- Type must be `cfwheels-plugins` for ForgeBox categorization

## See Also

- [wheels plugin install](plugins-install.md) - Install plugins from ForgeBox
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels reload](../core/reload.md) - Reload application
- [Developing Plugins](../../../plugins/developing-plugins.md) - Full plugin development guide
