/**
 * Update a specific Wheels plugin to the latest version
 * Examples:
 * wheels plugin update bcrypt
 * wheels plugin update cfwheels-bcrypt --version=2.0.0
 */
component aliases="wheels plugin update" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService";
    property name="forgebox" inject="ForgeBox";
    property name="fileSystemUtil" inject="FileSystem";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @name.hint Name or slug of the plugin to update
     * @version.hint Specific version to update to (optional)
     * @force.hint Force update even if already at latest version
     */
    function run(
        required string name,
        string version = "",
        boolean force = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);
        try {
            detailOutput.header("Updating Plugin: #arguments.name#");

            // Find plugin in /plugins folder
            var pluginsDir = fileSystemUtil.resolvePath("plugins");
            if (!directoryExists(pluginsDir)) {
                detailOutput.error("Plugins directory not found");
                detailOutput.statusWarning("Plugin '#arguments.name#' is not installed");
                setExitCode(1);
                return;
            }

            // Find plugin by name, slug, or folder name
            var foundPlugin = pluginService.findPluginByName(pluginsDir, arguments.name);

            if (!foundPlugin.found) {
                detailOutput.error("Plugin not found");
                detailOutput.statusWarning("Plugin '#arguments.name#' is not installed");
                detailOutput.line();
                detailOutput.subHeader("Install this plugin");
                detailOutput.output("- wheels plugin install #arguments.name#", true);
                setExitCode(1);
                return;
            }

            // Get plugin info from folder
            var pluginInfo = pluginService.getPluginInfoFromFolder(foundPlugin.path, foundPlugin.folderName);
            var pluginSlug = pluginInfo.slug;
            var currentVersion = pluginInfo.version;

            detailOutput.subHeader("Plugin Information");
            detailOutput.metric("Plugin", pluginInfo.name);
            detailOutput.metric("Current version", currentVersion);

            // Determine target version
            var targetVersion = len(arguments.version) ? arguments.version : "latest";
            var latestVersion = "";

            // Check if update is needed - use command to get fresh data
            try {
                // Get latest version using forgebox show command for fresh data
                var forgeboxResult = command('forgebox show')
                    .params(pluginSlug)
                    .run(returnOutput=true);

                // Parse the version from output
                var versionMatch = reFind("Versions\s*:\s*([0-9\.]+)", forgeboxResult, 1, true);
                if (versionMatch.pos[1] > 0) {
                    latestVersion = mid(forgeboxResult, versionMatch.pos[2], versionMatch.len[2]);
                }
                if (len(latestVersion)) {
                    detailOutput.metric("Latest version", latestVersion);

                    if (!arguments.force) {
                        // Check if already at target version
                        if (len(arguments.version)) {
                            // User specified a version
                            if (currentVersion == arguments.version) {
                                detailOutput.line();
                                detailOutput.statusSuccess("Plugin is already at version #arguments.version#");
                                detailOutput.line();
                                detailOutput.subHeader("Use --force to reinstall anyway");
                                detailOutput.output("- wheels plugin update #arguments.name# --force", true);
                                return;
                            }
                            targetVersion = arguments.version;
                        } else {
                            // Check latest version - clean versions for comparison
                            var cleanCurrent = trim(reReplace(currentVersion, "[^0-9\.]", "", "ALL"));
                            var cleanLatest = trim(reReplace(latestVersion, "[^0-9\.]", "", "ALL"));

                            if (cleanCurrent == cleanLatest) {
                                detailOutput.line();
                                detailOutput.statusSuccess("Plugin is already at the latest version (#latestVersion#)");
                                detailOutput.line();
                                detailOutput.statusInfo("Use --force to reinstall anyway");
                                detailOutput.output("- wheels plugin update #arguments.name# --force", true);
                                return;
                            }
                            targetVersion = latestVersion;
                        }
                    } else {
                        // Force flag set, use target version
                        targetVersion = len(arguments.version) ? arguments.version : latestVersion;
                    }
                } else {
                    // Couldn't get version from ForgeBox
                    if (!arguments.force && !len(arguments.version)) {
                        detailOutput.statusWarning("Unable to check latest version from ForgeBox");
                        detailOutput.line();
                        detailOutput.subHeader("Options");
                        detailOutput.output("- Specify a version:", true);
                        detailOutput.output("  wheels plugin update #arguments.name# --version=x.x.x", true);
                        detailOutput.output("- Force reinstall:", true);
                        detailOutput.output("  wheels plugin update #arguments.name# --force", true);
                        return;
                    }
                }
            } catch (any e) {
                // Error querying ForgeBox
                detailOutput.statusWarning("Error checking ForgeBox: #e.message#");
                detailOutput.line();

                if (!arguments.force && !len(arguments.version)) {
                    detailOutput.statusWarning("Unable to verify if update is needed");
                    detailOutput.line();
                    detailOutput.subHeader("Options");
                    detailOutput.output("- Specify a version:", true);
                    detailOutput.output("  wheels plugin update #arguments.name# --version=x.x.x", true);
                    detailOutput.output("- Force reinstall:", true);
                    detailOutput.output("  wheels plugin update #arguments.name# --force", true);
                    return;
                }

                // If version specified or force flag, continue
                if (len(arguments.version)) {
                    targetVersion = arguments.version;
                }
            }

            detailOutput.line();
            detailOutput.metric("Target version", targetVersion);
            detailOutput.divider();
            detailOutput.line();

            // Update process
            detailOutput.output("Removing old version...");
            directoryDelete(foundPlugin.path, true);
            detailOutput.remove(foundPlugin.folderName);

            // Install new version
            detailOutput.output("Installing new version...");

            var packageSpec = pluginSlug;
            if (targetVersion != "latest") {
                packageSpec &= "@" & targetVersion;
            }

            packageService.installPackage(
                ID = packageSpec,
                currentWorkingDirectory = fileSystemUtil.resolvePath(""),
                force = arguments.force,
                save = false,
                production = true,
                verbose = false
            );

            // Verify installation and move if needed
            var targetPath = pluginsDir & "/" & pluginSlug;
            if (!directoryExists(targetPath)) {
                // Check common installation locations and move if needed
                var possiblePaths = [
                    fileSystemUtil.resolvePath("modules/" & pluginSlug),
                    fileSystemUtil.resolvePath(pluginSlug)
                ];

                for (var possiblePath in possiblePaths) {
                    if (directoryExists(possiblePath)) {
                        // Move to plugins directory
                        directoryRename(possiblePath, targetPath);
                        break;
                    }
                }
            }

            detailOutput.line();
            detailOutput.statusSuccess("Plugin '#pluginInfo.name#' updated successfully!");
            detailOutput.line();

            // Show version comparison
            detailOutput.subHeader("Update Summary");
            detailOutput.metric("Plugin", pluginInfo.name);
            detailOutput.update("Version", "v#currentVersion# → v#targetVersion#");
            detailOutput.metric("Location", "/plugins/#foundPlugin.folderName#");
            detailOutput.line();

            // Show post-update commands
            detailOutput.subHeader("Commands");
            detailOutput.output("- wheels plugin info #arguments.name#   View plugin details", true);
            detailOutput.output("- wheels plugin list            View all installed plugins", true);
            detailOutput.output("- wheels reload                Reload application", true);
            detailOutput.line();

        } catch (any e) {
            detailOutput.error("Error updating plugin: #e.message#");
            setExitCode(1);
            return;
        }
    }
}