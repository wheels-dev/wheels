/**
 * View deployment audit trail
 * 
 * {code:bash}
 * wheels deploy:audit
 * wheels deploy:audit --lines=50
 * wheels deploy:audit --filter=deployment
 * {code}
 */
component extends="./base" {

    /**
     * @lines Number of audit entries to show
     * @filter Filter entries by action type
     * @json Output as JSON
     */
    function run(
        numeric lines=20,
        string filter="",
        boolean json=false
    ) {
        print.line();
        print.boldMagentaLine("Wheels Deploy Audit Trail");
        print.line("=".repeatString(50));
        
        var auditFile = fileSystemUtil.resolvePath(".kamal/deploy-audit.log");
        
        if (!fileExists(auditFile)) {
            print.yellowLine("No audit trail found");
            print.line("Deploy commands will be logged to: .kamal/deploy-audit.log");
            return;
        }
        
        // Read audit log
        var auditContent = fileRead(auditFile);
        var auditLines = listToArray(auditContent, chr(10));
        var entries = [];
        
        // Parse JSON entries
        for (var line in auditLines) {
            if (len(trim(line))) {
                try {
                    var entry = deserializeJSON(line);
                    
                    // Apply filter if specified
                    if (!len(arguments.filter) || entry.action contains arguments.filter) {
                        entries.append(entry);
                    }
                } catch (any e) {
                    // Skip malformed entries
                }
            }
        }
        
        // Sort by timestamp (newest first)
        entries.sort(function(a, b) {
            return compare(b.timestamp, a.timestamp);
        });
        
        // Limit entries
        if (arguments.lines > 0 && arrayLen(entries) > arguments.lines) {
            entries = entries.slice(1, arguments.lines);
        }
        
        // Output
        if (arguments.json) {
            print.line(serializeJSON(entries));
        } else {
            if (arrayIsEmpty(entries)) {
                print.yellowLine("No audit entries found");
                
                if (len(arguments.filter)) {
                    print.line("No entries matching filter: #arguments.filter#");
                }
            } else {
                print.line("Showing #arrayLen(entries)# audit entries:");
                print.line();
                
                for (var entry in entries) {
                    // Format timestamp
                    print.boldLine("#entry.timestamp# - #entry.action#");
                    print.line("  User: #entry.user#@#entry.host#");
                    
                    // Show relevant data based on action
                    switch(entry.action) {
                        case "deployment_started":
                        case "deployment_completed":
                            if (structKeyExists(entry.data, "tag")) {
                                print.line("  Tag: #entry.data.tag#");
                            }
                            if (structKeyExists(entry.data, "servers")) {
                                print.line("  Servers: #arrayToList(entry.data.servers)#");
                            }
                            break;
                            
                        case "deployment_failed":
                            if (structKeyExists(entry.data, "error")) {
                                print.redLine("  Error: #entry.data.error#");
                            }
                            break;
                            
                        case "secrets_pushed":
                        case "secrets_pulled":
                            if (structKeyExists(entry.data, "keys")) {
                                print.line("  Keys: #arrayToList(entry.data.keys)#");
                            }
                            break;
                            
                        case "hook_executed":
                        case "hook_failed":
                            if (structKeyExists(entry.data, "hook")) {
                                print.line("  Hook: #entry.data.hook#");
                            }
                            if (structKeyExists(entry.data, "error")) {
                                print.redLine("  Error: #entry.data.error#");
                            }
                            break;
                            
                        case "lock_acquired":
                        case "lock_released":
                            if (structKeyExists(entry.data, "message") && len(entry.data.message)) {
                                print.line("  Message: #entry.data.message#");
                            }
                            break;
                    }
                    
                    print.line();
                }
                
                if (arrayLen(entries) < arrayLen(auditLines)) {
                    print.line("Use lines=N to see more entries");
                }
            }
        }
    }
}