component {
    this.title = "Wheels CLI";
    this.author = "Wheels.dev Team";
    this.description = "Modern CLI for Wheels Framework";
    this.version = "3.0.28";
    this.autoMapModels = false;
    this.cfmapping = "wheels-cli";
    this.modelNamespace = "wheels-cli";
    
    // Dependencies
    this.dependencies = [
        "testbox-cli",
        "commandbox-migrations"
    ];
    
    function configure() {
        // Settings
        settings = {
            // Module path
            "modulePath": modulePath,
            // Default template repository
            templateRepository = "https://github.com/wheels-dev/wheels-templates",
            // Testing configuration
            testbox = {
                runner = "/tests/runner.cfm",
                coverage = true,
                watchPaths = ["models/**", "handlers/**", "views/**"]
            },
            // Migration configuration
            migrations = {
                defaultDirectory = "db/migrations",
                seedDirectory = "db/seeds"
            }
        };
        
        // Interceptors
        interceptors = [
            { class = "#moduleMapping#.interceptors.postInstall" }
        ];
    }
    
    function onLoad() {
        // Register helper services
        binder.map("TemplateService@wheels-cli")
            .to("#moduleMapping#.models.TemplateService");
        binder.map("TestService@wheels-cli")
            .to("#moduleMapping#.models.TestService");
        binder.map("MigrationService@wheels-cli")
            .to("#moduleMapping#.models.MigrationService");
        binder.map("AnalysisService@wheels-cli")
            .to("#moduleMapping#.models.AnalysisService");
        binder.map("PluginService@wheels-cli")
            .to("#moduleMapping#.models.PluginService");
        binder.map("EnvironmentService@wheels-cli")
            .to("#moduleMapping#.models.EnvironmentService");
        
        log.info('Wheels CLI Module loaded successfully.');
    }
    
    function onUnLoad() {
        log.info('Wheels CLI Module unloaded successfully.');
    }

}
