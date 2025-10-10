/**
 * Serve documentation locally
 * Examples:
 * wheels docs serve
 * wheels docs serve --port=8080 --root=docs/api
 */
component extends="../base" {
    
    property name="serverService" inject="ServerService";
    
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
        var docRoot = fileSystemUtil.resolvePath(arguments.root);
        
        if (!directoryExists(docRoot)) {
            print.redLine("Documentation directory not found: #docRoot#");
            print.line();
            print.yellowLine("Tip: Run 'wheels docs generate' first to create documentation");
            return;
        }
        
        print.yellowLine("Starting documentation server...")
             .line();
        
        // Check if index file exists
        var hasIndex = fileExists(docRoot & "/index.html") || 
                      fileExists(docRoot & "/README.md") || 
                      fileExists(docRoot & "/index.json");
        
        if (!hasIndex) {
            print.yellowLine("No index file found. Creating a simple directory listing...");
            createDirectoryListing(docRoot);
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
            
            print.greenLine("Documentation server started!");
            print.line();
            print.line("Serving: #docRoot#");
            print.line("URL: http://localhost:#arguments.port#");
            
            if (arguments.open) {
                print.line("Opening browser...");
            }
            
            print.line();
            
            // Keep the command running
            while (true) {
                sleep(5000); // wait for 5 seconds

                // Check if server is still running or still starting
                var serverInfo = serverService.getServerInfo(name=serverArgs.name, webroot=docRoot);
                systemOutput("Status: " & serverInfo.status & chr(10));

                // If status is missing or server crashed, break
                if (!structKeyExists(serverInfo, "status")) {
                    systemOutput("Server info missing. Exiting..."& chr(10));
                    break;
                }

                // If server is fully running, continue
                if (serverInfo.status == "running") {
                    systemOutput("Server is up and running!"& chr(10));
                    break;
                }

                // If still starting, just wait and continue
                if (serverInfo.status == "starting") {
                    systemOutput("Server is still starting... waiting..."& chr(10));
                    continue;
                }

                // Any other status (like "stopped", "error", etc.)
                print.redLine("Unexpected server status: " & serverInfo.status);
                break;
            }

            
        } catch (any e) {
            print.redLine("Failed to start server: #e.message#");
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