/**
 * Wheels CLI Module Configuration
 * Modern CommandBox module for CFWheels framework
 * 
 * @author CFWheels Team
 * @version 3.0.0
 */
component {
    
    property name="systemSettings" inject="SystemSettings";
    
    // Module Properties
    this.title         = "Wheels CLI";
    this.author        = "CFWheels Team";
    this.webURL        = "https://cfwheels.org";
    this.description   = "Next-generation CLI for CFWheels Framework";
    this.version       = "3.0.0";
    
    // Module Config
    this.autoMapModels     = false;
    this.modelNamespace    = "wheels-cli-next";
    this.cfmapping         = "wheels-cli-next";
    this.entryPoint        = "wheels";
    this.aliases           = ["cfwheels"];
    
    // Dependencies
    this.dependencies = [
        "commandbox-migrations",
        "commandbox-cfformat"
    ];
    
    /**
     * Configure the module
     */
    function configure() {
        // Module settings
        settings = {
            // CLI Configuration
            configFileName = ".wheelscli.json",
            configSearchPaths = [".", "config", ".wheels"],
            
            // Default settings
            defaults = {
                database = getSystemSetting("WHEELS_DEFAULT_DB", "sqlite"),
                template = getSystemSetting("WHEELS_DEFAULT_TEMPLATE", "default"),
                environment = getSystemSetting("WHEELS_ENV", "development"),
                verbose = getSystemSetting("WHEELS_VERBOSE", false)
            },
            
            // Snippet settings
            snippets = {
                searchPaths = ["config/snippets", ".wheels/snippets"],
                placeholder = {
                    prefix = "@",
                    suffix = "@"
                },
                defaults = {
                    author = getSystemSetting("WHEELS_AUTHOR", ""),
                    authorEmail = getSystemSetting("WHEELS_AUTHOR_EMAIL", ""),
                    license = getSystemSetting("WHEELS_LICENSE", "MIT")
                }
            },
            
            // Database settings
            database = {
                sqlite = {
                    defaultPath = "db/sqlite",
                    extension = ".db"
                },
                migrations = {
                    tableName = "schema_migrations",
                    path = "db/migrate"
                }
            },
            
            // Output formats
            output = {
                defaultFormat = "text",
                formats = ["text", "json", "xml", "table"]
            }
        };
        
        // No interceptors needed for CommandBox modules
        
        // WireBox Mappings
        binder.map("ConfigService@wheels-cli-next")
            .to("#moduleMapping#.models.services.ConfigService")
            .asSingleton()
            .initWith(settings = settings);
            
        binder.map("WheelsService@wheels-cli-next")
            .to("#moduleMapping#.models.services.WheelsService")
            .asSingleton();
            
        binder.map("DatabaseService@wheels-cli-next")
            .to("#moduleMapping#.models.services.DatabaseService")
            .asSingleton();
            
        binder.map("SnippetService@wheels-cli-next")
            .to("#moduleMapping#.models.services.SnippetService")
            .asSingleton()
            .initWith(settings = settings.snippets);
            
        binder.map("MigrationService@wheels-cli-next")
            .to("#moduleMapping#.models.services.MigrationService")
            .asSingleton();
            
        binder.map("FormatterService@wheels-cli-next")
            .to("#moduleMapping#.models.services.FormatterService")
            .asSingleton();
            
        binder.map("ProjectService@wheels-cli-next")
            .to("#moduleMapping#.models.services.ProjectService")
            .asSingleton();
            
        binder.map("TabCompletionService@wheels-cli-next")
            .to("#moduleMapping#.models.services.TabCompletionService")
            .asSingleton();
        
        // Command Aliases will be registered after module loads
    }
    
    /**
     * Module activation
     */
    function onLoad() {
        // Initialize configuration
        var configService = wirebox.getInstance("ConfigService@wheels-cli-next");
        configService.loadConfiguration();
        
        // Log activation
        if (log.canInfo()) {
            log.info("Wheels CLI Module v#this.version# loaded successfully");
        }
        
        // Command registration happens automatically
    }
    
    /**
     * Module deactivation
     */
    function onUnload() {
        if (log.canInfo()) {
            log.info("Wheels CLI Module unloaded");
        }
    }
    
    /**
     * Module installation
     */
    function onInstall() {
        // Create default configuration file
        var configPath = expandPath(".") & "/.wheelscli.json";
        if (!fileExists(configPath)) {
            var defaultConfig = {
                "name": "My Wheels App",
                "version": "0.0.1",
                "defaults": {
                    "database": "sqlite",
                    "template": "default"
                },
                "snippets": {
                    "author": "",
                    "license": "MIT"
                }
            };
            fileWrite(configPath, serializeJSON(defaultConfig, false, false));
        }
        
        // Installation complete
    }
    
    /**
     * Module update
     */
    function onUpdate(string previousVersion) {
        // Update complete
    }
    
    /**
     * Get system setting with fallback
     */
    private function getSystemSetting(required string name, any defaultValue = "") {
        var value = systemSettings.getSystemSetting(arguments.name, "");
        return len(value) ? value : arguments.defaultValue;
    }
}