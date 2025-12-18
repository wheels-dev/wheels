/**
 * Switch to a different environment
 * Examples:
 * wheels env switch production
 * wheels env switch development --restart
 * wheels env switch staging --backup --force
 * wheels env switch testing --quiet
 */
component extends="../base" {
    
    property name="environmentService" inject="EnvironmentService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @environment.hint Environment name to switch to
     * @check.hint Validate environment before switching
     * @restart.hint Restart application after switch
     * @backup.hint Create backup before switching
     * @force.hint Force switch even with validation issues
     * @quiet.hint Suppress output messages
     */
    function run(
        required string environment,
        boolean check = true,
        boolean restart = false,
        boolean backup = false,
        boolean force = false,
        boolean quiet = false
    ) {
        requireWheelsApp(getCWD());
        var projectRoot = resolvePath(".");
        arguments = reconstructArgs(arguments);

        // Get current environment
        var currentEnv = environmentService.getCurrent(projectRoot);
        
        // Display switch information (unless quiet mode)
        if (!arguments.quiet) {
            detailOutput.header("Environment Switch");
            detailOutput.line();
            
            if (currentEnv != "none") {
                detailOutput.metric("Current Environment", currentEnv);
            } else {
                detailOutput.statusWarning("No environment currently set");
            }
            
            detailOutput.metric("Target Environment", arguments.environment);
            detailOutput.line();
        }
        
        // Validation phase (if check is enabled and not forced)
        if (arguments.check && !arguments.force) {
            if (!arguments.quiet) {
                detailOutput.output("Validating target environment...");
            }
            
            var validation = validateEnvironment(arguments.environment, projectRoot);
            
            if (!validation.isValid) {
                if (!arguments.quiet) {
                    detailOutput.statusFailed("Validation failed: #validation.error#");
                }
                
                if (!arguments.force) {
                    if (!arguments.quiet) {
                        detailOutput.error("Switch cancelled due to validation errors");
                        detailOutput.statusInfo("Use --force to override validation");
                    }
                    setExitCode(1);
                    return;
                } else if (!arguments.quiet) {
                    detailOutput.statusWarning("Continuing anyway (--force enabled)");
                }
            } else if (!arguments.quiet) {
                detailOutput.statusSuccess("Environment validation passed");
                if (structKeyExists(validation, "warning") && len(validation.warning)) {
                    detailOutput.statusWarning("#validation.warning#");
                }
            }
        } else if (arguments.force && !arguments.quiet) {
            detailOutput.statusWarning("Validation skipped (--force enabled)");
        }
        
        // Backup phase (if backup is requested)
        if (arguments.backup) {
            if (!arguments.quiet) {
                detailOutput.output("Creating backup...");
            }
            
            var backupResult = createBackup(projectRoot);
            
            if (!backupResult.success) {
                if (!arguments.quiet) {
                    detailOutput.statusFailed("Backup failed: #backupResult.error#");
                }
                
                if (!arguments.force) {
                    if (!arguments.quiet) {
                        detailOutput.error("Switch cancelled due to backup failure");
                    }
                    setExitCode(1);
                    return;
                } else if (!arguments.quiet) {
                    detailOutput.statusWarning("Continuing without backup (--force enabled)");
                }
            } else if (!arguments.quiet) {
                detailOutput.statusSuccess("Backup created");
                detailOutput.metric("Backup saved", "#backupResult.filename#");
            }
        }
        
        // Confirm for production switches (unless forced or quiet)
        if (arguments.environment == "production" && currentEnv != "production" && !arguments.force && !arguments.quiet) {
            detailOutput.statusWarning("Switching to PRODUCTION environment");
            detailOutput.output("This will:");
            detailOutput.output("- Disable debug mode", true);
            detailOutput.output("- Enable full caching", true);
            detailOutput.output("- Hide detailed error messages", true);
            detailOutput.line();
            
            var confirmed = ask("Are you sure you want to continue? (yes/no): ");
            if (confirmed != "yes" && confirmed != "y") {
                detailOutput.statusInfo("Switch cancelled");
                return;
            }
            detailOutput.line();
        }
        
        // Perform the switch
        if (!arguments.quiet) {
            detailOutput.output("Switching environment...");
        }
        
        var result = environmentService.switch(arguments.environment, projectRoot);
        
        if (result.success) {
            if (!arguments.quiet) {
                
                // Show what was done
                if (structKeyExists(result, "oldEnvironment") && len(result.oldEnvironment)) {
                    detailOutput.update(".env file: Updated from #result.oldEnvironment# to #arguments.environment#", true);
                } else {
                    detailOutput.create(".env file", "Set to #arguments.environment# environment");
                }
            }
            
            // Restart services if requested
            if (arguments.restart) {
                if (!arguments.quiet) {
                    detailOutput.output("Restarting application...");
                }
                
                var restartResult = restartApplication(projectRoot);
                
                if (restartResult.success) {
                    if (!arguments.quiet) {
                        detailOutput.statusSuccess("Application restarted");
                        detailOutput.metric("Status", restartResult.message);
                    }
                } else {
                    if (!arguments.quiet) {
                        detailOutput.statusWarning("Restart failed: #restartResult.error#");
                        detailOutput.output("Please restart manually");
                    }
                }
            }
            
            // Display success message and details (unless quiet)
            if (!arguments.quiet) {
                detailOutput.line();
                detailOutput.statusSuccess("Environment switched successfully!");
                detailOutput.line();
                
                // Show environment details if available
                if (structKeyExists(result, "database") || structKeyExists(result, "debug") || structKeyExists(result, "cache")) {
                    detailOutput.subHeader("Environment Details");
                    detailOutput.metric("Environment", arguments.environment);
                    
                    if (len(result.database) && result.database != "default") {
                        detailOutput.metric("Database", result.database);
                    }
                    if (structKeyExists(result, "debug")) {
                        detailOutput.metric("Debug Mode", result.debug ? "Enabled" : "Disabled");
                    }
                    if (len(result.cache) && result.cache != "default") {
                        detailOutput.metric("Cache", result.cache);
                    }
                    detailOutput.line();
                }
                
                // Show next steps (unless restart was done)
                if (!arguments.restart) {
                    detailOutput.statusInfo("IMPORTANT");
                    detailOutput.output("- Restart your application server for changes to take effect",true);
                    detailOutput.output("- Run 'wheels reload' if using Wheels development server",true);
                    detailOutput.output("- Or use 'wheels env switch #arguments.environment# --restart' next time",true);
                    detailOutput.line();
                }
                
                // Environment-specific tips
                if (arguments.environment == "production") {
                    detailOutput.subHeader("Production Tips");
                    detailOutput.output("- Ensure all migrations are up to date", true);
                    detailOutput.output("- Clear application caches after restart", true);
                    detailOutput.output("- Monitor error logs for any issues", true);
                    detailOutput.line();
                } else if (arguments.environment == "development") {
                    detailOutput.subHeader("Development Mode");
                    detailOutput.output("- Debug information will be displayed", true);
                    detailOutput.output("- Caching may be disabled", true);
                    detailOutput.output("- Detailed error messages will be shown", true);
                    detailOutput.line();
                }
            } else {
                // Minimal output in quiet mode - just success
                detailOutput.statusSuccess("Environment switched to #arguments.environment#");
            }
            
        } else {
            if (!arguments.quiet) {
                detailOutput.statusFailed("Failed to switch environment");
                detailOutput.error("#result.error#");
                detailOutput.line();
                
                // Provide helpful suggestions
                detailOutput.statusInfo("Suggestions");
                detailOutput.output("- Check if you have write permissions for .env file", true);
                detailOutput.output("- Ensure the environment name is valid", true);
                detailOutput.output("- Try running with administrator/sudo privileges if needed", true);
                detailOutput.output("- Use --force to bypass validation checks", true);
            } else {
                // Minimal output in quiet mode
                detailOutput.statusFailed("#result.error#");
            }
            
            setExitCode(1);
        }
    }
    
    /**
     * Validate the target environment by checking for required files
     */
    private function validateEnvironment(required string environment, required string projectRoot) {
        var envFile = "#arguments.projectRoot#/.env.#arguments.environment#";
        var configFile = "#arguments.projectRoot#/config/#arguments.environment#/settings.cfm";
        
        var errors = [];
        var warnings = [];
        
        // Check if .env.[environment] file exists
        if (!fileExists(envFile)) {
            errors.append(".env.#arguments.environment# file not found");
        }
        
        // Check if config/[environment]/settings.cfm exists
        if (!fileExists(configFile)) {
            errors.append("config/#arguments.environment#/settings.cfm file not found");
        }
        
        // If both files are missing, it's invalid
        if (arrayLen(errors) == 2) {
            return {
                isValid: false,
                error: "Environment '#arguments.environment#' is not configured. Missing required files: #arrayToList(errors, ' and ')#"
            };
        }
        
        // If one file exists but not the other, it's valid but with a warning
        if (arrayLen(errors) == 1) {
            return {
                isValid: true,
                warning: "Missing: #errors[1]#. Environment may not be fully configured."
            };
        }
        
        // Both files exist - valid environment
        return {
            isValid: true
        };
    }
    
    /**
     * Create a backup of current environment files
     */
    private function createBackup(required string projectRoot) {
        try {
            var timestamp = dateTimeFormat(now(), "yyyymmdd-HHmmss");
            var envFile = "#arguments.projectRoot#/.env";
            
            if (!fileExists(envFile)) {
                return {
                    success: false,
                    error: ".env file not found"
                };
            }
            
            var backupFile = "#arguments.projectRoot#/.env.backup-#timestamp#";
            fileCopy(envFile, backupFile);
            
            // Also backup server.json if it exists
            var serverJsonFile = "#arguments.projectRoot#/server.json";
            if (fileExists(serverJsonFile)) {
                fileCopy(serverJsonFile, "#arguments.projectRoot#/server.json.backup-#timestamp#");
            }
            
            return {
                success: true,
                filename: ".env.backup-#timestamp#"
            };
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Restart the application
     */
    private function restartApplication(required string projectRoot) {
        try {
            // Try to restart using CommandBox if server.json exists
            var serverJsonFile = "#arguments.projectRoot#/server.json";
            
            if (fileExists(serverJsonFile)) {
                // Stop the server
                command("server stop")
                    .inWorkingDirectory(arguments.projectRoot)
                    .run();
                
                // Start the server
                command("server start")
                    .inWorkingDirectory(arguments.projectRoot)
                    .run();
                
                return {
                    success: true,
                    message: "CommandBox server restarted"
                };
            } else {
                // Try wheels reload command
                command("wheels reload")
                    .inWorkingDirectory(arguments.projectRoot)
                    .run();
                    
                return {
                    success: true,
                    message: "Application reloaded"
                };
            }
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
}