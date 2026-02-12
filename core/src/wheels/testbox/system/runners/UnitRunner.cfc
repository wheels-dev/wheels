/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This TestBox runner is used to run and report on xUnit style test suites.
 */
component
	extends   ="wheels.testbox.system.runners.BaseRunner"
	implements="wheels.testbox.system.runners.IRunner"
	accessors ="true"
{

	// runner options
	property name="options";
	// testbox reference
	property name="testbox";

	/**
	 * Constructor
	 *
	 * @options The options for this runner
	 * @testbox The TestBox class reference
	 */
	function init( required struct options, required testBox ){
		variables.options = arguments.options;
		variables.testbox = arguments.testbox;

		return this;
	}

	/**
	 * Execute a BDD test on the incoming target and store the results in the incoming test results
	 *
	 * @target      The target bundle class to test
	 * @testResults The test results object to keep track of results for this test case
	 * @callbacks   A struct of listener callbacks or a class with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 */
	any function run(
		required any target,
		required wheels.testbox.system.TestResult testResults,
		required callbacks
	){
		// Get target information
		var targetMD          = getMetadata( arguments.target );
		var targetAnnotations = targetMD.keyExists( "annotations" ) ? targetMD.annotations : targetMD;
		var bundleName        = (
			structKeyExists( targetAnnotations, "displayName" ) ? targetAnnotations.displayname : targetMD.name
		);
		var bundlePath = targetMD.name;


		// Discover the test suite data to use for testing
		var testSuites = getTestSuites(
			arguments.target,
			targetMD,
			arguments.testResults
		);
		var testSuitesCount = arrayLen( testSuites );
		// Start recording stats for this bundle
		var bundleStats     = arguments.testResults.startBundleStats( bundlePath = bundlePath, name = bundleName );

		// Verify we can run this bundle
		if (
			canRunBundle(
				bundlePath  = bundlePath,
				testResults = arguments.testResults,
				targetMD    = targetMD
			)
		) {
			try {
				// execute beforeAll(), beforeTests() for this bundle, no matter how many suites they have.
				if ( structKeyExists( arguments.target, "beforeAll" ) ) {
					arguments.target.beforeAll();
				}

				// find any methods annotated 'beforeAll' and execute them
				var beforeAllAnnotationMethods = variables.testbox
					.getUtility()
					.getAnnotatedMethods( annotation = "beforeAll", metadata = targetMD );

				for ( var beforeAllMethod in beforeAllAnnotationMethods ) {
					invoke( arguments.target, "#beforeAllMethod.name#" );
				}

				if ( structKeyExists( arguments.target, "beforeTests" ) ) {
					arguments.target.beforeTests();
				}

				// Iterate over found test suites and test them, if nested suites, then this will recurse as well.
				for ( var thisSuite in testSuites ) {
					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSuiteStart" ) ) {
						arguments.callbacks.onSuiteStart(
							arguments.target,
							arguments.testResults,
							thisSuite
						);
					}
					// Module call backs
					variables.testbox.announceToModules(
						"onSuiteStart",
						[
							arguments.target,
							arguments.testResults,
							thisSuite
						]
					);

					// Execute Suite
					testSuite(
						target      = arguments.target,
						suite       = thisSuite,
						testResults = arguments.testResults,
						bundleStats = bundleStats,
						callbacks   = arguments.callbacks
					);

					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSuiteEnd" ) ) {
						arguments.callbacks.onSuiteEnd(
							arguments.target,
							arguments.testResults,
							thisSuite
						);
					}

					// Module call backs
					variables.testbox.announceToModules(
						"onSuiteEnd",
						[
							arguments.target,
							arguments.testResults,
							thisSuite
						]
					);
				}

				// execute afterAll(), afterTests() for this bundle, no matter how many suites they have.
				if ( structKeyExists( arguments.target, "afterAll" ) ) {
					arguments.target.afterAll();
				}

				// find any methods annotated 'afterAll' and execute them
				var afterAllAnnotationMethods = variables.testbox
					.getUtility()
					.getAnnotatedMethods( annotation = "afterAll", metadata = targetMD );

				for ( var afterAllMethod in afterAllAnnotationMethods ) {
					invoke( arguments.target, "#afterAllMethod.name#" );
				}

				if ( structKeyExists( arguments.target, "afterTests" ) ) {
					arguments.target.afterTests();
				}
			} catch ( Any e ) {
				bundleStats.globalException = e;
				// For a righteous man falls seven times, and rises (tests) again :)
				// The amount doesn't matter, nothing can run at this point, failure with before/after aspects that need fixing
				bundleStats.totalError      = 7;
				arguments.testResults.incrementStat( type = "error", count = bundleStats.totalError );

				variables.testbox.announceToModules(
					"onSuiteError",
					[ e, arguments.target, arguments.testResults ]
				);
			}
		}

		// finalize the bundle stats
		arguments.testResults.endStats( bundleStats );

		return this;
	}

	/************************************** TESTING METHODS *********************************************/

	/**
	 * Test the incoming suite definition
	 *
	 * @target      The target bundle class
	 * @method      The method definition to test
	 * @testResults The testing results object
	 * @bundleStats The bundle stats this suite belongs to
	 * @callbacks   The class or struct of callback listener methods
	 */
	private function testSuite(
		required target,
		required suite,
		required testResults,
		required bundleStats,
		required callbacks = {}
	){
		// Start suite stats
		var suiteStats = arguments.testResults.startSuiteStats( arguments.suite, arguments.bundleStats );

		// Record bundle + suite + global initial stats
		suiteStats.totalSpecs = arrayLen( arguments.suite.specs );
		arguments.bundleStats.totalSpecs += suiteStats.totalSpecs;
		arguments.bundleStats.totalSuites++;
		// increment global suites + specs
		arguments.testResults.incrementSuites().incrementSpecs( suiteStats.totalSpecs );

		// Verify we can execute the incoming suite via skipping or labels
		if (
			!arguments.suite.skip &&
			canRunSuite(
				arguments.suite,
				arguments.testResults,
				arguments.target
			)
		) {
			// prepare threaded names
			var threadNames    = [];
			// threaded variables just in case some suite is async and another is not.
			thread.testResults = arguments.testResults;
			thread.suiteStats  = suiteStats;
			thread.target      = arguments.target;

			// iterate over suite specs and test them
			for ( var thisSpec in arguments.suite.specs ) {
				// is this async or not?
				if ( arguments.suite.asyncAll ) {
					// prepare thread name
					var thisThreadName = variables.testBox
						.getUtility()
						.slugify( "tb-" & thisSpec.name & "-#hash( getTickCount() + randRange( 1, 10000000 ) )#" );
					// append to used thread names
					arrayAppend( threadNames, thisThreadName );
					// thread it
					thread
						name      ="#thisThreadName#"
						thisSpec  ="#thisSpec#"
						suite     ="#arguments.suite#"
						threadName="#thisThreadName#"
						callbacks ="#arguments.callbacks#" {
						// verify call backs
						if ( structKeyExists( attributes.callbacks, "onSpecStart" ) ) {
							attributes.callbacks.onSpecStart(
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							);
						}

						// Module call backs
						variables.testbox.announceToModules(
							"onSpecStart",
							[
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							]
						);

						// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
						thread.target.runTestMethod(
							spec        = attributes.thisSpec,
							testResults = thread.testResults,
							suiteStats  = thread.suiteStats,
							runner      = this
						);

						// verify call backs
						if ( structKeyExists( attributes.callbacks, "onSpecEnd" ) ) {
							attributes.callbacks.onSpecEnd(
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							);
						}

						// Module call backs
						variables.testbox.announceToModules(
							"onSpecEnd",
							[
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							]
						);
					}
				} else {
					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSpecStart" ) ) {
						arguments.callbacks.onSpecStart(
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						);
					}

					// Module call backs
					variables.testbox.announceToModules(
						"onSpecStart",
						[
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						]
					);

					// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
					thread.target.runTestMethod(
						spec        = thisSpec,
						testResults = thread.testResults,
						suiteStats  = thread.suiteStats,
						runner      = this
					);

					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSpecEnd" ) ) {
						arguments.callbacks.onSpecEnd(
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						);
					}

					// Module call backs
					variables.testbox.announceToModules(
						"onSpecEnd",
						[
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						]
					);
				}
			}
			// end loop over specs

			// join threads if async
			if ( arguments.suite.asyncAll ) {
				thread action="join" name="#arrayToList( threadNames )#" {
				};
			}

			// All specs finalized, set suite status according to spec data
			if ( suiteStats.totalError GT 0 ) {
				suiteStats.status = "Error";
			} else if ( suiteStats.totalFail GT 0 ) {
				suiteStats.status = "Failed";
			} else {
				suiteStats.status = "Passed";
			}

			// Skip Checks
			if ( suiteStats.totalSpecs == suiteStats.totalSkipped ) {
				suiteStats.status = "Skipped";
			}
		} else {
			// Record skipped stats and status
			suiteStats.status = "Skipped";
			arguments.bundleStats.totalSkipped += suiteStats.totalSpecs;
			arguments.testResults.incrementStat( "skipped", suiteStats.totalSpecs );
			// Module call backs
			variables.testbox.announceToModules(
				"onSuiteSkipped",
				[
					arguments.target,
					arguments.testResults,
					suiteStats,
					arguments.bundleStats
				]
			);
		}

		// Finalize the suite stats
		arguments.testResults.endStats( suiteStats );
	}

	/**
	 * Get all the test suites in the passed in bundle
	 *
	 * @target      The target to get the suites from
	 * @targetMD    The metadata of the target
	 * @testResults The test results object
	 */
	private array function getTestSuites(
		required target,
		required targetMD,
		required testResults
	){
		var annotations = targetMD.keyExists( "annotations" ) ? arguments.targetMD.annotations : arguments.targetMD;
		var suite       = {
			// ID
			"id"   : hash( arguments.targetMD.name ),
			// suite name
			"name" : (
				structKeyExists( annotations, "displayName" ) ? annotations.displayname : arguments.targetMD.name
			),
			// async flag
			"asyncAll" : ( structKeyExists( annotations, "asyncAll" ) ? annotations.asyncAll : false ),
			// skip suite testing flag
			"skip"     : (
				structKeyExists( annotations, "skip" ) ? ( len( annotations.skip ) ? annotations.skip : true ) : false
			),
			// labels attached to the suite for execution
			"labels" : ( structKeyExists( annotations, "labels" ) ? listToArray( annotations.labels ) : [] ),
			// the specs attached to this suite.
			"specs"  : getTestMethods( arguments.target, arguments.testResults ),
			// nested suites
			"suites" : []
		};

		// skip constraint for suite?
		if ( !isBoolean( suite.skip ) && isCustomFunction( arguments.target[ suite.skip ] ) ) {
			suite.skip = invoke( arguments.target, "#suite.skip#" );
		}

		// check them.
		if ( arrayLen( arguments.testResults.getLabels() ) )
			suite.skip = ( !canRunLabel( suite.labels, arguments.testResults ) );

		return [ suite ];
	}

	/**
	 * Retrieve the testing methods/specs from a given target.
	 *
	 * @target      The target to get the methods from
	 * @testResults The test results object
	 *
	 * @return An array of method specs
	 */
	private array function getTestMethods( required any target, required any testResults ){
		var mResults    = [];
		var methodArray = structKeyArray( arguments.target );
		var index       = 1;

		for ( var thisMethod in methodArray ) {
			// only valid functions and test functions allowed
			if (
				(
					isCustomFunction( arguments.target[ thisMethod ] ) || isClosure(
						arguments.target[ thisMethod ]
					)
				)
				&&
				isValidTestMethod( thisMethod, arguments.target )
			) {
				// Build the spec data packet
				var specMD            = getMetadata( arguments.target[ thisMethod ] );
				// BoxLang when not in compat mode has annontations and documentation separated in metadata
				var specAnnotations   = specMD.keyExists( "annotations" ) ? specMD.annotations : specMD;
				var specDocumentation = specMD.keyExists( "documentation" ) ? specMD.documentation : specMD;
				var spec              = {
					"id"          : hash( specMD.name ),
					"name"        : specMD.name,
					"displayName" : (
						structKeyExists( specAnnotations, "displayName" ) ? specAnnotations.displayName : specMD.name
					),
					"hint" : ( structKeyExists( specDocumentation, "hint" ) ? specDocumentation : "" ),
					"skip" : (
						structKeyExists( specAnnotations, "skip" ) ? (
							len( specAnnotations.skip ) ? specAnnotations.skip : true
						) : false
					),
					"focused" : (
						structKeyExists( specAnnotations, "focused" ) ? (
							len( specAnnotations.focused ) ? specAnnotations.focused : true
						) : false
					),
					"labels" : (
						structKeyExists( specAnnotations, "labels" ) ? listToArray( specAnnotations.labels ) : []
					),
					"order" : (
						structKeyExists( specAnnotations, "order" ) ? listToArray( specAnnotations.order ) : index++
					),
					"expectedException" : (
						structKeyExists( specAnnotations, "expectedException" ) ? (
							len( specAnnotations.expectedException ) ? specAnnotations.expectedException : true
						) : false
					)
				};

				// skip constraint?
				if ( !isBoolean( spec.skip ) && isCustomFunction( arguments.target[ spec.skip ] ) ) {
					spec.skip = invoke( arguments.target, spec.skip );
				}

				// do we have labels applied?
				if ( arrayLen( arguments.testResults.getLabels() ) )
					spec.skip = ( !canRunLabel( spec.labels, arguments.testResults ) );

				// register spec
				arrayAppend( mResults, spec );
			}
		}
		return mResults;
	}

}
