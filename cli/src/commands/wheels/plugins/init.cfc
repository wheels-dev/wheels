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
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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


            // Create plugin in /plugins directory
            var pluginsBaseDir = fileSystemUtil.resolvePath("plugins");
            var pluginDir = pluginsBaseDir & "/" & simplePluginName;

            // Ensure /plugins directory exists
            if (!directoryExists(pluginsBaseDir)) {
                directoryCreate(pluginsBaseDir);
            }

            if (directoryExists(pluginDir)) {
                detailOutput.error("Plugin already exists");
                setExitCode(1);
                return;
            }
            detailOutput.header("  Initializing Wheels Plugin: #pluginName#");

            detailOutput.output("Creating plugin in /plugins/#simplePluginName#/...");

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
                "private": false,
                "directory":"/plugins/",
                "packageDirectory":simplePluginName
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

            detailOutput.line();
            detailOutput.statusSuccess("Plugin created successfully in /plugins/#simplePluginName#/");
            detailOutput.line();

            detailOutput.statusInfo("Files Created:");
            detailOutput.output("- #simplePluginName#.cfc: Main plugin component",true);
            detailOutput.output("- index.cfm: Documentation page",true);
            detailOutput.output("- box.json: Package metadata",true);
            detailOutput.output("- README.md: Project documentation",true);
            detailOutput.line();

            detailOutput.statusInfo("Next Steps:");
            detailOutput.output("1. Edit #simplePluginName#.cfc to add your plugin functions", true);
            detailOutput.output("2. Update index.cfm and README.md with usage examples", true);
            detailOutput.output("3. Test: wheels reload (then call your functions)", true);
            detailOutput.output("4. Publish: box login && box publish", true);

        } catch (any e) {
            detailOutput.statusFailed("Error initializing plugin");
            detailOutput.error("#e.message#");
            setExitCode(1);
        }
    }
}