component output="false" {

	// Set up minimal application for tests
	this.name = "WheelsCoreTests" & Hash(GetDirectoryFromPath(GetBaseTemplatePath()));
	this.sessionManagement = true;
	this.bufferOutput = false;
	
	// Set up paths relative to test directory
	this.testDir = GetDirectoryFromPath(GetCurrentTemplatePath());
	this.rootDir = ReReplace(this.testDir, "core[/\\]tests[/\\]?$", "");
	this.coreDir = this.rootDir & "core/";
	this.vendorDir = this.rootDir & "vendor/";
	
	// Set up mappings
	this.mappings["/wheels"] = this.coreDir & "src/wheels/";
	this.mappings["/app"] = this.testDir & "resources/app/";
	this.mappings["/vendor"] = this.vendorDir;
	this.mappings["/wirebox"] = this.vendorDir & "wirebox/";
	this.mappings["/testbox"] = this.vendorDir & "testbox/";
	this.mappings["/tests"] = this.testDir;
	this.mappings["/config"] = this.testDir & "resources/app/config/";
	
	// Initialize wheels struct
	this.wheels = {};
	this.wheels.rootPath = this.testDir;
	
	// Simple environment setup
	this.env = {};
	this.env["WHEELS_ENV"] = "testing";
	
	function onApplicationStart() {
		// Check if WireBox exists
		if (!DirectoryExists(this.vendorDir & "wirebox/")) {
			throw(message="WireBox not found. Please run 'box install' from the project root.");
		}
		
		// Initialize WireBox
		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");
		
		// Initialize Wheels
		application.wo = wirebox.getInstance("global");
		initArgs.path = "wheels";
		initArgs.filename = "onapplicationstart";
		application.wirebox.getInstance(name = "wheels.events.onapplicationstart", initArguments = initArgs).$init(this);
	}
	
	function onRequestStart() {
		// Ensure application is initialized
		if (!StructKeyExists(application, "wo")) {
			onApplicationStart();
		}
		
		// Initialize request scope
		application.wo.$initializeRequestScope();
		
		return true;
	}
	
}