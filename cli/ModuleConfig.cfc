/**
 * Wheels CLI Module Configuration
 * Modern CommandBox module for CFWheels framework
 * 
 * @author CFWheels Team
 * @version 3.0.0
 */
component {
    
    // Module Properties
    this.title         = "Wheels CLI";
    this.author        = "CFWheels Team";
    this.webURL        = "https://cfwheels.org";
    this.description   = "Next-generation CLI for CFWheels Framework";
    this.version       = "3.0.0";
    
    // Module Config
    this.autoMapModels     = false;
    this.modelNamespace    = "wheelscli";
    this.cfmapping         = "wheelscli";
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
            
            // Template settings
            templates = {
                searchPaths = ["config/templates", ".wheels/templates"],
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
        
        // Custom Interceptors
        interceptors = [
            {
                class = "#moduleMapping#.interceptors.CLIInterceptor",
                name = "WheelsCLIInterceptor"
            }
        ];
        
        // Interceptor Points
        interceptorSettings = {
            customInterceptionPoints = [
                "preWheelsCommand",
                "postWheelsCommand",
                "onWheelsCommandError",
                "onWheelsProjectDetection"
            ]
        };
        
        // WireBox Mappings
        binder.map("ConfigService@wheelscli")
            .to("#moduleMapping#.models.services.ConfigService")
            .asSingleton()
            .initWith(settings = settings);
            
        binder.map("WheelsService@wheelscli")
            .to("#moduleMapping#.models.services.WheelsService")
            .asSingleton();
            
        binder.map("DatabaseService@wheelscli")
            .to("#moduleMapping#.models.services.DatabaseService")
            .asSingleton();
            
        binder.map("TemplateService@wheelscli")
            .to("#moduleMapping#.models.services.TemplateService")
            .asSingleton()
            .initWith(settings = settings.templates);
            
        binder.map("MigrationService@wheelscli")
            .to("#moduleMapping#.models.services.MigrationService")
            .asSingleton();
            
        binder.map("FormatterService@wheelscli")
            .to("#moduleMapping#.models.services.FormatterService")
            .asSingleton();
            
        binder.map("ProjectService@wheelscli")
            .to("#moduleMapping#.models.services.ProjectService")
            .asSingleton();
            
        binder.map("TabCompletionService@wheelscli")
            .to("#moduleMapping#.models.services.TabCompletionService")
            .asSingleton();
        
        // Command Aliases
        binder.map("command:w").to("command:wheels");
        binder.map("command:wheels g").to("command:wheels create");
        binder.map("command:wheels generate").to("command:wheels create");
        binder.map("command:wheels s").to("command:wheels server");
        binder.map("command:wheels db:migrate").to("command:wheels db migrate");
        binder.map("command:wheels db:rollback").to("command:wheels db rollback");
    }
    
    /**
     * Module activation
     */
    function onLoad() {
        // Initialize configuration
        var configService = wirebox.getInstance("ConfigService@wheelscli");
        configService.loadConfiguration();
        
        // Log activation
        if (log.canInfo()) {
            log.info("Wheels CLI Module v#this.version# loaded successfully");
        }
        
        // Register custom command help
        var commandService = wirebox.getInstance("CommandService");
        commandService.addCommandHelp("wheels", "CFWheels framework CLI commands");
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
        var configPath = shell.pwd() & "/.wheelscli.json";
        if (!fileExists(configPath)) {
            var defaultConfig = {
                "name": "My Wheels App",
                "version": "0.0.1",
                "defaults": {
                    "database": "sqlite",
                    "template": "default"
                },
                "templates": {
                    "author": "",
                    "license": "MIT"
                }
            };
            fileWrite(configPath, serializeJSON(defaultConfig, false, false));
        }
        
        print.greenLine("Wheels CLI installed successfully!");
        print.line("Run 'wheels help' to get started.");
    }
    
    /**
     * Module update
     */
    function onUpdate(string previousVersion) {
        print.greenLine("Wheels CLI updated from v#arguments.previousVersion# to v#this.version#");
    }
    
    /**
     * Get system setting with fallback
     */
    private function getSystemSetting(required string name, any defaultValue = "") {
        var value = systemSettings.getSystemSetting(arguments.name, "");
        return len(value) ? value : arguments.defaultValue;
    }
}