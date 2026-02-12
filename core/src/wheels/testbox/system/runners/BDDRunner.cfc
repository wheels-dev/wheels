/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This TestBox runner is used to run and report on BDD style test suites.
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
		// Get target metadata
		var targetMD          = getMetadata( arguments.target );
		var tartetAnnotations = targetMD.keyExists( "annotations" ) ? targetMD.annotations : targetMD;
		var bundleName        = (
			structKeyExists( tartetAnnotations, "displayName" ) ? tartetAnnotations.displayname : targetMD.name
		);

		// Execute the suite descriptors
		arguments.target.run( testResults = arguments.testResults, testbox = variables.testbox );

		// Discover the test suite data to use for testing
		var testSuites      = getTestSuites( arguments.target, targetMD );
		var testSuitesCount = arrayLen( testSuites );

		// Start recording stats for this bundle
		var bundleStats = arguments.testResults.startBundleStats( bundlePath = targetMD.name, name = bundleName );

		// Verify we can run this bundle
		if (
			canRunBundle(
				bundlePath  = targetMD.name,
				testResults = arguments.testResults,
				targetMD    = targetMD
			)
		) {
			try {
				// execute beforeAll() for this bundle, no matter how many suites they have.
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

					// Test Suite
					testSuite(
						target     : arguments.target,
						suite      : thisSuite,
						testResults: arguments.testResults,
						bundleStats: bundleStats,
						callbacks  : arguments.callbacks
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

				// execute afterAll() for this bundle, no matter how many suites they have.
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
			} catch ( Any e ) {
				bundleStats.globalException = e;
				// For a righteous man falls seven times, and rises (tests) again :)
				// The amount doesn't matter, nothing can run at this point, failure with before/after aspects that need fixing
				bundleStats.totalError      = -1;
				arguments.testResults.incrementStat( type = "error", count = bundleStats.totalError );

				// Module call backs
				variables.testbox.announceToModules(
					"onSuiteError",
					[
						e,
						arguments.target,
						arguments.testResults,
						isNull( thisSuite ) ? {} : thisSuite
					]
				);
			}
		}
		// end if we can run bundle

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
	 * @parentStats If this is a nested test suite, then it will have some parentStats goodness
	 * @callbacks   The class or struct of callback listener methods
	 */
	private function testSuite(
		required target,
		required suite,
		required testResults,
		required bundleStats,
		required parentStats = {},
		required callbacks   = {}
	){
		// Start suite stats
		var suiteStats = arguments.testResults.startSuiteStats(
			arguments.suite,
			arguments.bundleStats,
			arguments.parentStats
		);
		// init consolidated spec labels
		var consolidatedLabels = [];
		// Build labels from nested suites, so suites inherit from parent suite labels
		var parentSuite        = arguments.suite;
		while ( !isSimpleValue( parentSuite ) ) {
			consolidatedLabels.append( parentSuite.labels, true );
			parentSuite = parentSuite.parentref;
		}

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
								attributes.suite,
								attributes.thisSpec
							);
						}
						// Module call backs
						variables.testbox.announceToModules(
							"onSpecStart",
							[
								thread.target,
								thread.testResults,
								attributes.suite,
								attributes.thisSpec
							]
						);

						// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
						thread.target.runSpec(
							spec        = attributes.thisSpec,
							suite       = attributes.suite,
							testResults = thread.testResults,
							suiteStats  = thread.suiteStats,
							runner      = this
						);

						// verify call backs
						if ( structKeyExists( attributes.callbacks, "onSpecEnd" ) ) {
							attributes.callbacks.onSpecEnd(
								thread.target,
								thread.testResults,
								attributes.suite,
								attributes.thisSpec
							);
						}
						// Module call backs
						variables.testbox.announceToModules(
							"onSpecEnd",
							[
								thread.target,
								thread.testResults,
								attributes.suite,
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
							arguments.suite,
							thisSpec
						);
					}
					// Module call backs
					variables.testbox.announceToModules(
						"onSpecStart",
						[
							arguments.target,
							arguments.testResults,
							arguments.suite,
							thisSpec
						]
					);

					// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
					thread.target.runSpec(
						spec       : thisSpec,
						suite      : arguments.suite,
						testResults: thread.testResults,
						suiteStats : thread.suiteStats,
						runner     : this
					);

					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSpecEnd" ) ) {
						arguments.callbacks.onSpecEnd(
							arguments.target,
							arguments.testResults,
							arguments.suite,
							thisSpec
						);
					}
					// Module call backs
					variables.testbox.announceToModules(
						"onSpecEnd",
						[
							arguments.target,
							arguments.testResults,
							arguments.suite,
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

			// Do we have any internal suites? If we do, test them recursively, go down the rabbit hole
			for ( var thisInternalSuite in arguments.suite.suites ) {
				// run the suite specs recursively
				var nestedStats = testSuite(
					target      = arguments.target,
					suite       = thisInternalSuite,
					testResults = arguments.testResults,
					bundleStats = arguments.bundleStats,
					parentStats = suiteStats,
					callbacks   = arguments.callbacks
				);

				// Add in nested stats to parent suite
				// These numbers will aggregate as we unroll the recursive calls
				suiteStats.totalError   = suiteStats.totalError + nestedStats.totalError;
				suiteStats.totalFail    = suiteStats.totalFail + nestedStats.totalFail;
				suiteStats.totalSkipped = suiteStats.totalSkipped + nestedStats.totalSkipped;
				suiteStats.totalPass    = suiteStats.totalPass + nestedStats.totalPass;
			}

			// All specs finalized, set suite status according to spec data
			if ( suiteStats.totalError GT 0 ) {
				suiteStats.status = "Error";
			} else if ( suiteStats.totalFail GT 0 ) {
				suiteStats.status = "Failed";
			} else {
				suiteStats.status = "Passed";
			}


			// Suite Skipped Status?
			if ( suiteStats.totalSpecs neq 0 && suiteStats.totalSpecs == suiteStats.totalSkipped ) {
				var suiteSkipped = true;
				// iterate over nested suites to discover if indeed skipped
				for ( var thisSuiteStat in suiteStats.suiteStats ) {
					// if not skipped, then short circuit it as not skipped
					if ( thisSuiteStat.status neq "Skipped" ) {
						suiteSkipped = false;
						break;
					}
				}
				// mark suite skipped if indeed it was skipped.
				if ( suiteSkipped ) {
					suiteStats.status = "Skipped";
				}
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
					arguments.suite
				]
			);
		}

		// Finalize the suite stats
		arguments.testResults.endStats( suiteStats );

		return suiteStats;
	}

	/************************************** DISCOVERY METHODS *********************************************/

	/**
	 * Get all the test suites in the passed in bundle
	 *
	 * @target   The target to get the suites from
	 * @targetMD The metdata of the target
	 */
	private array function getTestSuites( required target, required targetMD ){
		// get the spec suites
		return arguments.target.$suites;
	}

}
