/**
 * Update all installed Wheels plugins to their latest versions
 * Examples:
 * wheels plugin update:all
 * wheels plugin update:all --dryRun
 */
component aliases="wheels plugin update:all,wheels plugins update:all" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService";
    property name="forgebox" inject="ForgeBox";
    property name="fileSystemUtil" inject="FileSystem";

    /**
     * @dryRun.hint Show what would be updated without actually updating
     * @force.hint Force update even if already at latest version
     */
    function run(
        boolean dryRun = false,
        boolean force = false
    ) {
        try {
            print.line()
                 .boldCyanLine("===========================================================")
                 .boldCyanLine("  Checking for Plugin Updates")
                 .boldCyanLine("===========================================================")
                 .line();

            // Get list of installed plugins from /plugins folder
            var plugins = pluginService.list();

            if (arrayLen(plugins) == 0) {
                print.yellowLine("No plugins installed in /plugins folder")
                     .line();
                print.line("Install plugins with:")
                     .cyanLine("  wheels plugin install <plugin-name>");
                return;
            }

            var updatesAvailable = [];
            var upToDate = [];
            var errors = [];

            // Check each plugin for updates
            for (var plugin in plugins) {
                try {
                    var pluginSlug = plugin.slug ?: plugin.name;

                    // Format plugin name with padding for alignment
                    var displayName = plugin.name;
                    var padding = repeatString(" ", max(40 - len(displayName), 1));
                    print.text("  " & displayName & padding);

                    // Get latest version using forgebox show command for fresh data
                    var forgeboxResult = command('forgebox show')
                        .params(pluginSlug)
                        .run(returnOutput=true);

                    var latestVersion = "unknown";
                    var versionMatch = reFind("Versions\s*:\s*([0-9\.]+)", forgeboxResult, 1, true);
                    if (versionMatch.pos[1] > 0) {
                        latestVersion = mid(forgeboxResult, versionMatch.pos[2], versionMatch.len[2]);
                    }

                    var currentVersion = plugin.version;

                    // Clean versions for comparison
                    var cleanCurrent = trim(reReplace(currentVersion, "[^0-9\.]", "", "ALL"));
                    var cleanLatest = trim(reReplace(latestVersion, "[^0-9\.]", "", "ALL"));

                    // Compare versions
                    if (cleanCurrent != cleanLatest && latestVersion != "unknown") {
                        print.yellowBoldText("[UPDATE] ")
                             .yellowLine("#currentVersion# -> #latestVersion#");
                        arrayAppend(updatesAvailable, {
                            name: plugin.name,
                            slug: pluginSlug,
                            folderName: plugin.folderName ?: pluginSlug,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion
                        });
                    } else {
                        print.greenBoldText("[OK] ")
                             .greenLine("v#currentVersion#");
                        arrayAppend(upToDate, plugin.name);
                    }

                } catch (any e) {
                    print.redBoldText("[ERROR] ")
                         .redLine("Failed to check");
                    arrayAppend(errors, {
                        name: plugin.name,
                        error: e.message
                    });
                }
            }

            print.line()
                 .boldLine("-----------------------------------------------------------")
                 .line();

            // Show summary
            if (arrayLen(updatesAvailable) == 0) {
                print.boldGreenLine("[OK] All plugins are up to date!")
                     .line();

                if (arrayLen(errors) > 0) {
                    print.yellowLine("Note: #arrayLen(errors)# plugin(s) could not be checked");
                }
                return;
            }

            // Show available updates table
            print.boldLine("Updates Available:")
                 .line();

            for (var update in updatesAvailable) {
                var namePad = repeatString(" ", max(35 - len(update.name), 1));
                var versionInfo = update.currentVersion & " -> " & update.latestVersion;
                print.text("  ")
                     .boldText(update.name)
                     .text(namePad)
                     .yellowLine(versionInfo);
            }

            print.line();

            if (arguments.dryRun) {
                print.yellowBoldLine("[DRY RUN] No updates will be performed")
                     .line();
                print.line("Remove --dryRun to actually update plugins");
                return;
            }

            // Confirm updates
            if (!arguments.force) {
                var continue = ask("Update #arrayLen(updatesAvailable)# plugin#arrayLen(updatesAvailable) != 1 ? 's' : ''#? (y/N): ");
                if (lCase(continue) != "y") {
                    print.yellowLine("Update cancelled");
                    return;
                }
            }

            print.line()
                 .boldLine("Updating Plugins...")
                 .line();

            // Perform updates
            var successCount = 0;
            var failCount = 0;

            for (var update in updatesAvailable) {
                try {
                    var updatePad = repeatString(" ", max(35 - len(update.name), 1));
                    print.text("  " & update.name & updatePad);

                    // Remove old version
                    var pluginsDir = fileSystemUtil.resolvePath("plugins");
                    var oldPluginPath = pluginsDir & "/" & update.folderName;
                    if (directoryExists(oldPluginPath)) {
                        directoryDelete(oldPluginPath, true);
                    }

                    // Install new version to /plugins folder
                    packageService.installPackage(
                        ID = update.slug & "@" & update.latestVersion,
                        currentWorkingDirectory = fileSystemUtil.resolvePath(""),
                        force = true,
                        save = false,
                        production = true,
                        verbose = false
                    );

                    // Verify installation and move if needed
                    var targetPath = pluginsDir & "/" & update.slug;
                    if (!directoryExists(targetPath)) {
                        // Check common installation locations and move if needed
                        var possiblePaths = [
                            fileSystemUtil.resolvePath("modules/" & update.slug),
                            fileSystemUtil.resolvePath(update.slug)
                        ];

                        for (var possiblePath in possiblePaths) {
                            if (directoryExists(possiblePath)) {
                                // Move to plugins directory
                                directoryRename(possiblePath, targetPath);
                                break;
                            }
                        }
                    }

                    print.greenLine("[OK] Updated");
                    successCount++;

                } catch (any e) {
                    print.redLine("[ERROR] #e.message#");
                    failCount++;
                }
            }

            // Show final summary
            print.line()
                 .boldLine("===========================================================")
                 .boldLine("  Update Summary")
                 .boldLine("===========================================================")
                 .line();

            if (successCount > 0) {
                print.greenBoldText("[OK] ")
                     .greenLine("#successCount# plugin#successCount != 1 ? 's' : ''# updated successfully");
            }

            if (failCount > 0) {
                print.redBoldText("[ERROR] ")
                     .redLine("#failCount# plugin#failCount != 1 ? 's' : ''# failed to update");
            }

            if (arrayLen(errors) > 0) {
                print.yellowBoldText("[!] ")
                     .yellowLine("#arrayLen(errors)# plugin#arrayLen(errors) != 1 ? 's' : ''# could not be checked");
            }

            print.line()
                 .line("To see all installed plugins:")
                 .cyanLine("  wheels plugin list");

        } catch (any e) {
            error("Error updating plugins: #e.message#");
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
