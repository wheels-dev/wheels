/**
 * Initialize a new Wheels plugin project
 * Examples:
 * wheels plugin init my-wheels-plugin
 * wheels plugin init wheels-awesome-feature --author="John Doe"
 */
component aliases="wheels plugin init" extends="../base" {

    /**
     * @name.hint Name of the plugin (will be prefixed with 'wheels-' if not already)
     * @author.hint Plugin author name
     * @description.hint Plugin description
     * @version.hint Initial version number
     * @license.hint License type
     * @license.options MIT,Apache-2.0,GPL-3.0,BSD-3-Clause,ISC,Proprietary
     */
    function run(
        required string name,
        string author = "",
        string description = "",
        string version = "1.0.0",
        string license = "MIT"
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                license=["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause", "ISC", "Proprietary"]
            }
        );

        try {

            // Ensure plugin name follows convention
            var pluginName = arguments.name;
            if (!reFindNoCase("^wheels-", pluginName)) {
                pluginName = "wheels-" & pluginName;
            }

            // Extract simple plugin name (without "wheels-" prefix)
            var simplePluginName = replaceNoCase(pluginName, "wheels-", "", "one");

            // Convert to camelCase for function names (remove hyphens and capitalize)
            var functionPrefix = simplePluginName;
            if (find("-", functionPrefix)) {
                // Split by hyphen and capitalize each word after the first
                var parts = listToArray(functionPrefix, "-");
                functionPrefix = parts[1];
                for (var i = 2; i <= arrayLen(parts); i++) {
                    functionPrefix &= uCase(left(parts[i], 1)) & right(parts[i], len(parts[i]) - 1);
                }
            }

            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Initializing Wheels Plugin: #pluginName#")
                 .boldCyanLine("===========================================================")
                 .line();

            // Create plugin in /plugins directory
            var pluginsBaseDir = fileSystemUtil.resolvePath("plugins");
            var pluginDir = pluginsBaseDir & "/" & simplePluginName;

            // Ensure /plugins directory exists
            if (!directoryExists(pluginsBaseDir)) {
                directoryCreate(pluginsBaseDir);
            }

            if (directoryExists(pluginDir)) {
                print.boldRedText("[ERROR] ")
                     .redLine("Plugin already exists")
                     .line()
                     .yellowLine("Plugin '#simplePluginName#' already exists in /plugins folder")
                     .line();
                setExitCode(1);
                return;
            }

            print.line("Creating plugin in /plugins/#simplePluginName#/...");

            // Create plugin directory
            directoryCreate(pluginDir);
            directoryCreate(pluginDir & "/tests");

            // Create box.json
            var boxJson = {
                "name": pluginName,
                "version": arguments.version,
                "author": arguments.author,
                "slug": pluginName,
                "type": "cfwheels-plugins",
                "keywords": "cfwheels,wheels,plugin",
                "homepage": "",
                "shortDescription": arguments.description,
                "private": false
            };

            fileWrite(pluginDir & "/box.json", serializeJSON(boxJson, true));

            // Create main plugin CFC
            var pluginCFC = 'component hint="#pluginName#" output="false" mixin="global" {

    public function init() {
        this.version = "#arguments.version#";
        return this;
    }

    /**
     * Example function - Add your plugin methods here
     *
     * [section: Plugins]
     * [category: #functionPrefix#]
     *
     * @param1 Description of parameter
     */
    public function #functionPrefix#Example(required string param1) {
        // Your plugin logic here
        return arguments.param1;
    }

}';

            fileWrite(pluginDir & "/#simplePluginName#.cfc", pluginCFC);

            // Create index.cfm (plugin documentation page)
            var indexCFM = '<h1>#pluginName#</h1>
<p>#arguments.description#</p>

<h3>Installation</h3>
<pre>
wheels plugin install #pluginName#
</pre>

<h3>Usage</h3>
<h4>Example Function</h4>
<pre>
// Call the example function
result = #functionPrefix#Example("test");
</pre>

<h3>Functions</h3>
<ul>
    <li><strong>#functionPrefix#Example()</strong> - Example function</li>
</ul>

<h3>Version</h3>
<p>#arguments.version#</p>

<h3>Author</h3>
<p>#arguments.author#</p>
';

            fileWrite(pluginDir & "/index.cfm", indexCFM);

            // Create README.md
            var readme = "## #pluginName#

#arguments.description#

## Installation

Install via CommandBox:

```bash
wheels plugin install #pluginName#
```

## Usage

#### Example Function

```cfml
// Call the example function
result = #functionPrefix#Example(""test"");
```

## Functions

- **#functionPrefix#Example()** - Example function description

## Development

## Running Tests

```bash
box testbox run
```

## Publishing

```bash
box login
box publish
```

## License

#arguments.license#

## Author

#arguments.author#
";

            fileWrite(pluginDir & "/README.md", readme);
            
            // Create .gitignore
            var gitignore = '.DS_Store
.settings
settings.xml
WEB-INF
tests/results/
node_modules/
.env
.tmp/
*.log';
            
            fileWrite(pluginDir & "/.gitignore", gitignore);

            // Create test file
            var testFile = 'component extends="wheels.Testbox" {

    function run() {
        describe("#pluginName# Tests", function() {

            it("should initialize correctly", function() {
                var plugin = createObject("component", "#simplePluginName#").init();
                expect(plugin.version).toBe("#arguments.version#");
            });

            it("should have example function", function() {
                var plugin = createObject("component", "#simplePluginName#").init();
                var result = plugin.#functionPrefix#Example("test");
                expect(result).toBe("test");
            });

        });
    }

}';

            fileWrite(pluginDir & "/tests/#simplePluginName#Test.cfc", testFile);

            print.line()
                 .boldCyanLine("===========================================================")
                 .line()
                 .boldGreenText("[OK] ")
                 .greenLine("Plugin created successfully in /plugins/#simplePluginName#/")
                 .line();

            print.boldLine("Files Created:")
                 .line("  #simplePluginName#.cfc    Main plugin component")
                 .line("  index.cfm         Documentation page")
                 .line("  box.json          Package metadata")
                 .line("  README.md         Project documentation")
                 .line();

            print.boldLine("Next Steps:")
                 .cyanLine("  1. Edit #simplePluginName#.cfc to add your plugin functions")
                 .cyanLine("  2. Update index.cfm and README.md with usage examples")
                 .cyanLine("  3. Test: wheels reload (then call your functions)")
                 .cyanLine("  4. Publish: box login && box publish");

        } catch (any e) {
            print.line()
                 .boldRedText("[ERROR] ")
                 .redLine("Error initializing plugin")
                 .line()
                 .yellowLine("Error: #e.message#");
            setExitCode(1);
        }
    }
}