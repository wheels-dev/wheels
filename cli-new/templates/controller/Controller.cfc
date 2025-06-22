/**
 * @CONTROLLER_NAME@ Controller
 * Generated: @TIMESTAMP@
 * Generator: @GENERATED_BY@
 */
component extends="Controller" {
    
    function config() {
        // Controller configuration
        
        // Filters
        // filters(through="authenticate", except="");
        
        // Verification
        // verifies(except="index,show", params="key", paramsTypes="integer", handler="objectNotFound");
        
        // Response formats
        // provides("html,json,xml");
    }
    
@CONTROLLER_ACTIONS@
    
    /**
     * Handle object not found errors
     */
    private function objectNotFound() {
        renderView(template="/404");
    }
}