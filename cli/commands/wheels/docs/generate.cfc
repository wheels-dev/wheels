/**
 * Generate API documentation
 * Examples:
 * wheels docs generate
 * wheels docs generate output=docs/api format=html
 * wheels docs generate include=models,controllers serve=true
 */
component extends="../base" {
    
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
        print.yellowLine("📚 Generating documentation...")
             .line();
        
        var outputPath = fileSystemUtil.resolvePath(arguments.output);
        var componentsToDocument = listToArray(arguments.include);
        
        // Ensure output directory exists
        if (!directoryExists(outputPath)) {
            directoryCreate(outputPath, true);
        }
        
        var documentedComponents = {
            models = [],
            controllers = [],
            views = [],
            services = [],
            total = 0
        };
        
        // Document each component type
        for (var componentType in componentsToDocument) {
            if (arguments.verbose) {
                print.line("Documenting #componentType#...");
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
        }
        
        // Generate index/navigation
        if (arguments.format == "html") {
            generateHTMLIndex(outputPath, documentedComponents, arguments.template);
        } else if (arguments.format == "markdown") {
            generateMarkdownIndex(outputPath, documentedComponents);
        }
        
        // Display summary
        print.line();
        print.greenBoldLine("✅ Documentation generated successfully!");
        print.line();
        print.line("📊 Summary:");
        for (var type in componentsToDocument) {
            if (arrayLen(documentedComponents[type])) {
                print.line("  • #helpers.capitalize(type)#: #arrayLen(documentedComponents[type])# files");
            }
        }
        print.line("  • Total: #documentedComponents.total# components documented");
        print.line();
        print.greenLine("📁 Output directory: #outputPath#");
        
        if (arguments.serve) {
            print.line();
            command("wheels docs serve").params(root = outputPath).run();
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
        var sourcePath = fileSystemUtil.resolvePath("app/#arguments.type#");
        
        if (!directoryExists(sourcePath)) {
            if (arguments.verbose) {
                print.yellowLine("  ⚠️  Directory not found: app/#arguments.type#");
            }
            return documented;
        }
        
        var files = directoryList(sourcePath, true, "path", "*.cfc");
        
        for (var file in files) {
            try {
                var componentInfo = parseComponent(file, arguments.type);
                
                if (structCount(componentInfo)) {
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
                        print.greenLine("  ✓ #componentInfo.name#");
                    }
                }
            } catch (any e) {
                if (arguments.verbose) {
                    print.redLine("  ✗ Error documenting #getFileFromPath(file)#: #e.message#");
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
            var content = fileRead(arguments.filePath);
            var metadata = getComponentMetadata(arguments.filePath);
            
            info.name = listLast(metadata.name, ".");
            info.extends = structKeyExists(metadata, "extends") ? metadata.extends : "";
            info.implements = structKeyExists(metadata, "implements") ? listToArray(metadata.implements) : [];
            
            // Parse component attributes
            if (structKeyExists(metadata, "hint")) {
                info.description = metadata.hint;
            }
            
            // Parse properties
            if (structKeyExists(metadata, "properties")) {
                for (var prop in metadata.properties) {
                    arrayAppend(info.properties, parseProperty(prop));
                }
            }
            
            // Parse functions
            if (structKeyExists(metadata, "functions")) {
                for (var func in metadata.functions) {
                    if (!(func.name.startsWith("$")) && func.access != "private") {
                        arrayAppend(info.functions, parseFunction(func));
                    }
                }
            }
            
        } catch (any e) {
            // Return empty info if parsing fails
        }
        
        return info;
    }
    
    private function parseProperty(prop) {
        return {
            name = prop.name,
            type = structKeyExists(prop, "type") ? prop.type : "any",
            required = structKeyExists(prop, "required") ? prop.required : false,
            default = structKeyExists(prop, "default") ? prop.default : "",
            hint = structKeyExists(prop, "hint") ? prop.hint : ""
        };
    }
    
    private function parseFunction(func) {
        var funcInfo = {
            name = func.name,
            returnType = structKeyExists(func, "returntype") ? func.returntype : "any",
            access = structKeyExists(func, "access") ? func.access : "public",
            hint = structKeyExists(func, "hint") ? func.hint : "",
            parameters = []
        };
        
        if (structKeyExists(func, "parameters")) {
            for (var param in func.parameters) {
                arrayAppend(funcInfo.parameters, {
                    name = param.name,
                    type = structKeyExists(param, "type") ? param.type : "any",
                    required = structKeyExists(param, "required") ? param.required : false,
                    default = structKeyExists(param, "default") ? param.default : "",
                    hint = structKeyExists(param, "hint") ? param.hint : ""
                });
            }
        }
        
        return funcInfo;
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
    <title>' & componentInfo.name & ' - Wheels API Documentation</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css">
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
        pre { background: ##f4f4f4; padding: 15px; border-radius: 4px; overflow-x: auto; }
        code { font-family: "Courier New", monospace; }
    </style>
</head>
<body>
    <div class="component-header">
        <h1>' & componentInfo.name & '</h1>
        <span class="component-type">' & componentInfo.type & '</span>
        ' & (len(componentInfo.extends) ? '<p class="extends">extends ' & componentInfo.extends & '</p>' : '') & '
        ' & (len(componentInfo.description) ? '<p>' & componentInfo.description & '</p>' : '') & '
    </div>
    
    ' & generatePropertiesHTML(componentInfo.properties) & '
    ' & generateMethodsHTML(componentInfo.functions) & '
    
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
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
            html &= '<div class="method-name">' & func.name & '()</div>';
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
        var md = chr(35) & ' ' & componentInfo.name & chr(10) & chr(10);
        
        if (len(componentInfo.description)) {
            md &= componentInfo.description & chr(10) & chr(10);
        }
        
        if (len(componentInfo.extends)) {
            md &= '_Extends: ' & componentInfo.extends & '_' & chr(10) & chr(10);
        }
        
        // Properties
        if (arrayLen(componentInfo.properties)) {
            md &= chr(35) & chr(35) & ' Properties' & chr(10) & chr(10);
            for (var prop in componentInfo.properties) {
                md &= chr(35) & chr(35) & chr(35) & ' ' & prop.name & chr(10);
                md &= '- Type: `' & prop.type & '`' & chr(10);
                if (prop.required) md &= '- Required: Yes' & chr(10);
                if (len(prop.hint)) md &= '- Description: ' & prop.hint & chr(10);
                md &= chr(10);
            }
        }
        
        // Methods
        if (arrayLen(componentInfo.functions)) {
            md &= chr(35) & chr(35) & ' Methods' & chr(10) & chr(10);
            for (var func in componentInfo.functions) {
                md &= chr(35) & chr(35) & chr(35) & ' ' & func.name & '()' & chr(10);
                md &= '- Returns: `' & func.returnType & '`' & chr(10);
                if (len(func.hint)) md &= '- Description: ' & func.hint & chr(10);
                
                if (arrayLen(func.parameters)) {
                    md &= chr(10) & '**Parameters:**' & chr(10);
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
        var relativePath = replace(arguments.sourcePath, arguments.sourceRoot, "");
        var outputFile = arguments.outputPath & "/" & arguments.type & relativePath;
        
        // Change extension based on format
        switch (arguments.format) {
            case "html":
                outputFile = reReplace(outputFile, "\.cfc$", ".html");
                break;
            case "markdown":
                outputFile = reReplace(outputFile, "\.cfc$", ".md");
                break;
            case "json":
                outputFile = reReplace(outputFile, "\.cfc$", ".json");
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
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; display: flex; }
        .sidebar { width: 300px; background: ##f8f9fa; padding: 20px; height: 100vh; overflow-y: auto; }
        .content { flex: 1; padding: 20px; }
        h1 { color: ##2c3e50; margin-bottom: 30px; }
        h2 { color: ##34495e; margin-top: 30px; }
        .component-list { list-style: none; padding: 0; }
        .component-list li { margin: 5px 0; }
        .component-list a { text-decoration: none; color: ##3498db; }
        .component-list a:hover { text-decoration: underline; }
        .stats { background: ##ecf0f1; padding: 15px; border-radius: 5px; margin-bottom: 30px; }
    </style>
</head>
<body>
    <div class="sidebar">
        <h2>📚 API Documentation</h2>
        ';
        
        // Add navigation for each component type
        for (var type in ["models", "controllers", "services", "views"]) {
            if (structKeyExists(arguments.components, type) && arrayLen(arguments.components[type])) {
                indexHTML &= '<h3>' & helpers.capitalize(type) & '</h3>';
                indexHTML &= '<ul class="component-list">';
                
                for (var comp in arguments.components[type]) {
                    var link = type & '/' & comp.name & '.html';
                    indexHTML &= '<li><a href="' & link & '" target="content">' & comp.name & '</a></li>';
                }
                
                indexHTML &= '</ul>';
            }
        }
        
        indexHTML &= '
    </div>
    <div class="content">
        <iframe name="content" src="welcome.html" style="width: 100%; height: 100vh; border: none;"></iframe>
    </div>
</body>
</html>';
        
        fileWrite(arguments.outputPath & "/index.html", indexHTML);
        
        // Generate welcome page
        var welcomeHTML = '<h1>Welcome to Wheels API Documentation</h1>
<div class="stats">
    <h3>Documentation Summary</h3>
    <p>Total components documented: ' & arguments.components.total & '</p>
</div>
<p>Select a component from the sidebar to view its documentation.</p>';
        
        fileWrite(arguments.outputPath & "/welcome.html", welcomeHTML);
    }
    
    private function generateMarkdownIndex(outputPath, components) {
        var indexMD = chr(35) & ' Wheels API Documentation' & chr(10) & chr(10);
        indexMD &= 'Generated on ' & dateFormat(now(), "long") & chr(10) & chr(10);
        
        indexMD &= chr(35) & chr(35) & ' Table of Contents' & chr(10) & chr(10);
        
        for (var type in ["models", "controllers", "services", "views"]) {
            if (structKeyExists(arguments.components, type) && arrayLen(arguments.components[type])) {
                indexMD &= chr(35) & chr(35) & chr(35) & ' ' & helpers.capitalize(type) & chr(10) & chr(10);
                
                for (var comp in arguments.components[type]) {
                    var link = type & '/' & comp.name & '.md';
                    indexMD &= '- [' & comp.name & '](' & link & ')' & chr(10);
                }
                
                indexMD &= chr(10);
            }
        }
        
        fileWrite(arguments.outputPath & "/README.md", indexMD);
    }
}