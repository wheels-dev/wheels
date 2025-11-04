/**
 * DEPRECATED: Use 'wheels security scan' instead
 * This command is maintained for backward compatibility only
 */
component extends="../base" {
    
    /**
     * @deprecated Use 'wheels security scan' instead
     */
    function run(
        string path = ".",
        boolean fix = false,
        string report = "console",
        string severity = "medium",
        boolean deep = false
    ) {
        arguments = reconstructArgs(arguments);
        print.yellowBoldLine("DEPRECATED: This command is deprecated")
             .yellowLine("Please use 'wheels security scan' instead")
             .line();
        
        // Forward to new command
        print.line("Wait Running Command 'wheels security scan'...")
        command("wheels security scan")
            .params(argumentCollection = arguments)
            .run();
    }
}