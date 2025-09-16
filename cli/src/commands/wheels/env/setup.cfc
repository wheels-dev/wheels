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
        required string environment,
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

        " & bold & yellow & "USAGE:" & reset & "
            " & green & "wheels env setup" & reset & " " & brightBlue & "<environment>" & reset & " " & dim & "[options]" & reset & "

        " & bold & yellow & "ARGUMENTS:" & reset & "
            " & brightBlue & "environment" & reset & "     Name of the environment to create " & red & "(required)" & reset & "

        " & bold & yellow & "OPTIONS:" & reset & "
            " & cyan & "--template" & reset & "      Template type: " & magenta & "local" & reset & ", " & magenta & "docker" & reset & ", " & magenta & "vagrant" & reset & " " & dim & "(default: local)" & reset & "
            " & cyan & "--dbtype" & reset & "        Database type: " & magenta & "mysql" & reset & ", " & magenta & "postgres" & reset & ", " & magenta & "mssql" & reset & ", " & magenta & "h2" & reset & " " & dim & "(default: h2)" & reset &  "
            " & cyan & "--database" & reset & "      Database name " & dim & "(optional)" & reset & "
            " & cyan & "--datasource" & reset & "    Datasource name " & dim & "(optional)" & reset & "
            " & cyan & "--base" & reset & "          Base environment to copy from " & dim & "(optional)" & reset & "
            " & cyan & "--force" & reset & "         Overwrite existing environment " & dim & "(default: false)" & reset & "
            " & cyan & "--debug" & reset & "         Enable debug settings " & dim & "(default: false)" & reset & "
            " & cyan & "--cache" & reset & "         Enable cache settings " & dim & "(default: false)" & reset & "
            " & cyan & "--reloadPassword" & reset & "  Custom reload password " & dim & "(optional)" & reset & "
            " & cyan & "--help" & reset & "          Show this help message

        " & bold & yellow & "EXAMPLES:" & reset & "
            " & green & "wheels env setup dev" & reset & " " & cyan & "--dbtype=mysql" & reset & " " & cyan & "--debug=true" & reset & "
            " & green & "wheels env setup prod" & reset & " " & cyan & "--dbtype=postgres" & reset & " " & cyan & "--cache=true" & reset & " " & cyan & "--debug=false" & reset & "
            " & green & "wheels env setup test" & reset & " " & cyan & "--base=dev" & reset & " " & cyan & "--dbtype=h2" & reset & " " & cyan & "--reloadPassword=mypassword" & reset & "
            " & green & "wheels env setup staging" & reset & " " & cyan & "--template=docker" & reset & " " & cyan & "--dbtype=mysql" & reset & " " & cyan & "--force" & reset & "

        " & bold & yellow & "TEMPLATES:" & reset & "
            " & magenta & "local" & reset & "     - Local development setup
            " & magenta & "docker" & reset & "    - Docker containerized setup
            " & magenta & "vagrant" & reset & "   - Vagrant VM setup

        " & bold & yellow & "DATABASE TYPES:" & reset & "
            " & magenta & "mysql" & reset & "     - MySQL database
            " & magenta & "postgres" & reset & "  - PostgreSQL database
            " & magenta & "mssql" & reset & "     - Microsoft SQL Server
            " & magenta & "h2" & reset & "        - H2 embedded database " & dim & "(default)" & reset & "

        " & bold & brightGreen & "The command will create:" & reset & "
            " & brightWhite & "*" & reset & " .env.[environment] file with environment variables
            " & brightWhite & "*" & reset & " config/[environment]/settings.cfm with Wheels configuration
            " & brightWhite & "*" & reset & " Docker/Vagrant files if using those templates
            " & brightWhite & "*" & reset & " Updated server.json configuration
        ";
        
        return helpText;
    }
}