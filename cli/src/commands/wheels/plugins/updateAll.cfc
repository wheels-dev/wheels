/**
 * Update all installed Wheels plugins to their latest versions
 * Examples:
 * wheels plugin update:all
 * wheels plugin update:all --dryRun
 */
component aliases="wheels plugin update:all,wheels plugins update:all, wheels plugin updateall" extends="../base" {

    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService";
    property name="forgebox" inject="ForgeBox";
    property name="fileSystemUtil" inject="FileSystem";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @dryRun.hint Show what would be updated without actually updating
     * @force.hint Force update even if already at latest version
     */
    function run(
        boolean dryRun = false,
        boolean force = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);
        try {
            detailOutput.header("Checking for Plugin Updates");
            detailOutput.line();

            // Get list of installed plugins from /plugins folder
            var plugins = pluginService.list();

            if (arrayLen(plugins) == 0) {
                detailOutput.statusWarning("No plugins installed in /plugins folder");
                detailOutput.line();
                detailOutput.subHeader("Install plugins with");
                detailOutput.output("- wheels plugin install <plugin-name>", true);
                return;
            }

            detailOutput.output("Checking #arrayLen(plugins)# installed plugin(s)...");
            detailOutput.line();

            var updatesAvailable = [];
            var upToDate = [];
            var errors = [];

            // Check each plugin for updates
            for (var plugin in plugins) {
                try {
                    var pluginSlug = plugin.slug ?: plugin.name;

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
                        arrayAppend(updatesAvailable, {
                            name: plugin.name,
                            slug: pluginSlug,
                            folderName: plugin.folderName ?: pluginSlug,
                            currentVersion: currentVersion,
                            latestVersion: latestVersion
                        });
                        detailOutput.update("#plugin.name# (v#currentVersion# → v#latestVersion#)");
                    } else {
                        arrayAppend(upToDate, plugin.name);
                        detailOutput.identical("#plugin.name# (v#currentVersion#)");
                    }

                } catch (any e) {
                    arrayAppend(errors, {
                        name: plugin.name,
                        error: e.message
                    });
                    detailOutput.conflict("#plugin.name#");
                }
            }

            detailOutput.line();
            detailOutput.divider("-", 60);
            detailOutput.line();

            // Show summary
            if (arrayLen(updatesAvailable) == 0) {
                detailOutput.statusSuccess("All plugins are up to date!");
                detailOutput.line();
                
                if (arrayLen(errors) > 0) {
                    detailOutput.statusWarning("Note: #arrayLen(errors)# plugin(s) could not be checked");
                    for (var error in errors) {
                        detailOutput.output("- #error.name#: #error.error#", true);
                    }
                }
                return;
            }

            // Show available updates
            detailOutput.subHeader("Updates Available (#arrayLen(updatesAvailable)#)");
            detailOutput.line();

            // Create table for updates
            var updateRows = [];
            for (var update in updatesAvailable) {
                arrayAppend(updateRows, {
                    "Plugin": update.name,
                    "Current": update.currentVersion,
                    "Latest": update.latestVersion
                });
            }
            
            print.table(updateRows).toConsole();
            detailOutput.line();

            if (arguments.dryRun) {
                detailOutput.statusWarning("[DRY RUN] No updates will be performed");
                detailOutput.line();
                detailOutput.output("Remove --dryRun to actually update plugins");
                return;
            }

            // Confirm updates
            if (!arguments.force) {
                var continue = ask("Update #arrayLen(updatesAvailable)# plugin(s)? (y/N): ");
                if (lCase(continue) != "y") {
                    detailOutput.statusInfo("Update cancelled");
                    return;
                }
            }

            detailOutput.line();
            detailOutput.subHeader("Updating Plugins...");
            detailOutput.line();

            // Perform updates
            var successCount = 0;
            var failCount = 0;

            for (var update in updatesAvailable) {
                try {
                    // Remove old version
                    var pluginsDir = fileSystemUtil.resolvePath("plugins");
                    var oldPluginPath = pluginsDir & "/" & update.folderName;
                    if (directoryExists(oldPluginPath)) {
                        directoryDelete(oldPluginPath, true);
                        detailOutput.remove("#update.name# (v#update.currentVersion#)");
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

                    detailOutput.update("#update.name# (v#update.latestVersion#)");
                    successCount++;

                } catch (any e) {
                    detailOutput.statusFailed("Failed to update #update.name#: #e.message#");
                    failCount++;
                }
            }

            // Show final summary
            detailOutput.line();
            detailOutput.header("Update Summary");
            detailOutput.line();

            // Create summary table
            var summaryRows = [];
            arrayAppend(summaryRows, { "Status" = "Total plugins checked", "Count" = "#arrayLen(plugins)#" });
            arrayAppend(summaryRows, { "Status" = "Up to date", "Count" = "#arrayLen(upToDate)#" });
            arrayAppend(summaryRows, { "Status" = "Updated successfully", "Count" = "#successCount#" });
            if (failCount > 0) {
                arrayAppend(summaryRows, { "Status" = "Update failed", "Count" = "#failCount#" });
            }
            if (arrayLen(errors) > 0) {
                arrayAppend(summaryRows, { "Status" = "Check errors", "Count" = "#arrayLen(errors)#" });
            }
            
            print.table(summaryRows).toConsole();
            detailOutput.line();

            if (successCount > 0) {
                detailOutput.statusSuccess("#successCount# plugin(s) updated successfully!");
                detailOutput.line();
                detailOutput.statusInfo("Remember to run 'wheels reload' for changes to take effect");
            }

            if (failCount > 0) {
                detailOutput.statusFailed("#failCount# plugin(s) failed to update");
            }

            if (arrayLen(errors) > 0) {
                detailOutput.statusWarning("#arrayLen(errors)# plugin(s) could not be checked");
            }

            detailOutput.line();
            detailOutput.subHeader("Next Steps");
            detailOutput.output("- Run 'wheels plugin list' to see all installed plugins", true);
            detailOutput.output("- Run 'wheels reload' to reload application with new versions", true);
            detailOutput.output("- Run 'wheels plugin outdated' to check for updates again", true);
            detailOutput.line();

        } catch (any e) {
            detailOutput.error("Error updating plugins: #e.message#");
        }
    }
}