/**
 * Remove Wheels CLI plugins
 * Examples:
 * wheels plugins remove wheels-vue-cli
 * wheels plugins remove wheels-docker
 */
component alias="wheels plugin remove" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";

    /**
     * @name.hint Plugin name to remove
     * @force.hint Force removal without confirmation
     */
    function run(
        required string name,
        boolean force = false
    ) {
        // Reconstruct arguments to handle prefix (--)
        arguments = reconstructArgs(arguments);

        // Confirmation prompt unless forced
        if (!arguments.force) {
            var confirm = ask("Are you sure you want to remove the plugin '#arguments.name#'? (y/n): ");
            if (!reFindNoCase("^y(es)?$", trim(confirm))) {
                print.yellowLine("Plugin removal cancelled.");
                return;
            }
        }
        
        print.yellowLine("[*] Removing plugin: #arguments.name#...")
             .line();

        var result = pluginService.remove(name = arguments.name);

        if (result.success) {
            print.greenLine("[OK] Plugin removed successfully");
            print.line("Run 'wheels plugins list' to see remaining plugins");
        } else {
            print.redLine("[ERROR] Failed to remove plugin: #result.error#");
            setExitCode(1);
        }
    }
}