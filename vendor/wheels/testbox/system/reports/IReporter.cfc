/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * The TestBox main reporting interface for producing awesome testing reports
 */
interface {

	/**
	 * Get the name of the reporter
	 */
	function getName();

	/**
	 * Do the reporting thing here using the incoming test results
	 * The report should return back in whatever format they desire and should set any
	 * Specific browser types if needed.
	 *
	 * @results    The instance of the TestBox TestResult object to build a report on
	 * @testbox    The TestBox core object
	 * @options    A structure of options this reporter needs to build the report with
	 * @justReturn Boolean flag that if set just returns the content with no content type and buffer reset
	 */
	any function runReport(
		required wheels.testbox.system.TestResult results,
		required wheels.testbox.system.TestBox testbox,
		struct options     = {},
		boolean justReturn = false
	);

}
