/**
 * View logs from Docker test containers
 *
 * {code:bash}
 * wheels docker:test:logs
 * wheels docker:test:logs --follow
 * wheels docker:test:logs --tail=100
 * wheels docker:test:logs --service=app
 * {code}
 */
component extends="../../base" {
    
    property name="fileSystemUtil" inject="FileSystem";
    
    /**
     * @follow.hint Follow log output (like tail -f)
     * @tail.hint Number of lines to show from the end of the logs
     * @service.hint Show logs for a specific service only (app, mysql, postgres, sqlserver)
     * @timestamps.hint Show timestamps
     */
    function run(
        boolean follow = false,
        numeric tail = 0,
        string service = "",
        boolean timestamps = false
    ) {
        var testDir = fileSystemUtil.resolvePath(".wheels-test");
        
        if (!directoryExists(testDir) || !fileExists("#testDir#/docker-compose.yml")) {
            print.yellowLine("No test containers found in current directory.");
            print.line("Run 'wheels docker:test' first to start containers.");
            return;
        }
        
        print.yellowLine("Fetching Docker test container logs...");
        print.line();
        
        var dockerCommand = "cd .wheels-test && docker compose logs";
        
        if (arguments.follow) {
            dockerCommand &= " -f";
        }
        
        if (arguments.tail > 0) {
            dockerCommand &= " --tail=#arguments.tail#";
        }
        
        if (arguments.timestamps) {
            dockerCommand &= " -t";
        }
        
        if (len(arguments.service)) {
            dockerCommand &= " #arguments.service#";
        }
        
        if (arguments.follow) {
            print.cyanLine("Following logs... Press Ctrl+C to stop");
            print.line();
        }
        
        command("!#dockerCommand#").run();
    }
}