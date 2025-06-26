/**
 * Generate a new Wheels plugin scaffold
 * 
 * Examples:
 * wheels generate plugin Authentication
 * wheels generate plugin ImageProcessor --version="1.0.0" --author="John Doe"
 * wheels generate plugin CacheManager --methods="init,configure,process"
 * wheels generate plugin APIConnector --dependencies="wheels-http-client"
 */
component aliases='wheels g plugin' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the plugin (e.g., Authentication, ImageProcessor)
     * @version.hint Plugin version (default: 1.0.0)
     * @author.hint Plugin author name
     * @description.hint Plugin description
     * @methods.hint Comma-separated list of methods to include
     * @dependencies.hint Comma-separated list of dependencies
     * @mixin.hint Component types to mixin (controller,model,global)
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string version = "1.0.0",
        string author = "",
        string description = "",
        string methods = "",
        string dependencies = "",
        string mixin = "global",
        boolean force = false
    ) {
        detailOutput.header("🔌", "Generating plugin: #arguments.name#");
        
        // Validate plugin name
        var validation = codeGenerationService.validateName(arguments.name, "plugin");
        if (!validation.valid) {
            error("Invalid plugin name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        // Create plugin directory
        var pluginDir = helpers.getAppPath() & "/plugins/" & lCase(arguments.name);
        
        if (directoryExists(pluginDir) && !arguments.force) {
            error("Plugin directory already exists: /plugins/#lCase(arguments.name)#. Use force=true to overwrite.");
            return;
        }
        
        if (!directoryExists(pluginDir)) {
            directoryCreate(pluginDir);
            detailOutput.output("Created plugin directory: /plugins/#lCase(arguments.name)#");
        }
        
        // Create subdirectories
        var subdirs = ["src", "tests", "docs"];
        for (var dir in subdirs) {
            var subdir = pluginDir & "/" & dir;
            if (!directoryExists(subdir)) {
                directoryCreate(subdir);
            }
        }
        
        // Parse methods and dependencies
        var methodList = len(arguments.methods) ? listToArray(arguments.methods, ",") : [];
        var dependencyList = len(arguments.dependencies) ? listToArray(arguments.dependencies, ",") : [];
        var mixinList = listToArray(arguments.mixin, ",");
        
        // Generate plugin files
        createPluginIndex(pluginDir, arguments, methodList, mixinList);
        createPluginBox(pluginDir, arguments, dependencyList);
        createPluginReadme(pluginDir, arguments);
        createPluginLicense(pluginDir, arguments);
        createPluginTest(pluginDir, arguments, methodList);
        
        // Create sample files based on mixin types
        if (listFindNoCase(arguments.mixin, "controller")) {
            createControllerMixin(pluginDir, arguments);
        }
        if (listFindNoCase(arguments.mixin, "model")) {
            createModelMixin(pluginDir, arguments);
        }
        if (listFindNoCase(arguments.mixin, "global")) {
            createGlobalMixin(pluginDir, arguments);
        }
        
        detailOutput.success("Plugin scaffold created successfully!");
        
        // Show next steps
        detailOutput.separator();
        detailOutput.output("Next steps:");
        detailOutput.output("1. Navigate to: /plugins/#lCase(arguments.name)#");
        detailOutput.output("2. Implement your plugin logic in index.cfc");
        detailOutput.output("3. Add tests in the tests directory");
        detailOutput.output("4. Update the README.md with documentation");
        detailOutput.output("5. Publish to ForgeBox when ready:");
        detailOutput.code("box publish", "bash");
    }
    
    /**
     * Create main plugin index.cfc file
     */
    private void function createPluginIndex(required string pluginDir, required struct args, required array methods, required array mixinTypes) {
        var content = "/**" & chr(10);
        content &= " * #args.name# Plugin for CFWheels" & chr(10);
        if (len(args.description)) {
            content &= " * #args.description#" & chr(10);
        }
        content &= " * Version: #args.version#" & chr(10);
        if (len(args.author)) {
            content &= " * Author: #args.author#" & chr(10);
        }
        content &= " */" & chr(10);
        content &= "component output=""false"" mixin=""#arrayToList(mixinTypes)#"" {" & chr(10) & chr(10);
        
        // Init method
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Plugin initialization" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public function init() {" & chr(10);
        content &= chr(9) & chr(9) & "this.version = ""#args.version#"";" & chr(10);
        content &= chr(9) & chr(9) & "return this;" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Generate custom methods
        if (arrayLen(methods)) {
            for (var method in methods) {
                content &= generatePluginMethod(trim(method));
            }
        } else {
            // Add a sample method
            content &= chr(9) & "/**" & chr(10);
            content &= chr(9) & " * Sample plugin method" & chr(10);
            content &= chr(9) & " */" & chr(10);
            content &= chr(9) & "public any function #lCase(args.name)#Method() {" & chr(10);
            content &= chr(9) & chr(9) & "// Add your plugin logic here" & chr(10);
            content &= chr(9) & chr(9) & "return ""Hello from #args.name# plugin!"";" & chr(10);
            content &= chr(9) & "}" & chr(10);
        }
        
        content &= chr(10) & "}";
        
        fileWrite(pluginDir & "/index.cfc", content);
        detailOutput.output("Created: index.cfc");
    }
    
    /**
     * Create plugin box.json file
     */
    private void function createPluginBox(required string pluginDir, required struct args, required array dependencies) {
        var boxJson = {
            "name": lCase(args.name),
            "version": args.version,
            "author": args.author,
            "location": "",
            "directory": "",
            "createPackageDirectory": true,
            "packageDirectory": "",
            "homepage": "",
            "documentation": "",
            "repository": {
                "type": "",
                "URL": ""
            },
            "bugs": "",
            "slug": "wheels-plugin-#lCase(args.name)#",
            "shortDescription": len(args.description) ? args.description : "#args.name# plugin for CFWheels",
            "description": len(args.description) ? args.description : "#args.name# plugin for CFWheels",
            "instructions": "",
            "changelog": "",
            "type": "wheels-plugins",
            "keywords": ["cfwheels", "plugin", lCase(args.name)],
            "private": false,
            "engines": {
                "cfwheels": ">=2.0.0"
            },
            "defaultPort": 0,
            "projectURL": "",
            "license": [
                {
                    "type": "MIT",
                    "URL": ""
                }
            ],
            "contributors": [],
            "dependencies": {},
            "devDependencies": {},
            "installPaths": {},
            "scripts": {},
            "ignore": ["**/.*", "tests"]
        };
        
        // Add dependencies
        for (var dep in dependencies) {
            boxJson.dependencies[trim(dep)] = "*";
        }
        
        fileWrite(pluginDir & "/box.json", serializeJSON(boxJson));
        detailOutput.output("Created: box.json");
    }
    
    /**
     * Create plugin README.md file
     */
    private void function createPluginReadme(required string pluginDir, required struct args) {
        var content = "## #args.name# Plugin for CFWheels" & chr(10) & chr(10);
        
        if (len(args.description)) {
            content &= args.description & chr(10) & chr(10);
        }
        
        content &= "## Installation" & chr(10) & chr(10);
        content &= "```bash" & chr(10);
        content &= "box install wheels-plugin-#lCase(args.name)#" & chr(10);
        content &= "```" & chr(10) & chr(10);
        
        content &= "Or add to your `box.json` dependencies:" & chr(10) & chr(10);
        content &= "```json" & chr(10);
        content &= "{" & chr(10);
        content &= "  ""dependencies"": {" & chr(10);
        content &= "    ""wheels-plugin-#lCase(args.name)#"": ""^#args.version#""" & chr(10);
        content &= "  }" & chr(10);
        content &= "}" & chr(10);
        content &= "```" & chr(10) & chr(10);
        
        content &= "## Usage" & chr(10) & chr(10);
        content &= "Once installed, the plugin will automatically be loaded by CFWheels." & chr(10) & chr(10);
        
        content &= chr(10) & "## Example" & chr(10) & chr(10);
        content &= "```cfscript" & chr(10);
        content &= "// Example usage of the plugin" & chr(10);
        content &= "result = #lCase(args.name)#Method();" & chr(10);
        content &= "```" & chr(10) & chr(10);
        
        content &= "## Configuration" & chr(10) & chr(10);
        content &= "Add any configuration instructions here." & chr(10) & chr(10);
        
        content &= "## API Reference" & chr(10) & chr(10);
        content &= "Document your plugin methods here." & chr(10) & chr(10);
        
        content &= "## Contributing" & chr(10) & chr(10);
        content &= "1. Fork it" & chr(10);
        content &= "2. Create your feature branch (`git checkout -b feature/my-new-feature`)" & chr(10);
        content &= "3. Commit your changes (`git commit -am 'Add some feature'`)" & chr(10);
        content &= "4. Push to the branch (`git push origin feature/my-new-feature`)" & chr(10);
        content &= "5. Create new Pull Request" & chr(10) & chr(10);
        
        content &= "## License" & chr(10) & chr(10);
        content &= "MIT License - see LICENSE file for details" & chr(10);
        
        fileWrite(pluginDir & "/README.md", content);
        detailOutput.output("Created: README.md");
    }
    
    /**
     * Create plugin LICENSE file
     */
    private void function createPluginLicense(required string pluginDir, required struct args) {
        var year = year(now());
        var author = len(args.author) ? args.author : "Plugin Author";
        
        var content = "MIT License" & chr(10) & chr(10);
        content &= "Copyright (c) #year# #author#" & chr(10) & chr(10);
        content &= "Permission is hereby granted, free of charge, to any person obtaining a copy" & chr(10);
        content &= "of this software and associated documentation files (the ""Software""), to deal" & chr(10);
        content &= "in the Software without restriction, including without limitation the rights" & chr(10);
        content &= "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell" & chr(10);
        content &= "copies of the Software, and to permit persons to whom the Software is" & chr(10);
        content &= "furnished to do so, subject to the following conditions:" & chr(10) & chr(10);
        content &= "The above copyright notice and this permission notice shall be included in all" & chr(10);
        content &= "copies or substantial portions of the Software." & chr(10) & chr(10);
        content &= "THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR" & chr(10);
        content &= "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY," & chr(10);
        content &= "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE" & chr(10);
        content &= "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER" & chr(10);
        content &= "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM," & chr(10);
        content &= "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE" & chr(10);
        content &= "SOFTWARE.";
        
        fileWrite(pluginDir & "/LICENSE", content);
        detailOutput.output("Created: LICENSE");
    }
    
    /**
     * Create plugin test file
     */
    private void function createPluginTest(required string pluginDir, required struct args, required array methods) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);
        
        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "// Initialize plugin" & chr(10);
        content &= chr(9) & chr(9) & "plugin = createObject(""component"", ""plugins.#lCase(args.name)#.index"").init();" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "function test_plugin_initialization() {" & chr(10);
        content &= chr(9) & chr(9) & "assert(isObject(plugin), ""Plugin should be initialized"");" & chr(10);
        content &= chr(9) & chr(9) & "assert(plugin.version == ""#args.version#"", ""Plugin version should be #args.version#"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        if (arrayLen(methods)) {
            for (var method in methods) {
                content &= chr(9) & "function test_#trim(method)#() {" & chr(10);
                content &= chr(9) & chr(9) & "// Test #trim(method)# method" & chr(10);
                content &= chr(9) & chr(9) & "local.result = plugin.#trim(method)#();" & chr(10);
                content &= chr(9) & chr(9) & "assert(isDefined(""local.result""), ""Method should return a value"");" & chr(10);
                content &= chr(9) & "}" & chr(10) & chr(10);
            }
        }
        
        content &= "}";
        
        fileWrite(pluginDir & "/tests/PluginTest.cfc", content);
        detailOutput.output("Created: tests/PluginTest.cfc");
    }
    
    /**
     * Create controller mixin file
     */
    private void function createControllerMixin(required string pluginDir, required struct args) {
        var content = "/**" & chr(10);
        content &= " * Controller methods for #args.name# plugin" & chr(10);
        content &= " */" & chr(10);
        content &= "component {" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Sample controller method" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function #lCase(args.name)#Filter() {" & chr(10);
        content &= chr(9) & chr(9) & "// Add before/after filter logic here" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= "}";
        
        fileWrite(pluginDir & "/src/controller.cfc", content);
        detailOutput.output("Created: src/controller.cfc");
    }
    
    /**
     * Create model mixin file
     */
    private void function createModelMixin(required string pluginDir, required struct args) {
        var content = "/**" & chr(10);
        content &= " * Model methods for #args.name# plugin" & chr(10);
        content &= " */" & chr(10);
        content &= "component {" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Sample model method" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function #lCase(args.name)#Callback() {" & chr(10);
        content &= chr(9) & chr(9) & "// Add model callback logic here" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= "}";
        
        fileWrite(pluginDir & "/src/model.cfc", content);
        detailOutput.output("Created: src/model.cfc");
    }
    
    /**
     * Create global mixin file
     */
    private void function createGlobalMixin(required string pluginDir, required struct args) {
        var content = "/**" & chr(10);
        content &= " * Global methods for #args.name# plugin" & chr(10);
        content &= " */" & chr(10);
        content &= "component {" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Sample global method" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public any function #lCase(args.name)#Helper() {" & chr(10);
        content &= chr(9) & chr(9) & "// Add global helper logic here" & chr(10);
        content &= chr(9) & chr(9) & "return ""Helper output"";" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= "}";
        
        fileWrite(pluginDir & "/src/global.cfc", content);
        detailOutput.output("Created: src/global.cfc");
    }
    
    /**
     * Generate plugin method
     */
    private string function generatePluginMethod(required string methodName) {
        var content = chr(9) & "/**" & chr(10);
        content &= chr(9) & " * #humanize(methodName)#" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public any function #methodName#() {" & chr(10);
        content &= chr(9) & chr(9) & "// TODO: Implement #methodName# logic" & chr(10);
        content &= chr(9) & chr(9) & "return ""#methodName# result"";" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        return content;
    }
    
    /**
     * Convert method name to human readable format
     */
    private string function humanize(required string text) {
        var result = reReplace(text, "([A-Z])", " \1", "all");
        result = trim(result);
        result = uCase(left(result, 1)) & mid(result, 2, len(result));
        return result;
    }
}