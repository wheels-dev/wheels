/**
 * Generate test files for Wheels applications
 *
 * Examples:
 * {code:bash}
 * wheels generate test model user
 * wheels generate test controller users
 * wheels generate test view users edit
 * wheels generate test unit UserService --open
 * wheels generate test integration UserController --crud
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
	 * @type.hint Type of test: model, controller, view, unit, integration
	 * @type.options model,controller,view,unit,integration
	 * @target.hint Name of object/class to test
	 * @name.hint Name of the action/view (for view tests)
	 * @crud.hint Generate CRUD test methods
	 * @mock.hint Generate mock objects
	 * @open.hint Open the created file in editor
	 **/
	function run(
		required string type,
		required string target,
		string name="",
		boolean crud=false,
		boolean mock=false,
		boolean open=false
	){
		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
		
		var obj = helpers.getNameVariants(listLast( arguments.target, '/\' ));
		var testsdirectory = fileSystemUtil.resolvePath( "tests/Testbox/specs" );

		// Validate directories
		if( !directoryExists( testsdirectory ) ) {
			error( "[#testsdirectory#] can't be found. Are you running this from your site root?" );
 		}
 		if( arguments.type == "view" && !len(arguments.name)){
 			error( "If creating a view, we need to know the name of the view as well as the target");
 		}

 		// Handle type
 		switch(arguments.type){
 			case "model":
 				var testName=obj.objectNameSingularC & ".cfc";
 				var testPath=fileSystemUtil.resolvePath("tests/Testbox/specs/models/#testName#");
 				if( !directoryExists(fileSystemUtil.resolvePath("tests/Testbox/specs/models"))){
 					directoryCreate(fileSystemUtil.resolvePath("tests/Testbox/specs/models"));
 				}
 			break;
 			case "controller":
 				var testName=obj.objectNamePluralC & ".cfc";
 				var testPath=fileSystemUtil.resolvePath("tests/Testbox/specs/controllers/#testName#");
 				if( !directoryExists(fileSystemUtil.resolvePath("tests/Testbox/specs/controllers"))){
 					directoryCreate(fileSystemUtil.resolvePath("tests/Testbox/specs/controllers"));
 				}
 			break;
 			case "view":
 				var testObjPath=fileSystemUtil.resolvePath("tests/Testbox/specs/views/#obj.objectNamePlural#");
 				var testName=obj.objectNamePlural & '/' &  lcase(arguments.name) & ".cfc";
 				var testPath=fileSystemUtil.resolvePath("tests/Testbox/specs/views/#testName#");
 				if( !directoryExists(fileSystemUtil.resolvePath("tests/Testbox/specs/views/#obj.objectNamePlural#"))){
 					directoryCreate(testObjPath);
 				}
 			break;
 			case "unit":
 				var testName=obj.objectNameSingularC & "Test.cfc";
 				var testPath=fileSystemUtil.resolvePath("tests/Testbox/specs/unit/#testName#");
 				if( !directoryExists(fileSystemUtil.resolvePath("tests/Testbox/specs/unit"))){
 					directoryCreate(fileSystemUtil.resolvePath("tests/Testbox/specs/unit"));
 				}
 			break;
 			case "integration":
 				var testName=obj.objectNameSingularC & "Test.cfc";
 				var testPath=fileSystemUtil.resolvePath("tests/Testbox/specs/integration/#testName#");
 				if( !directoryExists(fileSystemUtil.resolvePath("tests/Testbox/specs/integration"))){
 					directoryCreate(fileSystemUtil.resolvePath("tests/Testbox/specs/integration"));
 				}
 			break;
 			default:
 				error("Unknown type: should be one of model/controller/view/unit/integration");
 			break;
 		}

 		if( fileExists( testPath ) ) {
			if( !confirm( "[#testPath#] already exists. Overwrite? [y/n]" ) ){
				details.skip(testPath & " (cancelled by user)");
				return;
			}
 		}

		// Copy template files to the application folder if they do not exist there
		ensureSnippetTemplatesExist();
		
		// Get test content - enhanced with CRUD and mock options
		var testContent = generateTestContent(arguments.type, obj, arguments.crud, arguments.mock);
		
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
		arrayAppend(nextSteps, "Run your test with: wheels test run --filter=#obj.objectNameSingular#");
		if (!arguments.open) {
			arrayAppend(nextSteps, "Open the test file: #testPath#");
		}
		arrayAppend(nextSteps, "Add more test cases to cover edge cases");
		details.nextSteps(nextSteps);
	}
	
	/**
	 * Generate enhanced test content based on type and options
	 */
	private function generateTestContent(
		required string type,
		required struct obj,
		boolean crud = false,
		boolean mock = false
	) {
		var templatePath = "";
		
		// Check if enhanced template exists
		if (arguments.crud && fileExists(fileSystemUtil.resolvePath("app/snippets/tests/#arguments.type#-crud.txt"))) {
			templatePath = fileSystemUtil.resolvePath("app/snippets/tests/#arguments.type#-crud.txt");
		} else if (fileExists(fileSystemUtil.resolvePath("app/snippets/tests/#arguments.type#.txt"))) {
			templatePath = fileSystemUtil.resolvePath("app/snippets/tests/#arguments.type#.txt");
		} else {
			// Generate default content if no template exists
			return generateDefaultTestContent(arguments.type, arguments.obj, arguments.crud, arguments.mock);
		}
		
		var content = fileRead(templatePath);
		content = $replaceDefaultObjectNames(content, arguments.obj);
		
		// Add mock setup if requested
		if (arguments.mock) {
			content = addMockSetup(content, arguments.obj);
		}
		
		return content;
	}
	
	/**
	 * Generate default test content when no template exists
	 */
	private function generateDefaultTestContent(
		required string type,
		required struct obj,
		boolean crud = false,
		boolean mock = false
	) {
		var content = "component extends=""testbox.system.BaseSpec"" {" & chr(10) & chr(10);
		content &= "    function run() {" & chr(10);
		content &= "        describe(""#obj.objectNameSingularC# #arguments.type# Tests"", function() {" & chr(10);
		
		if (arguments.type == "model" && arguments.crud) {
			content &= generateModelCrudTests(arguments.obj);
		} else if (arguments.type == "controller" && arguments.crud) {
			content &= generateControllerCrudTests(arguments.obj);
		} else {
			content &= "            it(""should run a basic test"", function() {" & chr(10);
			content &= "                expect(true).toBeTrue();" & chr(10);
			content &= "            });" & chr(10);
		}
		
		content &= "        });" & chr(10);
		content &= "    }" & chr(10);
		content &= "}" & chr(10);
		
		return content;
	}
	
	/**
	 * Generate CRUD tests for models
	 */
	private function generateModelCrudTests(required struct obj) {
		var tests = "";
		tests &= "            beforeEach(function() {" & chr(10);
		tests &= "                variables.#obj.objectNameSingular# = model(""#obj.objectNameSingular#"").new();" & chr(10);
		tests &= "            });" & chr(10) & chr(10);
		
		tests &= "            it(""should create a new #obj.objectNameSingular#"", function() {" & chr(10);
		tests &= "                variables.#obj.objectNameSingular#.name = ""Test #obj.objectNameSingular#"";" & chr(10);
		tests &= "                expect(variables.#obj.objectNameSingular#.save()).toBeTrue();" & chr(10);
		tests &= "            });" & chr(10) & chr(10);
		
		tests &= "            it(""should update an existing #obj.objectNameSingular#"", function() {" & chr(10);
		tests &= "                variables.#obj.objectNameSingular#.name = ""Updated #obj.objectNameSingular#"";" & chr(10);
		tests &= "                expect(variables.#obj.objectNameSingular#.save()).toBeTrue();" & chr(10);
		tests &= "            });" & chr(10) & chr(10);
		
		tests &= "            it(""should delete a #obj.objectNameSingular#"", function() {" & chr(10);
		tests &= "                variables.#obj.objectNameSingular#.save();" & chr(10);
		tests &= "                expect(variables.#obj.objectNameSingular#.delete()).toBeTrue();" & chr(10);
		tests &= "            });" & chr(10);
		
		return tests;
	}
	
	/**
	 * Generate CRUD tests for controllers
	 */
	private function generateControllerCrudTests(required struct obj) {
		var tests = "";
		tests &= "            beforeEach(function() {" & chr(10);
		tests &= "                variables.controller = controller(""#obj.objectNamePlural#"");" & chr(10);
		tests &= "            });" & chr(10) & chr(10);
		
		tests &= "            it(""should display index page"", function() {" & chr(10);
		tests &= "                var result = variables.controller.index();" & chr(10);
		tests &= "                expect(result).toBeStruct();" & chr(10);
		tests &= "            });" & chr(10) & chr(10);
		
		tests &= "            it(""should create a new #obj.objectNameSingular#"", function() {" & chr(10);
		tests &= "                params.#obj.objectNameSingular# = { name = ""Test"" };" & chr(10);
		tests &= "                var result = variables.controller.create();" & chr(10);
		tests &= "                expect(result).toBeStruct();" & chr(10);
		tests &= "            });" & chr(10);
		
		return tests;
	}
	
	/**
	 * Add mock setup to test content
	 */
	private function addMockSetup(required string content, required struct obj) {
		// This would add mock object setup to the test
		// Implementation depends on mocking framework used
		return arguments.content;
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
