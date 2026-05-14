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
		required wheels.wheelstest.system.TestResult results,
		required wheels.wheelstest.system.TestBox testbox,
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
		// prepare the report inline (the upstream "assets/text.cfm" template
		// is not vendored alongside this CFC — see issue #2675)
		var nl = chr( 10 );
		savecontent variable="local.report" {
			writeOutput( repeatString( "=", 64 ) & nl );
			writeOutput( "TEST RESULTS - " & arguments.results.getCFMLEngine() & " " & arguments.results.getCFMLEngineVersion() & nl );
			writeOutput( repeatString( "=", 64 ) & nl );
			writeOutput( "Duration: " & arguments.results.getTotalDuration() & "ms" & nl );
			writeOutput( "Bundles:  " & arguments.results.getTotalBundles() & nl );
			writeOutput( "Suites:   " & arguments.results.getTotalSuites() & nl );
			writeOutput( "Specs:    " & arguments.results.getTotalSpecs() & nl );
			writeOutput( "Passed:   " & arguments.results.getTotalPass() & nl );
			writeOutput( "Failed:   " & arguments.results.getTotalFail() & nl );
			writeOutput( "Errored:  " & arguments.results.getTotalError() & nl );
			writeOutput( "Skipped:  " & arguments.results.getTotalSkipped() & nl );
			if ( arrayLen( arguments.results.getLabels() ) ) {
				writeOutput( "Labels:   " & arrayToList( arguments.results.getLabels(), ", " ) & nl );
			}
			writeOutput( repeatString( "=", 64 ) & nl );
			for ( var bundle in variables.bundleStats ) {
				writeOutput( nl );
				writeOutput( getBundleIndicator( bundle ) & " " & bundle.path & " (" & bundle.totalDuration & "ms)" & nl );
				if ( isStruct( bundle.globalException ) && structKeyExists( bundle.globalException, "message" ) ) {
					writeOutput( tab() & "Bundle Exception: " & bundle.globalException.message & nl );
				}
				for ( var suite in bundle.suiteStats ) {
					$renderSuiteText( suite = suite, depth = 1, nl = nl );
				}
			}
		}
		return reReplace(
			trim( local.report ),
			"[\r\n]+",
			chr( 10 ),
			"all"
		);
	}

	/**
	 * Recursively render a suite and its nested suites/specs as plain text.
	 *
	 * @suite The suite stats struct
	 * @depth Indent depth (1-based)
	 * @nl    Newline character to emit
	 */
	function $renderSuiteText( required struct suite, required numeric depth, required string nl ){
		var indent = repeatString( "  ", arguments.depth );
		writeOutput( indent & arguments.suite.name & " (" & arguments.suite.totalDuration & "ms)" & arguments.nl );
		for ( var spec in arguments.suite.specStats ) {
			var statusKey = lCase( spec.status );
			writeOutput( indent & "  " & getStatusIndicator( statusKey ) & " " & spec.name & arguments.nl );
			if ( ( statusKey == "failed" || statusKey == "error" ) && len( spec.failMessage ) ) {
				writeOutput( indent & "      " & spec.failMessage & arguments.nl );
			}
		}
		for ( var childSuite in arguments.suite.suiteStats ) {
			$renderSuiteText( suite = childSuite, depth = arguments.depth + 1, nl = arguments.nl );
		}
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
