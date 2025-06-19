/**
 * Manage development environments
 * 
 * {code:bash}
 * wheels env list
 * wheels env show
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
             .yellowLine("  wheels env show")
             .line("    Show environment variables from .env file")
             .line()
             .yellowLine("  wheels env setup <environment>")
             .line("    Setup a new environment (development, staging, production)")
             .line("    Options: --template=docker --database=postgres")
             .line()
             .yellowLine("  wheels env switch <environment>")
             .line("    Switch to a different environment")
             .line()
             .line("Examples:")
             .cyanLine("  wheels env list")
             .cyanLine("  wheels env show")
             .cyanLine("  wheels env show --key=DB_HOST")
             .cyanLine("  wheels env show --format=json")
             .cyanLine("  wheels env setup development")
             .cyanLine("  wheels env setup production --template=docker --database=postgres")
             .cyanLine("  wheels env switch staging");
    }
}