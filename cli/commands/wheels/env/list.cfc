/**
 * List available environments
 * Examples:
 * wheels env list
 * wheels env list --format=json
 */
component extends="../base" {
    
    property name="environmentService" inject="EnvironmentService@wheels-cli";
    
    /**
     * @format.hint Output format: table (default) or json
     * @format.options table,json
     */
    function run(
        string format = "table"
    ) {
        var environments = environmentService.list();
        
        if (arrayLen(environments) == 0) {
            print.yellowLine("No environments configured");
            print.line("Create an environment with: wheels env setup <environment>");
            return;
        }
        
        if (arguments.format == "json") {
            print.line(serializeJSON(environments, true));
        } else {
            print.greenBoldLine("🌍 Available Environments")
                 .line();
            
            // Get current environment
            var currentEnv = "";
            if (fileExists(resolvePath(".env"))) {
                var envContent = fileRead(resolvePath(".env"));
                var matches = reMatchNoCase("WHEELS_ENV=([^\r\n]+)", envContent);
                if (arrayLen(matches)) {
                    currentEnv = listLast(matches[1], "=");
                }
            }
            
            // Display environments
            for (var env in environments) {
                var isCurrent = (env.name == currentEnv);
                var marker = isCurrent ? " ⭐" : "";
                
                print.line("📁 #env.name##marker#");
                print.line("   📋 Template: #env.template#");
                print.line("   🗄️  Database: #env.database#");
                print.line("   📅 Created: #dateTimeFormat(env.created, 'yyyy-mm-dd HH:nn:ss')#");
                print.line();
            }
            
            if (len(currentEnv)) {
                print.yellowLine("⭐ Current environment: #currentEnv#");
            } else {
                print.yellowLine("No environment currently active");
                print.line("Switch to an environment with: wheels env switch <environment>");
            }
        }
    }
}