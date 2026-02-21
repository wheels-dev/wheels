/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Welcome to the next generation of BDD and xUnit testing for BoxLang & CFML applications
 * The TestBox core class allows you to execute all kinds of test bundles, directories and more.
 */
component accessors="true" {

	// The version
	property name="version";
	// The codename
	property name="codename";
	// The main utility object
	property name="utility";
	// The class bundles to test
	property name="bundles";
	// The labels used for the testing
	property name="labels";
	// The labels excluded from testing
	property name="excludes";
	// The reporter attached to this runner
	property name="reporter";
	// The configuration options attached to this runner
	property name="options";
	// Last TestResult in case runner wants to inspect it
	property name="result";
	// Code Coverage Service
	property name="coverageService";
	// TestBox Modules Registry
	property name="modules";
	// A list of globbing patterns to match bundles to test ONLY! Ex: *Spec|*Test
	property name="bundlesPattern";

	// Static Variables
	variables.TESTBOX_PATH            = expandPath( "/wheels/testbox" );
	variables.IS_BOXLANG              = server.keyExists( "boxlang" );
	variables.IS_CLI                  = variables.IS_BOXLANG && server.boxlang.cliMode ? true : false;
	variables.DEFAULT_REPORTER        = variables.IS_CLI ? "text" : "simple";
	variables.DEFAULT_BUNDLES_PATTERN = "*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx";
	// TestBox Info : Modified by the build process.
	variables.VERSION                 = "6.5.0+18";
	variables.CODENAME                = "";

	/**
	 * Constructor
	 *
	 * @bundles        The path, list of paths or array of paths of the spec bundle classes to run and test
	 * @directory      The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 * @directories    Same as @directory, but accepts an array or list
	 * @reporter       The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a wheels.testbox.system.reports.IReporter
	 * @labels         The list or array of labels that a suite or spec must have in order to execute.
	 * @excludes       The list or array of labels that a suite or spec must not have in order to execute.
	 * @options        A structure of configuration options that are optionally used to configure a runner.
	 * @bundlesPattern A globbing pattern list to match bundles to test ONLY, matches directoryList() filters! Ex: *Spec|*Test
	 */
	any function init(
		any bundles           = [],
		any directory         = {},
		any directories       = {},
		any reporter          = variables.DEFAULT_REPORTER,
		any labels            = [],
		any excludes          = [],
		struct options        = {},
		string bundlesPattern = variables.DEFAULT_BUNDLES_PATTERN
	){
		// Bundles pattern
		if ( !len( arguments.bundlesPattern ) ) {
			arguments.bundlesPattern = variables.DEFAULT_BUNDLES_PATTERN;
		}
		variables.bundlesPattern = arguments.bundlesPattern;
		// Utility and mappings
		variables.utility        = new wheels.testbox.system.util.Util();
		// Coverage Service
		if ( !structKeyExists( arguments.options, "coverage" ) ) {
			arguments.options.coverage = {};
		}
		variables.coverageService = new wheels.testbox.system.coverage.CoverageService( arguments.options.coverage );
		// reporter
		variables.reporter        = arguments.reporter;
		// options
		variables.options         = arguments.options;
		// Empty bundles to start
		variables.bundles         = [];
		// Modules Init
		variables.modules         = { "mappings" : {}, "registry" : structNew( "ordered" ) };

		// inflate labels
		inflateLabels( arguments.labels );
		// inflate excludes
		inflateExcludes( arguments.excludes );
		// Add bundles given (if any)
		addBundles( arguments.bundles );
		// Add directory given (if any)
		addDirectory( arguments.directory );
		// Add directories given (if any)
		addDirectories( arguments.directories );
		// Load TestBox Modules
		loadTestBoxModules();

		return this;
	}

	/**
	 * Load the TestBox Modules
	 */
	function loadTestBoxModules(){
		var modulesPath = variables.TESTBOX_PATH & "/system/modules";

		// Skip module loading if directory doesn't exist (e.g., ingested subset)
		if (!directoryExists(modulesPath)) return;

		// Register Modules
		directoryList( modulesPath, true, "path", "ModuleConfig.cfc" )
			.map( ( item ) => item.replaceNoCase( "ModuleConfig.cfc", "" ) )
			.each( ( path ) => {
				registerModule(
					"testbox" & arguments.path
						.replaceNoCase( variables.TESTBOX_PATH, "" )
						.reReplace( "[\\\/]", ".", "all" )
						.reReplace( "\.$", "", "all" )
				);
			} );

		directoryList( modulesPath, true, "path", "ModuleConfig.bx" )
			.map( ( item ) => item.replaceNoCase( "ModuleConfig.bx", "" ) )
			.each( ( path ) => {
				registerModule(
					"testbox" & arguments.path
						.replaceNoCase( variables.TESTBOX_PATH, "" )
						.reReplace( "[\\\/]", ".", "all" )
						.reReplace( "\.$", "", "all" )
				);
			} );

		// Activate Modules
		variables.modules.registry.each( ( moduleName, config ) => activateModule( moduleName ) );

		// Register Global Mappings
		variables.utility.addMapping( mappings: variables.modules.mappings );
	}

	/**
	 * Register a module in TestBox
	 *
	 * @path The invocationPath path to the module. Ex: tests.resources.myModule
	 */
	function registerModule( required path ){
		var moduleName                                 = listLast( arguments.path, "." );
		var absolutePath                               = expandPath( "/" & arguments.path.replace( ".", "/", "all" ) );
		// Register Mapping
		variables.modules.mappings[ "/" & moduleName ] = absolutePath;
		// Register Module
		variables.modules.registry[ moduleName ]       = {
			"name"              : moduleName,
			"settings"          : {},
			"moduleConfig"      : "",
			"path"              : absolutePath,
			"loadTime"          : now(),
			"activationTime"    : 0,
			"active"            : false,
			"activationFailure" : {},
			"mapping"           : moduleName,
			"invocationPath"    : arguments.path
		};
		return this;
	}

	/**
	 * Activate a module in TestBox
	 *
	 * @name The name of the module to activate
	 *
	 * @throws ModuleNotRegisteredException - If the module is not registered
	 */
	function activateModule( required name ){
		// Verify it
		if ( !variables.modules.registry.keyExists( arguments.name ) ) {
			throw( "ModuleNotRegisteredException", "The module #arguments.name# is not registered in TestBox" );
		}

		// If active, skip activation
		var moduleRecord = variables.modules.registry[ arguments.name ];
		if ( moduleRecord.active ) {
			return this;
		}

		// Create and Decorate ModuleConfig
		moduleRecord.moduleConfig = variables.utility
			.getMixerUtil()
			.start( createObject( "component", moduleRecord.invocationPath & ".ModuleConfig" ) );

		// Inject properties
		moduleRecord.moduleConfig
			.injectPropertyMixin( "testbox", this )
			.injectPropertyMixin( "testboxVersion", variables.version )
			.injectPropertyMixin( "moduleMapping", moduleRecord.invocationPath )
			.injectPropertyMixin( "modulePath", moduleRecord.path )
			.injectPropertyMixin( "getJavaSystem", getEnv().getJavaSystem )
			.injectPropertyMixin( "getSystemSetting", getEnv().getSystemSetting )
			.injectPropertyMixin( "getSystemProperty", getEnv().getSystemProperty )
			.injectPropertyMixin( "getEnv", getEnv().getEnv );

		// Activate it
		try {
			moduleRecord.moduleConfig.configure();
			moduleRecord.settings       = moduleRecord.moduleConfig.getPropertyMixin( "settings", "variables", {} );
			moduleRecord.active         = true;
			moduleRecord.activationTime = now();
			moduleRecord.moduleConfig.onLoad();
		} catch ( any e ) {
			moduleRecord.activationFailure = e;
			// writeDump(
			// 	var    = "**** Error activating (#arguments.name#) TestBox Module: #e.message & e.detail#",
			// 	output = "console"
			// );
		}

		return this;
	}

	/**
	 * Register and activate a TestBox module.  You must pass the full invocation
	 * path in order to register and activate the module.
	 *
	 * @path The invocationPath path to the module. Ex: tests.resources.myModule
	 */
	function registerAndActivateModule( required path ){
		var moduleName = listLast( arguments.path, "." );
		registerModule( arguments.path ).activateModule( moduleName );
		variables.utility.addMapping( name: "/" & moduleName, path: variables.modules.registry[ moduleName ].path );
		return this;
	}

	/**
	 * Get only the activated modules registry
	 *
	 * @return The struct of activated modules
	 */
	struct function getActiveModules(){
		return variables.modules.registry.filter( ( moduleName, config ) => {
			return config.active;
		} );
	}

	/**
	 * Get the modules registry
	 *
	 * @return The struct of registered modules regardless if they are activated or not
	 */
	struct function getModuleRegistry(){
		return variables.modules.registry;
	}

	/**
	 * Get the TestBox Env object
	 *
	 * @return wheels.testbox.system.util.Env
	 */
	function getEnv(){
		// Lazy Load it
		if ( isNull( variables.env ) ) {
			variables.env = new wheels.testbox.system.util.Env();
		}
		return variables.env;
	}

	/**
	 * Register a directory to test
	 *
	 * @directory A directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 */
	any function addDirectory( required any directory, boolean recurse = true ){
		// inflate directory?
		if ( isSimpleValue( arguments.directory ) ) {
			arguments.directory = {
				mapping : arguments.directory,
				recurse : arguments.recurse
			};
		}
		// directory passed?
		if ( !structIsEmpty( arguments.directory ) ) {
			for ( var bundle in getSpecPaths( arguments.directory ) ) {
				arrayAppend( variables.bundles, bundle );
			}
		}
		return this;
	}

	/**
	 * Constructor
	 *
	 * @directories A set of directories to test which can be a list of simple mapping paths or an array of structs with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 */
	any function addDirectories( required any directories, boolean recurse = true ){
		if ( isSimpleValue( arguments.directories ) ) {
			arguments.directories = listToArray( arguments.directories );
		}
		for ( var dir in arguments.directories ) {
			addDirectory( dir, arguments.recurse );
		}
		return this;
	}

	/**
	 * Add bundles to the TestBox `bundles` target to test
	 *
	 * @bundles The path, list of paths or array of paths of the spec bundle classess to run and test
	 */
	any function addBundles( required any bundles ){
		if ( isSimpleValue( arguments.bundles ) ) {
			arguments.bundles = listToArray( arguments.bundles );
		}
		for ( var bundle in arguments.bundles ) {
			arrayAppend( variables.bundles, bundle );
		}
		return this;
	}

	/**
	 * Run me some testing goodness, this can use the constructed object variables or the ones
	 * you can send right here.
	 *
	 * @bundles      The path, list of paths or array of paths of the spec bundle classes to run and test
	 * @directory    The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 * @reporter     The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a wheels.testbox.system.reports.IReporter. You can also pass a struct if the reporter requires options: {type="", options={}}
	 * @labels       The list or array of labels that a suite or spec must have in order to execute.
	 * @excludes     The list or array of labels that a suite or spec must not have in order to execute.
	 * @options      A structure of configuration options that are optionally used to configure a runner.
	 * @testBundles  A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites   A list or array of suite names that are the ones that will be executed ONLY!
	 * @testSpecs    A list or array of test names that are the ones that will be executed ONLY!
	 * @callbacks    A struct of listener callbacks or a class with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 * @eagerFailure If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	 */
	any function run(
		any bundles,
		any directory,
		any reporter,
		any labels,
		any excludes,
		struct options,
		any testBundles      = [],
		any testSuites       = [],
		any testSpecs        = [],
		any callbacks        = {},
		boolean eagerFailure = false
	){
		// reporter passed?
		if ( !isNull( arguments.reporter ) ) {
			variables.reporter = arguments.reporter;
		}
		// run it and get results
		var results      = runRaw( argumentCollection = arguments );
		// store latest results
		variables.result = results;
		// return report
		var report       = produceReport( results );
		// set response headers
		sendStatusHeaders( results );

		return report;
	}

	/**
	 * Run me some testing goodness but give you back the raw TestResults object instead of a report
	 *
	 * @bundles      The path, list of paths or array of paths of the spec bundle classes to run and test
	 * @directory    The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 * @labels       The list or array of labels that a suite or spec must have in order to execute.
	 * @excludes     The list or array of labels that a suite or spec must not have in order to execute.
	 * @options      A structure of configuration options that are optionally used to configure a runner.
	 * @testBundles  A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites   A list or array of suite names that are the ones that will be executed ONLY!
	 * @testSpecs    A list or array of test names that are the ones that will be executed ONLY!
	 * @callbacks    A struct of listener callbacks or a class with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 * @eagerFailure If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	 */
	wheels.testbox.system.TestResult function runRaw(
		any bundles,
		any directory,
		any labels,
		any excludes,
		struct options,
		any testBundles      = [],
		any testSuites       = [],
		any testSpecs        = [],
		any callbacks        = {},
		boolean eagerFailure = false
	){
		// inflate options if passed
		if ( !isNull( arguments.options ) ) {
			variables.options = arguments.options;
		}
		// inflate directory?
		if ( !isNull( arguments.directory ) && isSimpleValue( arguments.directory ) ) {
			arguments.directory = { mapping : arguments.directory, recurse : true };
		}
		// inflate test bundles, suites and specs from incoming variables.
		arguments.testBundles = (
			isSimpleValue( arguments.testBundles ) ? listToArray( arguments.testBundles ) : arguments.testBundles
		);
		arguments.testSuites = (
			isSimpleValue( arguments.testSuites ) ? listToArray( arguments.testSuites ) : arguments.testSuites
		);
		arguments.testSpecs = (
			isSimpleValue( arguments.testSpecs ) ? listToArray( arguments.testSpecs ) : arguments.testSpecs
		);

		// Verify URL conventions for bundle, suites and specs exclusions.
		if ( !isNull( url.testBundles ) ) {
			testBundles.append( listToArray( urlDecode( url.testBundles ) ), true );
		}
		if ( !isNull( url.testSuites ) ) {
			arguments.testSuites.append( listToArray( urlDecode( url.testSuites ) ), true );
		}
		if ( !isNull( url.testSpecs ) ) {
			arguments.testSpecs.append( listToArray( urlDecode( url.testSpecs ) ), true );
		}
		if ( !isNull( url.testMethod ) ) {
			arguments.testSpecs.append( listToArray( urlDecode( url.testMethod ) ), true );
		}

		// Using a directory runner?
		if ( !isNull( arguments.directory ) && !structIsEmpty( arguments.directory ) ) {
			arguments.bundles = getSpecPaths( arguments.directory );
		}

		// Inflate labels if passed
		if ( !isNull( arguments.labels ) ) {
			inflateLabels( arguments.labels );
		}
		// Inflate excludes if passed
		if ( !isNull( arguments.excludes ) ) {
			inflateExcludes( arguments.excludes );
		}
		// If bundles passed, inflate those as the target
		if ( !isNull( arguments.bundles ) ) {
			inflateBundles( arguments.bundles );
		}

		// create results object
		var results = new wheels.testbox.system.TestResult(
			bundleCount = arrayLen( variables.bundles ),
			labels      = variables.labels,
			excludes    = variables.excludes,
			testBundles = arguments.testBundles,
			testSuites  = arguments.testSuites,
			testSpecs   = arguments.testSpecs
		);

		coverageService.beginCapture();

		// iterate and run the test bundles
		for ( var thisBundlePath in variables.bundles ) {
			// Skip interfaces, they are not testable
			var thisMD = server.keyExists( "boxlang" ) ? getClassMetadata( thisBundlePath ) : getComponentMetadata(
				thisBundlePath
			);
			if ( thisMD.type eq "interface" ) {
				continue;
			}

			// Execute Bundle
			testBundle(
				bundlePath  = thisBundlePath,
				testResults = results,
				callbacks   = arguments.callbacks
			);

			// Eager Failures on Bundle?
			if ( arguments.eagerFailure ) {
				var failuresDetected = results
					.getBundleStats()
					// Get stats for running bundle
					.filter( function( item ){
						return ( item.path == thisBundlePath ? true : false );
					} )
					.reduce( function( result, item ){
						return ( item.totalError + item.totalFail ) > 0;
					}, false );

				if ( failuresDetected ) {
					// Hard skip iterations
					break;
				}
			}
		}

		// mark end of testing bundles
		results.end();
		// mark end of code coverage
		coverageService.processCoverage( results = results, testbox = this );
		coverageService.endCapture( true );
		// Store results
		variable.result = results;

		// Unload Modules
		variables.modules.registry.each( ( moduleName, config ) => {
			if ( config.active ) {
				config.moduleConfig.onUnload( results );
			}
		} );

		return results;
	}

	/**
	 * Run me some testing goodness, remotely via SOAP, Flex, REST, URL
	 *
	 * @bundles         The path or list of paths of the spec bundle classes to run and test
	 * @directory       The directory mapping to test: directory = the path to the directory using dot notation (myapp.testing.specs)
	 * @recurse         Recurse the directory mapping or not, by default it does
	 * @reporter        The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or a class path to the reporter to use.
	 * @reporterOptions A JSON struct literal of options to pass into the reporter
	 * @labels          The list of labels that a suite or spec must have in order to execute.
	 * @options         A JSON struct literal of configuration options that are optionally used to configure a runner.
	 * @testBundles     A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites      A list of suite names that are the ones that will be executed ONLY!
	 * @testSpecs       A list of test names that are the ones that will be executed ONLY!
	 * @eagerFailure    If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	 */
	remote function runRemote(
		string bundles,
		string directory,
		boolean recurse        = true,
		string reporter        = "simple",
		string reporterOptions = "{}",
		string labels          = "",
		string excludes        = "",
		string options,
		string testBundles   = "",
		string testSuites    = "",
		string testSpecs     = "",
		boolean eagerFailure = false
	) output=true{
		// local init
		init();

		// simple to complex
		arguments.labels      = listToArray( arguments.labels );
		arguments.excludes    = listToArray( arguments.excludes );
		arguments.testBundles = listToArray( arguments.testBundles );
		arguments.testSuites  = listToArray( arguments.testSuites );
		arguments.testSpecs   = listToArray( arguments.testSpecs );

		// options inflate from JSON
		if ( !isNull( arguments.options ) and isJSON( arguments.options ) ) {
			arguments.options = deserializeJSON( arguments.options );
		} else {
			arguments.options = {};
		}

		// Inflate directory?
		if ( !isNull( arguments.directory ) and len( arguments.directory ) ) {
			arguments.directory = {
				mapping : arguments.directory,
				recurse : arguments.recurse
			};
		}

		// reporter options inflate from JSON
		if ( !isNull( arguments.reporterOptions ) and isJSON( arguments.reporterOptions ) ) {
			arguments.reporterOptions = deserializeJSON( arguments.reporterOptions );
		} else {
			arguments.reporterOptions = {};
		}

		// setup reporter
		if ( !isNull( arguments.reporter ) and len( arguments.reporter ) ) {
			variables.reporter = {
				type    : arguments.reporter,
				options : arguments.reporterOptions
			};
		}

		// run it and get results
		variables.result = runRaw( argumentCollection = arguments );

		// check if reporter is "raw" and if raw, just return it else output the results
		if ( variables.reporter.type == "raw" ) {
			return produceReport( variables.result );
		} else {
			writeOutput( produceReport( variables.result ) );
		}

		// create status headers
		sendStatusHeaders( variables.result );
	}

	/**
	 * Send some status headers
	 */
	private function sendStatusHeaders( required results ){
		// If we are not in a web enabled runtime, just skip
		if ( !getFunctionList().keyExists( "getPageContext" ) ) {
			return this;
		}
		try {
			var response = getPageContext().getResponse();
			response.addHeader( "x-testbox-totalDuration", javacast( "string", results.getTotalDuration() ) );
			response.addHeader( "x-testbox-totalBundles", javacast( "string", results.getTotalBundles() ) );
			response.addHeader( "x-testbox-totalSuites", javacast( "string", results.getTotalSuites() ) );
			response.addHeader( "x-testbox-totalSpecs", javacast( "string", results.getTotalSpecs() ) );
			response.addHeader( "x-testbox-totalPass", javacast( "string", results.getTotalPass() ) );
			response.addHeader( "x-testbox-totalFail", javacast( "string", results.getTotalFail() ) );
			response.addHeader( "x-testbox-totalError", javacast( "string", results.getTotalError() ) );
			response.addHeader( "x-testbox-totalSkipped", javacast( "string", results.getTotalSkipped() ) );
		} catch ( Any e ) {
			writeLog(
				type = "error",
				text = "Error sending TestBox headers: #e.message# #e.detail# #e.stackTrace#",
				file = "testbox.log"
			);
		}

		return this;
	}

	/************************************** REPORTING COMMON METHODS *********************************************/

	/**
	 * Build a report according to this runner's setup reporter, which can be anything.
	 *
	 * @results The results object to use to produce a report
	 */
	private any function produceReport( required results ){
		var iData = { type : "", options : {} };

		// If the type is a simple value then inflate it
		if ( isSimpleValue( variables.reporter ) ) {
			iData = {
				type    : buildReporter( variables.reporter ),
				options : variables.options
			};
		}
		// If the incoming reporter is an object.
		else if ( isObject( variables.reporter ) ) {
			iData = { type : variables.reporter, options : variables.options };
		}
		// Do we have reporter type and options
		else if ( isStruct( variables.reporter ) ) {
			iData.type = buildReporter( variables.reporter.type );
			if ( structKeyExists( variables.reporter, "options" ) ) {
				iData.options = variables.reporter.options;
			} else {
				iData.options = variables.options;
			}
		}

		// build the report from the reporter
		return iData.type.runReport( arguments.results, this, iData.options );
	}

	/**
	 * Build a reporter according to passed in reporter type or class path
	 *
	 * @reporter The reporter type to build.
	 */
	any function buildReporter( required reporter ){
		switch ( arguments.reporter ) {
			case "json": {
				return new "wheels.testbox.system.reports.JSONReporter"( );
			}
			case "xml": {
				return new "wheels.testbox.system.reports.XMLReporter"( );
			}
			case "raw": {
				return new "wheels.testbox.system.reports.RawReporter"( );
			}
			case "simple": {
				return new "wheels.testbox.system.reports.SimpleReporter"( );
			}
			case "dot": {
				return new "wheels.testbox.system.reports.DotReporter"( );
			}
			case "text": {
				return new "wheels.testbox.system.reports.TextReporter"( );
			}
			case "junit": {
				return new "wheels.testbox.system.reports.JUnitReporter"( );
			}
			case "antjunit": {
				return new "wheels.testbox.system.reports.ANTJUnitReporter"( );
			}
			case "console": {
				return new "wheels.testbox.system.reports.ConsoleReporter"( );
			}
			case "min": {
				return new "wheels.testbox.system.reports.MinReporter"( );
			}
			case "mintext": {
				return new "wheels.testbox.system.reports.MinTextReporter"( );
			}
			case "tap": {
				return new "wheels.testbox.system.reports.TapReporter"( );
			}
			case "doc": {
				return new "wheels.testbox.system.reports.DocReporter"( );
			}
			case "codexwiki": {
				return new "wheels.testbox.system.reports.CodexWikiReporter"( );
			}
			default: {
				return new "#arguments.reporter#"( );
			}
		}
	}

	/**
	 * Announce an event to all modules
	 *
	 * @event The name of the event to announce
	 * @args  The arguments to pass to the event: struct or array
	 */
	function announceToModules( required event, args = {} ){
		getActiveModules().each( ( moduleName, config ) => {
			if ( structKeyExists( config.moduleConfig, event ) ) {
				invoke( config.moduleConfig, event, args );
			}
		} );
	}

	/***************************************** PRIVATE ************************************************************/

	/**
	 * This method executes the tests in a bundle class according to type. If the testing was ok a true is returned.
	 *
	 * @bundlePath  The path of the Bundle class to test.
	 * @testResults The testing results object to keep track of results
	 * @callbacks   The callbacks struct or class
	 *
	 * @throws BundleRunnerMajorException
	 */
	private function testBundle(
		required bundlePath,
		required testResults,
		required callbacks
	){
		// create new target bundle and get its metadata
		try {
			var target = getBundle( arguments.bundlePath );
		}
		// CFML
		catch ( "AbstractComponentException" e ) {
			// Skip abstract components
			return this;
		}
		// BoxLang
		catch ( "AbstractClassException" e ) {
			// Skip abstract components
			return this;
		}

		// verify call backs
		if ( structKeyExists( arguments.callbacks, "onBundleStart" ) ) {
			arguments.callbacks.onBundleStart( target, testResults );
		}
		// Module call backs
		announceToModules( "onBundleStart", { target : target, testResults : testResults } );

		try {
			// Discover type?
			if ( structKeyExists( target, "run" ) ) {
				// Run via BDD Style
				new wheels.testbox.system.runners.BDDRunner( options = variables.options, testbox = this ).run(
					target,
					arguments.testResults,
					arguments.callbacks
				);
			} else {
				// Run via xUnit Style
				new wheels.testbox.system.runners.UnitRunner( options = variables.options, testbox = this ).run(
					target,
					arguments.testResults,
					arguments.callbacks
				);
			}
		} catch ( Any e ) {
			throw(
				message = "Error executing bundle - #arguments.bundlePath#  message: #e.message# #e.detail#",
				detail  = e.stackTrace,
				type    = "BundleRunnerMajorException"
			);
		}

		// Store debug buffer for this bundle
		arguments.testResults.storeDebugBuffer( target.getDebugBuffer() );

		// verify call backs
		if ( structKeyExists( arguments.callbacks, "onBundleEnd" ) ) {
			arguments.callbacks.onBundleEnd( target, testResults );
		}
		// Module call backs
		announceToModules( "onBundleEnd", { target : target, testResults : testResults } );

		return this;
	}

	/**
	 * Creates and returns a bundle class with spec capabilities if not inherited.
	 *
	 * @bundlePath The path to the Bundle class
	 *
	 * @throws AbstractComponentException - When an abstract component exists as a spec
	 */
	private any function getBundle( required bundlePath ){
		try {
			var bundle = createObject( "component", "#arguments.bundlePath#" );
		} catch ( "Application" e ) {
			if ( findNoCase( "abstract component", e.message ) ) {
				throw( type: "AbstractComponentException", message: "Skip abstract components" );
			}
			rethrow;
		}
		var familyPath = "wheels.testbox.system.BaseSpec";

		// check if base spec assigned
		if ( isInstanceOf( bundle, familyPath ) ) {
			return bundle;
		}

		// Else virtualize it
		var baseObject         = new wheels.testbox.system.BaseSpec();
		var excludedProperties = "";

		// Mix it up baby
		variables.utility.getMixerUtil().start( bundle );

		// Mix in the virtual methods
		for ( var key in baseObject ) {
			// If target has overriden method, then don't override it with mixin, simulated inheritance
			if ( NOT structKeyExists( bundle, key ) AND NOT listFindNoCase( excludedProperties, key ) ) {
				bundle.injectMixin( key, baseObject[ key ] );
			}
		}

		// Mix in virtual super class just in case we need it
		bundle.$super = baseObject;

		return bundle;
	}

	/**
	 * Get an array of spec paths from a directory
	 *
	 * @directory The directory information struct to test: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the class found, it must return true to process or false to continue process ]
	 */
	private function getSpecPaths( required directory ){
		var results            = [];
		var pathPatternMatcher = new wheels.testbox.system.modules.globber.models.PathPatternMatcher();

		// recurse default
		arguments.directory.recurse = (
			structKeyExists( arguments.directory, "recurse" ) ? arguments.directory.recurse : true
		);
		// clean up paths
		var bundleExpandedPath = expandPath( "/" & replace( arguments.directory.mapping, ".", "/", "all" ) );
		bundleExpandedPath     = replace( bundleExpandedPath, "\", "/", "all" );

		// search directory with filters
		var bundlesFound = directoryList(
			bundleExpandedPath,
			arguments.directory.recurse,
			"path",
			"",
			"asc",
			"file"
		).filter( ( path ) => {
			return pathPatternMatcher.matchPatterns( variables.bundlesPattern.listToArray( "|" ), path );
		} );

		// cleanup paths and store them for usage
		for ( var x = 1; x lte arrayLen( bundlesFound ); x++ ) {
			// filter closure exists and the filter does not match the path
			if (
				structKeyExists( arguments.directory, "filter" ) && !arguments.directory.filter(
					bundlesFound[ x ]
				)
			) {
				continue;
			}

			// If not in BoxLang, skip bx bundles
			if ( !variables.IS_BOXLANG and bundlesFound[ x ].listLast( "." ) eq "bx" ) {
				continue;
			}

			// standardize paths
			bundlesFound[ x ] = reReplace(
				reReplaceNoCase( bundlesFound[ x ], "\.(bx|cfc)", "" ),
				"(\\|/)",
				"/",
				"all"
			);
			// clean base out of them
			bundlesFound[ x ] = replace( bundlesFound[ x ], bundleExpandedPath, "" );
			// Clean out slashes and append the mapping.
			bundlesFound[ x ] = arguments.directory.mapping & reReplace( bundlesFound[ x ], "(\\|/)", ".", "all" );
			arrayAppend( results, bundlesFound[ x ] );
		}

		return results;
	}

	/**
	 * Inflate incoming labels from a simple string as a standard array
	 */
	private function inflateLabels( required any labels ){
		variables.labels = ( isSimpleValue( arguments.labels ) ? listToArray( arguments.labels ) : arguments.labels );
	}

	/**
	 * Inflate incoming excludes from a simple string as a standard array
	 */
	private function inflateExcludes( required any excludes ){
		variables.excludes = (
			isSimpleValue( arguments.excludes ) ? listToArray( arguments.excludes ) : arguments.excludes
		);
	}

	/**
	 * Inflate incoming bundles from a simple string as a standard array
	 */
	private function inflateBundles( required any bundles ){
		variables.bundles = (
			isSimpleValue( arguments.bundles ) ? listToArray( arguments.bundles ) : arguments.bundles
		);
	}

}
