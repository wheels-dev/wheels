/**
 * Manage development environments
 * 
 * {code:bash}
 * wheels env list
 * wheels env setup development
 * wheels env switch production
 * {code}
 */
component extends="base" {
    
    /**
     * Display help for environment commands
     */
    function run() {
        print.greenBoldLine("🌍 Wheels Environment Management")
             .line()
             .line("Available commands:")
             .line()
             .yellowLine("  wheels env list")
             .line("    List all configured environments")
             .line()
             .yellowLine("  wheels env setup <environment>")
             .line("    Setup a new environment (development, staging, production)")
             .line("    Options: --template=docker --database=postgres")
             .line()
             .yellowLine("  wheels env switch <environment>")
             .line("    Switch to a different environment")
             .line()
             .line("Examples:")
             .line("  wheels env setup development")
             .line("  wheels env setup production --template=docker --database=postgres")
             .line("  wheels env switch staging");
    }
}