/**
 * StyleHelper CFC: Provides consistent styling for Wheels CLI output
 **/
component {

    property name="print" inject="Print";
    
    // Initialize
    function init() {
        return this;
    }

    //=====================================================================
    //=     Headers and Titles
    //=====================================================================

    /**
     * Display a main command header
     * @text The header text
     */
    public void function commandHeader(required string text) {
        print.line();
        print.boldMagentaLine("=============================================");
        print.boldMagentaLine(" " & uCase(text));
        print.boldMagentaLine("=============================================");
        print.line();
    }

    /**
     * Display a section header
     * @text The section text
     */
    public void function sectionHeader(required string text) {
        print.line();
        print.boldCyanLine("» " & text);
        print.cyanLine(repeatString("-", len(text) + 2));
        print.line();
    }

    //=====================================================================
    //=     Status Messages
    //=====================================================================

    /**
     * Display a success message
     * @text The success message
     */
    public void function success(required string text) {
        print.boldGreenLine("✅ " & text);
    }

    /**
     * Display an error message
     * @text The error message
     */
    public void function error(required string text) {
        print.boldRedLine("❌ " & text);
    }

    /**
     * Display a warning message
     * @text The warning message
     */
    public void function warning(required string text) {
        print.boldYellowLine("⚠️ " & text);
    }

    /**
     * Display an info message
     * @text The info message
     */
    public void function info(required string text) {
        print.blueLine("ℹ️ " & text);
    }

    /**
     * Display a processing message
     * @text The processing message
     */
    public void function processing(required string text) {
        print.cyanLine("🔄 " & text);
    }

    /**
     * Display a tip message
     * @text The tip message
     */
    public void function tip(required string text) {
        print.boldWhiteLine("💡 TIP: " & text);
    }

    //=====================================================================
    //=     Progress Tracking
    //=====================================================================

    /**
     * Start a progress operation
     * @text The operation description
     * @return The operation ID for completing later
     */
    public string function startProgress(required string text) {
        local.id = createUUID();
        print.text("⏳ " & text & "... ");
        return local.id;
    }

    /**
     * Complete a progress operation
     * @id The operation ID from startProgress
     * @success Whether the operation succeeded
     */
    public void function endProgress(required string id, boolean success=true) {
        if (arguments.success) {
            print.greenLine("done");
        } else {
            print.redLine("failed");
        }
    }

    //=====================================================================
    //=     Tables and Lists
    //=====================================================================

    /**
     * Display a modern table
     * @data Array of arrays or array of structs to display
     * @headers Optional column headers
     */
    public void function table(required array data, array headers=[]) {
        if (arrayLen(arguments.data) == 0) {
            return;
        }

        // Determine if data is array of arrays or array of structs
        local.isArrayOfArrays = isArray(arguments.data[1]);
        
        // Get column count
        local.columnCount = arrayLen(arguments.headers);
        if (local.columnCount == 0) {
            if (local.isArrayOfArrays) {
                local.columnCount = arrayLen(arguments.data[1]);
            } else {
                local.columnCount = structCount(arguments.data[1]);
                // Use struct keys as headers if no headers provided
                if (arrayLen(arguments.headers) == 0) {
                    arguments.headers = structKeyArray(arguments.data[1]);
                }
            }
        }
        
        // Determine column widths
        local.columnWidths = [];
        for (local.i = 1; local.i <= local.columnCount; local.i++) {
            local.columnWidths[local.i] = len(arrayLen(arguments.headers) >= local.i ? arguments.headers[local.i] : "");
        }
        
        // Find maximum width for each column
        for (local.row in arguments.data) {
            for (local.i = 1; local.i <= local.columnCount; local.i++) {
                if (local.isArrayOfArrays) {
                    local.value = arrayLen(local.row) >= local.i ? local.row[local.i] : "";
                } else {
                    if (arrayLen(arguments.headers) >= local.i) {
                        local.key = arguments.headers[local.i];
                        local.value = structKeyExists(local.row, local.key) ? local.row[local.key] : "";
                    } else {
                        local.value = "";
                    }
                }
                local.columnWidths[local.i] = max(local.columnWidths[local.i], len(local.value));
            }
        }
        
        // Build the table
        print.line();
        
        // Top border
        local.border = "┌";
        for (local.i = 1; local.i <= local.columnCount; local.i++) {
            local.border &= repeatString("─", local.columnWidths[local.i] + 2);
            if (local.i < local.columnCount) {
                local.border &= "┬";
            }
        }
        local.border &= "┐";
        print.line(local.border);
        
        // Headers
        if (arrayLen(arguments.headers) > 0) {
            local.headerRow = "│";
            for (local.i = 1; local.i <= local.columnCount; local.i++) {
                local.header = local.i <= arrayLen(arguments.headers) ? arguments.headers[local.i] : "";
                local.headerRow &= " " & local.header & repeatString(" ", local.columnWidths[local.i] - len(local.header) + 1) & "│";
            }
            print.boldWhiteLine(local.headerRow);
            
            // Header separator
            local.separator = "├";
            for (local.i = 1; local.i <= local.columnCount; local.i++) {
                local.separator &= repeatString("─", local.columnWidths[local.i] + 2);
                if (local.i < local.columnCount) {
                    local.separator &= "┼";
                }
            }
            local.separator &= "┤";
            print.line(local.separator);
        }
        
        // Rows
        for (local.rowIndex = 1; local.rowIndex <= arrayLen(arguments.data); local.rowIndex++) {
            local.row = arguments.data[local.rowIndex];
            local.rowStr = "│";
            
            for (local.i = 1; local.i <= local.columnCount; local.i++) {
                if (local.isArrayOfArrays) {
                    local.value = arrayLen(local.row) >= local.i ? local.row[local.i] : "";
                } else {
                    if (arrayLen(arguments.headers) >= local.i) {
                        local.key = arguments.headers[local.i];
                        local.value = structKeyExists(local.row, local.key) ? local.row[local.key] : "";
                    } else {
                        local.value = "";
                    }
                }
                local.rowStr &= " " & local.value & repeatString(" ", local.columnWidths[local.i] - len(local.value) + 1) & "│";
            }
            print.line(local.rowStr);
        }
        
        // Bottom border
        local.border = "└";
        for (local.i = 1; local.i <= local.columnCount; local.i++) {
            local.border &= repeatString("─", local.columnWidths[local.i] + 2);
            if (local.i < local.columnCount) {
                local.border &= "┴";
            }
        }
        local.border &= "┘";
        print.line(local.border);
        print.line();
    }

    /**
     * Display a bullet list
     * @items Array of items to display
     * @bullets Character to use for bullets
     */
    public void function bulletList(required array items, string bullet="•") {
        print.line();
        for (local.item in arguments.items) {
            print.line("  " & arguments.bullet & " " & local.item);
        }
        print.line();
    }

    //=====================================================================
    //=     Command Help and Usage
    //=====================================================================

    /**
     * Display command usage information
     * @command Command name
     * @arguments Array of argument descriptions [{name, description, required}]
     * @options Array of option descriptions [{name, description, default}]
     * @examples Array of example usages
     */
    public void function commandUsage(
        required string command,
        array arguments=[],
        array options=[],
        array examples=[]
    ) {
        sectionHeader("USAGE");
        print.whiteLine("  " & arguments.command);
        print.line();
        
        if (arrayLen(arguments.arguments)) {
            sectionHeader("ARGUMENTS");
            for (local.arg in arguments.arguments) {
                print.whiteBoldLine("  " & local.arg.name);
                print.whiteLine("    " & local.arg.description);
                if (structKeyExists(local.arg, "required") && local.arg.required) {
                    print.yellowLine("    Required: Yes");
                }
                print.line();
            }
        }
        
        if (arrayLen(arguments.options)) {
            sectionHeader("OPTIONS");
            for (local.opt in arguments.options) {
                print.whiteBoldLine("  --" & local.opt.name);
                print.whiteLine("    " & local.opt.description);
                if (structKeyExists(local.opt, "default")) {
                    print.cyanLine("    Default: " & local.opt.default);
                }
                print.line();
            }
        }
        
        if (arrayLen(arguments.examples)) {
            sectionHeader("EXAMPLES");
            for (local.example in arguments.examples) {
                print.yellowLine("  " & local.example);
            }
            print.line();
        }
    }

    /**
     * Display a command completion summary
     * @title Summary title
     * @items Array of summary items
     * @nextSteps Array of suggested next steps
     */
    public void function completionSummary(
        required string title,
        array items=[],
        array nextSteps=[]
    ) {
        print.line();
        success(arguments.title);
        print.line();
        
        if (arrayLen(arguments.items)) {
            for (local.item in arguments.items) {
                print.whiteLine("  • " & local.item);
            }
            print.line();
        }
        
        if (arrayLen(arguments.nextSteps)) {
            print.whiteBoldLine("  Next steps:");
            for (local.step in arguments.nextSteps) {
                print.whiteLine("  • " & local.step);
            }
            print.line();
        }
    }

    /**
     * Display an error with possible solutions
     * @message Error message
     * @solutions Array of possible solutions
     * @helpUrl URL for additional help
     */
    public void function errorWithSolutions(
        required string message,
        array solutions=[],
        string helpUrl=""
    ) {
        print.line();
        error(message);
        print.line();
        
        if (arrayLen(arguments.solutions)) {
            print.whiteBoldLine("   Possible solutions:");
            for (local.solution in arguments.solutions) {
                print.whiteLine("   • " & local.solution);
            }
            print.line();
        }
        
        if (len(arguments.helpUrl)) {
            print.cyanLine("   Need help? Visit " & arguments.helpUrl);
            print.line();
        }
    }
}