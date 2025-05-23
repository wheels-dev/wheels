/**
 * Manage Wheels CLI plugins
 * 
 * {code:bash}
 * wheels plugins list
 * wheels plugins install <plugin>
 * wheels plugins remove <plugin>
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
             .yellowLine("  wheels plugins list")
             .line("    List installed plugins")
             .line("    Options: --global --format=json --available")
             .line()
             .yellowLine("  wheels plugins install <plugin>")
             .line("    Install a plugin from ForgeBox or GitHub")
             .line("    Options: --dev --global --version=<version>")
             .line()
             .yellowLine("  wheels plugins remove <plugin>")
             .line("    Remove an installed plugin")
             .line("    Options: --global --force")
             .line()
             .line("Examples:")
             .line("  wheels plugins list --available")
             .line("  wheels plugins install wheels-vue-cli")
             .line("  wheels plugins install https://github.com/user/wheels-plugin --dev")
             .line("  wheels plugins remove wheels-docker --global");
    }
}