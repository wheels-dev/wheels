/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A text reporter
 */
component extends="BaseReporter" {

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "Text";
	}

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
	){
		if ( !arguments.justReturn ) {
			// content type
			getPageContextResponse().setContentType( "text/plain" );
		}
		// bundle stats
		variables.bundleStats = arguments.results.getBundleStats();
		// prepare incoming params
		prepareIncomingParams();
		// prepare the report
		savecontent variable="local.report" {
			include "assets/text.cfm";
		}
		return reReplace(
			trim( local.report ),
			"[\r\n]+",
			chr( 10 ),
			"all"
		);
	}

	/**
	 * Get the indicator status text
	 *
	 * @status The status to get back: error, failed, skipped, passed
	 */
	function getStatusIndicator( required status ){
		if ( arguments.status == "error" ) {
			return "!!";
		} else if ( arguments.status == "failed" ) {
			return "X";
		} else if ( arguments.status == "skipped" ) {
			return "-";
		} else {
			return "√";
		}
	}

	function getBundleIndicator( required bundle ){
		var thisStatus = "pass";
		if ( arguments.bundle.totalFail > 0 || arguments.bundle.totalError > 0 ) {
			thisStatus = "error";
		}
		if ( arguments.bundle.totalSkipped == arguments.bundle.totalSpecs ) {
			thisStatus = "skipped";
		}
		return getStatusIndicator( thisStatus );
	}

	function space( count = 1 ){
		return repeatString( "#chr( 160 )#", arguments.count );
	}

	function tab(){
		return space( 4 );
	}

}
