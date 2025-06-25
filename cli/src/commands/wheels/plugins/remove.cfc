/**
 * Remove Wheels CLI plugins
 * Examples:
 * wheels plugins remove wheels-vue-cli
 * wheels plugins remove wheels-docker --global
 */
component extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    
    /**
     * @name.hint Plugin name to remove
     * @global.hint Remove globally installed plugin
     * @force.hint Force removal without confirmation
     */
    function run(
        required string name,
        boolean global = false,
        boolean force = false
    ) {
        // Confirmation prompt unless forced
        if (!arguments.force) {
            var confirm = ask("Are you sure you want to remove the plugin '#arguments.name#'? (y/n): ");
            if (!reFindNoCase("^y(es)?$", trim(confirm))) {
                print.yellowLine("Plugin removal cancelled.");
                return;
            }
        }
        
        print.yellowLine("🗑️  Removing plugin: #arguments.name#...")
             .line();
        
        var result = pluginService.remove(
            name = arguments.name,
            global = arguments.global
        );
        
        if (result.success) {
            print.greenLine("✅ Plugin removed successfully");
            print.line("Run 'wheels plugins list' to see remaining plugins");
        } else {
            print.redLine("❌ Failed to remove plugin: #result.error#");
            setExitCode(1);
        }
    }
}