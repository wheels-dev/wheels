/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This TestBox runner is used to run and report on xUnit style test suites.
 */
interface {

	/**
	 * Constructor
	 *
	 * @options The options for a runner
	 * @testbox The TestBox class reference
	 */
	function init( required struct options, required testbox );

	/**
	 * Execute a test run on a target bundle class
	 *
	 * @target      The target bundle class to test
	 * @testResults The test results object to keep track of results for this test case
	 * @callbacks   A struct of listener callbacks or a class with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 */
	any function run(
		required any target,
		required wheels.testbox.system.TestResult testResults,
		required callbacks
	);

}
