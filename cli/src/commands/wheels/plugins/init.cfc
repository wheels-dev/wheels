/**
 * Initialize a new Wheels plugin project
 * Examples:
 * wheels plugin init my-wheels-plugin
 * wheels plugin init wheels-awesome-feature --author="John Doe"
 */
component aliases="wheels plugin init" extends="../base" {
    
    property name="fileService" inject="FileService@wheels-cli";
    
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
        try {
            // Ensure plugin name follows convention
            var pluginName = arguments.name;
            if (!reFindNoCase("^wheels-", pluginName)) {
                pluginName = "wheels-" & pluginName;
            }
            
            print.greenBoldLine("🚀 Initializing new Wheels plugin: #pluginName#")
                 .line();
            
            // Create plugin directory
            var pluginDir = getCWD() & "/" & pluginName;
            
            if (directoryExists(pluginDir)) {
                error("Directory '#pluginName#' already exists!");
                return;
            }
            
            print.line("Creating plugin structure...");
            
            // Create directory structure
            directoryCreate(pluginDir);
            directoryCreate(pluginDir & "/commands");
            directoryCreate(pluginDir & "/models");
            directoryCreate(pluginDir & "/tests");
            directoryCreate(pluginDir & "/templates");
            
            // Create box.json
            var boxJson = {
                "name": pluginName,
                "version": arguments.version,
                "author": arguments.author,
                "location": "ForgeBox",
                "slug": pluginName,
                "type": "commandbox-modules,cfwheels-plugins",
                "keywords": "cfwheels,wheels,cli,plugin",
                "homepage": "",
                "documentation": "",
                "repository": {
                    "type": "git",
                    "URL": ""
                },
                "bugs": "",
                "shortDescription": arguments.description,
                "description": arguments.description,
                "license": [{
                    "type": arguments.license,
                    "URL": ""
                }],
                "contributors": [],
                "dependencies": {},
                "devDependencies": {},
                "installPaths": {},
                "scripts": {},
                "ignore": [
                    "**/.*",
                    "tests/"
                ]
            };
            
            fileWrite(pluginDir & "/box.json", serializeJSON(boxJson, true));
            
            // Create ModuleConfig.cfc
            var moduleConfig = '/**
 * Module Configuration for #pluginName#
 */
component {
    
    // Module Properties
    this.title = "#pluginName#";
    this.author = "#arguments.author#";
    this.webURL = "";
    this.description = "#arguments.description#";
    this.version = "#arguments.version#";
    this.viewParentLookup = true;
    this.layoutParentLookup = true;
    this.entryPoint = "/#lCase(pluginName)#";
    this.inheritEntryPoint = false;
    this.modelNamespace = "#lCase(pluginName)#";
    this.cfmapping = "#lCase(pluginName)#";
    this.autoMapModels = true;
    this.dependencies = [];
    
    function configure() {
        // Module settings
        settings = {};
        
        // Module interceptors
        interceptors = [];
        
        // Custom declared points
        interceptorSettings = {
            customInterceptionPoints = []
        };
    }
    
    /**
     * Fired when the module is registered and activated
     */
    function onLoad() {
        // Register any custom commands
    }
    
    /**
     * Fired when the module is unregistered and unloaded
     */
    function onUnload() {
        // Cleanup code
    }
}';
            
            fileWrite(pluginDir & "/ModuleConfig.cfc", moduleConfig);
            
            // Create README.md
            var readme = "## #pluginName#

#arguments.description#

#### Installation

Install via CommandBox:

    wheels plugin install #pluginName#

#### Usage

[Add usage instructions here]

#### Commands

This plugin provides the following commands:

- `wheels [command]` - [Description]

#### Configuration

[Add configuration options here]

#### Development

Running Tests:

    box testbox run

Building for Release:

    box package publish

#### License

#arguments.license#

#### Author

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
            
            // Create example command
            var exampleCommand = '/**
 * Example command for #pluginName#
 */
component extends="commandbox.system.BaseCommand" {
    
    /**
     * Run the example command
     */
    function run() {
        print.greenLine("Hello from #pluginName#!");
    }
}';
            
            fileWrite(pluginDir & "/commands/hello.cfc", exampleCommand);
            
            // Create test file
            var testFile = 'component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("#pluginName# Tests", function() {
            it("should have tests", function() {
                expect(true).toBeTrue();
            });
        });
    }
}';
            
            fileWrite(pluginDir & "/tests/MainTest.cfc", testFile);
            
            print.greenLine("✅ Plugin structure created successfully!")
                 .line();
            
            // Show next steps
            print.boldLine("Next Steps:")
                 .line()
                 .line("1. Navigate to your plugin directory:")
                 .yellowLine("   cd #pluginName#")
                 .line()
                 .line("2. Initialize git repository:")
                 .yellowLine("   git init")
                 .line()
                 .line("3. Install dependencies:")
                 .yellowLine("   box install")
                 .line()
                 .line("4. Add your plugin commands in the 'commands' directory")
                 .line()
                 .line("5. Test your plugin locally:")
                 .yellowLine("   box package link")
                 .yellowLine("   wheels hello  ## Test the example command")
                 .line()
                 .line("6. When ready to publish:")
                 .yellowLine("   box login")
                 .yellowLine("   box package publish")
                 .line()
                 .boldLine("Plugin Structure:")
                 .line("  #pluginName#/")
                 .line("  ├── box.json          ## Package configuration")
                 .line("  ├── ModuleConfig.cfc  ## Module configuration")
                 .line("  ├── README.md         ## Documentation")
                 .line("  ├── commands/         ## CLI commands")
                 .line("  ├── models/           ## Service components")
                 .line("  ├── templates/        ## File templates")
                 .line("  └── tests/            ## Test suite");
            
        } catch (any e) {
            error("Error initializing plugin: #e.message#");
        }
    }
}