/**
 * Scan for security vulnerabilities
 * Examples:
 * wheels security scan
 * wheels security scan --fix --report=json
 * wheels security scan --path=models --severity=high
 */
component extends="../base" {
    
    property name="securityService" inject="SecurityService@wheels-cli";
    
    /**
     * @path.hint Path to scan (default: current directory)
     * @fix.hint Attempt to fix issues automatically
     * @report.hint Generate report in specified format
     * @report.options console,json,html
     * @severity.hint Minimum severity to report
     * @severity.options low,medium,high,critical
     * @output.hint Output file for report (optional)
     */
    function run(
        string path = ".",
        boolean fix = false,
        string report = "console",
        string severity = "medium",
        string output = ""
    ) {
        print.yellowLine("🔒 Scanning for security issues...")
             .line();
        
        var scanPath = fileSystemUtil.resolvePath(arguments.path);
        
        if (!directoryExists(scanPath)) {
            error("Path does not exist: #arguments.path#");
            return;
        }
        
        // Run security scan
        var results = securityService.scan(
            path = scanPath,
            severity = arguments.severity
        );
        
        // Display results summary
        print.line("Scan complete!")
             .line()
             .boldLine("Summary:");
        
        if (results.severityCounts.critical > 0) {
            print.redBoldLine("  🔴 Critical: #results.severityCounts.critical#");
        }
        if (results.severityCounts.high > 0) {
            print.redLine("  🟠 High: #results.severityCounts.high#");
        }
        if (results.severityCounts.medium > 0) {
            print.yellowLine("  🟡 Medium: #results.severityCounts.medium#");
        }
        if (results.severityCounts.low > 0) {
            print.greenLine("  🟢 Low: #results.severityCounts.low#");
        }
        
        print.line();
        
        // Attempt fixes if requested
        if (arguments.fix && arrayLen(results.fixableIssues)) {
            print.yellowLine("🔧 Attempting to fix #arrayLen(results.fixableIssues)# issues...")
                 .line();
            
            var fixedCount = securityService.autoFix(results.fixableIssues);
            
            if (fixedCount > 0) {
                print.greenLine("✅ Fixed #fixedCount# security issues");
            } else {
                print.yellowLine("⚠️  No issues could be automatically fixed");
            }
            
            print.line();
        }
        
        // Generate report
        var reportContent = securityService.generateReport(results, arguments.report);
        
        if (len(arguments.output)) {
            // Write to file
            fileWrite(fileSystemUtil.resolvePath(arguments.output), reportContent);
            print.greenLine("📄 Report saved to: #arguments.output#");
        } else if (arguments.report == "console") {
            // Display console report
            print.line(reportContent);
        } else {
            // Display non-console reports
            print.line("Report Output:")
                 .line("==============")
                 .line(reportContent);
        }
        
        // Set exit code if high severity issues found
        if (results.hasHighSeverity) {
            print.line()
                 .redBoldLine("❌ Security vulnerabilities found!");
            setExitCode(1);
        } else if (arrayLen(results.issues) == 0) {
            print.greenBoldLine("✅ No security issues found!");
        }
    }
}