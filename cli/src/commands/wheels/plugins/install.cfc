/**
 * Install Wheels CLI plugins
 * Examples:
 * wheels plugins install cfwheels-flashmessages-bootstrap
 * wheels plugins install cfwheels-bcrypt --dev
 * wheels plugins install cfwheels-bcrypt
 */
component aliases="wheels plugin install" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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

        detailOutput.header("Installing Plugin");
        detailOutput.line();

        var packageSpec = arguments.name;
        if (len(arguments.version)) {
            packageSpec &= "@" & arguments.version;
        }

        detailOutput.metric("Plugin", arguments.name);
        if (len(arguments.version)) {
            detailOutput.metric("Version", arguments.version);
        } else {
            detailOutput.metric("Version", "latest");
        }
        if (arguments.dev) {
            detailOutput.metric("Type", "Development dependency");
        }
        detailOutput.line();

        var result = pluginService.install(argumentCollection = arguments);

        detailOutput.divider("=", 60);
        detailOutput.line();

        if (result.success) {
            detailOutput.statusSuccess("Plugin installed successfully!");
            detailOutput.line();

            if (result.keyExists("plugin") && result.plugin.keyExists("description")) {
                detailOutput.output("#result.plugin.description#");
                detailOutput.line();
            }

            detailOutput.subHeader("Commands");
            detailOutput.output("- wheels plugin list          View all installed plugins", true);
            detailOutput.output("- wheels plugin info #arguments.name#   View plugin details", true);
            
            if (result.keyExists("plugin") && result.plugin.keyExists("homepage")) {
                detailOutput.line();
                detailOutput.subHeader("Documentation");
                detailOutput.output("- #result.plugin.homepage#", true);
            }
        } else {
            detailOutput.statusFailed("Failed to install plugin");
            detailOutput.error("Error: #result.error#");
            detailOutput.line();

            detailOutput.statusInfo("Possible solutions");
            detailOutput.output("- Verify the plugin name is correct", true);
            detailOutput.output("- Check if the plugin exists on ForgeBox:", true);
            detailOutput.output("  wheels plugin list --available", true);
            detailOutput.output("- Ensure the plugin type is 'cfwheels-plugins'", true);
            detailOutput.output("- Try clearing package cache: box clean", true);

            setExitCode(1);
        }
    }
}