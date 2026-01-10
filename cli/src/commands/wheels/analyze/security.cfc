/**
 * DEPRECATED: Use 'wheels security scan' instead
 * This command is maintained for backward compatibility only
 */
component extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

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
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(arguments);
        print.yellowLine("DEPRECATED: This command is deprecated").toConsole();
        print.yellowLine("Please use 'wheels security scan' instead").toConsole();
        detailOutput.line();

        // Forward to new command
        detailOutput.output("Wait Running Command 'wheels security scan'...");
        command("wheels security scan")
            .params(argumentCollection = arguments)
            .run();
    }
}