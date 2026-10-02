/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A JSON reporter
 */
component extends="BaseReporter" {

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "JSON";
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
			resetHTMLResponse();
			getPageContextResponse().setContentType( "application/json" );
		}

		// prepare incoming params
		prepareIncomingParams();
		var memento = arguments.results.getMemento( includeDebugBuffer = true );
		// A spec's error holds the raw exception. Serializing its Java object graph
		// sent BoxLang into a StackOverflowError and lost the whole run (#3905), so
		// errors are reduced to plain values first. If serialization still fails,
		// keep the totals and each spec's name and status.
		var state = { "json" : "" };
		try {
			state.json = serializeJSON( $plainMemento( memento ) );
		} catch ( any e ) {
			state.json = serializeJSON( $fallbackMemento( memento, e ) );
		}
		return state.json;
	}

	/**
	 * The memento with every spec error, failure origin and bundle exception
	 * reduced to plain values, and every other value copied to a bounded depth.
	 */
	public struct function $plainMemento( required struct memento ){
		var out = {};
		for ( var key in arguments.memento ) {
			if ( key == "bundleStats" && isArray( arguments.memento[ key ] ) ) {
				out[ key ] = [];
				for ( var bundle in arguments.memento[ key ] ) {
					arrayAppend( out[ key ], $plainBundle( bundle ) );
				}
			} else {
				out[ key ] = $plainValue( arguments.memento[ key ], 8 );
			}
		}
		return out;
	}

	public struct function $plainBundle( required struct bundle ){
		var out = {};
		for ( var key in arguments.bundle ) {
			if ( key == "globalException" ) {
				out[ key ] = $plainError( arguments.bundle[ key ] );
			} else if ( key == "suiteStats" && isArray( arguments.bundle[ key ] ) ) {
				out[ key ] = $plainSuites( arguments.bundle[ key ] );
			} else {
				out[ key ] = $plainValue( arguments.bundle[ key ], 8 );
			}
		}
		return out;
	}

	public array function $plainSuites( required array suites ){
		var out = [];
		for ( var suite in arguments.suites ) {
			var plain = {};
			for ( var key in suite ) {
				if ( key == "specStats" && isArray( suite[ key ] ) ) {
					plain[ key ] = [];
					for ( var spec in suite[ key ] ) {
						arrayAppend( plain[ key ], $plainSpec( spec ) );
					}
				} else if ( key == "suiteStats" && isArray( suite[ key ] ) ) {
					plain[ key ] = $plainSuites( suite[ key ] );
				} else {
					plain[ key ] = $plainValue( suite[ key ], 8 );
				}
			}
			arrayAppend( out, plain );
		}
		return out;
	}

	public struct function $plainSpec( required struct spec ){
		var out = {};
		for ( var key in arguments.spec ) {
			if ( key == "error" ) {
				out[ key ] = $plainError( arguments.spec[ key ] );
			} else if ( key == "failOrigin" ) {
				out[ key ] = $plainFrames( arguments.spec[ key ] );
			} else {
				out[ key ] = $plainValue( arguments.spec[ key ], 8 );
			}
		}
		return out;
	}

	/**
	 * An exception as plain strings: type, message, detail, extendedInfo,
	 * errorCode, a bounded stack trace and template/line frames. An empty or
	 * simple value (no error) is returned as it is.
	 */
	public any function $plainError( any error ){
		if ( isNull( arguments.error ) ) {
			return "";
		}
		if ( isSimpleValue( arguments.error ) ) {
			return arguments.error;
		}
		if ( isStruct( arguments.error ) && structIsEmpty( arguments.error ) ) {
			return {};
		}
		var out = {};
		for ( var field in [ "type", "message", "detail", "extendedInfo", "errorCode" ] ) {
			out[ field ] = $plainField( arguments.error, field );
		}
		// Some engines wrap driver exceptions in objects that don't expose their
		// fields as struct keys (BoxLang): fall back to the Java message.
		if ( !len( out.message ) ) {
			out.message = $javaMessage( arguments.error );
		}
		var trace      = $plainField( arguments.error, "stackTrace" );
		out[ "stackTrace" ] = len( trace ) > 4000 ? left( trace, 4000 ) & "..." : trace;
		out.tagContext = $plainFrames( $rawField( arguments.error, "tagContext" ) );
		return out;
	}

	/**
	 * Stack frames as template, line, column and raw_trace (at most 50). BoxLang
	 * names the line field lineNumber.
	 */
	public array function $plainFrames( any frames ){
		var out = [];
		if ( isNull( arguments.frames ) || !isArray( arguments.frames ) ) {
			return out;
		}
		for ( var frame in arguments.frames ) {
			if ( arrayLen( out ) >= 50 ) {
				break;
			}
			if ( !isNull( frame ) && isStruct( frame ) ) {
				arrayAppend(
					out,
					{
						"template"  : $plainField( frame, "template" ),
						"line"      : len( $plainField( frame, "line" ) ) ? $plainField( frame, "line" ) : $plainField( frame, "lineNumber" ),
						"column"    : $plainField( frame, "column" ),
						"raw_trace" : $plainField( frame, "raw_trace" )
					}
				);
			}
		}
		return out;
	}

	/**
	 * A copy of a value with only simple values, arrays and structs, to the given
	 * depth. Anything else (Java objects, components, queries) becomes "".
	 */
	public any function $plainValue( any value, numeric depth = 8 ){
		if ( isNull( arguments.value ) ) {
			return "";
		}
		if ( isSimpleValue( arguments.value ) ) {
			return arguments.value;
		}
		if ( arguments.depth <= 0 ) {
			return "";
		}
		if ( isArray( arguments.value ) ) {
			var list = [];
			for ( var item in arguments.value ) {
				arrayAppend( list, isNull( item ) ? "" : $plainValue( item, arguments.depth - 1 ) );
			}
			return list;
		}
		if ( isStruct( arguments.value ) && !isObject( arguments.value ) ) {
			var copy = {};
			for ( var key in arguments.value ) {
				var raw     = $rawField( arguments.value, key );
				copy[ key ] = isNull( raw ) ? "" : $plainValue( raw, arguments.depth - 1 );
			}
			return copy;
		}
		return "";
	}

	/**
	 * Just the totals and each spec's name, status and failure message, for when
	 * the full results can't be serialized.
	 */
	public struct function $fallbackMemento( required struct memento, any error ){
		var out = {};
		for ( var key in [ "totalDuration", "totalBundles", "totalSuites", "totalSpecs", "totalPass", "totalFail", "totalError", "totalSkipped", "CFMLEngine", "CFMLEngineVersion", "version" ] ) {
			out[ key ] = $plainField( arguments.memento, key );
		}
		out.reportError = "The JSON reporter could not serialize the full results: "
		& ( isNull( arguments.error ) ? "" : $plainField( arguments.error, "message" ) );
		out.bundleStats = [];
		var bundles     = $rawField( arguments.memento, "bundleStats" );
		if ( !isNull( bundles ) && isArray( bundles ) ) {
			for ( var bundle in bundles ) {
				var plain = {};
				for ( var key in [ "id", "name", "path", "totalDuration", "totalSuites", "totalSpecs", "totalPass", "totalFail", "totalError", "totalSkipped" ] ) {
					plain[ key ] = $plainField( bundle, key );
				}
				var exception         = $rawField( bundle, "globalException" );
				plain.globalException = isNull( exception ) ? "" : $plainError( exception );
				var suites            = $rawField( bundle, "suiteStats" );
				plain.suiteStats      = ( !isNull( suites ) && isArray( suites ) ) ? $fallbackSuites( suites ) : [];
				arrayAppend( out.bundleStats, plain );
			}
		}
		return out;
	}

	public array function $fallbackSuites( required array suites ){
		var out = [];
		for ( var suite in arguments.suites ) {
			var plain = {};
			for ( var key in [ "id", "name", "status", "totalDuration", "totalSpecs", "totalPass", "totalFail", "totalError", "totalSkipped" ] ) {
				plain[ key ] = $plainField( suite, key );
			}
			plain.specStats = [];
			var specs       = $rawField( suite, "specStats" );
			if ( !isNull( specs ) && isArray( specs ) ) {
				for ( var spec in specs ) {
					arrayAppend(
						plain.specStats,
						{
							"id"            : $plainField( spec, "id" ),
							"name"          : $plainField( spec, "name" ),
							"displayName"   : $plainField( spec, "displayName" ),
							"status"        : $plainField( spec, "status" ),
							"totalDuration" : $plainField( spec, "totalDuration" ),
							"failMessage"   : $plainField( spec, "failMessage" )
						}
					);
				}
			}
			var children     = $rawField( suite, "suiteStats" );
			plain.suiteStats = ( !isNull( children ) && isArray( children ) ) ? $fallbackSuites( children ) : [];
			arrayAppend( out, plain );
		}
		return out;
	}

	/**
	 * A field of a struct or exception as a simple value, or "" when it is
	 * missing or not simple.
	 */
	public any function $plainField( any container, required string name ){
		var raw = $rawField( arguments.container, arguments.name );
		return ( !isNull( raw ) && isSimpleValue( raw ) ) ? raw : "";
	}

	/**
	 * A field of a struct or exception, or null when it can't be read.
	 */
	public any function $rawField( any container, required string name ){
		var state = { "found" : false, "value" : "" };
		if ( isNull( arguments.container ) || isSimpleValue( arguments.container ) ) {
			return;
		}
		try {
			if ( structKeyExists( arguments.container, arguments.name ) ) {
				state.value = arguments.container[ arguments.name ];
				state.found = !isNull( state.value );
			}
		} catch ( any e ) {
			// Not a struct on this engine: try the key directly below.
		}
		if ( !state.found ) {
			try {
				state.value = arguments.container[ arguments.name ];
				state.found = !isNull( state.value );
			} catch ( any e ) {
				// Unreadable on this engine: treat as missing.
			}
		}
		if ( state.found ) {
			return state.value;
		}
	}

	/**
	 * The message of a Java exception object, or "".
	 */
	public string function $javaMessage( any error ){
		var state = { "message" : "" };
		try {
			var message = arguments.error.getMessage();
			if ( !isNull( message ) && isSimpleValue( message ) ) {
				state.message = message;
			}
		} catch ( any e ) {
			// Not a Java exception.
		}
		return state.message;
	}

}
