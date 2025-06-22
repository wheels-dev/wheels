/**
 * Test Application Configuration for Wheels CLI
 */
component {
    this.name = "WheelsCLITests_" & hash(getCurrentTemplatePath());
    this.applicationTimeout = createTimeSpan(0, 0, 10, 0);
    this.sessionManagement = false;
    
    // Mappings
    this.mappings["/tests"] = getDirectoryFromPath(getCurrentTemplatePath());
    this.mappings["/wheelscli"] = expandPath("../");
    this.mappings["/commands"] = expandPath("../commands");
    this.mappings["/models"] = expandPath("../models");
    this.mappings["/testbox"] = expandPath("../testbox");
    
    // Custom tag paths
    this.customTagPaths = "";
    
    /**
     * Application start
     */
    function onApplicationStart() {
        // Set up test environment
        application.testMode = true;
        
        // Initialize test container
        application.testbox = new testbox.system.TestBox();
        
        // Create mock WireBox for testing
        application.wirebox = createObject("component", "tests.mocks.MockWireBox");
        
        return true;
    }
    
    /**
     * Request start
     */
    function onRequestStart(string targetPage) {
        // Ensure application is initialized
        if (!structKeyExists(application, "testbox")) {
            onApplicationStart();
        }
        
        // Set test environment variables
        request.testMode = true;
        
        return true;
    }
}