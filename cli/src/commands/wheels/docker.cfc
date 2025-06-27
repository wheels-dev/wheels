/**
 * Manage Docker environments for Wheels applications
 *
 * {code:bash}
 * wheels docker help
 * {code}
 */
component extends="base" {
    
    /**
     * Show help for docker commands
     */
    function run() {
        print.line();
        print.boldMagentaLine("Wheels Docker Commands");
        print.line();
        print.yellowLine("Available commands:");
        print.line();
        print.line("  wheels docker init         - Initialize Docker configuration for development");
        print.line("  wheels docker deploy       - Deploy to Docker");
        print.line("  wheels docker test         - Test templates and examples in Docker containers");
        print.line("  wheels docker test stop    - Stop test containers");
        print.line("  wheels docker test clean   - Remove test containers and volumes");
        print.line("  wheels docker test logs    - View test container logs");
        print.line();
        print.line("Use 'wheels docker [command] help' for more information about a command.");
        print.line();
    }
}