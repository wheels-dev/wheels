/**
 * Base TestBox specification for Wheels applications
 * Provides integration between TestBox and Wheels framework
 * Extends TestBox's BaseSpec with Wheels-specific functionality
 */
component extends="testbox.system.BaseSpec" {
	
	// Wheels application reference
	property name="app" inject="wirebox:Wheels";
	
	/**
	 * Run before all tests in the spec
	 */
	function beforeAll() {
		// Store original application state
		variables.originalApplication = duplicate(application);
		
		// Set testing mode
		request.isTestingMode = true;
		
		// Initialize test database if needed
		if (structKeyExists(url, "resetdb") && url.resetdb) {
			resetTestDatabase();
		}
		
		// Store original environment
		if (structKeyExists(application, "wheels")) {
			variables.originalEnvironment = application.wheels.environment;
		}
	}
	
	/**
	 * Run after all tests in the spec
	 */
	function afterAll() {
		// Restore original application state
		if (structKeyExists(variables, "originalApplication")) {
			application = variables.originalApplication;
		}
		
		// Clear testing mode
		request.isTestingMode = false;
	}
	
	/**
	 * Run around each test with transaction rollback
	 * Ensures test isolation by rolling back database changes
	 */
	function aroundEach(spec) {
		// Initialize request.wheels if it doesn't exist
		if (!structKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		
		// Start transaction
		transaction {
			try {
				// Run the spec
				arguments.spec();
			} catch (any e) {
				transaction action="rollback";
				rethrow;
			}
			// Always rollback to keep tests isolated
			transaction action="rollback";
		}
		
		// Clean up request scope
		if (structKeyExists(request, "wheels")) {
			structDelete(request.wheels, "params");
		}
	}
	
	/************************************** WHEELS HELPERS *********************************************/
	
	/**
	 * Get a controller instance
	 *
	 * @name The name of the controller (e.g., "Users", "Admin.Users")
	 * @params Optional params to set for the controller
	 */
	function controller(required string name, struct params = {}) {
		// Set params if provided
		if (!structIsEmpty(arguments.params)) {
			params(arguments.params);
		}
		
		// Return controller instance
		if (structKeyExists(application, "wo")) {
			return application.wo.controller(arguments.name);
		} else if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "dispatch")) {
			return application.wheels.dispatch.controller(arguments.name);
		} else {
			// Fallback to creating instance directly
			var controllerPath = "app.controllers.#arguments.name#";
			return createObject("component", controllerPath);
		}
	}
	
	/**
	 * Get a model instance
	 *
	 * @name The name of the model (e.g., "User", "Product")
	 */
	function model(required string name) {
		if (structKeyExists(application, "wo")) {
			return application.wo.model(arguments.name);
		} else if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "dispatch")) {
			return application.wheels.dispatch.model(arguments.name);
		} else {
			// Fallback to creating instance directly
			var modelPath = "app.models.#arguments.name#";
			return createObject("component", modelPath);
		}
	}
	
	/**
	 * Set or get request params
	 *
	 * @params Struct of params to set (optional)
	 */
	function params(struct params = {}) {
		if (!structKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		
		if (!structKeyExists(request.wheels, "params")) {
			request.wheels.params = {};
		}
		
		if (!structIsEmpty(arguments.params)) {
			structAppend(request.wheels.params, arguments.params, true);
		}
		
		return request.wheels.params;
	}
	
	/**
	 * Set or get session data
	 *
	 * @data Struct of data to set in session (optional)
	 */
	function sessionData(struct data = {}) {
		if (!structKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		
		if (!structKeyExists(request.wheels, "session")) {
			request.wheels.session = {};
		}
		
		if (!structIsEmpty(arguments.data)) {
			structAppend(request.wheels.session, arguments.data, true);
		}
		
		return request.wheels.session;
	}
	
	/************************************** AUTHENTICATION HELPERS *********************************************/
	
	/**
	 * Login as a specific user
	 *
	 * @userId The ID of the user to login as
	 */
	function loginAs(required numeric userId) {
		var user = model("User").findByKey(arguments.userId);
		
		if (!isObject(user)) {
			fail("User with ID #arguments.userId# not found");
		}
		
		// Set session user data
		var sessionUser = {
			id: user.id,
			properties: user.properties()
		};
		
		sessionData({user: sessionUser});
		
		return user;
	}
	
	/**
	 * Logout the current user
	 */
	function logout() {
		var session = sessionData();
		if (structKeyExists(session, "user")) {
			structDelete(session, "user");
		}
	}
	
	/**
	 * Check if a user is logged in
	 */
	function isLoggedIn() {
		var session = sessionData();
		return structKeyExists(session, "user") && structKeyExists(session.user, "id");
	}
	
	/************************************** REQUEST HELPERS *********************************************/
	
	/**
	 * Process a request through Wheels
	 *
	 * @route The route to process (e.g., "users", "admin.users.edit")
	 * @method The HTTP method (GET, POST, PUT, PATCH, DELETE)
	 * @params Additional params to send with the request
	 * @headers HTTP headers to set
	 */
	function processRequest(
		required string route,
		string method = "GET",
		struct params = {},
		struct headers = {}
	) {
		var result = {
			controller = "",
			output = "",
			status = 200,
			headers = {}
		};
		
		// Set up CGI scope
		if (!structKeyExists(variables, "originalCGI")) {
			variables.originalCGI = duplicate(cgi);
		}
		
		// Set request method
		cgi.request_method = arguments.method;
		
		// Set up route
		if (find("/", arguments.route)) {
			cgi.path_info = arguments.route;
		} else {
			// Convert dot notation to path
			cgi.path_info = "/" & replace(arguments.route, ".", "/", "all");
		}
		
		// Merge params into appropriate scope
		switch(arguments.method) {
			case "GET":
				structAppend(url, arguments.params, true);
				break;
			case "POST":
			case "PUT":
			case "PATCH":
			case "DELETE":
				structAppend(form, arguments.params, true);
				break;
		}
		
		// Set headers
		for (var header in arguments.headers) {
			cgi["HTTP_#uCase(replace(header, '-', '_', 'all'))#"] = arguments.headers[header];
		}
		
		// Process through Wheels
		try {
			savecontent variable="result.output" {
				if (structKeyExists(application, "wo")) {
					result.controller = application.wo.dispatch();
				} else {
					// Handle older Wheels versions
					include "/index.cfm";
				}
			}
		} catch (any e) {
			result.error = e;
			result.status = 500;
		}
		
		// Restore CGI
		cgi = variables.originalCGI;
		
		return result;
	}
	
	/**
	 * Make a JSON API request
	 *
	 * @route The API route
	 * @method The HTTP method
	 * @data The data to send (will be JSON encoded)
	 * @headers Additional headers
	 */
	function apiRequest(
		required string route,
		string method = "GET",
		struct data = {},
		struct headers = {}
	) {
		// Add JSON content type
		arguments.headers["Content-Type"] = "application/json";
		arguments.headers["Accept"] = "application/json";
		
		// Convert data to JSON if needed
		var params = {};
		if (!structIsEmpty(arguments.data)) {
			if (listFindNoCase("POST,PUT,PATCH", arguments.method)) {
				params.body = serializeJSON(arguments.data);
			} else {
				params = arguments.data;
			}
		}
		
		// Make request
		var result = processRequest(
			route = arguments.route,
			method = arguments.method,
			params = params,
			headers = arguments.headers
		);
		
		// Try to parse JSON response
		if (len(result.output)) {
			try {
				result.json = deserializeJSON(result.output);
			} catch (any e) {
				// Not JSON, leave as is
			}
		}
		
		return result;
	}
	
	/************************************** FACTORY HELPERS *********************************************/
	
	/**
	 * Create a model instance and save it to the database
	 *
	 * @factoryName The name of the factory or model
	 * @attributes Attributes to override
	 */
	function create(required string factoryName, struct attributes = {}) {
		// Check if we have a factory service
		if (structKeyExists(application, "factories")) {
			return application.factories.create(arguments.factoryName, arguments.attributes);
		}
		
		// Fallback to creating model directly
		var instance = model(arguments.factoryName).new(arguments.attributes);
		instance.save();
		return instance;
	}
	
	/**
	 * Build a model instance without saving it
	 *
	 * @factoryName The name of the factory or model
	 * @attributes Attributes to override
	 */
	function build(required string factoryName, struct attributes = {}) {
		// Check if we have a factory service
		if (structKeyExists(application, "factories")) {
			return application.factories.build(arguments.factoryName, arguments.attributes);
		}
		
		// Fallback to creating model directly
		return model(arguments.factoryName).new(arguments.attributes);
	}
	
	/**
	 * Create multiple model instances
	 *
	 * @factoryName The name of the factory or model
	 * @count Number of instances to create
	 * @attributes Attributes to override (can be array of structs for individual overrides)
	 */
	function createList(required string factoryName, required numeric count, any attributes = {}) {
		var list = [];
		
		for (var i = 1; i <= arguments.count; i++) {
			var attrs = {};
			
			if (isArray(arguments.attributes) && arrayLen(arguments.attributes) >= i) {
				attrs = arguments.attributes[i];
			} else if (isStruct(arguments.attributes)) {
				attrs = arguments.attributes;
			}
			
			arrayAppend(list, create(arguments.factoryName, attrs));
		}
		
		return list;
	}
	
	/************************************** DATABASE HELPERS *********************************************/
	
	/**
	 * Reset the test database
	 */
	function resetTestDatabase() {
		// Run migrations down then up
		if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "migrator")) {
			application.wheels.migrator.migrateToVersion(0);
			application.wheels.migrator.migrateToLatest();
		}
		
		// Seed test data if seed file exists
		var seedFile = expandPath("/tests/fixtures/seed.cfm");
		if (fileExists(seedFile)) {
			include "/tests/fixtures/seed.cfm";
		}
	}
	
	/**
	 * Execute raw SQL query
	 *
	 * @sql The SQL to execute
	 * @params Query parameters
	 * @datasource The datasource to use (defaults to Wheels datasource)
	 */
	function queryExecute(required string sql, struct params = {}, string datasource = "") {
		if (!len(arguments.datasource)) {
			if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "dataSourceName")) {
				arguments.datasource = application.wheels.dataSourceName;
			}
		}
		
		return queryExecute(arguments.sql, arguments.params, {datasource: arguments.datasource});
	}
	
	/************************************** ASSERTION HELPERS *********************************************/
	
	/**
	 * Assert that a controller redirected
	 *
	 * @controller The controller instance
	 * @to Optional: The expected redirect location
	 */
	function assertRedirected(required any controller, string to = "") {
		expect(arguments.controller).toHaveKey("redirectTo");
		
		if (len(arguments.to)) {
			expect(arguments.controller.redirectTo.url).toBe(arguments.to);
		}
	}
	
	/**
	 * Assert that a controller rendered a view
	 *
	 * @controller The controller instance
	 * @view Optional: The expected view name
	 */
	function assertRendered(required any controller, string view = "") {
		expect(arguments.controller).toHaveKey("renderView");
		
		if (len(arguments.view)) {
			expect(arguments.controller.renderView.view).toBe(arguments.view);
		}
	}
	
	/**
	 * Assert that a model has errors
	 *
	 * @model The model instance
	 * @property Optional: Check for errors on specific property
	 */
	function assertHasErrors(required any model, string property = "") {
		var errors = arguments.model.allErrors();
		expect(arrayLen(errors)).toBeGT(0);
		
		if (len(arguments.property)) {
			var hasPropertyError = false;
			for (var error in errors) {
				if (error.property == arguments.property) {
					hasPropertyError = true;
					break;
				}
			}
			expect(hasPropertyError).toBeTrue("Model should have error on property: #arguments.property#");
		}
	}
	
	/**
	 * Assert that a model has no errors
	 *
	 * @model The model instance
	 */
	function assertNoErrors(required any model) {
		var errors = arguments.model.allErrors();
		expect(arrayLen(errors)).toBe(0, "Model should have no errors but has: #serializeJSON(errors)#");
	}
}