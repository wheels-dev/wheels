/**
 * Security analysis and vulnerability scanning
 * 
 * {code:bash}
 * wheels security scan
 * wheels security scan --fix
 * {code}
 */
component extends="base" {
    
    /**
     * Display help for security commands
     */
    function run() {
        print.greenBoldLine("🔒 Wheels Security Tools")
             .line()
             .line("Available commands:")
             .line()
             .yellowLine("  wheels security scan")
             .line("    Scan for security vulnerabilities")
             .line("    Options:")
             .line("      --path=<path>      Path to scan (default: current directory)")
             .line("      --fix              Attempt to fix issues automatically")
             .line("      --report=<format>  Report format (console, json, html)")
             .line("      --severity=<level> Minimum severity (low, medium, high, critical)")
             .line("      --output=<file>    Save report to file")
             .line()
             .line("Examples:")
             .line("  wheels security scan")
             .line("  wheels security scan --fix --report=html --output=security-report.html")
             .line("  wheels security scan --path=models --severity=high")
             .line()
             .line("Common vulnerabilities detected:")
             .line("  • SQL Injection")
             .line("  • Cross-Site Scripting (XSS)")
             .line("  • Hardcoded credentials")
             .line("  • File upload vulnerabilities")
             .line("  • Directory traversal")
             .line("  • Insecure random number generation");
    }
}