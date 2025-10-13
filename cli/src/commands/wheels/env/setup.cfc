/**
 * Setup development environment
 * Examples:
 * wheels env setup development
 * wheels env setup production --template=docker --database=postgres
 * wheels env setup staging --template=vagrant --database=mysql
 */
component extends="../base" {
    
    property name="environmentService" inject="EnvironmentService@wheels-cli";
    
    /**
     * @environment.hint Environment name (e.g. development, staging, production)
     * @environment.options development,staging,production
     * @template.hint Environment template (local, docker, vagrant)
     * @template.options local,docker,vagrant
     * @dbtype.hint Database type (h2, mysql, postgres, mssql)
     * @dbtype.options h2,mysql,postgres,mssql
     * @force.hint Overwrite existing configuration
     */
    function run(
        string environment,
        string template = "local",
        string dbtype = "H2",
        string database = "",
        string datasource = "",
        boolean force = false,
        string base = "",
        boolean debug = false,
        boolean cache = false,
        string reloadPassword = "",
        boolean help = false
    ) {
        var projectRoot = resolvePath(".");
        arguments = reconstructArgs(arguments);

        // Show help if requested
        if ( arguments.help == true) {
            return showSetupHelp();
        } else {
            while ( trim(arguments.environment) == "" ) {
                arguments.environment = ask(
                    "Enter environment (development, staging, production): "
                );
            }
        }

        print.yellowLine("Setting up #arguments.environment# environment...")
             .line();
        
        var result = environmentService.setup(argumentCollection = arguments, rootPath=projectRoot );

        if (result.success) {
            print.greenLine("Environment setup complete!")
                 .line();
            
            if (result.keyExists("nextSteps") && arrayLen(result.nextSteps)) {
                print.yellowBoldLine("Next Steps:")
                     .line();
                
                for (var step in result.nextSteps) {
                    print.line(step);
                }
            }
        } else {
            print.redLine("Setup failed: #result.error#");
            setExitCode(1);
        }
    }

    // Generate instructions 
    private function showSetupHelp() {
        // ANSI color codes as strings
        var reset = chr(27) & "[0m";
        var bold = chr(27) & "[1m";
        var dim = chr(27) & "[2m";
        
        // Text colors
        var red = chr(27) & "[31m";
        var green = chr(27) & "[32m";
        var yellow = chr(27) & "[33m";
        var blue = chr(27) & "[34m";
        var magenta = chr(27) & "[35m";
        var cyan = chr(27) & "[36m";
        var white = chr(27) & "[37m";
        
        // Bright colors
        var brightRed = chr(27) & "[91m";
        var brightGreen = chr(27) & "[92m";
        var brightYellow = chr(27) & "[93m";
        var brightBlue = chr(27) & "[94m";
        var brightMagenta = chr(27) & "[95m";
        var brightCyan = chr(27) & "[96m";
        var brightWhite = chr(27) & "[97m";
        
        var helpText = bold & brightCyan & "
        ================================================================
                    WHEELS ENVIRONMENT SETUP COMMAND
        ================================================================
        " & reset & "

        Setup comprehensive environment configurations for Wheels applications with
        database settings, templates, and framework configurations.

        " & bold & yellow & "USAGE:" & reset & "
            " & green & "wheels env setup" & reset & " " & brightBlue & "environment=<name>" & reset & " " & dim & "[options]" & reset & "

        " & bold & yellow & "ARGUMENTS:" & reset & "
            " & brightBlue & "environment" & reset & "     Name of the environment to create " & red & "(required)" & reset & "
                              Examples: development, staging, production, testing
                              " & red & "Note: Use named syntax environment=name to avoid parameter conflicts" & reset & "

        " & bold & yellow & "OPTIONS:" & reset & "
            " & cyan & "--template" & reset & "      Template type: " & magenta & "local" & reset & ", " & magenta & "docker" & reset & ", " & magenta & "vagrant" & reset & " " & dim & "(default: local)" & reset & "
            " & cyan & "--dbtype" & reset & "        Database type: " & magenta & "h2" & reset & ", " & magenta & "mysql" & reset & ", " & magenta & "postgres" & reset & ", " & magenta & "mssql" & reset & " " & dim & "(default: h2)" & reset & "
            " & cyan & "--database" & reset & "      Custom database name " & dim & "(default: wheels_[environment])" & reset & "
            " & cyan & "--datasource" & reset & "    ColdFusion datasource name " & dim & "(default: wheels_[environment])" & reset & "
            " & cyan & "--base" & reset & "          Base environment to copy settings from " & dim & "(copies config)" & reset & "
            " & cyan & "--force" & reset & "         Overwrite existing environment " & dim & "(default: false)" & reset & "
            " & cyan & "--debug" & reset & "         Enable debug settings " & dim & "(default: false)" & reset & "
            " & cyan & "--cache" & reset & "         Enable cache settings " & dim & "(default: false)" & reset & "
            " & cyan & "--reloadPassword" & reset & "  Custom reload password " & dim & "(default: wheels[environment])" & reset & "
            " & cyan & "--help" & reset & "          Show this detailed help message

        " & bold & yellow & "BASIC EXAMPLES:" & reset & "
            " & green & "wheels env setup environment=development" & reset & "        ## H2 database (default)
            " & green & "wheels env setup environment=staging" & reset & " " & cyan & "--dbtype=mysql" & reset & "  ## MySQL database
            " & green & "wheels env setup environment=production" & reset & " " & cyan & "--dbtype=postgres" & reset & " " & cyan & "--cache=true" & reset & " " & cyan & "--debug=false" & reset & "

        " & bold & yellow & "BASE ENVIRONMENT EXAMPLES:" & reset & "
            " & green & "wheels env setup environment=testing" & reset & " " & cyan & "--base=development" & reset & " " & cyan & "--dbtype=postgres" & reset & "
            " & green & "wheels env setup environment=qa" & reset & " " & cyan & "--base=production" & reset & " " & cyan & "--database=qa_db" & reset & "
            " & green & "wheels env setup environment=feature-test" & reset & " " & cyan & "--base=development" & reset & " " & cyan & "--dbtype=h2" & reset & "

        " & bold & yellow & "ADVANCED EXAMPLES:" & reset & "
            " & green & "wheels env setup environment=integration" & reset & " " & cyan & "--dbtype=mysql" & reset & " " & cyan & "--database=int_db" & reset & " " & cyan & "--datasource=int_ds" & reset & "
            " & green & "wheels env setup environment=docker-dev" & reset & " " & cyan & "--template=docker" & reset & " " & cyan & "--dbtype=postgres" & reset & "
            " & green & "wheels env setup environment=vm-test" & reset & " " & cyan & "--template=vagrant" & reset & " " & cyan & "--dbtype=mysql" & reset & "

        " & bold & yellow & "TEMPLATES:" & reset & "
            " & magenta & "local" & reset & "     - Traditional server deployment " & dim & "(default)" & reset & "
            " & magenta & "docker" & reset & "    - Containerized setup with docker-compose files
            " & magenta & "vagrant" & reset & "   - VM setup with Vagrantfile and provisioning

        " & bold & yellow & "DATABASE TYPES:" & reset & "
            " & magenta & "h2" & reset & "        - Embedded database, no network port " & dim & "(default, great for dev/test)" & reset & "
            " & magenta & "mysql" & reset & "     - MySQL database server " & dim & "(port 3306)" & reset & "
            " & magenta & "postgres" & reset & "  - PostgreSQL database server " & dim & "(port 5432)" & reset & "
            " & magenta & "mssql" & reset & "     - Microsoft SQL Server " & dim & "(port 1433)" & reset & "

        " & bold & yellow & "BASE ENVIRONMENT COPYING:" & reset & "
            When using " & cyan & "--base" & reset & ", the command copies existing configuration:
            " & brightWhite & reset & " Database credentials and host settings
            " & brightWhite & reset & " Server configuration and custom variables
            " & brightWhite & reset & " Overrides database type/driver/port with " & cyan & "--dbtype" & reset & "
            " & brightWhite & reset & " Creates new environment-specific database name

        " & bold & brightGreen & "FILES CREATED:" & reset & "
            " & brightWhite  & reset & " .env.[environment] - Environment variables and database settings
            " & brightWhite  & reset & " config/[environment]/settings.cfm - Wheels framework configuration
            " & brightWhite  & reset & " docker-compose.[environment].yml - If using Docker template
            " & brightWhite  & reset & " Vagrantfile.[environment] - If using Vagrant template
            " & brightWhite  & reset & " Updated server.json - Environment-specific server settings

        " & bold & brightGreen & "NEXT STEPS AFTER SETUP:" & reset & "
            1. Switch environment: " & green & "wheels env switch environment=[name]" & reset & "
            2. Start server: " & green & "box server start" & reset & "
            3. Access app: " & green & "http://localhost:8080" & reset & "
        ";
        
        return helpText;
    }
}