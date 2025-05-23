/**
 * Generate and serve documentation for your Wheels application
 * 
 * {code:bash}
 * wheels docs generate
 * wheels docs serve
 * wheels docs generate --format=markdown --output=docs/
 * {code}
 */
component extends="base" {
    
    /**
     * @subcommand.hint Subcommand to execute (generate, serve)
     * @subcommand.options generate,serve
     */
    function run(string subcommand = "") {
        if (!len(arguments.subcommand)) {
            print.line();
            print.boldMagentaLine("📚 Wheels Documentation Generator");
            print.line();
            print.yellowLine("Available commands:");
            print.line("  wheels docs generate - Generate documentation from your code");
            print.line("  wheels docs serve    - Serve documentation locally");
            print.line();
            print.line("Run 'wheels docs [command] help' for more information");
            return;
        }
        
        // Delegate to subcommand
        switch(arguments.subcommand) {
            case "generate":
                command("wheels docs generate").run();
                break;
            case "serve":
                command("wheels docs serve").run();
                break;
            default:
                error("Unknown subcommand: #arguments.subcommand#");
        }
    }
}