/**
 * Show detailed information about a Wheels plugin
 * Examples:
 * wheels plugin info wheels-auth
 * wheels plugin info wheels-api-builder
 */
component aliases="wheels plugin info" extends="../base" {
    
    property name="pluginService" inject="PluginService@wheels-cli";
    property name="packageService" inject="PackageService";
    
    /**
     * @name.hint Name of the plugin to show info for
     */
    function run(required string name) {
        
        // Reconstruct arguments for consistency
        arguments = reconstructArgs(arguments);
        try {
            print.line()
                 .boldMagentaLine("===========================================================")
                 .boldMagentaText("  Plugin Information: ")
                 .boldWhiteLine(arguments.name)
                 .boldMagentaLine("===========================================================")
                 .line();

            // Check local installation status in /plugins folder only
            var isInstalled = false;
            var installedVersion = "";
            var pluginPath = "";

            // Find plugin by folder name, slug, or actual name
            var pluginsDir = fileSystemUtil.resolvePath("plugins");
            if (directoryExists(pluginsDir)) {
                var foundPlugin = findPluginInFolder(pluginsDir, arguments.name);

                if (foundPlugin.found) {
                    isInstalled = true;
                    pluginPath = foundPlugin.path;
                    installedVersion = foundPlugin.version;
                }
            }
            
            // Display installation status and local plugin information
            var hasForgeboxData = false;
            var forgeboxInfo = {};

            if (isInstalled) {
                print.boldLine("Status:")
                     .text("  ")
                     .boldGreenLine("Installed locally")
                     .line();

                // Try to get information from local plugin's box.json
                var localPluginInfo = getLocalPluginInfo(pluginPath);

                if (!structIsEmpty(localPluginInfo)) {
                    // Display local plugin information
                    displayLocalPluginInfo(localPluginInfo, installedVersion);
                } else {
                    // Fallback if we can't read local plugin info
                    print.boldLine("Details:")
                         .text("  Version:     ")
                         .cyanLine(installedVersion)
                         .line();
                }
            } else {
                print.boldLine("Status:")
                     .text("  ")
                     .yellowBoldText("[X] ")
                     .yellowLine("Not installed")
                     .line();

                // Try to get detailed ForgeBox information only if not installed
                try {
                    // Get ForgeBox package details using API-style approach
                    var forgeboxResult = command('forgebox show').params(arguments.name).run(returnOutput=true);
                    if (len(trim(forgeboxResult)) > 0 && !findNoCase("not found", forgeboxResult)) {
                        hasForgeboxData = true;
                        // Parse basic info from forgebox output for display
                        forgeboxInfo = parseForgeBoxOutput(forgeboxResult, arguments.name);
                    }
                } catch (any e) {
                    hasForgeboxData = false;
                }

                // Display ForgeBox information section
                if (hasForgeboxData) {
                    print.line(forgeboxResult);
                } else {
                    // Plugin not found anywhere - show helpful message instead of error
                    print.redLine("Plugin Not Installed")
                         .line()
                         .line("The plugin '#arguments.name#' was not found in:")
                         .line(" Local installation (box.json dependencies)")
                         .line(" ForgeBox repository")
                         .line()
                         .line("Possible reasons:")
                         .line(" Plugin name may be misspelled")
                         .line(" Plugin may not exist on ForgeBox")
                         .line(" Network connection issues")
                         .line()
                         .line("Suggestions:")
                         .cyanLine(" Search for available plugins: wheels plugin list --available")
                         .cyanLine(" Verify the correct plugin name")
                         .line();
                    return;
                }
            }

            // Show installation/update commands only if plugin exists somewhere
            if (isInstalled || hasForgeboxData) {
                print.boldLine("Commands:");

                if (isInstalled) {
                    // Check if update available - handle version prefixes like "^0.0.4"
                    if (hasForgeboxData && structKeyExists(forgeboxInfo, "latestVersion") && len(forgeboxInfo.latestVersion)) {
                        var cleanInstalledVersion = trim(replace(installedVersion, "^", ""));
                        cleanInstalledVersion = trim(replace(cleanInstalledVersion, "~", ""));
                        var latestVersion = trim(forgeboxInfo.latestVersion);

                        if (cleanInstalledVersion != latestVersion) {
                            print.text("  ")
                                 .yellowBoldText("[!] ")
                                 .yellowLine("Update Available: #cleanInstalledVersion# -> #latestVersion#")
                                 .line();
                        }
                    }
                    print.text("  Update:  ")
                         .cyanLine("wheels plugin update #arguments.name#");
                } else {
                    print.text("  Install: ")
                         .cyanLine("wheels plugin install #arguments.name#");
                }

                print.text("  Search:  ")
                     .cyanLine("wheels plugin search")
                     .line();
            }
            
        } catch (any e) {
            error("Error getting plugin info: #e.message#");
        }
    }
    
    /**
     * Get plugin information from local box.json
     */
    private function getLocalPluginInfo(pluginPath) {
        var info = {};

        if (!len(pluginPath) || !directoryExists(pluginPath)) {
            return info;
        }

        var boxJsonPath = pluginPath & "/box.json";
        if (!fileExists(boxJsonPath)) {
            return info;
        }

        try {
            info = deserializeJSON(fileRead(boxJsonPath));
        } catch (any e) {
            // Unable to parse box.json
            return {};
        }

        return info;
    }

    /**
     * Display local plugin information from box.json
     */
    private function displayLocalPluginInfo(required struct pluginInfo, required string installedVersion) {
        print.line();

        // Display name prominently
        if (structKeyExists(pluginInfo, "name") && isSimpleValue(pluginInfo.name) && len(pluginInfo.name)) {
            print.boldCyanLine(pluginInfo.name);
        }

        // Display short description
        if (structKeyExists(pluginInfo, "shortDescription") && isSimpleValue(pluginInfo.shortDescription) && len(pluginInfo.shortDescription)) {
            print.line(pluginInfo.shortDescription).line();
        } else {
            print.line();
        }

        // Details section
        print.boldLine("Details:");

        // Display version
        if (structKeyExists(pluginInfo, "version") && isSimpleValue(pluginInfo.version) && len(pluginInfo.version)) {
            print.text("  Version:     ").cyanLine(pluginInfo.version);
        } else {
            print.text("  Version:     ").cyanLine(installedVersion);
        }

        // Display slug
        if (structKeyExists(pluginInfo, "slug") && isSimpleValue(pluginInfo.slug) && len(pluginInfo.slug)) {
            print.text("  Slug:        ").line(pluginInfo.slug);
        }

        // Display type
        if (structKeyExists(pluginInfo, "type") && isSimpleValue(pluginInfo.type) && len(pluginInfo.type)) {
            print.text("  Type:        ").line(pluginInfo.type);
        }

        // Display author
        if (structKeyExists(pluginInfo, "author") && isSimpleValue(pluginInfo.author) && len(pluginInfo.author)) {
            print.text("  Author:      ").line(pluginInfo.author);
        }

        // Display keywords - handle both string and array formats
        if (structKeyExists(pluginInfo, "keywords")) {
            if (isSimpleValue(pluginInfo.keywords) && len(pluginInfo.keywords)) {
                print.text("  Keywords:    ").line(pluginInfo.keywords);
            } else if (isArray(pluginInfo.keywords) && arrayLen(pluginInfo.keywords) > 0) {
                print.text("  Keywords:    ").line(arrayToList(pluginInfo.keywords, ', '));
            }
        }

        // Links section (only show if at least one link exists)
        var hasLinks = false;
        if (structKeyExists(pluginInfo, "homepage") && isSimpleValue(pluginInfo.homepage) && len(pluginInfo.homepage)) {
            hasLinks = true;
        } else if (structKeyExists(pluginInfo, "repository")) {
            if (isSimpleValue(pluginInfo.repository) && len(pluginInfo.repository)) {
                hasLinks = true;
            } else if (isStruct(pluginInfo.repository) && structKeyExists(pluginInfo.repository, "URL") &&
                       isSimpleValue(pluginInfo.repository.URL) && len(pluginInfo.repository.URL)) {
                hasLinks = true;
            }
        } else if (structKeyExists(pluginInfo, "bugs") && isSimpleValue(pluginInfo.bugs) && len(pluginInfo.bugs)) {
            hasLinks = true;
        } else if (structKeyExists(pluginInfo, "documentation") && isSimpleValue(pluginInfo.documentation) && len(pluginInfo.documentation)) {
            hasLinks = true;
        }

        if (hasLinks) {
            print.line().boldLine("Links:");

            // Display homepage
            if (structKeyExists(pluginInfo, "homepage") && isSimpleValue(pluginInfo.homepage) && len(pluginInfo.homepage)) {
                print.text("  Homepage:    ").blueLine(pluginInfo.homepage);
            }

            // Display repository - handle both string and struct formats
            if (structKeyExists(pluginInfo, "repository")) {
                if (isSimpleValue(pluginInfo.repository) && len(pluginInfo.repository)) {
                    print.text("  Repository:  ").blueLine(pluginInfo.repository);
                } else if (isStruct(pluginInfo.repository) && structKeyExists(pluginInfo.repository, "URL") &&
                           isSimpleValue(pluginInfo.repository.URL) && len(pluginInfo.repository.URL)) {
                    print.text("  Repository:  ").blueLine(pluginInfo.repository.URL);
                }
            }

            // Display documentation URL
            if (structKeyExists(pluginInfo, "documentation") && isSimpleValue(pluginInfo.documentation) && len(pluginInfo.documentation)) {
                print.text("  Docs:        ").blueLine(pluginInfo.documentation);
            }

            // Display bugs URL
            if (structKeyExists(pluginInfo, "bugs") && isSimpleValue(pluginInfo.bugs) && len(pluginInfo.bugs)) {
                print.text("  Issues:      ").blueLine(pluginInfo.bugs);
            }
        }

        print.line();
    }

    /**
     * Parse ForgeBox output to extract metadata
     */
    private function parseForgeBoxOutput(output, pluginName) {
        var info = {};
        var lines = listToArray(output, chr(10));
        
        try {
            for (var line in lines) {
                line = trim(line);
                
                // Extract key information from forgebox show output
                if (findNoCase("Type:", line)) {
                    info.type = trim(replace(line, "Type:", "", "one"));
                } else if (findNoCase("Slug:", line)) {
                    info.slug = trim(replace(line, "Slug:", "", "one"));
                } else if (findNoCase("Summary:", line)) {
                    info.summary = trim(replace(line, "Summary:", "", "one"));
                } else if (findNoCase("Versions:", line)) {
                    var versions = trim(replace(line, "Versions:", "", "one"));
                    if (len(versions)) {
                        // Parse versions list - format like "0.0.4, 0.0.3, 0.0.2"
                        var versionArray = [];
                        var versionList = listToArray(versions);
                        for (var v in versionList) {
                            arrayAppend(versionArray, trim(v));
                        }
                        info.versions = versionArray;
                        // Get first version as latest
                        if (arrayLen(versionArray) > 0) {
                            info.latestVersion = versionArray[1];
                        }
                    }
                } else if (findNoCase("Created On:", line)) {
                    info.created = trim(replace(line, "Created On:", "", "one"));
                } else if (findNoCase("Updated On:", line)) {
                    info.updated = trim(replace(line, "Updated On:", "", "one"));
                } else if (findNoCase("Downloads:", line)) {
                    info.downloads = trim(replace(line, "Downloads:", "", "one"));
                } else if (findNoCase("Installs:", line)) {
                    info.installs = trim(replace(line, "Installs:", "", "one"));
                } else if (findNoCase("Home URL:", line)) {
                    info.homepage = trim(replace(line, "Home URL:", "", "one"));
                } else if (findNoCase("Source URL:", line)) {
                    info.repository = trim(replace(line, "Source URL:", "", "one"));
                } else if (findNoCase("Bugs URL:", line)) {
                    info.bugs = trim(replace(line, "Bugs URL:", "", "one"));
                } else if (findNoCase("Documentation URL:", line)) {
                    info.documentation = trim(replace(line, "Documentation URL:", "", "one"));
                } else if (find("(", line) && find(")", line) && !findNoCase("Rating:", line)) {
                    // Try to extract author from format like "Shortcodes    ( Tom King, neokoenig )"
                    var startPos = find("(", line);
                    var endPos = find(")", line);
                    if (startPos > 0 && endPos > startPos) {
                        var authorText = mid(line, startPos + 1, endPos - startPos - 1);
                        info.author = trim(authorText);
                    }
                }
                
                // Extract plugin name from header - look for the actual plugin name
                if (!structKeyExists(info, "name") && len(line) > 0 && 
                    !findNoCase("contacting", line) && 
                    !findNoCase("=", line) && 
                    !findNoCase("visit in forgebox", line) &&
                    !findNoCase("type:", line) &&
                    !findNoCase("slug:", line) &&
                    (findNoCase(pluginName, line) || find(" ", line))) {
                    
                    // Try to get the clean name before author info
                    var nameOnly = line;
                    if (find("(", line)) {
                        nameOnly = trim(left(line, find("(", line) - 1));
                    }
                    if (find("Rating:", line)) {
                        nameOnly = trim(left(line, find("Rating:", line) - 1));
                    }
                    
                    if (len(nameOnly) > 0 && nameOnly != pluginName && !findNoCase("shortcodes", nameOnly)) {
                        info.name = nameOnly;
                    }
                }
            }
            
            // Set defaults if not found
            if (!structKeyExists(info, "name")) {
                info.name = pluginName;
            }
            
        } catch (any e) {
            // If parsing fails, return minimal info
            info.name = pluginName;
        }
        
        return info;
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

    /**
     * Find plugin in /plugins folder by folder name, slug, or actual name
     * Algorithm searches all plugin folders and matches against:
     * 1. Folder name (exact match, case insensitive)
     * 2. Plugin slug from box.json (exact match, case insensitive)
     * 3. Plugin name from box.json (exact match, case insensitive)
     * 4. Normalized variations (removes cfwheels-, wheels- prefixes)
     */
    private function findPluginInFolder(required string pluginsDir, required string searchTerm) {
        var result = {
            found: false,
            path: "",
            version: "unknown"
        };

        // Normalize search term for comparison
        var normalizedSearch = normalizePluginName(arguments.searchTerm);

        // Get all directories in plugins folder
        var pluginDirs = directoryList(arguments.pluginsDir, false, "query", "*", "name", "directory");

        for (var pluginDir in pluginDirs) {
            var folderName = pluginDir.name;
            var pluginPath = arguments.pluginsDir & "/" & folderName;

            // Check 1: Direct folder name match (case insensitive)
            if (compareNoCase(folderName, arguments.searchTerm) == 0) {
                result.found = true;
                result.path = pluginPath;
                result.version = getVersionFromPluginFolder(pluginPath);
                return result;
            }

            // Check 2 & 3: Check against slug and name in box.json
            var boxJsonPath = pluginPath & "/box.json";
            if (fileExists(boxJsonPath)) {
                try {
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));

                    // Check slug (case insensitive)
                    if (structKeyExists(boxJson, "slug") && compareNoCase(boxJson.slug, arguments.searchTerm) == 0) {
                        result.found = true;
                        result.path = pluginPath;
                        result.version = structKeyExists(boxJson, "version") ? boxJson.version : "unknown";
                        return result;
                    }

                    // Check actual name (case insensitive)
                    if (structKeyExists(boxJson, "name") && compareNoCase(boxJson.name, arguments.searchTerm) == 0) {
                        result.found = true;
                        result.path = pluginPath;
                        result.version = structKeyExists(boxJson, "version") ? boxJson.version : "unknown";
                        return result;
                    }

                    // Check 4: Normalized comparison (removes prefixes like cfwheels-, wheels-)
                    var normalizedSlug = normalizePluginName(structKeyExists(boxJson, "slug") ? boxJson.slug : "");
                    var normalizedName = normalizePluginName(structKeyExists(boxJson, "name") ? boxJson.name : "");
                    var normalizedFolder = normalizePluginName(folderName);

                    if ((len(normalizedSlug) && compareNoCase(normalizedSlug, normalizedSearch) == 0) ||
                        (len(normalizedName) && compareNoCase(normalizedName, normalizedSearch) == 0) ||
                        (len(normalizedFolder) && compareNoCase(normalizedFolder, normalizedSearch) == 0)) {
                        result.found = true;
                        result.path = pluginPath;
                        result.version = structKeyExists(boxJson, "version") ? boxJson.version : "unknown";
                        return result;
                    }

                } catch (any e) {
                    // Continue checking other folders
                }
            } else {
                // No box.json, check normalized folder name
                var normalizedFolder = normalizePluginName(folderName);
                if (compareNoCase(normalizedFolder, normalizedSearch) == 0) {
                    result.found = true;
                    result.path = pluginPath;
                    result.version = "unknown";
                    return result;
                }
            }
        }

        return result;
    }

    /**
     * Normalize plugin name by removing common prefixes
     * Examples:
     * - "cfwheels-bcrypt" -> "bcrypt"
     * - "CFWheels Bcrypt" -> "bcrypt"
     * - "wheels-bcrypt" -> "bcrypt"
     * - "bcrypt" -> "bcrypt"
     */
    private function normalizePluginName(required string pluginName) {
        var normalized = trim(arguments.pluginName);

        // Remove common prefixes (case insensitive)
        normalized = reReplaceNoCase(normalized, "^cfwheels[\s-]+", "");
        normalized = reReplaceNoCase(normalized, "^wheels[\s-]+", "");

        // Remove trailing -plugin suffix
        normalized = reReplaceNoCase(normalized, "[\s-]+plugin$", "");

        // Convert to lowercase and remove extra spaces
        normalized = lCase(trim(normalized));

        return normalized;
    }

    /**
     * Get version from plugin folder's box.json
     */
    private function getVersionFromPluginFolder(required string pluginPath) {
        var boxJsonPath = arguments.pluginPath & "/box.json";

        if (fileExists(boxJsonPath)) {
            try {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                if (structKeyExists(boxJson, "version")) {
                    return boxJson.version;
                }
            } catch (any e) {
                // Return unknown if error
            }
        }

        return "unknown";
    }
}