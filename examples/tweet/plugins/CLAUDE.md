# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with plugins in a Wheels application.

## Overview

Plugins are the recommended way to extend Wheels functionality without modifying the core framework. They allow you to add new functions, override existing ones, or create complete standalone features. Wheels uses a plugin architecture that keeps the core lightweight while enabling powerful extensions through community contributions.

## Plugin Architecture

### Purpose and Philosophy
- **Core remains lightweight**: Only essential functionality in Wheels core
- **Community extensions**: Plugins provide additional features
- **Easy distribution**: Zip files for simple installation/removal
- **Version compatibility**: Plugins specify compatible Wheels versions
- **Mixins system**: Functions injected into appropriate Wheels objects

### Plugin Lifecycle
1. **Development**: Create plugin CFC and interface files
2. **Packaging**: Zip plugin files with version number
3. **Distribution**: Publish to forgebox.io repository  
4. **Installation**: Drop zip in `/plugins` folder
5. **Loading**: Wheels automatically extracts and loads on startup
6. **Injection**: Plugin functions mixed into framework objects

## Plugin Structure

### Required Files

**`PluginName.cfc`** - Main plugin component:
```cfm
component {
    function init() {
        this.version = "2.0,3.0"; // Compatible Wheels versions
        return this;
    }
    
    // Plugin functions here
    public string function myNewFunction() {
        return "Hello from plugin!";
    }
}
```

**`index.cfm`** - Plugin user interface (shown in debug area):
```cfm
<cfoutput>
<h1>My Plugin #application.wheels.pluginMeta["myPlugin"]["version"]#</h1>
<p>This plugin adds amazing functionality to your Wheels app.</p>

<h3>Usage Examples:</h3>
<pre>
##myNewFunction()##
##linkTo(text="Click Me", action="index", customAttribute="value")##
</pre>
</cfoutput>
```

**`box.json`** - Package metadata (required for publishing):
```json
{
    "name": "My Amazing Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "location": "username/repo-name#v1.0.0",
    "directory": "/plugins/",
    "createPackageDirectory": true,
    "packageDirectory": "MyAmazingPlugin",
    "slug": "my-amazing-plugin",
    "type": "wheels-plugins",
    "shortDescription": "Adds amazing functionality",
    "keywords": "wheels,plugin,amazing"
}
```

### Plugin Packaging
```bash
# File structure
MyPlugin/
├── MyPlugin.cfc      # Main component
├── index.cfm         # UI interface  
├── box.json          # Package metadata
└── README.md         # Documentation

# Zip as: MyPlugin-1.0.0.zip
```

## Plugin Development

### Basic Plugin Template
```cfm
component {
    /**
     * Initialize plugin - REQUIRED method
     */
    function init() {
        this.version = "3.0"; // Wheels version compatibility
        return this;
    }
    
    /**
     * Add new functionality
     */
    public string function myHelper() {
        return "Custom functionality";
    }
    
    /**
     * Override existing function
     */
    public string function timeAgoInWords() {
        // Call original function and modify result
        return core.timeAgoInWords(argumentCollection=arguments) & " (approximately)";
    }
    
    /**
     * Private plugin function (use $ prefix)
     */
    private string function $internalHelper() {
        return "Internal use only";
    }
}
```

### Plugin Attributes

#### Mixin Targeting
Control where plugin functions are injected:

```cfm
<!--- Component level --->
<cfcomponent mixin="controller">
    <!--- All functions injected into controllers only --->
</cfcomponent>

<!--- Function level --->
component {
    public string function controllerOnly() mixin="controller" {
        return "Only available in controllers";
    }
    
    public string function modelOnly() mixin="model" {
        return "Only available in models";
    }
    
    public string function everywhere() {
        return "Available everywhere (default)";
    }
}
```

**Available mixin targets**:
- `controller` - Controllers and views
- `model` - Model objects
- `dispatch` - Dispatch object
- `global` - Global functions
- `application` - Application scope
- `none` - No injection
- `microsoftsqlserver`, `mysql`, `oracle`, `postgresql` - Database adapters

#### Environment Targeting
Restrict plugin loading to specific environments:

```cfm
<cfcomponent mixin="controller" environment="development">
    <!--- Only loads in development mode --->
</cfcomponent>

<cfcomponent environment="development,testing">
    <!--- Loads in development and testing only --->
</cfcomponent>
```

#### Plugin Dependencies
Specify required plugins:

```cfm
<cfcomponent dependency="BasePlugin,UtilityPlugin">
    <!--- Requires BasePlugin and UtilityPlugin to be installed --->
</cfcomponent>
```

### Function Override Patterns

#### Extending Core Functions
```cfm
component {
    /**
     * Override linkTo to add custom attributes
     */
    public string function linkTo() {
        // Extract custom arguments
        local.customClass = "";
        if (StructKeyExists(arguments, "customClass")) {
            local.customClass = arguments.customClass;
            StructDelete(arguments, "customClass");
        }
        
        // Call original function
        local.result = core.linkTo(argumentCollection=arguments);
        
        // Modify result if needed
        if (len(local.customClass)) {
            local.result = Replace(local.result, 'class="', 'class="' & local.customClass & ' ');
        }
        
        return local.result;
    }
}
```

#### Complete Function Replacement
```cfm
component {
    /**
     * Completely override a function
     */
    public string function singularize() {
        // Custom singularization logic
        return "$$completelyOverridden";
    }
    
    /**
     * Override with fallback to core
     */
    public string function pluralize() {
        // Custom logic first, then core fallback
        if (someCondition) {
            return customPluralize(argumentCollection=arguments);
        }
        return core.pluralize(argumentCollection=arguments);
    }
}
```

### Stand-Alone Plugins
Plugins that work independently without mixing into framework:

```cfm
component {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    public any function processData(required string input) {
        // Standalone functionality
        return processInput(arguments.input);
    }
}
```

Access from views via plugin object:
```cfm
<!--- In index.cfm or views --->
<cfoutput>
    #myPlugin.processData("test data")#
</cfoutput>
```

## Development Workflow

### Local Development Setup
Configure development-friendly settings in `/config/development/settings.cfm`:

```cfm
<cfscript>
// Prevent plugin files from being overwritten by zip
set(overwritePlugins = false);

// Prevent plugin directories from being deleted
set(deletePluginDirectories = false);

// Allow incompatible plugins for testing
set(loadIncompatiblePlugins = true);
</cfscript>
```

### Development Process
1. **Create plugin directory**: `/plugins/MyPlugin/`
2. **Develop plugin files**: `MyPlugin.cfc`, `index.cfm`
3. **Test locally**: Reload app with `?reload=true`
4. **Package for distribution**: Create zip file
5. **Publish to forgebox**: Use CommandBox publishing workflow

### Testing Plugins
```cfm
<!--- In plugin CFC --->
component {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Test function for development
     */
    public string function testFunction() {
        return "Plugin is working: " & Now();
    }
}
```

Test in views:
```cfm
<cfoutput>
    Plugin test: #testFunction()#
</cfoutput>
```

## Plugin Installation

### Manual Installation
1. Download plugin zip file
2. Place in `/plugins/` directory
3. Reload application: `?reload=true`
4. Plugin automatically extracts and loads

### CommandBox Installation
```bash
# List available plugins
wheels plugins list

# Install specific plugin
box install shortcodes

# Install specific version  
box install my-plugin@1.2.0

# Install from GitHub
box install username/repo-name
```

### Plugin Management Commands
```bash
# Plugin information
wheels plugins info pluginName

# List installed plugins
wheels plugins list --installed

# Check for updates
wheels plugins outdated

# Update plugin
wheels plugins update pluginName

# Update all plugins
wheels plugins update-all

# Remove plugin
wheels plugins remove pluginName
```

## Plugin Examples

### Simple Helper Plugin
```cfm
component {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Format currency with custom options
     * [section: View Helpers]
     * [category: Formatting]
     */
    public string function formatCurrency(required numeric amount, string symbol="$") {
        return arguments.symbol & NumberFormat(arguments.amount, "0.00");
    }
    
    /**
     * Generate random string
     * [section: Utilities] 
     * [category: String]
     */
    public string function randomString(numeric length=8) {
        local.chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        local.result = "";
        
        for (local.i = 1; local.i <= arguments.length; local.i++) {
            local.randomChar = Mid(local.chars, RandRange(1, Len(local.chars)), 1);
            local.result &= local.randomChar;
        }
        
        return local.result;
    }
}
```

### Form Enhancement Plugin
```cfm
component mixin="controller" {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Enhanced buttonTo with confirmation
     */
    public string function buttonTo() {
        local.confirm = $extractConfirm(arguments);
        local.result = core.buttonTo(argumentCollection=arguments);
        
        if (Len(local.confirm)) {
            local.result = $addJSConfirm(local.result, local.confirm, "input");
        }
        
        return local.result;
    }
    
    /**
     * Enhanced linkTo with confirmation  
     */
    public string function linkTo() {
        local.confirm = $extractConfirm(arguments);
        local.result = core.linkTo(argumentCollection=arguments);
        
        if (Len(local.confirm)) {
            local.result = $addJSConfirm(local.result, local.confirm, "a");
        }
        
        return local.result;
    }
    
    /**
     * Extract and remove confirm argument
     */
    private string function $extractConfirm(required struct args) {
        local.confirm = "";
        if (StructKeyExists(arguments.args, "confirm")) {
            local.confirm = arguments.args.confirm;
            StructDelete(arguments.args, "confirm");
        }
        return local.confirm;
    }
    
    /**
     * Add JavaScript confirmation to HTML
     */
    private string function $addJSConfirm(required string html, required string confirm, required string tag) {
        local.js = "return confirm('#JSStringFormat(arguments.confirm)#');";
        local.onclick = ' onclick="' & local.js & '"';
        
        // Find tag position and add onclick
        local.tagPos = Find("<" & arguments.tag & " ", arguments.html);
        if (local.tagPos) {
            local.closePos = Find(">", arguments.html, local.tagPos);
            local.result = Insert(local.onclick, arguments.html, local.closePos - 1);
        } else {
            local.result = arguments.html;
        }
        
        return local.result;
    }
}
```

### Model Enhancement Plugin
```cfm
component mixin="model" {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Add slug functionality to models
     */
    public string function generateSlug(required string text) {
        local.slug = LCase(arguments.text);
        local.slug = REReplace(local.slug, "[^a-z0-9\s]", "", "all");
        local.slug = REReplace(local.slug, "\s+", "-", "all");
        local.slug = REReplace(local.slug, "^-+|-+$", "", "all");
        return local.slug;
    }
    
    /**
     * Auto-slug functionality in beforeSave callback
     */
    public void function beforeSave() {
        // Auto-generate slug from title if empty
        if (hasProperty("slug") && hasProperty("title") && !Len(property("slug"))) {
            property(name="slug", value=generateSlug(property("title")));
        }
        
        // Call any existing beforeSave
        if (StructKeyExists(this, "$originalBeforeSave")) {
            $originalBeforeSave();
        }
    }
}
```

### Flash Messages Plugin  
```cfm
component {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Override flashMessages for Bootstrap styling
     */
    public string function flashMessages() {
        local.result = core.flashMessages(argumentCollection=arguments);
        
        if (Len(local.result)) {
            // Remove outer div
            local.result = Replace(local.result, '<div class="flash-messages">', '');
            local.result = Replace(local.result, '</div>', '');
            
            // Convert p tags to Bootstrap alerts
            local.result = Replace(local.result, '<p', '<div', 'all');
            local.result = Replace(local.result, '</p>', '</div>', 'all');
            
            // Add Bootstrap classes and dismiss button
            local.append = ' role="alert"><button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>';
            
            local.result = Replace(local.result, 'class="success-message">', 'class="alert alert-success alert-dismissible"' & local.append, 'all');
            local.result = Replace(local.result, 'class="error-message">', 'class="alert alert-danger alert-dismissible"' & local.append, 'all');
            local.result = Replace(local.result, 'class="info-message">', 'class="alert alert-info alert-dismissible"' & local.append, 'all');
            local.result = Replace(local.result, 'class="warning-message">', 'class="alert alert-warning alert-dismissible"' & local.append, 'all');
        }
        
        return local.result;
    }
}
```

## Plugin Publishing

### ForgeBox Setup
```bash
# Register for forgebox account
forgebox register

# Or login with existing account
forgebox login

# Verify login
forgebox whoami
```

### Package Configuration
Create comprehensive `box.json`:

```json
{
    "name": "MyAwesome Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "location": "username/repo-name#v1.0.0",
    "directory": "/plugins/",
    "createPackageDirectory": true,
    "packageDirectory": "MyAwesomePlugin",
    "slug": "my-awesome-plugin",
    "type": "wheels-plugins",
    "homepage": "https://github.com/username/repo-name",
    "shortDescription": "Adds awesome functionality to Wheels",
    "keywords": "wheels,plugin,awesome,helper",
    "private": false,
    "scripts": {
        "postVersion": "package set location='username/repo-name#v`package version`'",
        "patch-release": "bump --patch && publish",
        "minor-release": "bump --minor && publish", 
        "major-release": "bump --major && publish",
        "postPublish": "!git push --follow-tags"
    }
}
```

### Publishing Workflow
```bash
# Initial setup in plugin directory
git init
git add .
git commit -m "Initial plugin version"
git remote add origin https://github.com/username/repo-name.git
git push -u origin master

# Publishing releases
run-script patch-release  # 1.0.0 -> 1.0.1
run-script minor-release  # 1.0.0 -> 1.1.0  
run-script major-release  # 1.0.0 -> 2.0.0
```

This automatically:
- Updates version in `box.json`
- Creates git tag
- Pushes to GitHub
- Publishes to forgebox

### Manual Publishing
```bash
# Publish current version
publish

# Publish specific version
publish 1.2.3

# Unpublish version
unpublish 1.2.3 --force
```

## Advanced Plugin Patterns

### Plugin with Java Libraries
```cfm
component {
    function init() {
        this.version = "3.0";
        // Java libs automatically mapped from plugin directory
        return this;
    }
    
    public any function processWithJava() {
        // Use Java classes from plugin's .jar files
        local.processor = CreateObject("java", "com.myplugin.Processor");
        return local.processor.process(argumentCollection=arguments);
    }
}
```

### Plugin Configuration
```cfm
component {
    function init() {
        this.version = "3.0";
        
        // Set plugin defaults
        set(functionName="myPlugin", defaultOption="value");
        
        return this;
    }
    
    public string function myPlugin() {
        // Use configured defaults
        local.option = get("myPluginDefaultOption");
        return processWithOption(local.option);
    }
}
```

### Plugin Callbacks
```cfm
component {
    function init() {
        this.version = "3.0";
        return this;
    }
    
    /**
     * Called when plugin is loaded
     */
    public void function onLoad() {
        // Plugin initialization logic
        initializePlugin();
    }
    
    /**
     * Called when application reloads
     */
    public void function onReload() {
        // Reload-specific logic
        clearPluginCache();
    }
}
```

### Testing Integration
Create test files in plugin:

```cfm
<!--- tests/PluginTest.cfc --->
component extends="BaseSpec" {
    function run() {
        describe("MyPlugin", function() {
            it("should format currency correctly", function() {
                expect(formatCurrency(123.45)).toBe("$123.45");
                expect(formatCurrency(123.45, "€")).toBe("€123.45");
            });
            
            it("should generate random strings", function() {
                local.result = randomString(10);
                expect(len(local.result)).toBe(10);
            });
        });
    }
}
```

### CI/CD Integration
`.travis.yml` for automated testing:

```yaml
language: java
sudo: required
jdk:
  - oraclejdk8

before_install:
  - sudo apt-key adv --keyserver keys.gnupg.net --recv 6DA70622
  - sudo echo "deb http://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list

install:
  - sudo apt-get update && sudo apt-get --assume-yes install CommandBox
  - box version
  - box install wheels-cli
  - box install wheels-dev/wheels
  - box install username/my-plugin

before_script:
  - box server start lucee5

script: >
  testResults="$(box wheels test type=myplugin servername=lucee5)";
  echo "$testResults";
  if ! grep -i "\Tests Complete: All Good!" <<< $testResults; then exit 1; fi

notifications:
  email: true
```

## Plugin Security and Best Practices

### Security Considerations
```cfm
component {
    /**
     * Validate input in plugin functions
     */
    public string function processData(required string input) {
        // Validate and sanitize input
        if (!isValid("string", arguments.input)) {
            throw(message="Invalid input provided");
        }
        
        // Escape output if generating HTML
        return EncodeForHtml(processInput(arguments.input));
    }
    
    /**
     * Use private functions for internal logic
     */
    private string function $validateInput(required string input) {
        // Private validation logic
        return arguments.input;
    }
}
```

### Performance Best Practices
```cfm
component {
    /**
     * Cache expensive operations
     */
    public string function expensiveOperation(required string input) {
        local.cacheKey = "plugin_operation_" & Hash(arguments.input);
        
        if (get("cacheQueries")) {
            local.result = cacheGet(local.cacheKey);
            if (isDefined("local.result")) {
                return local.result;
            }
        }
        
        local.result = performExpensiveOperation(arguments.input);
        
        if (get("cacheQueries")) {
            cachePut(local.cacheKey, local.result, CreateTimeSpan(0, 1, 0, 0));
        }
        
        return local.result;
    }
}
```

### Documentation Standards
```cfm
component {
    /**
     * Process user input data
     *
     * [section: Plugins]
     * [category: Data Processing]
     *
     * @input The raw input string to process
     * @format Output format (html, text, xml)
     * @validate Whether to validate input (default: true)
     * @return Processed string in specified format
     */
    public string function processData(
        required string input,
        string format="html",
        boolean validate=true
    ) {
        // Implementation here
    }
}
```

## Plugin Management

### Version Compatibility
```cfm
component {
    function init() {
        // Multiple version support
        this.version = "2.0,3.0,3.1";
        return this;
    }
}
```

### Plugin Dependencies
```cfm
component dependency="BaseUtilities,DateHelpers" {
    function init() {
        this.version = "3.0";
        
        // Check dependencies are loaded
        if (!StructKeyExists(application.wheels.plugins, "BaseUtilities")) {
            throw(message="BaseUtilities plugin required");
        }
        
        return this;
    }
}
```

### Plugin Settings Management
```cfm
// In /config/settings.cfm
set(overwritePlugins = false);           // Don't overwrite during development
set(deletePluginDirectories = false);   // Don't delete plugin folders
set(loadIncompatiblePlugins = true);    // Load plugins with version warnings
set(showIncompatiblePlugins = true);    // Show compatibility warnings
```

### Plugin Debugging
```cfm
component {
    function init() {
        this.version = "3.0";
        
        // Debug mode check
        if (get("environment") == "development") {
            writeLog(text="MyPlugin loaded successfully", file="application");
        }
        
        return this;
    }
    
    public string function debugFunction() {
        if (get("showDebugInformation")) {
            return "Plugin debug info: " & SerializeJSON(getPluginInfo());
        }
        return "";
    }
}
```

## Plugin Distribution

### File Organization
```
MyPlugin/
├── MyPlugin.cfc          # Main component
├── index.cfm             # Plugin interface
├── box.json              # Package metadata  
├── README.md             # Documentation
├── CHANGELOG.md          # Version history
├── LICENSE               # License file
├── tests/                # Test files
│   └── MyPluginTest.cfc
├── docs/                 # Additional documentation
├── lib/                  # Java libraries (.jar files)
└── assets/               # CSS/JS/Images
```

### ZIP Packaging
```bash
# Create distribution zip
zip -r MyPlugin-1.0.0.zip MyPlugin/ -x "*.git*" "*tests*"
```

### Installation Verification
Users can verify plugin installation:

```cfm
<!--- Check if plugin loaded --->
<cfif StructKeyExists(application.wheels.plugins, "MyPlugin")>
    <p>MyPlugin is loaded</p>
    <p>Version: #application.wheels.pluginMeta["MyPlugin"]["version"]#</p>
<cfelse>
    <p>MyPlugin not found</p>
</cfif>
```

Plugins provide a powerful way to extend Wheels functionality while maintaining a clean separation from the core framework. They enable community contributions, code reuse, and customization without compromising the framework's lightweight philosophy.