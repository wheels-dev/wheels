/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * MockBox is in charge of all kinds of software mocking abilities.
 */
component accessors=true {

	property name="mockGenerator";
	property name="generationPath";

	/**
	 * Create an instance of MockBox
	 *
	 * @generationPath The mocking generation relative path.  If not defined, then the factory will use its internal tmp path. Just make sure that this folder is accessible from an include.
	 */
	function init( generationPath = "" ){
		var tempDir = "/testbox/system/stubs";

		// Setup the generation Path
		if ( len( trim( arguments.generationPath ) ) neq 0 ) {
			// Default to coldbox tmp path
			variables.generationPath = arguments.generationPath;
		} else {
			variables.generationPath = tempDir;
		}

		// Cleanup of paths.
		if ( right( variables.generationPath, 1 ) neq "/" ) {
			variables.generationPath = variables.generationPath & "/";
		}

		variables.mockGenerator = new wheels.testbox.system.mockutils.MockGenerator( this, false );

		return this;
	}

	/**
	 * --------------------------------------------------------------------------------------------
	 * MOCK CREATION METHODS
	 * --------------------------------------------------------------------------------------------
	 */

	/**
	 * Create an empty mock object. By empty we mean we remove all methods so you can mock them.
	 *
	 * @className   The class name of the object to mock. The mock factory will instantiate it for you
	 * @object      The object to mock, already instantiated
	 * @callLogging Add method call logging for all mocked methods. Defaults to true
	 *
	 * @return The object being mocked
	 */
	function createEmptyMock( className, object, boolean callLogging = true ){
		arguments.clearMethods = true;
		return createMock( argumentCollection = arguments );
	}

	/**
	 * Create a mock object or prepares an object to act as a mock for spying.
	 *
	 * @className    The class name of the object to mock. The mock factory will instantiate it for you
	 * @object       The object to mock, already instantiated
	 * @clearMethods If true, all methods in the target mock object will be removed. You can then mock only the methods that you want to mock. Defaults to false
	 * @callLogging  Add method call logging for all mocked methods. Defaults to true
	 *
	 * @return The object being mocked
	 */
	function createMock(
		className,
		object,
		clearMethods = false,
		callLogging  = true
	){
		var obj = 0;

		// class to mock
		if ( !isNull( arguments.className ) ) {
			obj = createObject( "component", arguments.className );
		} else if ( !isNull( arguments.object ) ) {
			// Object to Mock
			obj = arguments.object;
		} else {
			throw(
				type    = "mock.invalidArguments",
				message = "Invalid mocking arguments: className or object not found"
			);
		}

		// Clear up Mock object?
		if ( arguments.clearMethods ) {
			structClear( obj );
		}
		// Decorate Mock
		decorateMock( obj );

		// Call Logging Global Flag
		if ( arguments.callLogging ) {
			obj._mockCallLoggingActive = true;
		}

		// Return Mock
		return obj;
	}

	/**
	 * Prepares an already instantiated object to act as a mock for spying and much more.
	 *
	 * @object      The already instantiated object to prepare for mocking
	 * @callLogging Add method call logging for all mocked methods
	 *
	 * @return The object being prepared for mocking
	 */
	function prepareMock( required object, callLogging = true ){
		if ( structKeyExists( arguments.object, "mockbox" ) ) {
			return arguments.object;
		}
		return createMock( object = arguments.object );
	}

	/**
	 * Create an empty stub object that you can use for mocking.
	 *
	 * @callLogging Add method call logging for all mocked methods
	 * @extends     Make the stub extend from certain class
	 * @implements  Make the stub adhere to an interface
	 *
	 * @return The stub object
	 */
	function createStub(
		callLogging = true,
		extends     = "",
		implements  = ""
	){
		// No implements or inheritance
		if ( NOT len( trim( arguments.implements ) ) AND NOT len( trim( arguments.extends ) ) ) {
			return createMock( className = "wheels.testbox.system.mockutils.Stub", callLogging = arguments.callLogging );
		}
		// Generate the class + Create it + Remove it
		return prepareMock( variables.mockGenerator.generateClass( argumentCollection = arguments ) );
	}

	/**
	 * --------------------------------------------------------------------------------------------
	 * DECORATION INJECTED METHODS ON MOCK OBJECTS
	 * --------------------------------------------------------------------------------------------
	 */


	/**
	 * Mock a property inside of an object in any scope. Injected as = $property()
	 *
	 * @propertyName  The name of the property to mock
	 * @propertyScope The scope where the property lives in. By default we will use the variables scope.
	 * @mock          The object or data to inject
	 *
	 * @return The object being mocked
	 */
	function $property(
		required propertyName,
		propertyScope = "variables",
		required mock
	){
		"#arguments.propertyScope#.#arguments.propertyName#" = arguments.mock;
		return this;
	}


	/**
	 * Gets an internal mocked object property
	 *
	 * @name         The name of the property to retrieve.
	 * @scope        The scope to which to retrieve the property from. Defaults to 'variables' scope.
	 * @defaultValue Default value to return if property does not exist
	 *
	 * @return The value of the property or the default value if the property does not exist
	 */
	function $getProperty(
		required name,
		scope = "variables",
		defaultValue
	){
		// Cleanup deep scopes if needed, only one level deep is allowed
		if ( arguments.scope.find( "." ) ) {
			var testScope = arguments.scope.getToken( 1, "." );
			if ( testScope == "variables" ) {
				// remove the variables. from the scope
				arguments.scope = arguments.scope.getToken( 2, "." );
			}
		}

		// Direct Scope Lookups
		if ( !arguments.scope.find( "." ) ) {
			var targetScope = variables;

			if ( arguments.scope == "this" ) {
				targetScope = this;
			} else if ( arguments.scope != "variables" && structKeyExists( variables, arguments.scope ) ) {
				targetScope = variables[ arguments.scope ];
			}

			if ( structKeyExists( targetScope, arguments.name ) ) {
				return targetScope[ arguments.name ];
			}
			if ( !isNull( arguments.defaultValue ) ) {
				return arguments.defaultValue;
			}
		}

		throw(
			type    = "MockBox.PropertyDoesNotExist",
			message = "The property requested [#arguments.name#] does not exist in the [#arguments.scope#] scope"
		);
	}


	/**
	 * I return the number of times the specified mock object's methods have been called or a specific method has been called.  If the mock method has not been defined the results is a -1
	 *
	 * @methodName Name of the method to get the total made calls from. If not passed, then we count all methods in this mock object
	 *
	 * @return The number of times the specified mock object's method or all methods have been called
	 */
	numeric function $count( methodName = "" ){
		var key        = "";
		var totalCount = 0;

		// If method name used? Count only this method signatures
		if ( len( arguments.methodName ) ) {
			if ( structKeyExists( this._mockMethodCallCounters, arguments.methodName ) ) {
				return this._mockMethodCallCounters[ arguments.methodName ];
			}
			return -1;
		}

		// All Calls
		for ( key in this._mockMethodCallCounters ) {
			totalCount = totalCount + this._mockMethodCallCounters[ key ];
		}
		return totalCount;
	}

	/**
	 * Assert how many calls have been made to the mock or a specific mock method: Injected as $verifyCallCount() and $times()
	 *
	 * @count      The number of calls to assert
	 * @methodName Name of the method to verify the calls from, if not passed it asserts all mocked method calls
	 *
	 * @return True if the number of calls have been made to the mock or a specific mock method
	 */
	boolean function $times( required count, methodName = "" ){
		return ( this.$count( argumentCollection = arguments ) eq arguments.count );
	}


	/**
	 * Assert that no interactions have been made to the mock or a specific mock method: Alias to $times(0). Injected as $never()
	 *
	 * @methodName Name of the method to verify the calls from
	 *
	 * @return True if no interactions have been made to the mock or a specific mock method
	 */
	boolean function $never( methodName = "" ){
		if ( this.$count( arguments.methodName ) EQ 0 ) {
			return true;
		}
		return false;
	}

	/**
	 * Assert that at least a certain number of calls have been made on the mock or a specific mock method. Injected as $atLeast()
	 *
	 * @minNumberOfInvocations The min number of calls to assert
	 * @methodName             Name of the method to verify the calls from, if blank, from the entire mock
	 *
	 * @return True if at least a certain number of calls have been made on the mock or a specific mock method
	 */
	boolean function $atLeast( required minNumberOfInvocations, methodName = "" ){
		return ( this.$count( argumentCollection = arguments ) GTE arguments.minNumberOfInvocations );
	}


	/**
	 * Assert that only 1 call has been made on the mock or a specific mock method. Injected as $once()
	 *
	 * @methodName Name of the method to verify the calls from, if blank, from the entire mock
	 *
	 * @return True if only 1 call has been made on the mock or a specific mock method
	 */
	boolean function $once( methodName = "" ){
		return ( this.$count( argumentCollection = arguments ) EQ 1 );
	}

	/**
	 * Assert that at most a certain number of calls have been made on the mock or a specific mock method. Injected as $atMost()
	 *
	 * @maxNumberOfInvocations The max number of calls to assert
	 * @methodName             Name of the method to verify the calls from, if blank, from the entire mock
	 *
	 * @return True if at most a certain number of calls have been made on the mock or a specific mock method
	 */
	boolean function $atMost( required maxNumberOfInvocations, methodName = "" ){
		return ( this.$count( argumentCollection = arguments ) LTE arguments.maxNumberOfInvocations );
	}

	/**
	 * Use this method to mock more than 1 result as passed in arguments.  Can only be called when chained to a $() or $().$args() call.  Results will be recycled on a multiple of their lengths according to how many times they are called, simulating a state-machine algorithm. Injected as: $results()
	 */
	function $results(){
		if ( len( this._mockCurrentMethod ) ) {
			// Check if arguments hash is set
			if ( len( this._mockCurrentArgsHash ) ) {
				this._mockArgResults[ this._mockCurrentArgsHash ] = arguments;
			} else {
				// Save incoming results array
				this._mockResults[ this._mockCurrentMethod ] = arguments;
			}

			// Cleanup
			this._mockCurrentMethod   = "";
			this._mockCurrentArgsHash = "";

			return this;
		}

		// throw exception
		throw(
			type    = "MockFactory.IllegalStateException",
			message = "No current method name set",
			detail  = "This method was probably called without chaining it to a $() call. Ex: obj.$().$results(), or obj.$('method').$args().$results()"
		);
	}

	/**
	 * Use this method to mock more than 1 result as passed in arguments.  Can only be called when chained to a $() or $().$args() call. Results will be determined by the callback sent in. Basically the method will call this callback and return its results)
	 *
	 * @target The UDF or closure to execute as a callback
	 */
	function $callback( required target ){
		if ( len( this._mockCurrentMethod ) ) {
			// Check if arguments hash is set
			if ( len( this._mockCurrentArgsHash ) ) {
				this._mockArgResults[ this._mockCurrentArgsHash ] = {
					type   : "callback",
					target : arguments.target
				};
			} else {
				// Save incoming callback as what it should return
				this._mockCallbacks[ this._mockCurrentMethod ][ 1 ] = arguments.target;
			}

			// Cleanup
			this._mockCurrentMethod   = "";
			this._mockCurrentArgsHash = "";

			return this;
		}

		// throw exception
		throw(
			type    = "MockFactory.IllegalStateException",
			message = "No current method name set",
			detail  = "This method was probably called without chaining it to a $() call. Ex: obj.$().$callback(), or obj.$('method').$args().$callback()"
		);
	}

	/**
	 * Use this method to return an exception when called.  Can only be called when chained to a $() or $().$args() call.  Results will be recycled on a multiple of their lengths according to how many times they are called, simulating a state-machine algorithm. Injected as: $throws()
	 */
	function $throws(){
		if ( len( this._mockCurrentMethod ) ) {
			var args = arguments;
			return this.$callback( function(){
				throw(
					type      = structKeyExists( args, "type" ) ? args.type : "",
					message   = structKeyExists( args, "message" ) ? args.message : "",
					detail    = structKeyExists( args, "detail" ) ? args.detail : "",
					errorCode = structKeyExists( args, "errorCode" ) ? args.errorCode : "0"
				);
			} );
		}

		throw(
			type    = "MockFactory.IllegalStateException",
			message = "No current method name set",
			detail  = "This method was probably called without chaining it to a $() call. Ex: obj.$().$throws(), or obj.$('method').$args().$throws()"
		);
	}

	/**
	 * Use this method to mock specific arguments when calling a mocked method.  Can only be called when chained to a $() call.  If a method is called with arguments and no match, it defaults to the base results defined. Injected as: $args()
	 */
	function $args(){
		// check if method is set on concat
		if ( len( this._mockCurrentMethod ) ) {
			// argument Hash Signature
			this._mockCurrentArgsHash = this._mockCurrentMethod & "|" & this.mockBox.normalizeArguments(
				arguments
			);
			// concat this
			return this;
		}

		// throw exception
		throw(
			type    = "MockBox.IllegalStateException",
			message = "No current method name set",
			detail  = "This method was probably called without chaining it to a mockMethod() call. Ex: obj.mockMethod().mockArgs()"
		);
	}

	/**
	 * Mock a method, simple but magical. Injected as: $()
	 *
	 * @method             The method you want to mock
	 * @preserveReturnType Preserve the return type of the method
	 * @throwException     Throw an exception if the method is called
	 * @throwType          The type of exception to throw
	 * @throwDetail        The detail of the exception to throw
	 * @throwMessage       The message of the exception to throw
	 * @throwErrorCode     The error code of the exception to throw
	 * @callOriginal       Call the original method
	 * @preserveArguments  Preserve the arguments of the method
	 * @callback           The callback to execute
	 *
	 * @return The results it must return, if not passed it returns void or you will have to do the mockResults() chain
	 * @return The results it must return, if not passed it returns void or you will have to do the mockResults() chain
	 */
	function $(
		required method,
		any returns,
		boolean  preserveReturnType = true,
		boolean throwException      = false,
		string throwType            = "",
		string throwDetail          = "",
		string throwMessage         = "",
		string throwErrorCode       = "",
		boolean callOriginal        = false,
		boolean preserveArguments   = false,
		any callback
	){
		var fncMD          = structNew();
		var genFile        = "";
		var oMockGenerator = this.MockBox.getmockGenerator();

		// Check if the method is existent in public scope
		if ( structKeyExists( this, arguments.method ) && !isNull( this[ arguments.method ] ) ) {
			fncMD = getMetadata( this[ arguments.method ] );
		}
		// Else check in private scope
		else if ( structKeyExists( variables, arguments.method ) && !isNull( variables[ arguments.method ] ) ) {
			fncMD = getMetadata( variables[ arguments.method ] );
		}

		// Prepare Metadata Existence, works on virtual methods also
		if ( not structKeyExists( fncMD, "returntype" ) || isNull( fncMD.returnType ) ) {
			fncMD[ "returntype" ] = "any";
		}
		if ( not structKeyExists( fncMD, "access" ) || isNull( fncMD.access ) ) {
			fncMD[ "access" ] = "public";
		}
		if ( not structKeyExists( fncMD, "output" ) || isNull( fncMD.output ) ) {
			fncMD[ "output" ] = true;
		}
		// Preserve Return Type?
		if ( NOT arguments.preserveReturnType ) {
			fncMD[ "returntype" ] = "any";
		}

		// Remove Method From Object
		structDelete( this, arguments.method );
		structDelete( variables, arguments.method );

		// Generate Mock Method
		arguments.metadata     = fncMD;
		arguments.targetObject = this;
		oMockGenerator.generate( argumentCollection = arguments );

		// Results Setup For No Argument Definitions or base results
		if ( structKeyExists( arguments, "returns" ) && !isNull( arguments.returns ) ) {
			this._mockResults[ arguments.method ]      = arrayNew( 1 );
			this._mockResults[ arguments.method ][ 1 ] = arguments.returns;
		} else {
			this._mockResults[ arguments.method ] = arrayNew( 1 );
		}

		// Callbacks Setup For No Argument Definitions or base results
		if ( structKeyExists( arguments, "callback" ) && !isNull( arguments.callback ) ) {
			this._mockCallbacks[ arguments.method ]      = arrayNew( 1 );
			this._mockCallbacks[ arguments.method ][ 1 ] = arguments.callback;
		} else {
			this._mockCallbacks[ arguments.method ] = arrayNew( 1 );
		}

		// Create Mock Call Counters
		this._mockMethodCallCounters[ "#arguments.method#" ] = 0;

		// Save method name for concatenation
		this._mockCurrentMethod   = arguments.method;
		this._mockCurrentArgsHash = "";

		// Create Call Loggers, just in case
		this._mockCallLoggers[ arguments.method ] = arrayNew( 1 );

		return this;
	}


	/**
	 * Spy on a Method. Like mocking but keeping the original code.
	 *
	 * @method The method you want to mock or spy on
	 */
	function $spy( required method ){
		return this.$( method = arguments.method, callback = variables[ arguments.method ] );
	}


	/**
	 * Retrieve the method call logger structures. Injected as: $callLog()
	 */
	struct function $callLog(){
		return this._mockCallLoggers
	}

	/**
	 * Debugging method for MockBox enabled mocks/stubs, useful to find out things about your mocks. Injected as $debug()
	 */
	struct function $debug(){
		return {
			"mockResults"            : this._mockResults,
			"mockCallBacks"          : this._mockCallbacks,
			"mockArgResults"         : this._mockArgResults,
			"mockMethodCallCounters" : this._mockMethodCallCounters,
			"mockCallLoggingActive"  : this._mockCallLoggingActive,
			"mockCallLoggers"        : this._mockCallLoggers,
			"mockGenerationPath"     : this._mockGenerationPath,
			"mockOriginalMD"         : this._mockOriginalMD
		};
	}


	/**
	 * Reset all mock counters and logs on the targeted mock. Injected as $reset
	 */
	function $reset(){
		for ( var item in this._mockMethodCallCounters ) {
			this._mockMethodCallCounters[ item ] = 0;
			this._mockCallLoggers[ item ]        = [];
		}
		return this;
	}

	/**
	 * Accepts a specifically formatted chunk of text, and returns it as a query object.
	 * v2 rewrite by Jamie Jackson
	 * v3 rewrite by James Davis
	 *
	 * @queryData Specifically format chunk of text to convert to a query. (Required)
	 * @author    Bert Dawson (bert@redbanner.com)
	 * @version   3, June 25, 2013
	 *
	 * @return Returns a query object.
	 */
	Query function querySim( required queryData ){
		var fieldsDelimiter = "|";
		var listOfColumns   = "";
		var tmpQuery        = "";
		var cellValues      = "";
		var lineDelimiter   = chr( 10 ) & chr( 13 );
		var lineNum         = 0;
		var colPosition     = 0;
		var queryRows       = "";
		var columnArray     = "";

		// the first line is the column list, eg "column1,column2,column3"
		listOfColumns = trim( listFirst( queryData, lineDelimiter ) );
		columnArray   = listToArray( listOfColumns );

		// create a temporary Query
		tmpQuery = queryNew( listOfColumns );

		// Array of rows (ignoring empty rows)
		queryRows = listToArray( queryData, lineDelimiter );

		// loop though the queryData starting at the second line
		for ( lineNum = 2; lineNum <= arrayLen( queryRows ); lineNum = lineNum + 1 ) {
			cellValues = listToArray( queryRows[ lineNum ], fieldsDelimiter, true ); // Array of cell values, not ignoring empty values.
			if ( arrayLen( cellValues ) == listLen( listOfColumns ) ) {
				queryAddRow( tmpQuery );
				for ( colPosition = 1; colPosition <= arrayLen( cellValues ); colPosition++ ) {
					querySetCell(
						tmpQuery,
						trim( columnArray[ colPosition ] ),
						trim( cellValues[ colPosition ] )
					);
				}
			}
		}

		return ( tmpQuery );
	}

	/**
	 * Normalize arguments for serialization
	 *
	 * @args The arguments to normalize
	 */
	function normalizeArguments( required args ){
		// TreeMap will give us arguments in a consistent order, but we can't rely on Java to serialize argument values in the same way ColdFusion will
		var argOrderedTree = createObject( "java", "java.util.TreeMap" ).init( arguments.args );
		var serializedArgs = "";

		for ( var arg in argOrderedTree ) {
			if ( isNull( argOrderedTree[ arg ] ) || NOT structKeyExists( argOrderedTree, arg ) ) {
				/* we aren't going to be able to serialize an undefined variable, this might occur if an arguments structure
				 * containing optional parameters is passed by argumentCollection=arguments to the mocked method.
				 */
				continue;
			} else if ( isSimpleValue( argOrderedTree[ arg ] ) ) {
				/* toString() works best for simple values.  It is equivalent in the following scenario
				 * i = 1;
				 * j = i; j++; j--;
				 * toString(i) eq toString(j);
				 * This works around the ColdFusion bug (9.0.2 at least) where an integer variable is converted to a real number by the ++ or -- operators.
				 * serializeJSON and other Java methods of stringifying don't work around that issue.
				 *
				 * Strangely, it converts a literal real number 1.0 to the string "1.0".
				 */
				serializedArgs &= toString( argOrderedTree[ arg ] );
			} else if (
				isObject( argOrderedTree[ arg ] ) and
				// Find out if object, sometimes of course, on Adobe, is instance does not work, so sucky
				(
					isInstanceOf( argOrderedTree[ arg ], "Component" ) OR structKeyExists(
						getMetadata( argOrderedTree[ arg ] ),
						"extends"
					)
				)
			) {
				// If an object and a class, just use serializeJSON
				serializedArgs &= serializeJSON( getMetadata( argOrderedTree[ arg ] ) );
			} else {
				// Get obj rep
				try {
					serializedArgs &= argOrderedTree[ arg ].toString();
				} catch ( any e ) {
					// Fallback
					serializedArgs &= serializeJSON( argOrderedTree[ arg ] );
				}
			}
		}
		/* ColdFusion isn't case sensitive, so case of string values shouldn't matter.  We do it after serializing all args
		 * to catch any values deep in complex variables.
		 */
		return hash( lCase( serializedArgs ) );
	}

	/**
	 *  Decorate a mock object with all the necessary methods and properties
	 *
	 * @target The object to decorate
	 */
	private function decorateMock( required target ){
		var obj = target;

		// Mock Method Results Holder
		obj._mockResults            = structNew();
		obj._mockCallbacks          = structNew();
		obj._mockArgResults         = structNew();
		// Call Counters
		obj._mockMethodCallCounters = structNew();
		// Call Logging
		obj._mockCallLoggingActive  = false;
		// Mock Method Call Logger
		obj._mockCallLoggers        = structNew();
		// Mock Generation Path
		obj._mockGenerationPath     = getGenerationPath();
		// Original Metadata
		obj._mockOriginalMD         = getMetadata( obj );
		// Chaining Properties
		obj._mockCurrentMethod      = "";
		obj._mockCurrentArgsHash    = "";
		// Mock Method
		obj.$                       = variables.$;
		obj.$spy                    = variables.$spy;
		// Mock Property
		obj.$property               = variables.$property;
		obj.$getProperty            = variables.$getProperty;
		// Mock Results
		obj.$results                = variables.$results;
		obj.$throws                 = variables.$throws;
		obj.$callback               = variables.$callback;
		// Mock Arguments
		obj.$args                   = variables.$args;
		// CallLog
		obj.$callLog                = variables.$callLog;
		// Verify Call Counts
		obj.$count                  = variables.$count;
		obj.$times                  = variables.$times;
		obj.$never                  = variables.$never;
		obj.$verifyCallCount        = variables.$times;
		obj.$atLeast                = variables.$atLeast;
		obj.$once                   = variables.$once;
		obj.$atMost                 = variables.$atMost;
		// Debug
		obj.$debug                  = variables.$debug;
		obj.$reset                  = variables.$reset;
		// Mock Box
		obj.mockBox                 = this;
	}


	/**
	 * Get the util object
	 */
	private function getUtil(){
		return new wheels.testbox.system.util.Util();
	}

}
