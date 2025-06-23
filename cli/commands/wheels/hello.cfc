/**
 * Simple test command
 * @help A simple test command to verify CLI is working
 */
component extends="base" excludeFromHelp=false {
    
    // This is a test command with a run method
    function run() {
        print.line("Hello from Wheels CLI!");
    }
    
}