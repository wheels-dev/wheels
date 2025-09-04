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
 * {code}
 **/
component aliases='wheels g test' extends="../base"  {

	/**
	 * Initialize the command
	 */
	function init() {
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
	 * @open.hint Open the created file in editor
	 **/
	function run(
		required string type,
		required string target,
		string name="",
		boolean crud=false,
		boolean mock=false,
		boolean factory=false,
		boolean open=false
	){
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

		if( fileExists( testPath ) ) {
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
		details.header("🧪", "Test Generation");
		
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
				info.path = fileSystemUtil.resolvePath("tests/specs/unit/models/#info.className#.cfc");
				break;
				
			case "controller":
				info.className = obj.objectNamePluralC & "ControllerSpec";
				info.path = fileSystemUtil.resolvePath("tests/specs/integration/controllers/#info.className#.cfc");
				break;
				
			case "view":
				info.className = lCase(arguments.name) & "ViewSpec";
				var viewDir = fileSystemUtil.resolvePath("tests/specs/unit/views/#obj.objectNamePlural#");
				if (!directoryExists(viewDir)) {
					directoryCreate(viewDir);
				}
				info.path = "#viewDir#/#info.className#.cfc";
				break;
				
			case "unit":
				info.className = obj.objectNameSingularC & "Spec";
				info.path = fileSystemUtil.resolvePath("tests/specs/unit/helpers/#info.className#.cfc");
				break;
				
			case "integration":
				info.className = obj.objectNameSingularC & "IntegrationSpec";
				info.path = fileSystemUtil.resolvePath("tests/specs/integration/workflows/#info.className#.cfc");
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
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Model", () => {' & chr(10) & chr(10);
		
		// Setup
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		if (arguments.factory) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.#obj.objectNameSingular# = build("#obj.objectNameSingular#");' & chr(10);
		} else {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.#obj.objectNameSingular# = model("#obj.objectNameSingularC#").new();' & chr(10);
		}
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		// Validations
		content &= chr(9) & chr(9) & chr(9) & 'describe("Validations", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should validate required fields", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(#obj.objectNameSingular#.valid()).toBeFalse();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add specific field validations here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		// Associations
		content &= chr(9) & chr(9) & chr(9) & 'describe("Associations", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test your model associations here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should have expected associations", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Example: expect(#obj.objectNameSingular#).toHaveMethod("posts");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		// Methods
		content &= chr(9) & chr(9) & chr(9) & 'describe("Methods", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test custom model methods here' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		// CRUD operations
		if (arguments.crud) {
			content &= chr(9) & chr(9) & chr(9) & 'describe("CRUD Operations", () => {' & chr(10);
			
			// Create
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular#", () => {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var new#obj.objectNameSingularC# = create("#obj.objectNameSingular#", {' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add test attributes' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.name = "Test #obj.objectNameSingularC#";' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(#obj.objectNameSingular#.save()).toBeTrue();' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(new#obj.objectNameSingularC#.id).toBeGT(0);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Read
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should find an existing #obj.objectNameSingular#", () => {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var created = create("#obj.objectNameSingular#");' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var created = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var found = model("#obj.objectNameSingularC#").findByKey(created.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(found).toBeInstanceOf("app.models.#obj.objectNameSingularC#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(found.id).toBe(created.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Update
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should update an existing #obj.objectNameSingular#", () => {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = create("#obj.objectNameSingular#");' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'existing.name = "Updated Name";' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(existing.save()).toBeTrue();' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var updated = model("#obj.objectNameSingularC#").findByKey(existing.id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(updated.name).toBe("Updated Name");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Delete
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should delete a #obj.objectNameSingular#", () => {' & chr(10);
			if (arguments.factory) {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = create("#obj.objectNameSingular#");' & chr(10);
			} else {
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#.save();' & chr(10);
				content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = #obj.objectNameSingular#;' & chr(10);
			}
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var id = toDelete.id;' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(toDelete.delete()).toBeTrue();' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var deleted = model("#obj.objectNameSingularC#").findByKey(id);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(deleted).toBeFalse();' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
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
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# Controller", () => {' & chr(10) & chr(10);
		
		// Setup
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.controller = controller("#obj.objectNamePluralC#");' & chr(10);
		if (arguments.mock) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Setup mocks if needed' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.mockService = createMock("app.services.#obj.objectNameSingularC#Service");' & chr(10);
		}
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		if (arguments.crud) {
			// Index action
			content &= chr(9) & chr(9) & chr(9) & 'describe("index action", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should list all #obj.objectNamePlural#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#", method="GET");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add more specific assertions' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Show action
			content &= chr(9) & chr(9) & chr(9) & 'describe("show action", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should display a specific #obj.objectNameSingular#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Create test data' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var testRecord = create("#obj.objectNameSingular#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#/" & testRecord.id, method="GET");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Create action
			content &= chr(9) & chr(9) & chr(9) & 'describe("create action", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var params = {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#: {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'name: "Test #obj.objectNameSingularC#"' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '};' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#", method="POST", params=params);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(302); // Expecting redirect on success' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Update action
			content &= chr(9) & chr(9) & chr(9) & 'describe("update action", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should update an existing #obj.objectNameSingular#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var existing = create("#obj.objectNameSingular#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var params = {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '#obj.objectNameSingular#: {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'name: "Updated Name"' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '};' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#/#existing.id#", method="PATCH", params=params);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(302);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// Delete action
			content &= chr(9) & chr(9) & chr(9) & 'describe("delete action", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should delete a #obj.objectNameSingular#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var toDelete = create("#obj.objectNameSingular#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#/#toDelete.id#", method="DELETE");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(302);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		} else {
			// Basic controller test
			content &= chr(9) & chr(9) & chr(9) & 'describe("controller actions", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should respond to requests", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Add your controller action tests here' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		}
		
		// Authorization tests
		content &= chr(10) & chr(9) & chr(9) & chr(9) & 'describe("Authorization", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should require authentication", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'logout(); // Ensure no user is logged in' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = processRequest(route="#obj.objectNamePlural#", method="GET");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Assert redirect to login or 401 status' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
	
	/**
	 * Generate view test
	 */
	private function generateViewTest(required struct obj, required string viewName) {
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# #viewName# View", () => {' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Setup test data for view' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'it("should render without errors", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test view rendering' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'var output = renderView(view="#obj.objectNamePlural#/#viewName#");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'expect(output).toInclude("expected content");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'it("should display required elements", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Test for specific HTML elements' & chr(10);
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
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Unit Tests", () => {' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.service = new app.services.#obj.objectNameSingularC#Service();' & chr(10);
		
		if (arguments.mock) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Setup mocks' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.mockRepository = createMock("app.models.#obj.objectNameSingularC#");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'service.setRepository(mockRepository);' & chr(10);
		}
		
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'describe("Business Logic", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should perform expected calculations", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Test your service methods' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'describe("Error Handling", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should handle invalid input gracefully", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'service.process(null);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '}).toThrow();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		
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
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNameSingularC# Integration Test", () => {' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Setup test data and environment' & chr(10);
		if (arguments.factory) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Create test users, permissions, etc.' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.testUser = create("user", {role: "admin"});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'loginAs(testUser.id);' & chr(10);
		}
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'afterEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'logout();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'describe("End-to-End Workflow", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should complete the full #obj.objectNameSingular# workflow", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Test complete user journey' & chr(10);
		
		if (arguments.crud) {
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// 1. Create' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var createResult = processRequest(' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'route = "#obj.objectNamePlural#",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'method = "POST",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'params = {#obj.objectNameSingular#: {name: "Integration Test"}}' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & ');' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(createResult.status).toBe(302);' & chr(10) & chr(10);
			
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// 2. Verify creation' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var listResult = processRequest(route="#obj.objectNamePlural#", method="GET");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(listResult.output).toInclude("Integration Test");' & chr(10) & chr(10);
			
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// 3. Update' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// ... more workflow steps' & chr(10);
		}
		
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'describe("Performance", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should complete operations within acceptable time", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var startTime = getTickCount();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// Perform operations' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var endTime = getTickCount();' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(endTime - startTime).toBeLT(1000); // Less than 1 second' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
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
		var content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		content &= chr(9) & 'function run() {' & chr(10) & chr(10);
		content &= chr(9) & chr(9) & 'describe("#obj.objectNamePluralC# API", () => {' & chr(10) & chr(10);
		
		content &= chr(9) & chr(9) & chr(9) & 'beforeEach(() => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '// Setup API authentication' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.apiKey = create("apiKey");' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'variables.headers = {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '"Authorization": "Bearer #apiKey.token#",' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '"Content-Type": "application/json"' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '};' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
		
		if (arguments.crud) {
			// GET /api/resources
			content &= chr(9) & chr(9) & chr(9) & 'describe("GET /api/#obj.objectNamePlural#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should return paginated #obj.objectNamePlural#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = apiRequest(' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'route = "api/#obj.objectNamePlural#",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'method = "GET",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'headers = variables.headers' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & ');' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(200);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.json).toHaveKey("data");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.json.data).toBeArray();' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10) & chr(10);
			
			// POST /api/resources
			content &= chr(9) & chr(9) & chr(9) & 'describe("POST /api/#obj.objectNamePlural#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should create a new #obj.objectNameSingular#", () => {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var data = {' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'name: "API Test #obj.objectNameSingularC#"' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '};' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = apiRequest(' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'route = "api/#obj.objectNamePlural#",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'method = "POST",' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'data = data,' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'headers = variables.headers' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & ');' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(201);' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.json.data).toHaveKey("id");' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
			content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		}
		
		// Error handling
		content &= chr(10) & chr(9) & chr(9) & chr(9) & 'describe("Error Handling", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & 'it("should return 401 for unauthorized requests", () => {' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'var result = apiRequest(' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'route = "api/#obj.objectNamePlural#",' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'method = "GET"' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '// No auth headers' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & ');' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & 'expect(result.status).toBe(401);' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & chr(9) & chr(9) & '});' & chr(10);
		
		content &= chr(9) & chr(9) & '});' & chr(10);
		content &= chr(9) & '}' & chr(10);
		content &= '}' & chr(10);
		
		return content;
	}
	
	/**
	 * Open a file path in the default editor
	 */
	private function openPath(required string path) {
		if (shell.isWindows()) {
			runCommand("start #arguments.path#");
		} else if (shell.isMac()) {
			runCommand("open #arguments.path#");
		} else {
			runCommand("xdg-open #arguments.path#");
		}
	}
}