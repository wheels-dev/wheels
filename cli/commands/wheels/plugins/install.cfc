/**
 * Install Wheels CLI plugins
 * Examples:
 * wheels plugins install wheels-vue-cli
 * wheels plugins install wheels-docker --dev
 * wheels plugins install https://github.com/user/wheels-plugin --global
 */
component extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    
    /**
     * @name.hint Plugin name or repository URL
     * @dev.hint Install as development dependency
     * @global.hint Install globally
     * @version.hint Specific version to install
     */
    function run(
        required string name,
        boolean dev = false,
        boolean global = false,
        string version = ""
    ) {
        print.yellowLine("📦 Installing plugin: #arguments.name#...")
             .line();
        
        var result = pluginService.install(argumentCollection = arguments);
        
        if (result.success) {
            print.greenLine("✅ Plugin installed successfully");
            
            if (result.keyExists("plugin") && result.plugin.keyExists("description")) {
                print.line("📝 #result.plugin.description#");
            }
            
            print.line()
                 .yellowLine("Run 'wheels plugins list' to see installed plugins");
        } else {
            print.redLine("❌ Failed to install plugin: #result.error#");
            setExitCode(1);
        }
    }
}