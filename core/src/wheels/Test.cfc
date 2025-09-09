component output="false" displayName="Test" extends="wheels.Global"{

	property name="Mixins" inject="id:Plugins";

	function init(){
		return this;
	}
	/*
		Base component for rapidly writing/running test cases.

		Terminology
		-----------
		-	A Test Package is a collection of Test Cases that tests the functionality
			of an application/service/whatever.

		-	A Test Case is a collection of Tests to apply to a particular CF component,
			tag or include file.

		- 	A Test is a sequence of calls to the code being tested and Assertions about
			the results we get from the code.

		-	An Assertion is a statement we make about the results we get that should
			evaluate to true if the tested code is working properly.

		How are these things represented in test code using this file?
		--------------------------------------------------------------
		-	A Test Package is a directory that can be referred to by a CF mapping, and
			ideally outside the web root for security.

		-	A Test Case is a CF component in that directory that extends this component.

		-	A Test is a method in one of these components.  The method name should start with
			the word "test", it should require no arguments and return void.  Any setup or
			clearup code common to all test functions can be added to optional setup() and
			teardown() methods, which again take no arguments and return void.

			Tests in each Test Case are run in alphabetical order.  If you want your tests
			to run in a particular order you could name them test01xxx, test02yyy, etc.

		-	An Assertion is a call to the assert() method (inherited from this component) inside
			a test method.  assert() takes a string argument, an expression (see ColdFusion
			evaluate() documentation) that evaluates to true or false.  If false, a "failure"
			is recorded for the test case and the test case fails.  assert() tries to include
			the value of any variables it finds in the expression.

			If there are specific variable values you would like included in the failure message,
			pass them as additional string arguments to assert().  Multiple variables can be
			listed in a single space-delimited string if this is convenient.

			For more complicated assertions you may call the fail() method directly, which takes
			a single message string as an argument.

		-	If an uncaught exception is thrown an "error" is recorded for the Test Case and the
			Test Case fails.

		Running tests
		-------------
		Assuming this file is under a com.rocketboots.rocketunit cf mapping, you have some test cases
		under a com.myco.myapp.sometestpackage cf mapping, and a test case SomeTestCase.cfc in that
		mapping...

		To run a test package:

			<cfset test = createObject("component", "com.rocketboots.rocketunit.Test")>
			<cfset test.runTestPackage("test.com.myco.myapp.sometestpackage")>


		To run a specific test case:

			<cfset test = createObject("component", "test.com.myco.myapp.sometestpackage.SomeTestCase")>
			<cfset test.runTest()>

		To see human readable output after running a test:

			<cfoutput>#test.HTMLFormatTestResults()#</cfoutput>

		The test results are available in the request.test structure.  If you would like to
		use a different key in request (as we do for the rocketunit self-tests) for the results
		you can pass the key name as a second argument to the run method.

		You can call run() multiple times and the test results will be combined.

		If you wish to reset the test results before calling run() again, call resetTestResults().

		Copyright 2007 RocketBoots Pty Limited - http://www.rocketboots.com.au

			This file is part of RocketUnit.

			RocketUnit is free software; you can redistribute it and/or modify
			it under the terms of the GNU General Public License as published by
			the Free Software Foundation; either version 2 of the License, or
			(at your option) any later version.

			RocketUnit is distributed in the hope that it will be useful,
			but WITHOUT ANY WARRANTY; without even the implied warranty of
			MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
			GNU General Public License for more details.

			You should have received a copy of the GNU General Public License
			along with RocketUnit; if not, write to the Free Software
			Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

		@version $Id: Test.cfc 167 2007-04-12 07:50:15Z robin $
	*/

	// variables that are used by the testing framework itself
	TESTING_FRAMEWORK_VARS = {};
	TESTING_FRAMEWORK_VARS.WHEELS_TESTS_BASE_COMPONENT_PATH = "";
	TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = "";
	TESTING_FRAMEWORK_VARS.RUNNING_TEST = "";

	// used to hold debug information for display
	if (!StructKeyExists(request, "TESTING_FRAMEWORK_DEBUGGING")) {
		request["TESTING_FRAMEWORK_DEBUGGING"] = {};
	}
	if (!StructKeyExists(request, "TESTING_FRAMEWORK_DEBUG_STRINGS")) {
		request["TESTING_FRAMEWORK_DEBUG_STRINGS"] = {};
	}

	/**
	 * Called from a test function.
	 * If expression evaluates to false, record a failure against the test.
	 *
	 * [section: Test Model]
	 * [category: Testing Functions]
	 *
	 * @expression String containing CFML expression to evaluate.
	 * @2..n String(s) containing space-delimited list of variables to evaluate and include in the failure message to help determine cause of failed assertion.
	 */
	public void function assert(required string expression) {
		// Convert "yes" / "no" to true / false.
		arguments.expression = arguments.expression == "yes" ? true : arguments.expression;
		arguments.expression = arguments.expression == "no" ? false : arguments.expression;

		var token = "";
		var tokenValue = "";
		var message = "assert failed: #arguments.expression#";
		var newline = Chr(10) & Chr(13);
		var i = "";
		var evaluatedTokens = "";
		if (!Evaluate(arguments.expression)) {
			for (i in arguments) {
				local.expr = arguments[i];
				evaluatedTokens = {};
				// Double pass of expressions with different delimiters so that for expression "a(b) or c[d]", "a(b)", "c[d]", "b" and "d" are evaluated. Do not evaluate any expression more than once.
				for (token in ListToArray("#local.expr# #ReReplace(local.expr, "[([\])]", " ")#", " +=-*/%##")) {
					if (!StructKeyExists(evaluatedTokens, token)) {
						evaluatedTokens[token] = true;
						local.tokenValue = "__INVALID__";
						if (!(IsNumeric(token) || IsBoolean(token))) {
							try {
								local.tokenValue = Evaluate(token);
							} catch (any e) {
							}
						}
						// Format token value according to type.
						if ((!IsSimpleValue(local.tokenValue)) || (local.tokenValue != "__INVALID__")) {
							if (IsSimpleValue(local.tokenValue)) {
								if (!(IsNumeric(local.tokenValue) || IsBoolean(local.tokenValue))) {
									local.tokenValue = "'#local.tokenValue#'";
								}
							} else {
								if (IsArray(local.tokenValue)) {
									local.tokenValue = "Array containing #ArrayLen(local.tokenValue)# items";
								} else if (IsStruct(local.tokenValue)) {
									local.tokenValue = "Struct with #StructCount(local.tokenValue)# members";
								} else if (IsQuery(local.tokenValue)) {
									local.tokenValue = "Query with #local.tokenValue.RecordCount# rows";
								} else if (IsCustomFunction(local.tokenValue)) {
									local.tokenValue = "UDF";
								}
							}
							message = message & newline & token & " = " & tokenValue;
						}
					}
				}
			}
			fail(message);
		}
	}

	/*
		Called from a test function to cause the test to fail.
		Will throw an exception resulting in a test failure along with an option message.

		@param message	Message to record in test results against failure.
	*/
	public void function fail(string message = "") {
		/*
			run() interprets exception with this errorcode as a "Failure".
			All other errorcodes cause are interpreted as an "Error".
		*/
		Throw(errorcode = "__FAIL__", message = "#HtmlEditFormat(message)#");
	}

	/**
	 * Used to examine an expression
	 * Any overloaded arguments get passed to cfdump's attributeCollection
	 *
	 * [section: Test Model]
	 * [category: Testing Functions]
	 *
	 * @expression The expression to examine
	 * @display  Whether to display the debug call. False returns without outputting anything into the buffer. Good when you want to leave the debug command in the test for later purposes, but don't want it to display
		*/
	public any function debug(required string expression, boolean display = true) {
		local.attributeArgs = {"var" = $evaluateExpression(arguments.expression), "label" = arguments.expression};
		local.dump = "";

		// this string will be added to the request key regardless of display argument
		local.debugString = ArrayToList(
			[
				"",
				"---------- DEBUG START '#arguments.expression#' --------",
				SerializeJSON(attributeArgs["var"]),
				"---------- DEBUG END '#arguments.expression#' --------",
				""
			],
			Chr(13)
		);

		if (!StructKeyExists(request["TESTING_FRAMEWORK_DEBUG_STRINGS"], TESTING_FRAMEWORK_VARS.RUNNING_TEST)) {
			request["TESTING_FRAMEWORK_DEBUG_STRINGS"][TESTING_FRAMEWORK_VARS.RUNNING_TEST] = "";
		}
		request["TESTING_FRAMEWORK_DEBUG_STRINGS"][TESTING_FRAMEWORK_VARS.RUNNING_TEST] &= local.debugString;

		if (!arguments.display) {
			return;
		}

		StructDelete(arguments, "expression");
		StructDelete(arguments, "display");
		StructAppend(attributeArgs, arguments, true);

		savecontent variable="dump" {
			WriteDump(attributeCollection = attributeArgs);
		}

		if (!StructKeyExists(request["TESTING_FRAMEWORK_DEBUGGING"], TESTING_FRAMEWORK_VARS.RUNNING_TEST)) {
			request["TESTING_FRAMEWORK_DEBUGGING"][TESTING_FRAMEWORK_VARS.RUNNING_TEST] = [];
		}
		ArrayAppend(request["TESTING_FRAMEWORK_DEBUGGING"][TESTING_FRAMEWORK_VARS.RUNNING_TEST], dump);
	}

	/**
	 * Catches a raised error and returns the error type
	 * Great if you want to	test that a certain exception will be raised.
	 *
	 * [section: Test Model]
	 * [category: Testing Functions]
	 *
	 * @expression String containing CFML expression to evaluate
	 */
	public string function raised(required string expression) {
		try {
			Evaluate(arguments.expression);
		} catch (any e) {
			return Trim(e.type);
		}
		return "";
	}

	/*
		Run all the tests in a component.

		@param resultKey	Key to store distinct test result sets under in
							request scope, defaults to "test"
		@returns true if no errors
		*/
	public boolean function $runTest(string resultKey = "test", string testname = "") {
		var key = "";
		var keyList = "";
		var time = "";
		var testCase = "";
		var status = "";
		var result = "";
		var message = "";
		var numTests = 0;
		var numTestFailures = 0;
		var numTestErrors = 0;
		var newline = Chr(10) & Chr(13);
		var func = "";
		var functions = "";
		var tagContext = "";
		var context = "";

		/*
			Check for and if necessary set up the structure to store test results
		*/
		if (!StructKeyExists(request, resultKey)) {
			$resetTestResults(resultKey);
		}

		testCase = GetMetadata(this).name;

		/*
			Iterate through the members of the this scope in alphabetical order,
			invoking methods starting in "test".  Wrap with calls to setup()
			and teardown() if provided.
		*/
		if (!StructKeyExists(GetMetadata(this), "functions")) {
			functions = "";
		} else {
			functions = GetMetadata(this).functions;
		}
		for (func in functions) {
			keyList = ListAppend(keyList, func.name);
		};
		keyList = ListSort(keyList, "textnocase", "asc");

		for (key in ListToArray(keyList)) {
			/* Include test name and make distinct so debugging doesn't duplicate output */
			var distinctKey = Replace(Replace(Replace(testCase, ".", "_", "all"), "tests_", "", "one"), "wheels_", "", "one") & '_' & key;
			/* keep track of the test name so we can display debug information */
			TESTING_FRAMEWORK_VARS.RUNNING_TEST = distinctkey;

			if (
				(Left(key, 4) eq "test" and IsCustomFunction(this[key]))
				and (!Len(arguments.testname) or (Len(arguments.testname) and arguments.testname eq key))
			) {
				time = GetTickCount();

				if (StructKeyExists(this, "setup")) {
					setup();
				}

				try {
					message = "";
					Invoke(this, key);
					status = "Success";
					request[resultkey].numSuccesses = request[resultkey].numSuccesses + 1;
				} catch (any e) {
					message = e.message;

					if (e.ErrorCode eq "__FAIL__") {
						/*
							fail() throws __FAIL__ exception
						*/
						status = "Failure";
						request[resultkey].ok = false;
						request[resultkey].numFailures = request[resultkey].numFailures + 1;
						numTestFailures = numTestFailures + 1;
					} else {
						/*
							another exception thrown
						*/
						status = "Error";
						if (ArrayLen(e.tagContext)) {
							template = "#ListLast(e.tagContext[1].template, "/")#:#e.tagContext[1].line#";
							tagContext = "<ul>";
							for (context in e.tagContext) {
								tagContext = tagContext & '<li>#context.template#:#context.line#</li>';
							};
							tagContext = tagContext & "</ul>";
						} else {
							template = "";
							tagContext = "[Unknown tagContext]";
						}

						if (Len(template)) {
							message = message & newline & template;
						}
						if (StructKeyExists(e, "sql") and Len(e.sql)) {
							message = message & newline & newline & e.sql;
						}
						if (Len(e.extendedInfo)) {
							message = message & newline & newLine & e.extendedInfo;
						}
						message = message & newline & newline & tagContext;
						if (Len(e.detail)) {
							message = message & newline & newline & e.detail;
						}
						request[resultkey].ok = false;
						request[resultkey].numErrors = request[resultkey].numErrors + 1;
						numTestErrors = numTestErrors + 1;
					}
				}

				if (StructKeyExists(this, "teardown")) {
					teardown();
				}

				time = GetTickCount() - time;

				/*
					Record test results
				*/
				result = {
					testCase = testCase,
					testName = key,
					time = time,
					status = status,
					message = message,
					distinctKey = distinctKey
				};

				ArrayAppend(request[resultkey].results, result);

				request[resultkey].numTests = request[resultkey].numTests + 1;
				numTests = numTests + 1;
			}
		};

		result = {testCase = testCase, numTests = numTests, numFailures = numTestFailures, numErrors = numTestErrors};

		// filter test results based on url params
		// this is experimental output for ci pipeline
		if (StructKeyExists(request.wheels.params, "only")) {
			local.results = ArrayFilter(request[resultkey].results, function(testCase) {
				return ListFindNoCase(request.wheels.params.only, arguments.testCase.status);
			});
			request[resultkey].results = local.results;
		} else {
			ArrayAppend(request[resultkey].summary, result);
		}

		request[resultkey].numCases = request[resultkey].numCases + 1;
		request[resultkey].end = Now();

		return numTestErrors eq 0;
	}

	/*
		Clear results.

		@param resultKey	Key to store distinct test result sets under in
							request scope, defaults to "test"
		*/

	public void function $resetTestResults(string resultKey = "test") {
		request[resultkey] = {};
		request[resultkey].begin = Now();
		request[resultkey].ok = true;
		request[resultkey].numCases = 0;
		request[resultkey].numTests = 0;
		request[resultkey].numSuccesses = 0;
		request[resultkey].numFailures = 0;
		request[resultkey].numErrors = 0;
		request[resultkey].summary = [];
		request[resultkey].results = [];
	}

	/*
		Report test results at overall, test case and test level, highlighting
		failures and errors.

		@param resultKey	Key to retrieve distinct test result sets from in
							request scope, defaults to "test"
		@returns			HTML formatted test results
		*/

	public any function $results(string resultKey = "test") {
		local.rv = false;
		if (StructKeyExists(request, resultkey)) {
			request[resultkey].path = TESTING_FRAMEWORK_VARS.WHEELS_TESTS_BASE_COMPONENT_PATH;

			local.summaryLength = ArrayLen(request[resultkey].summary);
			for (local.i = 1; local.i <= local.summaryLength; local.i++) {
				request[resultkey].summary[local.i].cleanTestCase = $cleanTestCase(request[resultkey].summary[local.i].testCase);
				request[resultkey].summary[local.i].packageName = $cleanTestPath(request[resultkey].summary[local.i].testCase);
			};

			local.resultsLength = ArrayLen(request[resultkey].results);
			for (local.i = 1; local.i <= local.resultsLength; local.i++) {
				request[resultkey].results[local.i].cleanTestCase = $cleanTestCase(request[resultkey].results[local.i].testCase);
				request[resultkey].results[local.i].cleanTestName = $cleanTestName(request[resultkey].results[local.i].testName);
				request[resultkey].results[local.i].packageName = $cleanTestPath(request[resultkey].results[local.i].testCase);
				request[resultkey].results[local.i].debugString = "";
				if (StructKeyExists(request.TESTING_FRAMEWORK_DEBUG_STRINGS, request[resultkey].results[local.i].distinctKey)) {
					request[resultkey].results[local.i].debugString = request.TESTING_FRAMEWORK_DEBUG_STRINGS[
						request[resultkey].results[local.i].distinctKey
					];
				}
			};

			local.rv = request[resultkey];
		}
		return local.rv;
	}

	/*
	 * The function wheels uses to run tests
	 */
	public any function $wheelsRunner(struct options = {}) {
		// the key in the request scope that will contain the test results
		local.resultKey = "WheelsTests";

		// save the original environment for overloading
		if (application.wheels.restoreTestRunnerApplicationScope) {
			request.wheels.testRunnerApplicationScope = Duplicate(application.wheels);
		}
		// to enable unit testing controllers without actually performing the redirect
		set(functionName = "redirectTo", delay = true);

		// not only can we specify the package, but also the test we want to run
		local.test = "";
		if (StructKeyExists(arguments.options, "test") && Len(arguments.options.test)) {
			local.test = arguments.options.test;
		}
		local.paths = $resolvePaths(arguments.options);
		local.packages = $listTestPackages(arguments.options, local.paths.test_filter);

		if (StructKeyExists(arguments.options, "seed") && arguments.options.seed) {
			this.$seedDatabase(local.paths);
		}
		// run tests
		local.i = 0;
		for (local.row in local.packages) {
			local.i++;
			local.instance = application.wirebox.getInstance(name = "#local.row.package#");
			// is there a better way to check for existence of a function?
			// if the beforeall method is present, run it once only per request
			if (StructKeyExists(local.instance, "beforeAll") && local.i eq 1) {
				local.instance.beforeAll();
			}
			if (StructKeyExists(local.instance, "packageSetup")) {
				local.instance.packageSetup();
			}
			local.instance.$runTest(local.resultKey, local.test);
			if (StructKeyExists(local.instance, "packageTeardown")) {
				local.instance.packageTeardown();
			}
			// if the afterAll method is present, run it after the last package (once per request)
			if (StructKeyExists(local.instance, "afterAll") && local.i eq local.packages.recordCount) {
				local.instance.afterAll();
			}
		};
		// return the results
		return $results(local.resultKey);
	}

	/*
	 * Args:
	 * component: path to the component you want to check as a valid test
	 * shouldExtend: if the component should extend a base component to be a valid test
	 */
	public boolean function $isValidTest(required string component, string shouldExtend = "Test") {
		local.name = ListLast(arguments.component, ".");

		if (application.wheels.validateTestPackageMetaData && Len(arguments.shouldExtend)) {
			local.metadata = GetComponentMetadata(arguments.component);
			if (
				!StructKeyExists(local.metadata, "extends")
				or ListLast(local.metadata.extends.fullname, ".") neq arguments.shouldExtend
			) {
				return false;
			}
		}
		// package names that begin with underscores are not valid
		if (Left(local.name, 1) eq "_") {
			return false;
		}
		// don't test Test.cfc base components
		if (local.name eq "Test") {
			return false;
		}
		return true;
	}

	/*
	 * Removes the base test directory from the test name to make them prettier and more readable.
	 */
	public string function $cleanTestCase(
		required string name,
		string path = TESTING_FRAMEWORK_VARS.WHEELS_TESTS_BASE_COMPONENT_PATH
	) {
		return ListChangeDelims(Replace(arguments.name, arguments.path, ""), ".", ".");
	}

	/*
	 * Cleans up the test name so they are more readable.
	 */
	public string function $cleanTestName(required string name) {
		local.rv = arguments.name;
		if (Find("_", local.rv)) {
			local.rv = humanize(Trim(ReReplaceNoCase(ListRest(local.rv, "_"), "_|-", " ", "all")));
		} else {
			local.rv = ReReplaceNoCase(local.rv, "_|-", " ", "all");
			local.rv = Right(local.rv, Len(local.rv) - 4);
			local.rv = Trim(capitalize(LCase(humanize(local.rv))));
		}
		return local.rv;
	}

	/*
	 * Cleans up the test path.
	 */
	public string function $cleanTestPath(required string path) {
		return ListChangeDelims(Replace(arguments.path, TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH, ""), ".", ".");
	}

	/*
	 * This resolves all the paths needed to run the tests.
	 */
	public struct function $resolvePaths(struct options = {}) {
		local.rv = {};

		// default test type
		local.type = "core";
		// testfilter
		local.rv.test_filter = "*";
		// by default we run all packages, however they can specify to run a specific package of tests
		local.package = "";

		// if they specified a package we should only run that
		if (StructKeyExists(arguments.options, "package") && Len(arguments.options.package)) {
			local.package = arguments.options.package;
		}
		// overwrite the default test type if passed
		if (StructKeyExists(arguments.options, "type") and Len(arguments.options.type)) {
			local.type = arguments.options.type;
		}

		// which tests to run
		if (local.type eq "core") {
			// core tests
			TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = application.wheels.wheelsComponentPath;
		} else if (local.type eq "app") {
			// app tests
			TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = application.wheels.rootComponentPath;
		} else {
			// specific plugin tests
			TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = application.wheels.rootComponentPath;
			TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = ListAppend(
				TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH,
				"#application.wheels.pluginComponentPath#.#local.type#",
				"."
			);
		}

		// set test directory for tests
		if(local.type eq "app") {
			TESTING_FRAMEWORK_VARS.TEST_DIRECTORY = "tests.RocketUnit";
		} else {
			TESTING_FRAMEWORK_VARS.TEST_DIRECTORY = "tests";
		}

		TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH = ListAppend(TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH, TESTING_FRAMEWORK_VARS.TEST_DIRECTORY, ".");

		// add the package if specified
		local.rv.test_path = ListAppend("#TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH#", local.package, ".");

		// clean up testpath
		local.rv.test_path = ListChangeDelims(local.rv.test_path, ".", "./\");

		// convert to regular path
		local.rv.relative_root_test_path = "/" & ListChangeDelims(TESTING_FRAMEWORK_VARS.ROOT_TEST_PATH, "/", ".");
		local.rv.full_root_test_path = ExpandPath(local.rv.relative_root_test_path);
		local.rv.relative_test_path = "/" & ListChangeDelims(local.rv.test_path, "/", ".");
		local.rv.full_test_path = ExpandPath(local.rv.relative_test_path);

		if (!DirectoryExists(local.rv.full_test_path)) {
			if (FileExists(local.rv.full_test_path & ".cfc")) {
				local.rv.test_filter = Reverse(ListFirst(Reverse(local.rv.test_path), "."));
				local.rv.test_path = Reverse(ListRest(Reverse(local.rv.test_path), "."));
				local.rv.relative_test_path = "/" & ListChangeDelims(local.rv.test_path, "/", ".");
				local.rv.full_test_path = ExpandPath(local.rv.relative_test_path);
			} else {
				Throw(
					type = "Wheels.Testing",
					message = "Cannot find test package or single test",
					detail = "In order to run test you must supply a valid test package or single test file to run"
				);
			}
		}

		// for test results display
		TESTING_FRAMEWORK_VARS.WHEELS_TESTS_BASE_COMPONENT_PATH = local.rv.test_path;

		return local.rv;
	}

	/*
	 * Returns a query containing all the test to run and their directory path.
	 */
	public query function $listTestPackages(struct options = {}, string filter = "*") {
		local.rv = QueryNew("package", "Varchar");
		local.paths = $resolvePaths(arguments.options);
		$initialiseTestEnvironment(local.paths, arguments.options);
		local.packages = DirectoryList(
			local.paths.full_test_path,
			true,
			"query",
			"#arguments.filter#.cfc",
			arguments.options.sort
		);
		for (local.package in local.packages) {
			local.packageName = ListChangeDelims(
				RemoveChars(local.package.directory, 1, Len(local.paths.full_test_path)),
				".",
				"\/"
			);
			// Directories that begin with an underscore are ignored.
			if (!ReFindNoCase("(^|\.)_", local.packageName)) {
				local.packageName = ListPrepend(local.packageName, local.paths.test_path, ".");
				local.packageName = ListAppend(local.packageName, ListFirst(local.package.name, "."), ".");
				// Ignore invalid packages.
				local.useTest = $isValidTest(local.packageName);
				// a bit hacky.. try to use Left rather than contains
				if (StructKeyExists(arguments.options, "skip") && local.packageName contains arguments.options.skip) {
					local.useTest = false;
				}
				if (local.useTest) {
					QueryAddRow(local.rv);
					QuerySetCell(local.rv, "package", local.packageName);
				}
			}
		};
		return local.rv;
	}

	/*
	 * Initialises the test environment and populates test database.
	 */
	public void function $initialiseTestEnvironment(required struct paths, required struct options) {
		if (FileExists(arguments.paths.full_root_test_path & "/env.cfm")) {
			include "#arguments.paths.relative_root_test_path#/env.cfm";
		}
	}

	/*
	 * Seeds the test database.
	 */
	public void function $seedDatabase(required struct paths) {
		if (FileExists(arguments.paths.full_root_test_path & "/seed.cfm")) {
			include "#arguments.paths.relative_root_test_path#/seed.cfm";
		}
	}

	/*
	 * Returns true if a file path is a wheels core file.
	 */
	public any function $isCoreFile(required string path) {
		local.path = Replace(arguments.path, ExpandPath("/"), "", "one");
		return (Left(local.path, 7) == "wheels/" || ListFindNoCase("index.cfm", local.path));
	}

	public any function $evaluateExpression(required string expression) {
		local.parts = $splitOutsideFunctions(arguments.expression, ".");

		try {
			if (arrayLen(local.parts) == 1) {
				if(structKeyExists(variables, local.parts[1])){
					return variables[local.parts[1]];
				} else if(findNoCase("(", local.parts[1])){
					local.match = reFind("\(([^()]+)\)", local.parts[1], 1, true);
					local.functionName = listToArray(local.parts[1], "(");
					if(local.match.len[1] == 0){
						return variables[local.functionName[1]]();
					} else{
						local.args = listToArray(local.match.match[2], "=");
						if(arrayLen(local.args) == 2){
							return invoke(variables, local.functionName[1], variables[local.args[2]]);
						} else {
							// Use the Evaluate function to run Built-in functions
							return Evaluate("expression");
						}
					}
				}
			} else if (arrayLen(local.parts) == 2 && structKeyExists(variables, local.parts[1]) && !reFind("\\(", local.parts[2])) {
				local.structRef = variables[local.parts[1]];
				if (structKeyExists(local.structRef, local.parts[2])) {
					return local.structRef[local.parts[2]];
				}
			} else {
				local.match = reFind("\(([^()]+)\)", local.parts[2], 1, true);
				if(local.match.len[1] == 0){
					local.functionName = replaceNoCase(local.parts[2], "()", "");
					local.structRef = variables[local.parts[1]];
					if (structKeyExists(local.structRef, local.functionName)) {
						return invoke(local.structRef, local.functionName);
					}
				} else {
					if(findNoCase("=", local.match.match[2]) != 0){
						local.args = listToArray(local.match.match[2], "=");
						local.functionName = listToArray(local.parts[2], "(");
						local.structRef = variables[local.parts[1]];
						if (structKeyExists(local.structRef, local.functionName[1])) {
							return invoke(local.structRef, local.functionName[1], variables[local.args[2]]);
						}
					}
				}
			}

			throw("Invalid expression: #arguments.expression#");
		} catch (any e) {
			return "Error evaluating expression: " & e.message;
		}
	}

	function onDIcomplete(){
		if (structKeyExists(server, "boxlang")) {
			variables.this = this;
		}
		Mixins.$initializeMixins(variables);
	}

}
