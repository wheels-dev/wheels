/**
 * Install Wheels CLI plugins
 * Examples:
 * wheels plugins install cfwheels-flashmessages-bootstrap
 * wheels plugins install cfwheels-bcrypt --dev
 * wheels plugins install cfwheels-bcrypt
 */
component aliases="wheels plugin install" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    
    /**
     * @name.hint Plugin name or repository URL
     * @dev.hint Install as development dependency
     * @version.hint Specific version to install
     */
    function run(
        required string name,
        boolean dev = false,
        string version = ""
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);

        print.line()
             .boldCyanLine("===========================================================")
             .boldCyanLine("  Installing Plugin")
             .boldCyanLine("===========================================================")
             .line();

        var packageSpec = arguments.name;
        if (len(arguments.version)) {
            packageSpec &= "@" & arguments.version;
        }

        print.line("Plugin:  #arguments.name#");
        if (len(arguments.version)) {
            print.line("Version: #arguments.version#");
        } else {
            print.line("Version: latest");
        }
        print.line();

        var result = pluginService.install(argumentCollection = arguments);

        print.boldCyanLine("===========================================================")
             .line();

        if (result.success) {
            print.boldGreenText("[OK] ")
                 .greenLine("Plugin installed successfully!")
                 .line();

            if (result.keyExists("plugin") && result.plugin.keyExists("description")) {
                print.line("#result.plugin.description#")
                     .line();
            }

            print.boldLine("Commands:")
                 .cyanLine("  wheels plugin list          View all installed plugins")
                 .cyanLine("  wheels plugin info #arguments.name#   View plugin details");
        } else {
            print.boldRedText("[ERROR] ")
                 .redLine("Failed to install plugin")
                 .line()
                 .yellowLine("Error: #result.error#")
                 .line();

            print.line("Possible solutions:")
                 .line("  - Verify the plugin name is correct")
                 .line("  - Check if the plugin exists on ForgeBox:")
                 .cyanLine("    wheels plugin list --available")
                 .line("  - Ensure the plugin type is 'cfwheels-plugins'");

            setExitCode(1);
        }
    }
}