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
            print.line()
                .boldBlueLine("Environment Switch")
                .line("=".repeatString(50))
                .line();
            
            if (currentEnv != "none") {
                print.line("Current Environment: ")
                    .boldText(currentEnv)
                    .line();
            } else {
                print.yellowLine("No environment currently set");
            }
            
            print.line("Target Environment:  ")
                .boldText(arguments.environment)
                .line()
                .line();
        }
        
        // Validation phase (if check is enabled and not forced)
        if (arguments.check && !arguments.force) {
            if (!arguments.quiet) {
                print.text("Validating target environment... ");
            }
            
            var validation = validateEnvironment(arguments.environment, projectRoot);
            
            if (!validation.isValid) {
                if (!arguments.quiet) {
                    print.redLine("[FAILED]")
                        .redLine("  Validation failed: #validation.error#");
                }
                
                if (!arguments.force) {
                    if (!arguments.quiet) {
                        print.line()
                            .redBoldLine("[X] Switch cancelled due to validation errors")
                            .yellowLine("  Use --force to override validation")
                            .line();
                    }
                    setExitCode(1);
                    return;
                } else if (!arguments.quiet) {
                    print.yellowLine("  WARNING: Continuing anyway (--force enabled)");
                }
            } else if (!arguments.quiet) {
                print.greenLine("[OK]");
                if (structKeyExists(validation, "warning") && len(validation.warning)) {
                    print.yellowLine("  Warning: #validation.warning#");
                }
            }
        } else if (arguments.force && !arguments.quiet) {
            print.yellowLine("WARNING: Validation skipped (--force enabled)");
        }
        
        // Backup phase (if backup is requested)
        if (arguments.backup) {
            if (!arguments.quiet) {
                print.text("Creating backup... ");
            }
            
            var backupResult = createBackup(projectRoot);
            
            if (!backupResult.success) {
                if (!arguments.quiet) {
                    print.redLine("[FAILED]")
                        .redLine("  Backup failed: #backupResult.error#");
                }
                
                if (!arguments.force) {
                    if (!arguments.quiet) {
                        print.line()
                            .redBoldLine("[X] Switch cancelled due to backup failure")
                            .line();
                    }
                    setExitCode(1);
                    return;
                } else if (!arguments.quiet) {
                    print.yellowLine("  WARNING: Continuing without backup (--force enabled)");
                }
            } else if (!arguments.quiet) {
                print.greenLine("[OK]")
                    .greyLine("  Backup saved: #backupResult.filename#");
            }
        }
        
        // Confirm for production switches (unless forced or quiet)
        if (arguments.environment == "production" && currentEnv != "production" && !arguments.force && !arguments.quiet) {
            print.yellowLine("WARNING: Switching to PRODUCTION environment")
                .line("   This will:")
                .line("   - Disable debug mode")
                .line("   - Enable full caching")
                .line("   - Hide detailed error messages")
                .line();
            
            var confirmed = ask("Are you sure you want to continue? (yes/no): ");
            if (confirmed != "yes" && confirmed != "y") {
                print.redLine("[X] Switch cancelled")
                    .line();
                return;
            }
            print.line();
        }
        
        // Show progress (unless quiet)
        if (!arguments.quiet) {
            print.text("Switching environment... ");
        }
        
        // Perform the switch
        var result = environmentService.switch(arguments.environment, projectRoot);
        
        if (result.success) {
            if (!arguments.quiet) {
                print.greenLine("[OK]");
                
                // Show what was done
                if (structKeyExists(result, "oldEnvironment") && len(result.oldEnvironment)) {
                    print.text("Updated environment variable... ")
                        .greenLine("[OK]");
                } else {
                    print.text("Set environment variable... ")
                        .greenLine("[OK]");
                }
            }
            
            // Restart services if requested
            if (arguments.restart) {
                if (!arguments.quiet) {
                    print.text("Restarting application... ");
                }
                
                var restartResult = restartApplication(projectRoot);
                
                if (restartResult.success) {
                    if (!arguments.quiet) {
                        print.greenLine("[OK]")
                            .greyLine("  #restartResult.message#");
                    }
                } else {
                    if (!arguments.quiet) {
                        print.yellowLine("[WARNING]")
                            .yellowLine("  Restart failed: #restartResult.error#")
                            .yellowLine("  Please restart manually");
                    }
                }
            }
            
            // Display success message and details (unless quiet)
            if (!arguments.quiet) {
                print.line()
                    .line("=".repeatString(50))
                    .greenBoldLine("[SUCCESS] Environment switched successfully!")
                    .line();
                
                // Show environment details if available
                if (structKeyExists(result, "database") || structKeyExists(result, "debug") || structKeyExists(result, "cache")) {
                    print.boldLine("Environment Details:")
                        .line("- Environment: #arguments.environment#");
                    
                    if (len(result.database) && result.database != "default") {
                        print.line("- Database:    #result.database#");
                    }
                    if (structKeyExists(result, "debug")) {
                        print.line("- Debug Mode:  #result.debug ? 'Enabled' : 'Disabled'#");
                    }
                    if (len(result.cache) && result.cache != "default") {
                        print.line("- Cache:       #result.cache#");
                    }
                    print.line();
                }
                
                // Show next steps (unless restart was done)
                if (!arguments.restart) {
                    print.yellowBoldLine("IMPORTANT:")
                        .line("- Restart your application server for changes to take effect")
                        .line("- Run 'wheels reload' if using Wheels development server")
                        .line("- Or use 'wheels env switch #arguments.environment# --restart' next time")
                        .line();
                }
                
                // Environment-specific tips
                if (arguments.environment == "production") {
                    print.cyanLine("Production Tips:")
                        .line("- Ensure all migrations are up to date")
                        .line("- Clear application caches after restart")
                        .line("- Monitor error logs for any issues")
                        .line();
                } else if (arguments.environment == "development") {
                    print.cyanLine("Development Mode:")
                        .line("- Debug information will be displayed")
                        .line("- Caching may be disabled")
                        .line("- Detailed error messages will be shown")
                        .line();
                }
            } else {
                // Minimal output in quiet mode - just success
                print.greenLine("Environment switched to #arguments.environment#");
            }
            
        } else {
            if (!arguments.quiet) {
                print.redLine("[FAILED]");
                print.line()
                    .redBoldLine("[X] Failed to switch environment")
                    .redLine("  Error: #result.error#")
                    .line();
                
                // Provide helpful suggestions
                print.yellowLine("Suggestions:")
                    .line("- Check if you have write permissions for .env file")
                    .line("- Ensure the environment name is valid")
                    .line("- Try running with administrator/sudo privileges if needed")
                    .line("- Use --force to bypass validation checks")
                    .line();
            } else {
                // Minimal output in quiet mode
                print.redLine("Failed: #result.error#");
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