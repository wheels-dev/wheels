/**
 * Show detailed information about a Wheels plugin
 * Examples:
 * wheels plugin info wheels-auth
 * wheels plugin info wheels-api-builder
 */
component aliases="wheels plugin info" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="forgebox" inject="ForgeBox@commandbox-core";
    property name="packageService" inject="PackageService@commandbox-core";
    
    /**
     * @name.hint Name of the plugin to show info for
     */
    function run(required string name) {
        try {
            print.greenBoldLine("📦 Plugin Information: #arguments.name#")
                 .line();
            
            // Try to get package info from ForgeBox
            var packageInfo = {};
            var isInstalled = false;
            var installedVersion = "";
            
            try {
                // Check if plugin is installed locally
                var boxJsonPath = resolvePath("box.json");
                if (fileExists(boxJsonPath)) {
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));
                    
                    // Check dependencies
                    if (boxJson.keyExists("dependencies") && boxJson.dependencies.keyExists(arguments.name)) {
                        isInstalled = true;
                        installedVersion = boxJson.dependencies[arguments.name];
                    }
                    
                    // Check devDependencies
                    if (boxJson.keyExists("devDependencies") && boxJson.devDependencies.keyExists(arguments.name)) {
                        isInstalled = true;
                        installedVersion = boxJson.devDependencies[arguments.name];
                    }
                }
                
                // Get package info from ForgeBox
                packageInfo = forgebox.getPackage(arguments.name);
                
            } catch (any e) {
                // Package not found on ForgeBox
                if (!isInstalled) {
                    error("Plugin '#arguments.name#' not found on ForgeBox or installed locally");
                    return;
                }
            }
            
            // Display installation status
            if (isInstalled) {
                print.greenLine("✅ Status: Installed locally")
                     .line("📌 Version: #installedVersion#")
                     .line();
            } else {
                print.yellowLine("❌ Status: Not installed")
                     .line();
            }
            
            // Display ForgeBox info if available
            if (!structIsEmpty(packageInfo)) {
                print.boldLine("ForgeBox Information:");
                
                if (packageInfo.keyExists("name")) {
                    print.line("📝 Name: #packageInfo.name#");
                }
                
                if (packageInfo.keyExists("slug")) {
                    print.line("🔗 Slug: #packageInfo.slug#");
                }
                
                if (packageInfo.keyExists("version")) {
                    print.line("🏷️  Latest Version: #packageInfo.version#");
                }
                
                if (packageInfo.keyExists("type")) {
                    print.line("📁 Type: #packageInfo.type#");
                }
                
                if (packageInfo.keyExists("summary")) {
                    print.line("📄 Description: #packageInfo.summary#");
                }
                
                if (packageInfo.keyExists("author")) {
                    print.line("👤 Author: #packageInfo.author.name ?: 'Unknown'#");
                }
                
                if (packageInfo.keyExists("downloads")) {
                    print.line("📊 Downloads: #numberFormat(packageInfo.downloads)#");
                }
                
                if (packageInfo.keyExists("createDate")) {
                    print.line("📅 Created: #dateFormat(packageInfo.createDate, 'yyyy-mm-dd')#");
                }
                
                if (packageInfo.keyExists("updateDate")) {
                    print.line("🔄 Updated: #dateFormat(packageInfo.updateDate, 'yyyy-mm-dd')#");
                }
                
                if (packageInfo.keyExists("homepage") && len(packageInfo.homepage)) {
                    print.line("🌐 Homepage: #packageInfo.homepage#");
                }
                
                if (packageInfo.keyExists("repository") && structKeyExists(packageInfo.repository, "URL")) {
                    print.line("💻 Repository: #packageInfo.repository.URL#");
                }
                
                if (packageInfo.keyExists("bugs") && len(packageInfo.bugs)) {
                    print.line("🐛 Issues: #packageInfo.bugs#");
                }
                
                if (packageInfo.keyExists("license") && len(packageInfo.license)) {
                    print.line("⚖️  License: #packageInfo.license#");
                }
                
                // Show dependencies if any
                if (packageInfo.keyExists("dependencies") && !structIsEmpty(packageInfo.dependencies)) {
                    print.line()
                         .boldLine("Dependencies:");
                    for (var dep in packageInfo.dependencies) {
                        print.line("  • #dep#: #packageInfo.dependencies[dep]#");
                    }
                }
                
                // Show versions if available
                if (packageInfo.keyExists("versions") && arrayLen(packageInfo.versions)) {
                    print.line()
                         .boldLine("Available Versions:");
                    var versionCount = min(5, arrayLen(packageInfo.versions));
                    for (var i = 1; i <= versionCount; i++) {
                        print.line("  • #packageInfo.versions[i].version# (#dateFormat(packageInfo.versions[i].updateDate, 'yyyy-mm-dd')#)");
                    }
                    if (arrayLen(packageInfo.versions) > 5) {
                        print.line("  ... and #arrayLen(packageInfo.versions) - 5# more");
                    }
                }
            }
            
            // Show installation instructions
            print.line()
                 .boldLine("Installation:");
            
            if (isInstalled) {
                print.line("To update this plugin:")
                     .yellowLine("  wheels plugin update #arguments.name#");
            } else {
                print.line("To install this plugin:")
                     .yellowLine("  wheels plugin install #arguments.name#");
            }
            
            // Show additional commands
            print.line()
                 .line("To see all available plugins:")
                 .yellowLine("  wheels plugin search");
            
        } catch (any e) {
            error("Error getting plugin info: #e.message#");
        }
    }
    
    /**
     * Resolve a file path
     */
    private function resolvePath(path) {
        if (left(arguments.path, 1) == "/" || mid(arguments.path, 2, 1) == ":") {
            return arguments.path;
        }
        return expandPath(".") & "/" & arguments.path;
    }
}