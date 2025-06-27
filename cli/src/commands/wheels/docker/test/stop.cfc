/**
 * Stop Docker test containers
 *
 * {code:bash}
 * wheels docker:test:stop
 * wheels docker:test:stop --remove-volumes
 * {code}
 */
component extends="../../base" {
    
    property name="fileSystemUtil" inject="FileSystem";
    
    /**
     * @removeVolumes.hint Also remove associated volumes
     */
    function run(boolean removeVolumes = false) {
        var testDir = fileSystemUtil.resolvePath(".wheels-test");
        
        if (!directoryExists(testDir) || !fileExists("#testDir#/docker-compose.yml")) {
            print.yellowLine("No test containers found in current directory.");
            return;
        }
        
        print.yellowLine("Stopping Docker test containers...");
        
        var dockerCommand = "cd .wheels-test && docker-compose down";
        if (arguments.removeVolumes) {
            dockerCommand &= " -v";
        }
        
        command(dockerCommand).run();
        
        print.line();
        print.greenBoldLine("✓ Docker test containers stopped successfully!");
        
        if (arguments.removeVolumes) {
            print.greenLine("✓ Volumes removed");
        }
    }
}