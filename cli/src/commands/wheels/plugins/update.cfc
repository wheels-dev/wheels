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
        try {
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Updating Plugin: #arguments.name#")
                 .boldCyanLine("===========================================================")
                 .line();

            // Find plugin in /plugins folder
            var pluginsDir = fileSystemUtil.resolvePath("plugins");
            if (!directoryExists(pluginsDir)) {
                print.boldRedText("[ERROR] ")
                     .redLine("Plugins directory not found")
                     .line()
                     .yellowLine("Plugin '#arguments.name#' is not installed")
                     .line();
                setExitCode(1);
                return;
            }

            // Find plugin by name, slug, or folder name
            var foundPlugin = pluginService.findPluginByName(pluginsDir, arguments.name);

            if (!foundPlugin.found) {
                print.boldRedText("[ERROR] ")
                     .redLine("Plugin not found")
                     .line()
                     .yellowLine("Plugin '#arguments.name#' is not installed")
                     .line()
                     .line("Install this plugin:")
                     .cyanLine("  wheels plugin install #arguments.name#");
                setExitCode(1);
                return;
            }

            // Get plugin info from folder
            var pluginInfo = pluginService.getPluginInfoFromFolder(foundPlugin.path, foundPlugin.folderName);
            var pluginSlug = pluginInfo.slug;
            var currentVersion = pluginInfo.version;

            print.line("Plugin:          #pluginInfo.name#");
            print.line("Current version: #currentVersion#");

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
                    print.line("Latest version:  #latestVersion#");

                    if (!arguments.force) {
                        // Check if already at target version
                        if (len(arguments.version)) {
                            // User specified a version
                            if (currentVersion == arguments.version) {
                                print.line()
                                     .boldCyanLine("===========================================================")
                                     .line()
                                     .boldGreenText("[OK] ")
                                     .greenLine("Plugin is already at version #arguments.version#")
                                     .line()
                                     .line("Use --force to reinstall anyway:");
                                print.cyanLine("  wheels plugin update #arguments.name# --force");
                                return;
                            }
                            targetVersion = arguments.version;
                        } else {
                            // Check latest version - clean versions for comparison
                            var cleanCurrent = trim(reReplace(currentVersion, "[^0-9\.]", "", "ALL"));
                            var cleanLatest = trim(reReplace(latestVersion, "[^0-9\.]", "", "ALL"));

                            if (cleanCurrent == cleanLatest) {
                                print.line()
                                     .boldCyanLine("===========================================================")
                                     .line()
                                     .boldGreenText("[OK] ")
                                     .greenLine("Plugin is already at the latest version (#latestVersion#)")
                                     .line()
                                     .line("Use --force to reinstall anyway:");
                                print.cyanLine("  wheels plugin update #arguments.name# --force");
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
                        print.line()
                             .yellowLine("Unable to check latest version from ForgeBox")
                             .line()
                             .line("Options:")
                             .line("  - Specify a version:")
                             .cyanLine("    wheels plugin update #arguments.name# --version=x.x.x")
                             .line("  - Force reinstall:")
                             .cyanLine("    wheels plugin update #arguments.name# --force");
                        return;
                    }
                }
            } catch (any e) {
                // Error querying ForgeBox
                print.line()
                     .yellowLine("Error checking ForgeBox: #e.message#")
                     .line();

                if (!arguments.force && !len(arguments.version)) {
                    print.yellowLine("Unable to verify if update is needed")
                         .line()
                         .line("Options:")
                         .line("  - Specify a version:")
                         .cyanLine("    wheels plugin update #arguments.name# --version=x.x.x")
                         .line("  - Force reinstall:")
                         .cyanLine("    wheels plugin update #arguments.name# --force");
                    return;
                }

                // If version specified or force flag, continue
                if (len(arguments.version)) {
                    targetVersion = arguments.version;
                }
            }

            print.line()
                 .line("Target version: #targetVersion#")
                 .boldCyanLine("===========================================================")
                 .line();

            // Remove old version
            print.line("Removing old version...");
            directoryDelete(foundPlugin.path, true);

            // Install new version
            print.line("Installing new version...");

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

            print.line()
                 .boldCyanLine("===========================================================")
                 .line()
                 .boldGreenText("[OK] ")
                 .greenLine("Plugin '#pluginInfo.name#' updated successfully!")
                 .line();

            // Show post-update info
            print.boldLine("Commands:")
                 .cyanLine("  wheels plugin info #arguments.name#   View plugin details")
                 .cyanLine("  wheels plugin list            View all installed plugins");

        } catch (any e) {
            print.line()
                 .boldRedText("[ERROR] ")
                 .redLine("Error updating plugin")
                 .line()
                 .yellowLine("Error: #e.message#");
            setExitCode(1);
        }
    }

    /**
     * Resolve a file path
     */
    private function resolvePath(path) {
        if (left(arguments.path, 1) == "/" || mid(arguments.path, 2, 1) == ":") {
            return arguments.path;
        }
        return expandPath(".") & "/" & arguments.path;
    }
}
