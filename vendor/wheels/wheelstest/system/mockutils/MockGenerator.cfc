/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is the MockGenerator class responsible for generating method and class stubs
 * for mocking purposes.
 */
component accessors="true" {

	/**
	 * MockBox instance
	 */
	property name="mockbox";

	/**
	 * Remove stubs after generation
	 */
	property
		name   ="removeStubs"
		type   ="boolean"
		default="true";

	/**
	 * Constructor
	 *
	 * @mockBox     The MockBox instance
	 * @removeStubs Remove the stubs after generation
	 */
	function init( required any mockBox, boolean removeStubs = true ){
		variables.lb          = "#chr( 13 )##chr( 10 )#";
		variables.mockBox     = arguments.mockBox;
		variables.removeStubs = arguments.removeStubs;
		return this;
	}

	/**
	 * Generate a method stub for a target object
	 *
	 * @method             The method name
	 * @preserveReturnType Preserve the return type of the method
	 * @throwException     Throw an exception when the method is called
	 * @throwType          The exception type
	 * @throwDetail        The exception detail
	 * @throwMessage       The exception message
	 * @throwErrorCode     The exception error code
	 * @metadata           The metadata of the method
	 * @targetObject       The target object to generate the stub for
	 * @callLogging        Log the method call
	 * @preserveArguments  Preserve the arguments of the method
	 * @callback           The callback to execute
	 *
	 * @return The return value of the method
	 */
	function generate(
		required string method,
		any returns,
		boolean preserveReturnType = true,
		boolean throwException     = false,
		string throwType           = "",
		string throwDetail         = "",
		string throwMessage        = "",
		string throwErrorCode      = "",
		any metadata               = "",
		required any targetObject,
		boolean callLogging       = false,
		boolean preserveArguments = false,
		any callback
	){
		var udfOut         = createObject( "java", "java.lang.StringBuilder" ).init( "" );
		var genPath        = expandPath( variables.mockBox.getGenerationPath() );
		var tmpFile        = "";
		var fncMD          = arguments.metadata;
		var isReservedName = false;
		var safeMethodName = arguments.method;
		var stubCode       = "";

		// Check reserved list and if so, rename it so we can include it, stupid CF
		if ( structKeyExists( getFunctionList(), arguments.method ) ) {
			isReservedName = true;
			safeMethodName = "$reserved_#arguments.method#";
		}

		// Create Method Signature
		// cfformat-ignore-start
		udfOut.append(
			"<c" & "fsc" & "ript>
			variables[ ""#safeMethodName#"" ] = variables[ ""@@tmpMethodName@@"" ];
			this[ ""#safeMethodName#"" ]           = variables[ ""@@tmpMethodName@@"" ];

			// Clean up
			structDelete( variables, ""@@tmpMethodName@@"" );
			structDelete( this, ""@@tmpMethodName@@"" );
			#fncMD.access# #fncMD.returntype# function @@tmpMethodName@@( #variables.lb#"
		);


		// Create Arguments Signature
		if ( structKeyExists( fncMD, "parameters" ) AND arguments.preserveArguments ) {
			for ( var x = 1; x lte arrayLen( fncMD.parameters ); x++ ) {
				var thisParam = fncMD.parameters[ x ];
				udfOut.append( "						" );

				// Is it required?
				if ( !isNull( thisParam.required ) && thisParam.required ) {
					udfOut.append( "required " );
				}

				// If we have a type, add it
				if ( !isNull( thisParam.type ) ) {
					udfOut.append( thisParam.type & " " );
				}

				// Param name and default
				udfOut.append( thisParam.name & " " );
				if ( !isNull( thisParam.default ) && thisParam.default != "[runtime expression]" ) {
					udfOut.append( "= " & outputQuotedValue( thisParam.default ) & " " );
				}

				// Remove these standard keys
				structDelete( thisParam, "default" );
				structDelete( thisParam, "name" );
				structDelete( thisParam, "nameAsKey" );
				structDelete( thisParam, "required" );
				structDelete( thisParam, "type" );
				structDelete( thisParam, "documentation" );

				// If we have an annotations block, merge it and remove it
				if( structKeyExists( thisParam, "annotations" ) ) {
					thisParam.append( thisParam.annotations, true );
					structDelete( thisParam, "annotations" );
				}

				// Just loop over the rest and output them
				for ( var thisParamProp in thisParam ) {
					udfOut.append( thisParamProp & " = " & outputQuotedValue( thisParam[ thisParamProp ] ) & " " );
				}

				// Comma if not last
				if ( x < arrayLen( fncMD.parameters ) ) {
					udfOut.append( "," );
				}

				udfOut.append( "#variables.lb#" );
			}
		}

		// Close Argument list and output
		udfOut.append(
			"
			) output=#fncMD.output# {#variables.lb# "
		);

		// Continue Method Generation
		udfOut.append(
			"
			var results                 = this._mockResults;
			var resultsKey           = ""#arguments.method#"";
			var resultsCounter   = 0;
			var internalCounter = 0;
			var resultsLen           = 0;
			var callbackLen         = 0;
			var argsHashKey         = resultsKey & ""|"" & this.mockBox.normalizeArguments( arguments );
			var fCallBack             = """";

			// If Method & argument Hash Results, switch the results struct
if (structKeyExists( this._mockArgResults, argsHashKey) ) {
										// Check if it is a callback
if (isStruct( this._mockArgResults[ argsHashKey ]) &&
												structKeyExists( this._mockArgResults[ argsHashKey ], ""type"" ) &&
												structKeyExists( this._mockArgResults[ argsHashKey ], ""target"" ) ) {
																	fCallBack = this._mockArgResults[ argsHashKey ].target;
} else {
																	// switch context and key
																	results       = this._mockArgResults;
																	resultsKey = argsHashKey;
										}
			}

			// Get the statemachine counter
if (isSimpleValue( fCallBack) ) {
										resultsLen = arrayLen( results[ resultsKey ] );
			}

			// Get the callback counter, if it exists
if (structKeyExists( this._mockCallbacks, resultsKey) ) {
										callbackLen = arrayLen( this._mockCallbacks[ resultsKey ] );
			}

			// Log the Method Call
			this._mockMethodCallCounters[ listFirst( resultsKey, ""|"" ) ] = this._mockMethodCallCounters[ listFirst( resultsKey, ""|"" ) ] + 1;

			// Get the CallCounter Reference
			internalCounter = this._mockMethodCallCounters[listFirst(resultsKey,""|"")];
			"
		);

		// Call Logging argument or Global Flag
		if ( arguments.callLogging OR arguments.targetObject._mockCallLoggingActive ) {
			udfOut.append( "arrayAppend( this._mockCallLoggers[""#arguments.method#""], arguments );#variables.lb#" );
		}

		// Exceptions? To Throw
		if ( arguments.throwException ) {
			udfOut.append(
				"
				throw(
					#outputQuotedValue( arguments.throwMessage )#,
					#outputQuotedValue( arguments.throwType )#,
					#outputQuotedValue( arguments.throwDetail )#,
					#outputQuotedValue( arguments.throwErrorCode )#
				);#variables.lb#"
			);
		}

		// Returns Something according to metadata?
		if ( fncMD[ "returntype" ] neq "void" ) {
			udfOut.append(
				"
					if (resultsLen neq 0) {
						if (internalCounter gt resultsLen) {
							resultsCounter = internalCounter - ( resultsLen * fix( ( internalCounter - 1 ) / resultsLen ) );
							return results[ resultsKey ][ resultsCounter ];
						} else {
							return results[ resultsKey ][ internalCounter ];
						}
					}
					"
			);

			// Callback Single
			udfOut.append(
				"
					if ( callbackLen neq 0 ) {
						fCallBack = this._mockCallbacks[ resultsKey ].first();
						return fCallBack( argumentCollection : arguments );
					}
					"
			);

			// Callback Args
			udfOut.append(
				"
					if ( not isSimpleValue( fCallBack ) ){
						return fCallBack( argumentCollection : arguments );
					}
				"
			);
		}
		udfOut.append( "}#variables.lb#" );
		udfOut.append( "</c" & "fsc" & "ript>" );
		// cfformat-ignore-end

		// Write it out
		stubCode = trim( udfOUt.toString() );
		tmpFile  = hash( stubCode ) & ".cfm";

		// This is necessary for methods named after CF keywords like "contains"
		var tmpMethodName = "tmp_#arguments.method#_" & hash( stubCode );
		stubCode          = replaceNoCase(
			stubCode,
			"@@tmpMethodName@@",
			tmpMethodName,
			"all"
		);

		if ( !fileExists( genPath & tmpFile ) ) {
			writeStub( genPath & tmpFile, stubCode );
		}

		// Mix In Stub
		try {
			// include it
			arguments.targetObject.$include = variables.$include;
			arguments.targetObject.$include( variables.mockBox.getGenerationPath() & tmpFile );
			structDelete( arguments.targetObject, "$include" );

			// reserved rename to original
			if ( isReservedName ) {
				arguments.targetObject[ arguments.method ] = arguments.targetObject[ safeMethodName ];
			}

			// Remove Stub
			removeStub( genPath & tmpFile );
		} catch ( Any e ) {
			// Remove Stub
			removeStub( genPath & tmpFile );
			rethrow;
		}
	}

	/**
	 * Output a quoted value
	 *
	 * @value The value to quote
	 */
	function outputQuotedValue( required string value ){
		return """#replaceNoCase( value, """", """""", "all" )#""";
	}

	/**
	 * Write a stub to disk
	 *
	 * @genPath The generation path
	 * @code    The code to write
	 */
	function writeStub( required string genPath, required string code ){
		fileWrite( arguments.genPath, arguments.code );
	}

	/**
	 * Remove a stub from disk
	 *
	 * @genPath The generation path
	 */
	boolean function removeStub( required string genPath ){
		if ( fileExists( arguments.genPath ) && variables.removeStubs ) {
			fileDelete( arguments.genPath );
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Generate a class stub
	 *
	 * @extends    The class to extend
	 * @implements The interfaces to implement
	 */
	function generateClass( string extends = "", string implements = "" ){
		var udfOut    = createObject( "java", "java.lang.StringBuilder" ).init( "" );
		var genPath   = expandPath( variables.mockBox.getGenerationPath() );
		var tmpFile   = "";
		var classPath = "";
		var oStub     = "";
		var local     = {};
		var stubCode  = "";

		// Create CFC Signature
		udfOut.append( "<c" & "fcomponent output=""false"" hint=""A MockBox awesome Component""" );

		// extends
		if ( len( trim( arguments.extends ) ) ) {
			udfOut.append( " extends=""#arguments.extends#""" );
		}

		// implements
		if ( len( trim( arguments.implements ) ) ) {
			udfOut.append( " implements=""#arguments.implements#""" );
		}

		// close tag
		udfOut.append( ">#variables.lb#" );

		// iterate over implementations
		for ( local.x = 1; local.x lte listLen( arguments.implements ); local.x++ ) {
			// generate interface methods
			var thisMD = server.keyExists( "boxlang" ) ? getClassMetadata( listGetAt( arguments.implements, x ) ) : getComponentMetadata(
				listGetAt( arguments.implements, x )
			);
			generateMethodsFromMD( udfOut, thisMD );
		}

		// close it
		udfOut.append( "</c" & "fcomponent>" );

		// Write it out
		stubCode = udfOUt.toString();
		tmpFile  = hash( stubCode ) & ".cfc";
		if ( !fileExists( genPath & tmpFile ) ) {
			writeStub( genPath & tmpFile, stubCode );
		}

		try {
			// create stub + clean first . if found.
			classPath = replace(
				variables.mockBox.getGenerationPath(),
				"/",
				".",
				"all"
			) & listFirst( tmpFile, "." );
			classPath = reReplace( classPath, "^\.", "" );
			oStub     = createObject( "component", classPath );
			// Remove Stub
			removeStub( genPath & tmpFile );
			// Return it
			return oStub;
		} catch ( Any e ) {
			// Remove Stub
			removeStub( genPath & tmpFile );
			rethrow;
		}
	}

	/**
	 * Generate methods from metadata
	 *
	 * @buffer The buffer to append to
	 * @md     The metadata to generate from
	 */
	private function generateMethodsFromMD( required any buffer, required any md ){
		var local         = {};
		var udfOut        = arguments.buffer;
		var methodIgnores = [ "nameAsKey", "lambda", "closure" ];
		var paramIgnores  = [ "nameAsKey" ];

		// local functions if they exist
		var aFunctions = [];
		if ( structKeyExists( arguments.md, "functions" ) ) {
			aFunctions = arguments.md.functions;
		}

		for ( var thisMethod in aFunctions ) {
			// start function tag
			udfOut.append( "<c" & "ffunction" );

			// Iterate over the values of the function
			for ( var methodAttribute in thisMethod ) {
				// Do Simple values only
				if (
					isSimpleValue( thisMethod[ methodAttribute ] ) && not arrayFindNoCase(
						methodIgnores,
						methodAttribute
					)
				) {
					udfOut.append( " #lCase( methodAttribute )# = ""#thisMethod[ methodAttribute ]#""" );
				}
			}

			// close function start tag
			udfOut.append( ">#variables.lb#" );

			// Do parameters if they exist
			for ( var thisParam in thisMethod.parameters ) {
				// start argument
				udfOut.append( "<c" & "fargument" );

				// do attributes
				for ( var paramAttribute in thisParam ) {
					// Do Simple values only
					if (
						isSimpleValue( thisParam[ paramAttribute ] ) && not arrayFindNoCase(
							paramIgnores,
							paramAttribute
						)
					) {
						udfOut.append( " #lCase( paramAttribute )# = ""#thisParam[ paramAttribute ]#""" );
					}
				}

				// end argument
				udfOut.append( ">#variables.lb#" );
			}


			// close function
			udfOut.append( "</c" & "ffunction>#variables.lb#" );
		}

		// Check extends and recurse
		if ( structKeyExists( arguments.md, "extends" ) && arguments.md.extends.count() ) {
			for ( var thisKey in arguments.md.extends ) {
				generateMethodsFromMD( udfOut, arguments.md.extends[ thisKey ] );
			}
		}
	}

	/**
	 * Include a template
	 *
	 * @templatePath The template path to include
	 */
	private function $include( required string templatePath ){
		include "#arguments.templatePath#";
	}

}
