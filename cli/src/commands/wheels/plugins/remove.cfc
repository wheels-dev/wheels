/**
 * Remove Wheels CLI plugins
 * Examples:
 * wheels plugins remove wheels-vue-cli
 * wheels plugins remove wheels-docker
 */
component aliases="wheels plugin remove" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Plugin name to remove
     * @force.hint Force removal without confirmation
     */
    function run(
        required string name,
        boolean force = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);

        // Confirmation prompt unless forced
        if (!arguments.force) {
            var confirm = ask("Are you sure you want to remove the plugin '#arguments.name#'? (y/n): ");
            if (!reFindNoCase("^y(es)?$", trim(confirm))) {
                detailOutput.statusInfo("Plugin removal cancelled.");
                return;
            }
        }
        
        detailOutput.output("Removing plugin: #arguments.name#...");

        var result = pluginService.remove(name = arguments.name);

        if (result.success) {
            detailOutput.statusSuccess("Plugin removed successfully");
            detailOutput.line();
            detailOutput.statusInfo("Run 'wheels plugins list' to see remaining plugins");
        } else {
            detailOutput.statusFailed("Failed to remove plugin: #result.error#");
            setExitCode(1);
        }
    }
}