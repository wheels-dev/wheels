/**
 * Seed the database with data.
 *
 * By default, runs convention seed files (app/db/seeds.cfm and app/db/seeds/<environment>.cfm)
 * if they exist. Falls back to generating random test data if no seed files are found.
 *
 * {code:bash}
 * wheels db:seed                           # Run convention seeds (or generate if no seed files)
 * wheels db:seed --environment=production  # Run seeds for a specific environment
 * wheels db:seed --generate                # Force random test data generation
 * wheels db:seed --generate --count=10     # Generate 10 records per model
 * wheels db:seed --generate --models=user,post  # Generate for specific models
 * {code}
 */
component extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @environment Environment to seed (defaults to current)
     * @generate Force random test data generation instead of convention seeds
     * @models Comma-delimited list of models to seed (only with --generate)
     * @count Number of records to generate per model (only with --generate)
     * @dataFile Path to JSON file containing seed data (only with --generate)
     */
    function run(
        string environment="",
        boolean generate=false,
        string models="",
        numeric count=5,
        string dataFile=""
    ) {
        print.line();
        print.boldMagentaLine("Wheels Database Seed");
        print.line();

        // Build URL parameters
        local.urlParams = "&command=dbSeed";

        // Determine mode
        if (arguments.generate) {
            local.urlParams &= "&mode=generate";
            local.urlParams &= "&count=#arguments.count#";

            if (len(trim(arguments.models))) {
                local.urlParams &= "&models=#urlEncodedFormat(arguments.models)#";
            }

            print.yellowLine("Mode: generate random test data");
        } else {
            local.urlParams &= "&mode=auto";
            print.yellowLine("Mode: convention seeds (auto-detect)");
        }

        if (len(trim(arguments.environment))) {
            local.urlParams &= "&environment=#urlEncodedFormat(arguments.environment)#";
        }

        // Handle data file if provided (generate mode only)
        if (arguments.generate && len(trim(arguments.dataFile))) {
            local.filePath = fileSystemUtil.resolvePath(arguments.dataFile);
            if (!fileExists(local.filePath)) {
                error("Seed data file not found: #arguments.dataFile#");
            }

            try {
                local.seedData = fileRead(local.filePath);
                local.seedData = deserializeJSON(local.seedData);
                local.urlParams &= "&dataProvided=true";

                local.tempDataFile = fileSystemUtil.resolvePath("app/tmp/seed_data.json");
                file action='write' file='#local.tempDataFile#' mode='777' output='#serializeJSON(local.seedData)#';
                local.urlParams &= "&dataFile=#urlEncodedFormat(local.tempDataFile)#";

                print.yellowLine("Using seed data from: #arguments.dataFile#");
            } catch (any e) {
                error("Invalid JSON in seed data file: #e.message#");
            }
        }

        // Send command
        print.line("Seeding database...");
        local.result = $sendToCliCommand(urlstring=local.urlParams);
        if (!local.result.success) {
            return;
        }

        // Display results based on mode
        if (structKeyExists(local.result, "success") && local.result.success) {
            local.resultMode = structKeyExists(local.result, "mode") ? local.result.mode : "generate";

            if (local.resultMode == "convention") {
                // Convention seed results
                print.boldGreenLine("Database seeded successfully (convention)");
                print.line();

                if (structKeyExists(local.result, "environment")) {
                    print.yellowLine("Environment: #local.result.environment#");
                }

                if (structKeyExists(local.result, "totalCreated")) {
                    print.line("  Created: #local.result.totalCreated# records");
                }
                if (structKeyExists(local.result, "totalSkipped")) {
                    print.line("  Skipped: #local.result.totalSkipped# existing records");
                }

                // Show per-model details
                if (structKeyExists(local.result, "results") && isArray(local.result.results)) {
                    print.line();
                    for (local.item in local.result.results) {
                        if (structKeyExists(local.item, "model") && structKeyExists(local.item, "action")) {
                            if (local.item.action == "created") {
                                print.greenLine("  + #local.item.model# created");
                            } else if (local.item.action == "skipped") {
                                print.yellowLine("  ~ #local.item.model# skipped (exists)");
                            } else if (local.item.action == "failed") {
                                local.errMsg = structKeyExists(local.item, "errors") ? serializeJSON(local.item.errors) : "unknown error";
                                print.redLine("  ! #local.item.model# failed: #local.errMsg#");
                            }
                        }
                    }
                }
            } else {
                // Generate mode results
                print.boldGreenLine("Database seeded successfully (generated)");

                if (structKeyExists(local.result, "seeded") && isArray(local.result.seeded)) {
                    print.line();
                    print.yellowLine("Models seeded:");
                    for (local.model in local.result.seeded) {
                        if (structKeyExists(local.model, "model") && structKeyExists(local.model, "count")) {
                            if (structKeyExists(local.model, "success") && local.model.success) {
                                print.line("  + #local.model.model#: #local.model.count# records");
                            } else {
                                local.errMsg = structKeyExists(local.model, "error") ? local.model.error : "unknown error";
                                print.redLine("  ! #local.model.model#: failed - #local.errMsg#");
                            }
                        }
                    }
                }
            }
        } else {
            print.boldRedLine("Failed to seed database");
            if (structKeyExists(local.result, "message")) {
                print.redLine(local.result.message);
            }
        }

        print.line();
    }
}
