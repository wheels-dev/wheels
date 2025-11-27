/**
 * Generate test files for Wheels applications using TestBox BDD syntax
 *
 * Examples:
 * {code:bash}
 * wheels generate test model user
 * wheels generate test controller users
 * wheels generate test view users edit
 * wheels generate test unit UserService --open
 * wheels generate test integration UserWorkflow --crud
 * wheels generate test api v1.users --mock
 * wheels generate test model user --force
 * {code}
 **/
component aliases='wheels g test' extends="../base"  {

	/**
	 * Initialize the command
	 */
	function init() {
		super.init();
		return this;
	}

	/**
	 * @type.hint Type of test: model, controller, view, unit, integration, api
	 * @type.options model,controller,view,unit,integration,api
	 * @target.hint Name of object/class to test
	 * @name.hint Name of the action/view (for view tests)
	 * @crud.hint Generate CRUD test methods
	 * @mock.hint Generate mock objects and stubs
	 * @factory.hint Generate factory examples
	 * @force.hint Overwrite existing files without asking
	 * @open.hint Open the created file in editor
	 **/
	function run(
		required string type,
		required string target,
		string name="",
		boolean crud=false,
		boolean mock=false,
		boolean factory=false,
		boolean force=false,
		boolean open=false
	){
        requireWheelsApp(getCWD());
		arguments = reconstructArgs(
			argStruct=arguments,
			allowedValues={
				type: ["model", "controller", "view", "unit", "integration", "api"]
			}
		);

		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
		
		var obj = helpers.getNameVariants(listLast( arguments.target, '/\' ));
		var testsdirectory = fileSystemUtil.resolvePath( "tests/specs" );

		// Validate directories
		if( !directoryExists( testsdirectory ) ) {
			// Try legacy directory
			testsdirectory = fileSystemUtil.resolvePath( "tests" );
			if( !directoryExists( testsdirectory ) ) {
				error( "Tests directory not found. Are you running this from your site root?" );
			}
		}
		
		if( arguments.type == "view" && !len(arguments.name)){
			error( "If creating a view test, we need to know the name of the view as well as the target");
		}

		// Determine test directory and name based on type
		var testInfo = determineTestInfo(arguments.type, obj, arguments.name);
		var testPath = testInfo.path;
		
		// Create directory if it doesn't exist
		if (!directoryExists(getDirectoryFromPath(testPath))) {
			directoryCreate(getDirectoryFromPath(testPath));
		}

		if( fileExists( testPath ) && !arguments.force ) {
			if( !confirm( "[#testPath#] already exists. Overwrite? [y/n]" ) ){
				details.skip(testPath & " (cancelled by user)");
				return;
			}
		}

		// Copy template files to the application folder if they do not exist there
		ensureSnippetTemplatesExist();
		
		// Get test content - enhanced with CRUD, mock, and factory options
		var testContent = generateTestContent(
			type = arguments.type, 
			obj = obj, 
			crud = arguments.crud, 
			mock = arguments.mock,
			factory = arguments.factory,
			name = arguments.name
		);
		
		// Output detail header
		details.header("Test Generation");
		
		file action='write' file='#testPath#' mode ='777' output='#trim( testContent )#';
		details.create(testPath);
		
		if (arguments.open) {
			openPath(testPath);
		}
		
		details.success("Test created successfully!");
		
		// Suggest next steps
		var nextSteps = [];
		arrayAppend(nextSteps, "Run your test with: box testbox run --testBundles=#listLast(testPath, '/')#");
		arrayAppend(nextSteps, "Run all tests with: box testbox run");
		if (!arguments.open) {
			arrayAppend(nextSteps, "Open the test file: #testPath#");
		}
		if (arguments.type == "model" && !arguments.factory) {
			arrayAppend(nextSteps, "Add factory support with: wheels g test model #arguments.target# --factory");
		}
		arrayAppend(nextSteps, "Add more test cases to cover edge cases and error conditions");
		details.nextSteps(nextSteps);
	}
	
	/**
	 * Determine test info based on type
	 */
	private struct function determineTestInfo(
		required string type,
		required struct obj,
		string name = ""
	) {
		var info = {
			path = "",
			className = ""
		};
		
		switch(arguments.type) {
			case "model":
				info.className = obj.objectNameSingularC & "Spec";
				info.path = fileSystemUtil.resolvePath("tests/specs/models/#info.className#.cfc");
				break;
				
			case "controller":
				info.className = obj.objectNamePluralC & "ControllerSpec";
				info.path = fileSystemUtil.resolvePath("tests/specs/controllers/#info.className#.cfc");
				break;
				
			case "view":
				info.className = lCase(arguments.name) & "ViewSpec";
				var viewDir = fileSystemUtil.resolvePath("tests/specs/views/#obj.objectNamePlural#");
				if (!directoryExists(viewDir)) {
					directoryCreate(viewDir);
				}
				info.path = "#viewDir#/#info.className#.cfc";
				break;
				
			case "unit":
				info.className = obj.objectNameSingularC & "Spec";
				info.path = fileSystemUtil.resolvePath("tests/specs/unit/#info.className#.cfc");
				break;
				
			case "integration":
				info.className = obj.objectNameSingularC & "IntegrationSpec";
				info.path = fileSystemUtil.resolvePath("tests/specs/integration/#info.className#.cfc");
				break;
				
			case "api":
				info.className = obj.objectNamePluralC & "APISpec";
				var apiDir = fileSystemUtil.resolvePath("tests/specs/integration/api");
				if (!directoryExists(apiDir)) {
					directoryCreate(apiDir);
				}
				info.path = "#apiDir#/#info.className#.cfc";
				break;
				
			default:
				throw(type="InvalidTestType", message="Unknown type: should be one of model/controller/view/unit/integration/api");
		}
		
		return info;
	}
	
	/**
	 * Generate enhanced test content based on type and options
	 */
	private function generateTestContent(
		required string type,
		required struct obj,
		boolean crud = false,
		boolean mock = false,
		boolean factory = false,
		string name = ""
	) {
		var content = "";
		
		switch(arguments.type) {
			case "model":
				content = generateModelTest(arguments.obj, arguments.crud, arguments.factory);
				break;
				
			case "controller":
				content = generateControllerTest(arguments.obj, arguments.crud, arguments.mock);
				break;
				
			case "view":
				content = generateViewTest(arguments.obj, arguments.name);
				break;
				
			case "unit":
				content = generateUnitTest(arguments.obj, arguments.mock);
				break;
				
			case "integration":
				content = generateIntegrationTest(arguments.obj, arguments.crud, arguments.factory);
				break;
				
			case "api":
				content = generateAPITest(arguments.obj, arguments.crud, arguments.mock);
				break;
		}
		
		return content;
	}
	
	/**
	 * Generate model test with TestBox BDD syntax
	 */
	private function generateModelTest(
		required struct obj,
		boolean crud = false,
		boolean factory = false
	) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Model", function() {' & chr(10) & chr(10);

		// Setup
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(function() {' & chr(10);
		if (arguments.factory) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Factory pattern: create reusable test data with sensible defaults' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.#obj.objectNameSingular# = model("#obj.objectNameSingularC#").new({' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add default test attributes here' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		} else {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.#obj.objectNameSingular# = model("#obj.objectNameSingularC#").new();' & chr(10);
		}
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		// Basic validation test
		content &= chr(9) & chr(9) & chr(9) & 'it("should validate required fields", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(#obj.objectNameSingular#.valid()).toBe(false);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Add specific field validations here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		// Association test
		content &= chr(9) & chr(9) & chr(9) & 'it("should have expected associations", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test your model associations here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Example: expect(isObject(#obj.objectNameSingular#)).toBe(true);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		// Custom method test placeholder
		content &= chr(9) & chr(9) & chr(9) & 'it("should test custom model methods", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test custom model methods here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		// CRUD operations
		if (arguments.crud) {
			// Create
			content &= chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular#", function() {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var new#obj.objectNameSingularC# = model("#obj.objectNameSingularC#").create({' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.name = "Test #obj.objectNameSingularC#";' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(#obj.objectNameSingular#.save()).toBe(true);' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var new#obj.objectNameSingularC# = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(new#obj.objectNameSingularC#.id).toBeGT(0);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Read
			content &= chr(9) & chr(9) & chr(9) & 'it("should find an existing #obj.objectNameSingular#", function() {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var created = model("#obj.objectNameSingularC#").create({' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var created = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var found = model("#obj.objectNameSingularC#").findByKey(created.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(isObject(found)).toBe(true);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(found.id).toBe(created.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Update
			content &= chr(9) & chr(9) & chr(9) & 'it("should update an existing #obj.objectNameSingular#", function() {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = model("#obj.objectNameSingularC#").create({' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'existing.name = "Updated Name";' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(existing.save()).toBe(true);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var updated = model("#obj.objectNameSingularC#").findByKey(existing.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(updated.name).toBe("Updated Name");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Delete
			content &= chr(9) & chr(9) & chr(9) & 'it("should delete a #obj.objectNameSingular#", function() {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = model("#obj.objectNameSingularC#").create({' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var id = toDelete.id;' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(toDelete.delete()).toBe(true);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var deleted = model("#obj.objectNameSingularC#").findByKey(id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(isObject(deleted)).toBe(false);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		}
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
	
	/**
	 * Generate controller test with TestBox BDD syntax
	 */
	private function generateControllerTest(
		required struct obj,
		boolean crud = false,
		boolean mock = false
	) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function beforeAll() {' & chr(10);
		content &= chr(9) & chr(9) & 'variables.baseUrl = "http://localhost:8080";' & chr(10);
		content &= chr(9) & '}' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# Controller", function() {' & chr(10) & chr(10);
		
		if (arguments.crud) {
			// Index action
			content &= chr(9) & chr(9) & chr(9) & 'it("should list all #obj.objectNamePlural# (index action)", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "response");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.filecontent).toInclude("#obj.objectNamePluralC#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Show action
			content &= chr(9) & chr(9) & chr(9) & 'it("should display a specific #obj.objectNameSingular# (show action)", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Create test data' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var testRecord = model("#obj.objectNameSingularC#").create({' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#/" & testRecord.id, method = "GET", result = "response");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Create action
			content &= chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular# (create action)", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "POST", result = "response") {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "formfield", name = "#obj.objectNameSingular#[name]", value = "Test #obj.objectNameSingularC#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add more form fields as needed' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(302); // Redirect on success' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Update action
			content &= chr(9) & chr(9) & chr(9) & 'it("should update an existing #obj.objectNameSingular# (update action)", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = model("#obj.objectNameSingularC#").create({' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#/" & existing.id, method = "PUT", result = "response") {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "formfield", name = "#obj.objectNameSingular#[name]", value = "Updated Name");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add more form fields as needed' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(302);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// Delete action
			content &= chr(9) & chr(9) & chr(9) & 'it("should delete a #obj.objectNameSingular#", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = model("#obj.objectNameSingularC#").create({' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#/" & toDelete.id, method = "DELETE", result = "response");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(302);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		} else {
			// Basic controller test
			content &= chr(9) & chr(9) & chr(9) & 'it("should respond to index request", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "response");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Add more specific assertions for your controller actions' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		}
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
	
	/**
	 * Generate view test
	 */
	private function generateViewTest(required struct obj, required string viewName) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function beforeAll() {' & chr(10);
		content &= chr(9) & chr(9) & 'variables.baseUrl = "http://localhost:8080";' & chr(10);
		content &= chr(9) & '}' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# #viewName# View", function() {' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should render #viewName# view without errors", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test view rendering via HTTP request' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#/#viewName#", method = "GET", result = "response");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.filecontent).toInclude("#obj.objectNamePluralC#");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should display required HTML elements", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#/#viewName#", method = "GET", result = "response");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Add specific HTML element assertions' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(response.filecontent).toInclude("<form");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(response.filecontent).toInclude("<input");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);

		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);

		return content;
	}
	
	/**
	 * Generate unit test
	 */
	private function generateUnitTest(required struct obj, boolean mock = false) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Unit Tests", function() {' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should test #obj.objectNameSingular# functionality", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Create your service/component to test' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// var service = new app.lib.#obj.objectNameSingularC#Service();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test your service methods here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(service.someMethod()).toBe(expectedValue);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should handle edge cases", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test edge cases like empty strings, null values, etc.' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(someFunction("")).toBe(expectedValue);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should handle errors gracefully", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test error handling' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '//     someFunction(invalidInput);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// }).toThrow();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);

		if (arguments.mock) {
			content &= chr(10) & chr(9) & chr(9) & chr(9) & 'it("should work with mocked dependencies", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Example of using MockBox for mocking' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// var mockDependency = createMock("app.lib.DependencyService");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// mockDependency.$("someMethod").$results("mocked value");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test with mocked dependency' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		}

		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);

		return content;
	}
	
	/**
	 * Generate integration test
	 */
	private function generateIntegrationTest(
		required struct obj,
		boolean crud = false,
		boolean factory = false
	) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function beforeAll() {' & chr(10);
		content &= chr(9) & chr(9) & 'variables.baseUrl = "http://localhost:8080";' & chr(10);
		content &= chr(9) & '}' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Integration Test", function() {' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should complete the full #obj.objectNameSingular# workflow", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test complete user journey using HTTP requests' & chr(10);

		if (arguments.crud) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// 1. Visit listing page' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "listResponse");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(listResponse.status_code).toBe(200);' & chr(10) & chr(10);

			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// 2. Create new record' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "POST", result = "createResponse") {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "formfield", name = "#obj.objectNameSingular#[name]", value = "Integration Test");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(createResponse.status_code).toBe(302); // Redirect on success' & chr(10) & chr(10);

			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// 3. Verify listing shows new record' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "verifyResponse");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(verifyResponse.filecontent).toInclude("Integration Test");' & chr(10) & chr(10);

			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// 4. Add more workflow steps (update, delete, etc.)' & chr(10);
		} else {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Add your integration workflow tests here' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "response");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
		}
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

		content &= chr(9) & chr(9) & chr(9) & 'it("should complete operations within acceptable time", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var startTime = getTickCount();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.baseUrl##/#obj.objectNamePlural#", method = "GET", result = "response");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var endTime = getTickCount();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var executionTime = endTime - startTime;' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(executionTime).toBeLT(5000, "Request should complete in under 5 seconds");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
	
	/**
	 * Generate API test
	 */
	private function generateAPITest(
		required struct obj,
		boolean crud = false,
		boolean mock = false
	) {
		var content = 'component extends="wheels.Testbox" {' & chr(10) & chr(10);
		content &= chr(9) & 'function beforeAll() {' & chr(10);
		content &= chr(9) & chr(9) & 'variables.apiUrl = "http://localhost:8080/api";' & chr(10);
		content &= chr(9) & '}' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# API", function() {' & chr(10) & chr(10);

		if (arguments.crud) {
			// GET /api/resources
			content &= chr(9) & chr(9) & chr(9) & 'it("should return paginated #obj.objectNamePlural# via GET", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.apiUrl##/#obj.objectNamePlural#", method = "GET", result = "response") {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "header", name = "Accept", value = "application/json");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add authentication header if needed' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// cfhttpparam(type = "header", name = "Authorization", value = "Bearer TOKEN");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var jsonData = deserializeJSON(response.filecontent);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(jsonData).toHaveKey("data");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(isArray(jsonData.data)).toBe(true);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);

			// POST /api/resources
			content &= chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular# via POST", function() {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var postData = {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'name = "API Test #obj.objectNameSingularC#"' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '};' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.apiUrl##/#obj.objectNamePlural#", method = "POST", result = "response") {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "header", name = "Content-Type", value = "application/json");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttpparam(type = "body", value = serializeJSON(postData));' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(response.status_code).toBe(201);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var jsonData = deserializeJSON(response.filecontent);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(jsonData.data).toHaveKey("id");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		}

		// Error handling
		content &= chr(10) & chr(9) & chr(9) & chr(9) & 'it("should return 401 for unauthorized requests", function() {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test without authentication header' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'cfhttp(url = "##variables.apiUrl##/#obj.objectNamePlural#", method = "GET", result = "response");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// expect(response.status_code).toBe(401);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Add your authentication tests here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
}