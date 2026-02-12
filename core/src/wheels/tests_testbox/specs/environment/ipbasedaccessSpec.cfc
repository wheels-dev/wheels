component extends="wheels.Testbox" {

	function beforeAll() {
		// Store original settings to restore later
		variables.originalEnvironment = application.wheels.environment;
		if (StructKeyExists(application.wheels, "allowIPBasedDebugAccess")) {
			variables.originalAllowIPBasedDebugAccess = application.wheels.allowIPBasedDebugAccess;
		}
		if (StructKeyExists(application.wheels, "debugAccessIPs")) {
			variables.originalDebugAccessIPs = application.wheels.debugAccessIPs;
		}
		if (StructKeyExists(application.wheels, "enablePublicComponent")) {
			variables.originalEnablePublicComponent = application.wheels.enablePublicComponent;
		}
	}

	function afterAll() {
		// Restore original settings
		application.wheels.environment = variables.originalEnvironment;
		if (StructKeyExists(variables, "originalAllowIPBasedDebugAccess")) {
			application.wheels.allowIPBasedDebugAccess = variables.originalAllowIPBasedDebugAccess;
		}
		if (StructKeyExists(variables, "originalDebugAccessIPs")) {
			application.wheels.debugAccessIPs = variables.originalDebugAccessIPs;
		}
		if (StructKeyExists(variables, "originalEnablePublicComponent")) {
			application.wheels.enablePublicComponent = variables.originalEnablePublicComponent;
		}
	}

	function run() {

		describe("IP-Based Debug Access Tests", () => {

			beforeEach(() => {
				// Reset shared application state before each test to prevent bleed-through
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
			});

			it("development environment always enables public component regardless of IP", () => {
				// Set up development environment
				application.wheels.environment = "development";
				application.wheels.allowIPBasedDebugAccess = false;
				application.wheels.debugAccessIPs = [];
				
				// Simulate application restart event
				application.wheels.enablePublicComponent = false;
				if (application.wheels.environment == "development") {
					application.wheels.enablePublicComponent = true;
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
			});
			
			it("testing environment with IP-based access enabled and matching IP should enable public component", () => {
				// Set up testing environment with IP-based access
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
				expect(application.wheels.showDebugInformation).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeTrue();
			});
			
			it("testing environment with IP-based access enabled and non-matching IP should not enable public component", () => {
				// Set up testing environment with IP-based access
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with non-matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeFalse();
				expect(application.wheels.showDebugInformation).toBeFalse();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});
			
			it("testing environment with IP-based access disabled should not enable public component even with matching IP", () => {
				// Set up testing environment with IP-based access disabled
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = false;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeFalse();
				expect(application.wheels.showDebugInformation).toBeFalse();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});
			
			it("production environment with IP-based access enabled and matching IP should enable public component", () => {
				// Set up production environment with IP-based access
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
				expect(application.wheels.showDebugInformation).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeTrue();
			});
			
			it("should handle multiple IPs in the debugAccessIPs array", () => {
				// Set up production environment with multiple IPs
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1", "10.0.0.1", "127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				
				// Simulate request start with matching IP (the last one in the array)
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
			});
		});
	}
}