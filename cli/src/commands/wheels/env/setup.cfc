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
     * @environment.hint Environment name (development, staging, production)
     * @environment.options development,staging,production
     * @template.hint Environment template (local, docker, vagrant)
     * @template.options local,docker,vagrant
     * @database.hint Database type (h2, mysql, postgres, mssql)
     * @database.options h2,mysql,postgres,mssql
     * @force.hint Overwrite existing configuration
     */
    function run(
        required string environment,
        string template = "local",
        string dbtype = "h2",
        boolean force = false
    ) {
        var projectRoot = resolvePath(".");
        arguments = reconstructArgs(arguments);

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
}