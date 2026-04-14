/**
 * Generate seed files for database seeding.
 *
 * Creates app/db/seeds.cfm (main seed file) and optionally environment-specific
 * seed files in app/db/seeds/.
 *
 * {code:bash}
 * wheels generate seed                        # Create main seeds.cfm
 * wheels generate seed --environment=development  # Create environment-specific seed file
 * wheels generate seed --all                  # Create main + development + production stubs
 * {code}
 */
component aliases='wheels g seed' extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @environment Create an environment-specific seed file (e.g., development, production)
     * @all Create main seeds.cfm plus development and production stubs
     * @force Overwrite existing seed files
     */
    function run(
        string environment="",
        boolean all=false,
        boolean force=false
    ) {
        requireWheelsApp(getCWD());

        detailOutput.header("Seed File Generation");

        local.dbDir = fileSystemUtil.resolvePath("app/db");
        local.seedsDir = local.dbDir & "/seeds";

        // Ensure app/db/ directory exists
        if (!directoryExists(local.dbDir)) {
            directoryCreate(local.dbDir);
            detailOutput.create("app/db/");
        }

        local.filesCreated = [];

        // Create main seeds.cfm
        if (!len(trim(arguments.environment)) || arguments.all) {
            local.mainFile = local.dbDir & "/seeds.cfm";
            if (!fileExists(local.mainFile) || arguments.force) {
                file action='write' file='#local.mainFile#' mode='777' output='#getMainSeedTemplate()#';
                arrayAppend(local.filesCreated, "app/db/seeds.cfm");
                detailOutput.create("app/db/seeds.cfm");
            } else {
                print.yellowLine("  app/db/seeds.cfm already exists (use --force to overwrite)");
            }
        }

        // Ensure app/db/seeds/ directory exists for environment files
        if (len(trim(arguments.environment)) || arguments.all) {
            if (!directoryExists(local.seedsDir)) {
                directoryCreate(local.seedsDir);
                detailOutput.create("app/db/seeds/");
            }
        }

        // Create environment-specific file(s)
        if (arguments.all) {
            for (local.env in ["development", "production"]) {
                local.envFile = local.seedsDir & "/" & local.env & ".cfm";
                if (!fileExists(local.envFile) || arguments.force) {
                    file action='write' file='#local.envFile#' mode='777' output='#getEnvironmentSeedTemplate(local.env)#';
                    arrayAppend(local.filesCreated, "app/db/seeds/" & local.env & ".cfm");
                    detailOutput.create("app/db/seeds/" & local.env & ".cfm");
                } else {
                    print.yellowLine("  app/db/seeds/#local.env#.cfm already exists");
                }
            }
        } else if (len(trim(arguments.environment))) {
            local.envFile = local.seedsDir & "/" & arguments.environment & ".cfm";
            if (!fileExists(local.envFile) || arguments.force) {
                file action='write' file='#local.envFile#' mode='777' output='#getEnvironmentSeedTemplate(arguments.environment)#';
                arrayAppend(local.filesCreated, "app/db/seeds/" & arguments.environment & ".cfm");
                detailOutput.create("app/db/seeds/" & arguments.environment & ".cfm");
            } else {
                print.yellowLine("  app/db/seeds/#arguments.environment#.cfm already exists");
            }
        }

        if (arrayLen(local.filesCreated)) {
            detailOutput.success("Seed files created successfully!");

            var nextSteps = [
                "Edit your seed files to add seed data",
                "Run seeds: wheels db:seed",
                "Run for specific environment: wheels db:seed --environment=development"
            ];
            detailOutput.nextSteps(nextSteps);
        } else {
            print.yellowLine("No new files created.");
        }
    }

    /**
     * Generate the main seeds.cfm template content
     */
    private string function getMainSeedTemplate() {
        var content = '<!--- app/db/seeds.cfm --->
<!--- Shared seed data that runs in ALL environments. --->
<!--- Use seedOnce() for idempotent seeding — re-running won''t duplicate data. --->
<cfscript>

// Example: Seed default roles
// seedOnce(modelName="Role", uniqueProperties="name", properties={
//     name: "admin",
//     description: "Administrator with full access"
// });
//
// seedOnce(modelName="Role", uniqueProperties="name", properties={
//     name: "member",
//     description: "Regular member"
// });

// Example: Seed using model methods directly (not idempotent — use for one-time setup)
// if (model("Setting").count() == 0) {
//     model("Setting").create(key="siteName", value="My App");
//     model("Setting").create(key="siteEmail", value="admin@example.com");
// }

</cfscript>';
        return content;
    }

    /**
     * Generate an environment-specific seed template
     */
    private string function getEnvironmentSeedTemplate(required string environment) {
        var content = '<!--- app/db/seeds/#arguments.environment#.cfm --->
<!--- Seed data specific to the #arguments.environment# environment. --->
<!--- Runs AFTER seeds.cfm. Uses seedOnce() for idempotent seeding. --->
<cfscript>
';

        if (arguments.environment == "development") {
            content &= '
// Example: Create test users for development
// seedOnce(modelName="User", uniqueProperties="email", properties={
//     firstName: "Dev",
//     lastName: "User",
//     email: "dev@example.com",
//     role: "admin"
// });
//
// seedOnce(modelName="User", uniqueProperties="email", properties={
//     firstName: "Test",
//     lastName: "User",
//     email: "test@example.com",
//     role: "member"
// });
';
        } else if (arguments.environment == "production") {
            content &= '
// Production seeds should be minimal — only essential reference data.
// Example: Ensure critical lookup data exists
// seedOnce(modelName="Role", uniqueProperties="name", properties={
//     name: "superadmin",
//     description: "Production superadmin"
// });
';
        } else {
            content &= '
// Add #arguments.environment#-specific seed data here.
// Use seedOnce() for idempotent records.
';
        }

        content &= '
</cfscript>';
        return content;
    }

}
