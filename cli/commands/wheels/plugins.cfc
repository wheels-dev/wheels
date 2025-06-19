/**
 * Manage Wheels CLI plugins
 * 
 * {code:bash}
 * wheels plugins list
 * wheels plugins install <plugin>
 * wheels plugins remove <plugin>
 * wheels plugins search [query]
 * wheels plugins info <plugin>
 * wheels plugins update <plugin>
 * wheels plugins update:all
 * wheels plugins outdated
 * wheels plugins init <name>
 * {code}
 */
component extends="base" {
    
    /**
     * Display help for plugin commands
     */
    function run() {
        print.greenBoldLine("🔌 Wheels Plugin Management")
             .line()
             .line("Available commands:")
             .line()
             .yellowLine("  wheels plugin list")
             .line("    List installed plugins")
             .line("    Options: --global --format=json --available")
             .line()
             .yellowLine("  wheels plugin search [query]")
             .line("    Search for plugins on ForgeBox")
             .line("    Options: --format=json --orderBy=<name|downloads|updated>")
             .line()
             .yellowLine("  wheels plugin info <plugin>")
             .line("    Show detailed information about a plugin")
             .line()
             .yellowLine("  wheels plugin install <plugin>")
             .line("    Install a plugin from ForgeBox or GitHub")
             .line("    Options: --dev --global --version=<version>")
             .line()
             .yellowLine("  wheels plugin update <plugin>")
             .line("    Update a specific plugin to the latest version")
             .line("    Options: --version=<version> --force")
             .line()
             .yellowLine("  wheels plugin update:all")
             .line("    Update all installed plugins")
             .line("    Options: --dry-run --force")
             .line()
             .yellowLine("  wheels plugin outdated")
             .line("    List plugins with available updates")
             .line("    Options: --format=json")
             .line()
             .yellowLine("  wheels plugin remove <plugin>")
             .line("    Remove an installed plugin")
             .line("    Options: --global --force")
             .line()
             .yellowLine("  wheels plugin init <name>")
             .line("    Initialize a new plugin project")
             .line("    Options: --author --description --version --license")
             .line()
             .line("Examples:")
             .line("  wheels plugin search auth")
             .line("  wheels plugin info wheels-api-builder")
             .line("  wheels plugin install wheels-vue-cli")
             .line("  wheels plugin update wheels-auth --version=2.0.0")
             .line("  wheels plugin update:all --dry-run")
             .line("  wheels plugin outdated")
             .line("  wheels plugin init my-awesome-plugin --author=\"John Doe\"");
    }
}