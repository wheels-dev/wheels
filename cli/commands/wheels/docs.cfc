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
     * @subCommand.hint Subcommand to execute (generate, serve)
     * @subCommand.options generate,serve
     */
    function run(string subCommand = "") {
        if (!len(arguments.subCommand)) {
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
        
        // Forward all remaining arguments to the subcommand
        var args = duplicate(arguments);
        structDelete(args, "subCommand");
        
        // Show help for the subcommands since we can't delegate directly
        switch(arguments.subCommand) {
            case "generate":
                print.line();
                print.boldGreenLine("📝 Generate Documentation");
                print.line();
                print.line("Usage: wheels docs:generate [options]");
                print.line();
                print.line("Options:");
                print.line("  --format    Output format (markdown, html) [default: html]");
                print.line("  --output    Output directory [default: docs/]");
                print.line("  --verbose   Show detailed output");
                print.line();
                print.line("Example:");
                print.line("  wheels docs:generate --format=markdown --output=docs/api/");
                break;
            case "serve":
                print.line();
                print.boldGreenLine("🌐 Serve Documentation");  
                print.line();
                print.line("Usage: wheels docs:serve [options]");
                print.line();
                print.line("Options:");
                print.line("  --port      Port to serve on [default: 8080]");
                print.line("  --host      Host to bind to [default: localhost]");
                print.line("  --open      Open browser automatically");
                print.line();
                print.line("Example:");
                print.line("  wheels docs:serve --port=3000 --open");
                break;
            default:
                error("Unknown subcommand: #arguments.subCommand#");
        }
    }
}