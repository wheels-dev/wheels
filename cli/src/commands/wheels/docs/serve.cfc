/**
 * Serve documentation locally
 * Examples:
 * wheels docs serve
 * wheels docs serve --port=8080 --root=docs/api
 */
component extends="../base" {
    
    property name="serverService" inject="ServerService";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @root.hint Root directory to serve (default: docs/api)
     * @port.hint Port to serve on
     * @open.hint Open browser automatically
     */
    function run(
        string root = "docs/api",
        numeric port = 35729,
        boolean open = true
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            numericRanges={
                port: {min:1024, max:65535}
            }
        );
        var docRoot = fileSystemUtil.resolvePath(arguments.root);
        
        if (!directoryExists(docRoot)) {
            detailOutput.error("Documentation directory not found: #docRoot#");
            detailOutput.line();
            detailOutput.statusInfo("Tip: Run 'wheels docs generate' first to create documentation");
            return;
        }
        
        detailOutput.header("Documentation Server");
        print.line("Starting documentation server...").toConsole();
        detailOutput.line();
        
        // Check if index file exists
        var hasIndex = fileExists(docRoot & "/index.html") || 
                      fileExists(docRoot & "/README.md") || 
                      fileExists(docRoot & "/index.json");
        
        if (!hasIndex) {
            detailOutput.statusWarning("No index file found. Creating a simple directory listing...");
            createDirectoryListing(docRoot);
            detailOutput.create("directory listing index.html");
        }
        
        // Start the server
        var serverArgs = {
            directory = docRoot,
            port = arguments.port,
            openBrowser = arguments.open,
            name = "wheels-docs-#createUUID()#",
            saveSettings = false
        };
        
        try {
            serverService.start(serverArgs);
            
            detailOutput.statusSuccess("Documentation server started!");
            detailOutput.line();
            detailOutput.metric("Serving directory", docRoot);
            detailOutput.metric("URL", "http://localhost:#arguments.port#");
            
            if (arguments.open) {
                print.line("Opening browser...").toConsole();
            }
            
            detailOutput.line();
            
            // Keep the command running
            while (true) {
                sleep(5000); // wait for 5 seconds

                // Check if server is still running or still starting
                var serverInfo = serverService.getServerInfo(name=serverArgs.name, webroot=docRoot);
                
                // If status is missing or server crashed, break
                if (!structKeyExists(serverInfo, "status")) {
                    detailOutput.statusFailed("Server info missing. Exiting...");
                    break;
                }

                // If server is fully running, continue
                if (serverInfo.status == "running") {
                    detailOutput.statusSuccess("Server is up and running!");
                    break;
                }

                // If still starting, just wait and continue
                if (serverInfo.status == "starting") {
                    print.line("Server is still starting... waiting...").toConsole();
                    continue;
                }

                // Any other status (like "stopped", "error", etc.)
                detailOutput.statusFailed("Unexpected server status: " & serverInfo.status);
                break;
            }

            
        } catch (any e) {
            detailOutput.error("Failed to start server: #e.message#");
            return;
        }
    }
    
    private function createDirectoryListing(docRoot) {
        var files = directoryList(arguments.docRoot, true, "query");
        
        var html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Wheels Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 40px; }
        h1 { color: ##2c3e50; }
        .file-list { list-style: none; padding: 0; }
        .file-list li { margin: 10px 0; }
        .file-list a { text-decoration: none; color: ##3498db; padding: 5px 10px; display: inline-block; }
        .file-list a:hover { background: ##ecf0f1; border-radius: 4px; }
        .file { margin-left: 20px; }
        .folder { font-weight: bold; }
        .icon { margin-right: 5px; }
    </style>
</head>
<body>
    <h1>📚 Wheels Documentation</h1>
    <p>Generated on ' & dateTimeFormat(now(), "full") & '</p>
    
    <ul class="file-list">
';
        
        // Group files by directory
        var tree = buildFileTree(files, arguments.docRoot);
        html &= renderFileTree(tree, "");
        
        html &= '
    </ul>
</body>
</html>';
        
        fileWrite(arguments.docRoot & "/index.html", html);
    }
    
    private function buildFileTree(files, rootPath) {
        var tree = {};
        
        for (var file in arguments.files) {
            if (file.type == "File" && file.name != "index.html") {
                var relativePath = replace(file.directory, arguments.rootPath, "");
                if (left(relativePath, 1) == "/" || left(relativePath, 1) == "\") {
                    relativePath = right(relativePath, len(relativePath) - 1);
                }
                
                var parts = listToArray(relativePath, "/\");
                var current = tree;
                
                for (var part in parts) {
                    if (!structKeyExists(current, part)) {
                        current[part] = { _files = [] };
                    }
                    current = current[part];
                }
                
                arrayAppend(current._files, file.name);
            }
        }
        
        return tree;
    }
    
    private function renderFileTree(tree, path) {
        var html = "";
        
        // Render directories
        for (var key in arguments.tree) {
            if (key != "_files") {
                html &= '<li class="folder"><span class="icon">📁</span>' & key;
                html &= '<ul class="file-list">';
                html &= renderFileTree(arguments.tree[key], arguments.path & "/" & key);
                html &= '</ul>';
                html &= '</li>';
            }
        }
        
        // Render files
        if (structKeyExists(arguments.tree, "_files")) {
            for (var file in arguments.tree._files) {
                var icon = "📄";
                if (file contains ".html") icon = "🌐";
                else if (file contains ".md") icon = "📝";
                else if (file contains ".json") icon = "📊";
                
                var filePath = arguments.path & "/" & file;
                if (left(filePath, 1) == "/") filePath = right(filePath, len(filePath) - 1);
                
                html &= '<li class="file"><a href="' & filePath & '"><span class="icon">' & icon & '</span>' & file & '</a></li>';
            }
        }
        
        return html;
    }
}