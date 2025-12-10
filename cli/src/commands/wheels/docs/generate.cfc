/**
 * Generate API documentation
 * Examples:
 * wheels docs generate
 * wheels docs generate --output=docs/api --format=html
 * wheels docs generate --include=models,controllers --serve=true
 */
component extends="../base" {
    
    property name="fileSystemUtil" inject="FileSystem";
    property name="helpers" inject="Helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @output.hint Output directory for docs
     * @format.hint Documentation format (html, json, markdown)
     * @format.options html,json,markdown
     * @template.hint Documentation template to use
     * @template.options default,bootstrap,minimal
     * @include.hint Components to include (models,controllers,views,services)
     * @serve.hint Start local server after generation
     * @verbose.hint Verbose output
     */
    function run(
        string output = "docs/api",
        string format = "html",
        string template = "default",
        string include = "models,controllers",
        boolean serve = false,
        boolean verbose = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                format: ["html", "json", "markdown"],
                template: ["default", "minimal", "detailed"],
                include: ["models", "controllers", "views", "services"]
            },
            allowCommaSeparated=["include"]
        );
        
        detailOutput.header("Documentation Generator");
        print.line("Generating documentation...").toConsole();
        detailOutput.line();
        
        var outputPath = resolvePath(arguments.output);
        var componentsToDocument = listToArray(arguments.include);
        
        // Ensure output directory exists
        if (!directoryExists(outputPath)) {
            directoryCreate(outputPath, true);
            detailOutput.create("directory #arguments.output#");
        }
        
        var documentedComponents = {
            models = [],
            controllers = [],
            views = [],
            services = [],
            total = 0
        };
        
        detailOutput.subHeader("Scanning Source Files");
        
        // Document each component type
        for (var componentType in componentsToDocument) {
            if (arguments.verbose) {
                print.line("Documenting #componentType#...").toConsole();
            }
            
            var documented = documentComponents(
                type = componentType,
                outputPath = outputPath,
                format = arguments.format,
                template = arguments.template,
                verbose = arguments.verbose
            );
            
            documentedComponents[componentType] = documented;
            documentedComponents.total += arrayLen(documented);
            
            if (arrayLen(documented) > 0) {
                detailOutput.statusSuccess("Found #arrayLen(documented)# #componentType#");
            } else if (arguments.verbose) {
                detailOutput.statusWarning("No #componentType# found");
            }
        }
        
        // Generate index/navigation
        detailOutput.line();
        print.line("Writing documentation...").toConsole();
        
        if (arguments.format == "html") {
            generateHTMLIndex(outputPath, documentedComponents, arguments.template);
            detailOutput.statusSuccess("HTML files generated");
        } else if (arguments.format == "markdown") {
            generateMarkdownIndex(outputPath, documentedComponents);
            detailOutput.statusSuccess("Markdown files generated");
        } else if (arguments.format == "json") {
            fileWrite(outputPath & "/documentation.json", serializeJSON(documentedComponents, true));
            detailOutput.statusSuccess("JSON documentation generated");
        }
        
        // Display summary
        detailOutput.separator();
        detailOutput.statusSuccess("Documentation generated successfully!");
        detailOutput.line();
        
        detailOutput.subHeader("Summary");
        for (var type in componentsToDocument) {
            if (arrayLen(documentedComponents[type])) {
                detailOutput.metric(
                    label = "#uCase(left(type, 1)) & right(type, len(type)-1)#",
                    value = "#arrayLen(documentedComponents[type])# files"
                );
            }
        }
        detailOutput.metric(
            label = "Total Components",
            value = "#documentedComponents.total# documented"
        );
        detailOutput.line();
        detailOutput.statusInfo("Output directory: #outputPath#");
        
        if (arguments.serve) {
            detailOutput.line();
            print.line("Starting documentation server...").toConsole();
            detailOutput.line();
            
            // Start server using CommandBox
            command("wheels docs serve")
                .params(
                    directory = outputPath,
                    port = 8585,
                    browser = true
                )
                .run();
            
            detailOutput.statusSuccess("Documentation server started at http://localhost:8585");
        }
    }
    
    private function documentComponents(
        required string type,
        required string outputPath,
        required string format,
        required string template,
        boolean verbose = false
    ) {
        var documented = [];
        var sourcePath = resolvePath("app/#arguments.type#");
        
        // Also check alternative paths
        if (!directoryExists(sourcePath)) {
            sourcePath = resolvePath("#arguments.type#");
        }
        
        if (!directoryExists(sourcePath)) {
            if (arguments.verbose) {
                detailOutput.statusWarning("Directory not found: app/#arguments.type#");
            }
            return documented;
        }
        
        var files = directoryList(sourcePath, true, "path", "*.cfc");
        
        for (var file in files) {
            try {
                var componentInfo = parseComponent(file, arguments.type);
                
                if (structCount(componentInfo) && len(componentInfo.name)) {
                    // Generate documentation
                    var docContent = generateDocumentation(
                        componentInfo,
                        arguments.format,
                        arguments.template
                    );
                    
                    // Write documentation file
                    var outputFile = generateOutputPath(
                        file,
                        sourcePath,
                        arguments.outputPath,
                        arguments.type,
                        arguments.format
                    );
                    
                    var outputDir = getDirectoryFromPath(outputFile);
                    if (!directoryExists(outputDir)) {
                        directoryCreate(outputDir, true);
                    }
                    
                    fileWrite(outputFile, docContent);
                    arrayAppend(documented, componentInfo);
                    
                    if (arguments.verbose) {
                        detailOutput.create("#componentInfo.name#", true);
                    }
                }
            } catch (any e) {
                if (arguments.verbose) {
                    detailOutput.statusFailed("#getFileFromPath(file)#: #e.message#", true);
                }
            }
        }
        
        return documented;
    }
    
    private function parseComponent(filePath, type) {
        var info = {
            name = "",
            path = arguments.filePath,
            type = arguments.type,
            extends = "",
            implements = [],
            properties = [],
            functions = [],
            description = "",
            hints = {}
        };
        
        try {
            // Get component name from file path
            info.name = reReplace(getFileFromPath(arguments.filePath), "\.cfc$", "");
            
            // Read file content for parsing
            var content = fileRead(arguments.filePath);
            
            // Parse component declaration
            var componentMatch = reMatchNoCase("component[^{]*\{", content);
            if (arrayLen(componentMatch)) {
                var declaration = componentMatch[1];
                
                // Extract extends
                var extendsMatch = reMatchNoCase('extends\s*=\s*"([^"]+)"', declaration);
                if (arrayLen(extendsMatch)) {
                    info.extends = reReplace(extendsMatch[1], 'extends\s*=\s*"([^"]+)"', "\1");
                }
                
                // Extract hint/description from comments
                var commentPattern = "/\*\*([^*]|\*(?!/))*\*/";
                var comments = reMatchNoCase(commentPattern, content);
                if (arrayLen(comments)) {
                    var firstComment = comments[1];
                    // Clean up comment
                    firstComment = reReplace(firstComment, "^/\*\*\s*", "");
                    firstComment = reReplace(firstComment, "\s*\*/$", "");
                    firstComment = reReplace(firstComment, "\n\s*\*\s*", " ", "all");
                    info.description = trim(firstComment);
                }
            }
            
            // Parse functions
            var functionPattern = "(public|private|remote|package)?\s*(any|string|numeric|boolean|struct|array|query|void|component)?\s*function\s+(\w+)\s*\([^)]*\)";
            var functionMatches = reFindNoCase(functionPattern, content, 1, true);
            
            if (structKeyExists(functionMatches, "pos") && arrayLen(functionMatches.pos)) {
                for (var i = 1; i <= arrayLen(functionMatches.pos); i++) {
                    if (functionMatches.pos[i] > 0) {
                        var funcText = mid(content, functionMatches.pos[i], functionMatches.len[i]);
                        var funcName = reReplace(funcText, functionPattern, "\3");
                        var access = reReplace(funcText, functionPattern, "\1");
                        var returnType = reReplace(funcText, functionPattern, "\2");
                        
                        if (!len(access)) access = "public";
                        if (!len(returnType)) returnType = "any";
                        
                        // Skip private functions unless verbose
                        if (access != "private" || arguments.verbose) {
                            arrayAppend(info.functions, {
                                name = funcName,
                                access = access,
                                returnType = returnType,
                                hint = "",
                                parameters = []
                            });
                        }
                    }
                }
            }
            
            // Parse properties
            var propertyPattern = "property\s+[^;]+;";
            var propertyMatches = reMatchNoCase(propertyPattern, content);
            
            for (var propMatch in propertyMatches) {
                var propName = "";
                var nameMatch = reMatchNoCase('name\s*=\s*"([^"]+)"', propMatch);
                if (arrayLen(nameMatch)) {
                    propName = reReplace(nameMatch[1], 'name\s*=\s*"([^"]+)"', "\1");
                }
                
                if (len(propName)) {
                    arrayAppend(info.properties, {
                        name = propName,
                        type = "any",
                        required = false,
                        default = "",
                        hint = ""
                    });
                }
            }
            
        } catch (any e) {
            // Return info with at least the name populated
        }
        
        return info;
    }
    
    private function generateDocumentation(componentInfo, format, template) {
        switch (arguments.format) {
            case "html":
                return generateHTMLDoc(arguments.componentInfo, arguments.template);
            case "markdown":
                return generateMarkdownDoc(arguments.componentInfo);
            case "json":
                return serializeJSON(arguments.componentInfo, true);
            default:
                return "";
        }
    }
    
    private function generateHTMLDoc(componentInfo, template) {
        var html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>' & arguments.componentInfo.name & ' - Wheels API Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; color: ##333; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1, h2, h3 { color: ##2c3e50; }
        .component-header { background: ##f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .component-type { display: inline-block; background: ##007bff; color: white; padding: 2px 8px; border-radius: 4px; font-size: 12px; }
        .extends { color: ##6c757d; font-style: italic; }
        .property, .method { border-left: 3px solid ##007bff; padding: 15px; margin: 20px 0; background: ##f8f9fa; }
        .property-name, .method-name { font-weight: bold; font-size: 18px; }
        .type { color: ##007bff; font-family: monospace; }
        .parameter { margin: 10px 0; padding: 10px; background: white; border-radius: 4px; }
        .required { color: ##dc3545; }
        .access { display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 11px; margin-left: 10px; }
        .access.public { background: ##28a745; color: white; }
        .access.private { background: ##6c757d; color: white; }
        pre { background: ##f4f4f4; padding: 15px; border-radius: 4px; overflow-x: auto; }
        code { font-family: "Courier New", monospace; }
    </style>
</head>
<body>
    <div class="component-header">
        <h1>' & arguments.componentInfo.name & '</h1>
        <span class="component-type">' & arguments.componentInfo.type & '</span>
        ' & (len(arguments.componentInfo.extends) ? '<p class="extends">extends ' & arguments.componentInfo.extends & '</p>' : '') & '
        ' & (len(arguments.componentInfo.description) ? '<p>' & arguments.componentInfo.description & '</p>' : '') & '
    </div>
    
    ' & generatePropertiesHTML(arguments.componentInfo.properties) & '
    ' & generateMethodsHTML(arguments.componentInfo.functions) & '
</body>
</html>';
        
        return html;
    }
    
    private function generatePropertiesHTML(properties) {
        if (!arrayLen(arguments.properties)) return "";
        
        var html = '<h2>Properties</h2>';
        
        for (var prop in arguments.properties) {
            html &= '<div class="property">';
            html &= '<div class="property-name">' & prop.name & '</div>';
            html &= '<div class="type">Type: ' & prop.type & '</div>';
            if (prop.required) {
                html &= '<span class="required">Required</span>';
            }
            if (len(prop.hint)) {
                html &= '<p>' & prop.hint & '</p>';
            }
            html &= '</div>';
        }
        
        return html;
    }
    
    private function generateMethodsHTML(functions) {
        if (!arrayLen(arguments.functions)) return "";
        
        var html = '<h2>Methods</h2>';
        
        for (var func in arguments.functions) {
            html &= '<div class="method">';
            html &= '<div class="method-name">' & func.name & '()';
            html &= '<span class="access ' & func.access & '">' & func.access & '</span>';
            html &= '</div>';
            html &= '<div class="type">Returns: ' & func.returnType & '</div>';
            
            if (len(func.hint)) {
                html &= '<p>' & func.hint & '</p>';
            }
            
            if (arrayLen(func.parameters)) {
                html &= '<h4>Parameters:</h4>';
                for (var param in func.parameters) {
                    html &= '<div class="parameter">';
                    html &= '<strong>' & param.name & '</strong>';
                    html &= ' <span class="type">' & param.type & '</span>';
                    if (param.required) {
                        html &= ' <span class="required">required</span>';
                    }
                    if (len(param.hint)) {
                        html &= ' - ' & param.hint;
                    }
                    html &= '</div>';
                }
            }
            
            html &= '</div>';
        }
        
        return html;
    }
    
    private function generateMarkdownDoc(componentInfo) {
        var md = '## ' & arguments.componentInfo.name & chr(10) & chr(10);
        
        md &= 'Type: ' & arguments.componentInfo.type & chr(10) & chr(10);
        
        if (len(arguments.componentInfo.description)) {
            md &= arguments.componentInfo.description & chr(10) & chr(10);
        }
        
        if (len(arguments.componentInfo.extends)) {
            md &= '_Extends: ' & arguments.componentInfo.extends & '_' & chr(10) & chr(10);
        }
        
        // Properties
        if (arrayLen(arguments.componentInfo.properties)) {
            md &= '## Properties' & chr(10) & chr(10);
            for (var prop in arguments.componentInfo.properties) {
                md &= '#### ' & prop.name & chr(10);
                md &= '- Type: `' & prop.type & '`' & chr(10);
                if (prop.required) md &= '- Required: Yes' & chr(10);
                if (len(prop.hint)) md &= '- Description: ' & prop.hint & chr(10);
                md &= chr(10);
            }
        }
        
        // Methods  
        if (arrayLen(arguments.componentInfo.functions)) {
            md &= '## Methods' & chr(10) & chr(10);
            for (var func in arguments.componentInfo.functions) {
                md &= '#### ' & func.name & '()' & chr(10);
                md &= '- Access: ' & func.access & chr(10);
                md &= '- Returns: `' & func.returnType & '`' & chr(10);
                if (len(func.hint)) md &= '- Description: ' & func.hint & chr(10);
                
                if (arrayLen(func.parameters)) {
                    md &= chr(10) & 'Parameters:' & chr(10);
                    for (var param in func.parameters) {
                        md &= '- `' & param.name & '` (' & param.type & ')';
                        if (param.required) md &= ' _required_';
                        if (len(param.hint)) md &= ' - ' & param.hint;
                        md &= chr(10);
                    }
                }
                md &= chr(10);
            }
        }
        
        return md;
    }
    
    private function generateOutputPath(sourcePath, sourceRoot, outputPath, type, format) {
        // Remove the source root from the path to get relative path
        var relativePath = replace(arguments.sourcePath, arguments.sourceRoot, "");
        // Remove leading slash if present
        if (left(relativePath, 1) == "/" || left(relativePath, 1) == "\") {
            relativePath = right(relativePath, len(relativePath) - 1);
        }
        
        // Get just the filename without extension
        var fileName = reReplace(getFileFromPath(relativePath), "\.cfc$", "");
        
        // Create subdirectory for component type
        var typeDir = arguments.outputPath & "/" & arguments.type;
        if (!directoryExists(typeDir)) {
            directoryCreate(typeDir, true);
        }
        
        // Build the output file path
        var outputFile = typeDir & "/" & fileName;
        
        // Add appropriate extension based on format
        switch (arguments.format) {
            case "html":
                outputFile &= ".html";
                break;
            case "markdown":
                outputFile &= ".md";
                break;
            case "json":
                outputFile &= ".json";
                break;
        }
        
        return outputFile;
    }
    
    private function generateHTMLIndex(outputPath, components, template) {
        var indexHTML = '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Wheels API Documentation</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        .container { display: flex; height: 100vh; }
        .sidebar { width: 300px; background: ##f8f9fa; padding: 20px; overflow-y: auto; border-right: 1px solid ##dee2e6; }
        .main { flex: 1; overflow: hidden; display: flex; flex-direction: column; }
        .navbar { background: white; padding: 15px 30px; border-bottom: 1px solid ##dee2e6; }
        .content { flex: 1; padding: 40px; overflow-y: auto; }
        h1 { color: ##2c3e50; margin-bottom: 30px; }
        h2 { color: ##34495e; margin-top: 30px; font-size: 20px; }
        h3 { color: ##34495e; font-size: 16px; margin: 20px 0 10px 0; }
        .component-list { list-style: none; padding: 0; }
        .component-list li { margin: 2px 0; }
        .component-list a { text-decoration: none; color: ##3498db; display: block; padding: 8px 12px; border-radius: 4px; transition: all 0.2s; }
        .component-list a:hover { background: ##e9ecef; color: ##2980b9; }
        .component-list a.active { background: ##3498db; color: white; }
        .stats { background: ##f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 30px; border: 1px solid ##dee2e6; }
        .stats h3 { margin-top: 0; color: ##2c3e50; }
        .logo { font-size: 24px; font-weight: bold; color: ##2c3e50; margin-bottom: 30px; }
        iframe { width: 100%; height: 100%; border: none; }
        .breadcrumb { color: ##6c757d; font-size: 14px; }
        .error-msg { padding: 20px; background: ##f8d7da; border: 1px solid ##f5c6cb; color: ##721c24; border-radius: 5px; }
    </style>
    <script>
        function loadDoc(url, name, linkElement) {
            var frame = document.getElementById("docFrame");
            frame.src = url;
            document.getElementById("breadcrumb").innerHTML = name;
            
            // Update active state
            var links = document.querySelectorAll(".component-list a");
            links.forEach(function(link) {
                link.classList.remove("active");
            });
            if (linkElement) {
                linkElement.classList.add("active");
            }
            
            // Handle load errors
            frame.onerror = function() {
                frame.srcdoc = ''<html><body><div class="error-msg">Unable to load documentation for '' + name + ''</div></body></html>'';
            };
        }
        
        window.onload = function() {
            // Load welcome page by default
            document.getElementById("docFrame").src = "welcome.html";
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="sidebar">
            <div class="logo">📚 Wheels API</div>';
        
        // Add navigation for each component type
        for (var type in ["models", "controllers", "services", "views"]) {
            if (structKeyExists(arguments.components, type) && arrayLen(arguments.components[type])) {
                indexHTML &= '<h3>' & uCase(left(type, 1)) & right(type, len(type)-1) & '</h3>';
                indexHTML &= '<ul class="component-list">';
                
                for (var comp in arguments.components[type]) {
                    var link = type & '/' & comp.name & '.html';
                    indexHTML &= '<li><a href="##" onclick="loadDoc(''' & link & ''', ''' & type & ' / ' & comp.name & ''', this); return false;">' & comp.name & '</a></li>';
                }
                
                indexHTML &= '</ul>';
            }
        }
        
        indexHTML &= '
        </div>
        <div class="main">
            <div class="navbar">
                <div class="breadcrumb">Home / <span id="breadcrumb">Welcome</span></div>
            </div>
            <div class="content">
                <iframe id="docFrame"></iframe>
            </div>
        </div>
    </div>
</body>
</html>';
        
        fileWrite(arguments.outputPath & "/index.html", indexHTML);
        
        // Generate welcome page
        var welcomeHTML = '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome - Wheels API Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 20px; color: ##333; line-height: 1.6; }
        h1 { color: ##2c3e50; }
        h2 { color: ##34495e; margin-top: 30px; }
        .stats { background: ##f8f9fa; padding: 20px; border-radius: 5px; border: 1px solid ##dee2e6; margin: 20px 0; }
        .stats h3 { margin-top: 0; color: ##2c3e50; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 15px; }
        .stat-card { background: white; padding: 15px; border-radius: 5px; border: 1px solid ##e9ecef; }
        .stat-label { font-size: 14px; color: ##6c757d; }
        .stat-value { font-size: 24px; font-weight: bold; color: ##2c3e50; }
    </style>
</head>
<body>
    <h1>Welcome to Wheels API Documentation</h1>
    <div class="stats">
        <h3>Documentation Summary</h3>
        <div class="stats-grid">';
        
        // Add individual counts for each type
        for (var type in ["models", "controllers", "services", "views"]) {
            if (structKeyExists(arguments.components, type)) {
                welcomeHTML &= '
            <div class="stat-card">
                <div class="stat-label">' & uCase(left(type, 1)) & right(type, len(type)-1) & '</div>
                <div class="stat-value">' & arrayLen(arguments.components[type]) & '</div>
            </div>';
            }
        }
        
        welcomeHTML &= '
            <div class="stat-card">
                <div class="stat-label">Total Components</div>
                <div class="stat-value">' & arguments.components.total & '</div>
            </div>
        </div>
        <p style="margin-top: 15px; color: ##6c757d; font-size: 14px;">Generated on: ' & dateFormat(now(), "long") & ' ' & timeFormat(now(), "short") & '</p>
    </div>
    
    <h2>Getting Started</h2>
    <p>This documentation was automatically generated from your Wheels application source code. Use the sidebar on the left to navigate through your components.</p>
    
    <h2>Component Types</h2>
    <ul>
        <li><strong>Models:</strong> Data models representing your application''s business entities</li>
        <li><strong>Controllers:</strong> Request handlers that manage application flow</li>
        <li><strong>Services:</strong> Business logic and utility services</li>
        <li><strong>Views:</strong> Presentation layer components</li>
    </ul>
    
    <h2>Navigation</h2>
    <p>Select any component from the sidebar to view its detailed documentation, including:</p>
    <ul>
        <li>Properties and their types</li>
        <li>Available methods and functions</li>
        <li>Method parameters and return types</li>
        <li>Access modifiers (public, private, etc.)</li>
    </ul>
</body>
</html>';
        
        fileWrite(arguments.outputPath & "/welcome.html", welcomeHTML);
    }
    
    private function generateMarkdownIndex(outputPath, components) {
        var indexMD = '## Wheels API Documentation' & chr(10) & chr(10);
        indexMD &= 'Generated on ' & dateFormat(now(), "long") & ' at ' & timeFormat(now(), "short") & chr(10) & chr(10);
        
        indexMD &= '## Table of Contents' & chr(10) & chr(10);
        
        for (var type in ["models", "controllers", "services", "views"]) {
            if (structKeyExists(arguments.components, type) && arrayLen(arguments.components[type])) {
                indexMD &= '#### ' & uCase(left(type, 1)) & right(type, len(type)-1) & chr(10) & chr(10);
                
                for (var comp in arguments.components[type]) {
                    var link = type & '/' & comp.name & '.md';
                    indexMD &= '- [' & comp.name & '](' & link & ')' & chr(10);
                }
                
                indexMD &= chr(10);
            }
        }
        
        indexMD &= '## Summary' & chr(10) & chr(10);
        indexMD &= 'Total components documented: ' & arguments.components.total & chr(10);
        
        fileWrite(arguments.outputPath & "/README.md", indexMD);
    }
}