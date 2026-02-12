/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A JUnit reporter for use with the ANT junitreport task, which uses an old version of JUnit formatting.
 */
component extends="BaseReporter" {

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "ANTJUnit";
	}

	/**
	 * Do the reporting thing here using the incoming test results
	 * The report should return back in whatever format they desire and should set any
	 * Specifc browser types if needed.
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
			resetHTMLResponse();
			getPageContextResponse().setContentType( "application/xml" );
		}

		// prepare incoming params
		prepareIncomingParams();

		return toJUnit( arguments.results );
	}

	private function toJUnit( required results ){
		var buffer = createObject( "java", "java.lang.StringBuilder" ).init( "" );
		var r      = arguments.results;

		// build top level test suites container
		buffer.append( "<testsuites>" );

		// iterate over bundles
		var bundlestats = r.getBundleStats();
		for ( var thisBundle in bundleStats ) {
			// excluding "empty" test suites
			if (
				structKeyExists( url, "testBundles" ) AND len( url.testBundles ) and !listFindNoCase(
					url.testBundles,
					thisBundle.path
				)
			) {
				continue;
			}

			// build test suite header
			// cfformat-ignore-start
			buffer.append(
				"<testsuite
				tests=""#thisBundle.totalSpecs#""
				failures=""#thisBundle.totalFail#""
				errors=""#thisBundle.totalError#""
				skipped=""#thisBundle.totalSkipped#""
				time=""#thisBundle.totalDuration / 1000#""
				timestamp=""#dateFormat( now(), "yyyy-mm-dd" )#T#timeFormat( now(), "HH:mm:ss" )#""
				hostname=""#encodeForXMLAttribute( cgi.remote_host )#""
				package=""#encodeForXMLAttribute( thisBundle.path )#""
				name=""#encodeForXMLAttribute( thisBundle.name )#""
				>"
			);
			// cfformat-ignore-end

			// build out properties
			// buildProperties( buffer );

			// build out tests, even if nested, treat as single threaded
			buildTestSuites( buffer, r, thisBundle, thisBundle.suiteStats );

			// close header
			buffer.append( "</testsuite>" );
		}

		buffer.append( "</testsuites>" );

		return buffer.toString();
	}

	private function buildTestSuites(
		required buffer,
		required results,
		required bundleStats,
		required suiteStats,
		parentName = ""
	){
		var r     = arguments.results;
		var out   = arguments.buffer;
		var stats = arguments.suiteStats;
		var index = 1;

		// Do we have a global exception?
		if ( !isSimpleValue( arguments.bundleStats.globalException ) ) {
			// build test case
			// cfformat-ignore-start
			out.append(
				"<testcase
				name=""#encodeForXMLAttribute( arguments.bundleStats.name )#""
				time=""#arguments.bundleStats.totalDuration / 1000#""
				classname=""#arguments.bundleStats.path#""
				>
					<error
						type=""globalException""
						message=""#encodeForXMLAttribute( arguments.bundleStats.globalException.message )#""><![CDATA[
						#arguments.bundleStats.globalException.stackTrace.toString()#
					]]></error>
			</testcase>
			"
			);
			// cfformat-ignore-end
return;
		}

		// iterate over
		for ( var thisSuite in arguments.suiteStats ) {
			// build out full suite name
			var fullName = arguments.parentName & thisSuite.name;

			// build out test cases
			for ( var thisSpecStat in thisSuite.specStats ) {
				buildTestCase(
					out,
					r,
					thisSpecStat,
					arguments.bundleStats,
					fullName
				);
			}

			// Check embedded suites
			if ( arrayLen( thisSuite.suiteStats ) ) {
				buildTestSuites(
					out,
					r,
					arguments.bundlestats,
					thisSuite.suiteStats,
					fullName & " "
				);
			}
		}
	}

	private function buildTestCase(
		required buffer,
		required results,
		required specStats,
		required bundleStats,
		required fullName
	){
		var r     = arguments.results;
		var out   = arguments.buffer;
		var stats = arguments.specStats;

		// build test case
		// cfformat-ignore-start
		out.append(
			"<testcase
			name=""#encodeForXMLAttribute( fullName & " " & stats.name )#""
			time=""#stats.totalDuration / 1000#""
			classname=""#arguments.bundleStats.path#""
			>"
		);

		switch ( stats.status ) {
			case "failed": {
				out.append(
					"<failure message=""#encodeForXMLAttribute( stats.failMessage )#""><![CDATA["
				);
				if ( isArray( stats.failOrigin ) && arrayLen( stats.failOrigin ) ) {
					for ( var thisContext in stats.failOrigin ) {
						if ( findNoCase( arguments.bundleStats.path, reReplace( thisContext.template, "(/|\\)", ".", "all" ) ) ) {
							if ( structKeyExists( thisContext, "codePrintPlain" ) ) {
								out.append(
									"#thisContext.codePrintPlain#"
								);
							}
							out.append(
								"#thisContext.template#:#thisContext.line#"
							);
						}
					}
				}
				if ( !isNull( stats.failDetail ) && len( stats.failDetail ) ) {
					out.append(
						"Failure Details: #stats.failDetail#"
					);
				}
				if ( !isNull( stats.failExtendedInfo ) &&  len( stats.failExtendedInfo ) ) {
					out.append(
						"Failure Extended Info: #stats.failExtendedInfo#"
					);
				}
				out.append(
					"]]></failure>"
				);
				break;
			}
			case "skipped": {
				out.append( "<skipped></skipped>" );
				break;
			}
			case "error": {
				out.append(
					"<error type=""#encodeForXMLAttribute( !isNull( stats.error.type ) ? stats.error.type : '' )#"" message=""#encodeForXMLAttribute( stats.error.message )#""><![CDATA[
					#stats.error.stackTrace.toString()#
					]]></error>"
				);
				break;
			}
		}
		// cfformat-ignore-end

		out.append( "</testcase>" );
	}

	private function buildProperties( required buffer ){
		var out = arguments.buffer;

		out.append( "<properties>" );

		genPropsFromCollection( out, server.coldfusion );
		genPropsFromCollection( out, server.os );
		if ( structKeyExists( server, "lucee" ) ) {
			genPropsFromCollection( out, server.lucee );
		}
		genPropsFromCollection( out, cgi );

		out.append( "</properties>" );
	}

	private function genPropsFromCollection( required buffer, required collection ){
		for ( var thisProp in arguments.collection ) {
			// null check
			if ( isNull( arguments.collection[ thisProp ] ) ) {
				continue;
			}
			if ( isSimpleValue( arguments.collection[ thisProp ] ) ) {
				// This is for a nasty Lucee regression where server.os.MacAddress is null, yet isNull() checks say it isn't.
				// Try/catch is the only way to detect this right now :/
				// Regression known to exist in Lucee 5.2.8.50
				try {
					arguments.buffer.append(
						"<property name=""#encodeForXMLAttribute( lCase( thisProp ) )#"" value=""#encodeForXMLAttribute( arguments.collection[ thisProp ] )#"" />"
					);
				} catch ( any e ) {
					arguments.buffer.append(
						"<property name=""#encodeForXMLAttribute( lCase( thisProp ) )#"" value="""" />"
					);
				}
			} else if (
				isArray( arguments.collection[ thisProp ] ) OR
				isStruct( arguments.collection[ thisProp ] ) OR
				isQuery( arguments.collection[ thisProp ] )
			) {
				arguments.buffer.append(
					"<property name=""#encodeForXMLAttribute( lCase( thisProp ) )#"" value=""#encodeForXMLAttribute( arguments.collection[ thisProp ].toString() )#"" />"
				);
			}
		}
	}

}
