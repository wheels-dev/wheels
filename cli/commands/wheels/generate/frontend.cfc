/**
 * Scaffold and integrate modern frontend frameworks with Wheels
 * 
 * {code:bash}
 * wheels generate frontend --framework=react
 * wheels generate frontend --framework=vue
 * wheels generate frontend --framework=alpine
 * {code}
 */
component extends="../base" {

    /**
     * Initialize the command
     */
    function init() {
        super.init();
        variables.rails = application.wirebox.getInstance("RailsOutputService");
        return this;
    }

    /**
     * @framework Frontend framework to use (react, vue, alpine)
     * @path Directory to install frontend (defaults to /app/assets/frontend)
     * @api Generate API endpoint for frontend
     */
    function run(
        required string framework,
        string path="app/assets/frontend",
        boolean api=false
    ) {
        // Output Rails-style header
        rails.header("🌐", "Frontend Generation");
        
        rails.error("This feature is currently under development");
    }
}