/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This object represents our Assertion style DSL for Unit style testing
 */
component {

	/**
	 * Fail assertion
	 *
	 * @message The message to send in the failure
	 * @detail  The detail to add in the exception
	 */
	function fail( message = "", detail = "" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "A test failure occurred" );
		throw(
			type    = "TestBox.AssertionFailed",
			message = arguments.message,
			detail  = arguments.detail
		);
	}

	/**
	 * Skip a Test
	 *
	 * @message The message to send in the skip information dialog
	 * @detail  The detail to add in the exception
	 */
	function skip( message = "", detail = "" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "Test was skipped" );
		throw(
			type    = "TestBox.SkipSpec",
			message = arguments.message,
			detail  = arguments.detail
		);
	}

	/**
	 * Assert that the passed expression is true
	 *
	 * @expression The expression to test
	 * @message    The message to send in the failure
	 */
	function assert( required boolean expression, message = "" ){
		return isTrue( arguments.expression, arguments.message );
	}

	/**
	 * Assert something is true
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function isTrue( required boolean actual, message = "" ){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#arguments.actual#] to be true"
		);
		if ( NOT arguments.actual ) {
			fail( arguments.message );
		}
		return this;
	}

	/**
	 * Assert something is false
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function isFalse( required boolean actual, message = "" ){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#arguments.actual#] to be false"
		);
		if ( arguments.actual ) {
			fail( arguments.message );
		}
		return this;
	}

	/**
	 * Assert something is equal to each other, no case is required
	 *
	 * @expected The expected data
	 * @actual   The actual data to test
	 * @message  The message to send in the failure
	 */
	function isEqual( any expected, any actual, message = "" ){
		// validate equality
		if ( equalize( argumentCollection = arguments ) ) {
			return this;
		}
		arguments.message = (
			len( arguments.message ) ? arguments.message & ". Expected [#getStringName( arguments.expected )#] Actual [#getStringName( arguments.actual )#]" : "Expected [#getStringName( arguments.expected )#] but received [#getStringName( arguments.actual )#]"
		);
		// if we reach here, nothing is equal man!
		fail( arguments.message );
	}

	/**
	 * Assert something is not equal to each other, no case is required
	 *
	 * @expected The expected data
	 * @actual   The actual data to test
	 * @message  The message to send in the failure
	 */
	function isNotEqual( any expected, any actual, message = "" ){
		arguments.message = (
			len( arguments.message ) ? arguments.message & ". Expected [#getStringName( arguments.expected )#] Actual [#getStringName( arguments.actual )#]" : "Expected [#getStringName( arguments.expected )#] to not be [#getStringName( arguments.actual )#]"
		);
		// validate equality
		if ( !equalize( argumentCollection = arguments ) ) {
			return this;
		}
		// if we reach here, they are equal!
		fail( arguments.message );
	}

	/**
	 * Assert an object is the same instance as another object
	 *
	 * @expected The expected data
	 * @actual   The actual data to test
	 * @message  The message to send in the failure
	 */
	function isSameInstance(
		required any expected,
		required any actual,
		message = ""
	){
		var expectedIdentityHashCode = getIdentityHashCode( arguments.expected );
		var actualIdentityHashCode   = getIdentityHashCode( arguments.actual );

		// validate same object
		if ( expectedIdentityHashCode == actualIdentityHashCode ) {
			return this;
		}
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#getStringName( arguments.expected )#:#expectedIdentityHashCode#] but received [#getStringName( arguments.actual )#:#actualIdentityHashCode#]"
		);
		// if we reach here, the objects weren't the same
		fail( arguments.message );
	}

	/**
	 * Assert an object is not the same instance as another object
	 *
	 * @expected The expected data
	 * @actual   The actual data to test
	 * @message  The message to send in the failure
	 */
	function isNotSameInstance(
		required any expected,
		required any actual,
		message = ""
	){
		var expectedIdentityHashCode = getIdentityHashCode( arguments.expected );
		var actualIdentityHashCode   = getIdentityHashCode( arguments.actual );

		// validate not same object
		if ( expectedIdentityHashCode != actualIdentityHashCode ) {
			return this;
		}
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#getStringName( arguments.expected )#:#expectedIdentityHashCode#] to not be [#getStringName( arguments.actual )#:#actualIdentityHashCode#]"
		);
		// if we reach here, they are equal!
		fail( arguments.message );
	}

	/**
	 * Assert strings are equal to each other with case.
	 *
	 * @expected The expected data
	 * @actual   The actual data to test
	 * @message  The message to send in the failure
	 */
	function isEqualWithCase( string expected, string actual, message = "" ){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#getStringName( arguments.expected )#] but received [#getStringName( arguments.actual )#]"
		);
		// null check
		if ( isNull( arguments.expected ) && isNull( arguments.actual ) ) {
			return this;
		}
		if ( isNull( arguments.expected ) || isNull( arguments.actual ) ) {
			fail( arguments.message );
		}
		// equalize with case
		if ( compare( arguments.expected, arguments.actual ) eq 0 ) {
			return this;
		}
		// if we reach here, nothing is equal man!
		fail( arguments.message );
	}

	/**
	 * Assert something is null
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function null( any actual, message = "" ){
		// equalize with case
		if ( isNull( arguments.actual ) ) {
			return this;
		}
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected a null value but got #getStringName( arguments.actual )#"
		);
		// if we reach here, nothing is equal man!
		fail( arguments.message );
	}


	/**
	 * Assert something is not null
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function notNull( any actual, message = "" ){
		// equalize with case
		if ( !isNull( arguments.actual ) ) {
			return this;
		}
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected the actual value to be NOT null but it was null"
		);
		// if we reach here, nothing is equal man!
		fail( arguments.message );
	}

	/**
	 * Assert the type of the incoming actual data, it uses the internal ColdFusion isValid() function behind the scenes
	 *
	 * @type    The type to check, valid types are: array, binary, boolean, component, date, time, float, numeric, integer, query, string, struct, url, uuid
	 * @actual  The actual data to check
	 * @message The message to send in the failure
	 */
	function typeOf(
		required string type,
		required any actual,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Actual data [#getStringName( arguments.actual )#] is not of this type: [#arguments.type#]"
		);
		if ( isValid( arguments.type, arguments.actual ) ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that is NOT a type of the incoming actual data, it uses the internal ColdFusion isValid() function behind the scenes
	 *
	 * @type    The type to check, valid types are: array, binary, boolean, component, date, time, float, numeric, integer, query, string, struct, url, uuid
	 * @actual  The actual data to check
	 * @message The message to send in the failure
	 */
	function notTypeOf(
		required string type,
		required any actual,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Actual data [#getStringName( arguments.actual )#] is actually of this type: [#arguments.type#]"
		);
		if ( !isValid( arguments.type, arguments.actual ) ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that the actual object is of the expected instance type
	 *
	 * @actual   The actual data to check
	 * @typeName The typename to check
	 * @message  The message to send in the failure
	 */
	function instanceOf(
		required any actual,
		required string typeName,
		message = ""
	){
		var md            = getMetadata( arguments.actual );
		var actualType    = isStruct( md ) && md.keyExists( "name" ) ? md.name : actual.getClass().getName();
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual is of type [#actualType#] which is not the expected type of [#arguments.typeName#]"
		);

		if ( isInstanceOf( arguments.actual, arguments.typeName ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the actual object is NOT of the expected instance type
	 *
	 * @actual   The actual data to check
	 * @typeName The typename to check
	 * @message  The message to send in the failure
	 */
	function notInstanceOf(
		required any actual,
		required string typeName,
		message = ""
	){
		var md            = getMetadata( arguments.actual );
		var actualType    = isStruct( md ) && md.keyExists( "name" ) ? md.name : actual.getClass().getName();
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual is of type [#actualType#] which is the expected type of [#arguments.typeName#]"
		);
		if ( !isInstanceOf( arguments.actual, arguments.typeName ) ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that the actual data matches the incoming regular expression with no case sensitivity
	 *
	 * @actual  The actual data to check
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function match(
		required string actual,
		required string regex,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual.toString()#] does not match [#arguments.regex#]"
		);
		if ( arrayLen( reMatchNoCase( arguments.regex, arguments.actual ) ) gt 0 ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that the actual data matches the incoming regular expression with case sensitivity
	 *
	 * @actual  The actual data to check
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function matchWithCase(
		required string actual,
		required string regex,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual.toString()#] does not match [#arguments.regex#]"
		);
		if ( arrayLen( reMatch( arguments.regex, arguments.actual ) ) gt 0 ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that the actual data does NOT match the incoming regular expression with case sensitivity
	 *
	 * @actual  The actual data to check
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function notMatchWithCase(
		required string actual,
		required string regex,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual.toString()#] does not match [#arguments.regex#]"
		);
		if ( arrayLen( reMatch( arguments.regex, arguments.actual ) ) eq 0 ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that the actual data does NOT match the incoming regular expression with no case sensitivity
	 *
	 * @actual  The actual data to check
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function notMatch(
		required string actual,
		required string regex,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual.toString()#] actually matches [#arguments.regex#]"
		);
		if ( arrayLen( reMatchNoCase( arguments.regex, arguments.actual ) ) eq 0 ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that a given key exists in the passed in struct/object
	 *
	 * @target        The target object/struct
	 * @key           The key to check for existence
	 * @message       The message to send in the failure
	 * @caseSensitive If the key check is case sensitive
	 */
	function key(
		required any target,
		required string key,
		message               = "",
		boolean caseSensitive = false
	){
		arguments.target = normalizeToStruct( arguments.target );

		arguments.message = (
			len( arguments.message ) ? arguments.message : "The key(s) [#arguments.key#] does not exist in the target object. Found keys are [#structKeyArray( arguments.target ).toString()#]"
		);

		// Inflate Key and process
		if (
			arguments.key
				.listToArray()
				.filter( function( thisKey ){
					if ( caseSensitive ) {
						return target.keyList().find( arguments.thisKey );
					} else {
						return structKeyExists( target, arguments.thisKey );
					}
				} )
				.len() != listLen( arguments.key )
		) {
			fail( arguments.message );
		}
		return this;
	}

	/**
	 * Assert that a given key DOES NOT exist in the passed in struct/object
	 *
	 * @target        The target object/struct
	 * @key           The key to check for existence
	 * @message       The message to send in the failure
	 * @caseSensitive If the key check is case sensitive
	 */
	function notKey(
		required any target,
		required string key,
		message               = "",
		boolean caseSensitive = false
	){
		arguments.target  = normalizeToStruct( arguments.target );
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The key [#arguments.key#] exists in the target object. Found keys are [#structKeyArray( arguments.target ).toString()#]"
		);

		// Inflate Key and process
		if (
			arguments.key
				.listToArray()
				.filter( function( thisKey ){
					if ( caseSensitive ) {
						return target.keyList().find( arguments.thisKey );
					} else {
						return structKeyExists( target, arguments.thisKey );
					}
				} )
				.len() > 0
		) {
			fail( arguments.message );
		}
		return this;
	}

	/**
	 * Assert that a given key exists in the passed in struct by searching the entire nested structure
	 *
	 * @target  The target object/struct
	 * @key     The key to check for existence anywhere in the nested structure
	 * @message The message to send in the failure
	 */
	function deepKey(
		required struct target,
		required string key,
		message = ""
	){
		arguments.target  = normalizeToStruct( arguments.target );
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The key [#arguments.key#] does not exist anywhere in the target object."
		);
		if ( arrayLen( structFindKey( arguments.target, arguments.key ) ) GT 0 ) {
			return this;
		}
		fail( arguments.message );
	}

	/**
	 * Assert that a given key DOES NOT exists in the passed in struct by searching the entire nested structure
	 *
	 * @target  The target object/struct
	 * @key     The key to check for existence anywhere in the nested structure
	 * @message The message to send in the failure
	 */
	function notDeepKey(
		required struct target,
		required string key,
		message = ""
	){
		arguments.target = normalizeToStruct( arguments.target );
		var results      = structFindKey( arguments.target, arguments.key );
		// check if not found?
		if ( arrayLen( results ) EQ 0 ) {
			return this;
		}
		// found, so throw it
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The key [#arguments.key#] actually exists in the target object: #results.toString()#"
		);
		fail( arguments.message );
	}

	/**
	 * Assert the size of a given string, array, structure or query
	 *
	 * @target  The target object to check the length for, this can be a string, array, structure or query
	 * @length  The length to check
	 * @message The message to send in the failure
	 */
	function lengthOf(
		required any target,
		required string length,
		message = ""
	){
		var aLength = getTargetLength( arguments.target );
		// validate it
		if ( aLength eq arguments.length ) {
			return this;
		}

		// found, so throw it
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The expected length [#arguments.length#] is different than the actual length [#aLength#]"
		);
		fail( arguments.message );
	}

	/**
	 * Assert the size of a given string, array, structure or query
	 *
	 * @target  The target object to check the length for, this can be a string, array, structure or query
	 * @length  The length to check
	 * @message The message to send in the failure
	 */
	function notLengthOf(
		required any target,
		required string length,
		message = ""
	){
		var aLength = getTargetLength( arguments.target );
		// validate it
		if ( aLength neq arguments.length ) {
			return this;
		}

		// found, so throw it
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The expected length [#arguments.length#] is equal than the actual length [#aLength#]"
		);
		fail( arguments.message );
	}

	/**
	 * Assert that a a given string, array, structure or query is empty
	 *
	 * @target  The target object to check the length for, this can be a string, array, structure or query
	 * @message The message to send in the failure
	 */
	function isEmpty( required any target, message = "" ){
		var aLength = getTargetLength( arguments.target );
		// validate it
		if ( aLength eq 0 ) {
			return this;
		}

		// found, so throw it
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The expected value is not empty, actual size [#aLength#]"
		);
		fail( arguments.message );
	}

	/**
	 * Assert that a a given string, array, structure or query is not empty
	 *
	 * @target  The target object to check the length for, this can be a string, array, structure or query
	 * @message The message to send in the failure
	 */
	function isNotEmpty( required any target, message = "" ){
		var aLength = getTargetLength( arguments.target );
		// validate it
		if ( aLength GT 0 ) {
			return this;
		}

		// found, so throw it
		arguments.message = ( len( arguments.message ) ? arguments.message : "The expected target is empty." );
		fail( arguments.message );
	}

	/**
	 * Assert that the passed in function will throw an exception
	 *
	 * @target  The target function to execute and check for exceptions
	 * @type    Match this type with the exception thrown
	 * @regex   Match this regex against the message + detail of the exception
	 * @message The message to send in the failure
	 */
	function throws(
		required any target,
		type    = "",
		regex   = ".*",
		message = ""
	){
		var detail = "";

		try {
			arguments.target();
			arguments.message = (
				len( arguments.message ) ? arguments.message : "The incoming function did not throw an expected exception. Type=[#arguments.type#], Regex=[#arguments.regex#]"
			);
		} catch ( Any e ) {
			// If no type, message expectations, just throw flag
			if ( !len( arguments.type ) && arguments.regex eq ".*" ) {
				return this;
			}

			// determine if the expected 'type' matches the actual exception 'type'
			var typeMatches = len( arguments.type ) == 0 OR e.type eq arguments.type;

			// determine if the expected 'regex' matches the actual exception 'message' or 'detail'
			var regexMatches = arguments.regex eq ".*" OR (
				arrayLen( reMatchNoCase( arguments.regex, e.message ) ) OR arrayLen(
					reMatchNoCase( arguments.regex, e.detail )
				)
			);

			// this assertion passes if the expected type and regex match the actual exception data
			if ( typeMatches && regexMatches ) {
				return this;
			}
			// diff message types
			arguments.message = (
				len( arguments.message ) ? arguments.message : "The incoming function threw exception [type: #e.type#] [message: #e.message#] [#e.detail#] different than expected params type=[#arguments.type#], regex=[#arguments.regex#]"
			);
			detail = e.stackTrace;
		}

		// found, so throw it
		fail( arguments.message, detail );
	}

	/**
	 * Assert that the passed in function will NOT throw an exception, an exception of a specified type or exception message regex
	 *
	 * @target  The target function to execute and check for exceptions
	 * @type    Match this type with the exception thrown
	 * @regex   Match this regex against the message+detail of the exception
	 * @message The message to send in the failure
	 */
	function notThrows(
		required any target,
		type    = "",
		regex   = "",
		message = ""
	){
		try {
			arguments.target();
		} catch ( Any e ) {
			arguments.message = (
				len( arguments.message ) ? arguments.message : "The incoming function DID throw an exception of type [#e.type#] with message [#e.message#] detail [#e.detail#]"
			);

			// If type passed and matches, then its ok
			if ( len( arguments.type ) AND e.type neq arguments.type ) {
				return this;
			}

			// Message+Detail regex must not match
			if (
				len( arguments.regex ) AND
				(
					!arrayLen( reMatchNoCase( arguments.regex, e.message ) ) OR !arrayLen(
						reMatchNoCase( arguments.regex, e.detail )
					)
				)
			) {
				return this;
			}

			fail( arguments.message );
		}

		return this;
	}

	/**
	 * Assert that the passed in actual number or date is expected to be close to it within +/- a passed delta and optional datepart
	 *
	 * @expected The expected number or date
	 * @actual   The actual number or date
	 * @delta    The +/- delta to range it
	 * @datepart If passed in values are dates, then you can use the datepart to evaluate it
	 * @message  The message to send in the failure
	 */
	function closeTo(
		required any expected,
		required any actual,
		required any delta,
		datePart = "",
		message  = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not in range of [#arguments.expected#] by +/- [#arguments.delta#]"
		);

		if ( isNumeric( arguments.actual ) ) {
			if (
				isValid(
					"range",
					arguments.actual,
					( arguments.expected - arguments.delta ),
					( arguments.expected + arguments.delta )
				)
			) {
				return this;
			}
		} else if ( isDate( arguments.actual ) ) {
			if ( !listFindNoCase( "yyyy,q,m,ww,w,y,d,h,n,s,l", arguments.datePart ) ) {
				fail( "The passed in datepart [#arguments.datepart#] is not valid." );
			}

			if (
				abs(
					dateDiff(
						arguments.datePart,
						arguments.actual,
						arguments.expected
					)
				) lt arguments.delta
			) {
				return this;
			}
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the passed in actual number or date is between the passed in min and max values
	 *
	 * @actual  The actual number or date to evaluate
	 * @min     The expected min number or date
	 * @max     The expected max number or date
	 * @message The message to send in the failure
	 */
	function between(
		required any actual,
		required any min,
		required any max,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not between [#arguments.min#] and [#arguments.max#]"
		);

		// numeric between
		if ( isNumeric( arguments.actual ) ) {
			if (
				isValid(
					"range",
					arguments.actual,
					arguments.min,
					arguments.max
				)
			) {
				return this;
			}
		} else if ( isDate( arguments.actual ) ) {
			// check min/max dates first
			if ( dateCompare( arguments.min, arguments.max ) NEQ -1 ) {
				fail( "The passed in min [#arguments.min#] is either equal or later than max [#arguments.max#]" );
			}

			// To pass, ( actual > min && actual < max )
			if (
				( dateCompare( arguments.actual, arguments.min ) EQ 1 ) AND
				( dateCompare( arguments.actual, arguments.max ) EQ -1 )
			) {
				return this;
			}
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with no case-sensitivity
	 *
	 * @target  The target object to check if the incoming needle exists in. This can be a string or array
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function includes(
		required any target,
		required any needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The needle [#arguments.needle#] was not found in [#arguments.target.toString()#]"
		);

		// string
		if ( isSimpleValue( arguments.target ) AND findNoCase( arguments.needle, arguments.target ) ) {
			return this;
		}
		// array
		if ( isArray( arguments.target ) AND arrayFindNoCase( arguments.target, arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with case-sensitivity
	 *
	 * @target  The target object to check if the incoming needle exists in. This can be a string or array
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function includesWithCase(
		required any target,
		required any needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The needle [#arguments.needle#] was not found in [#arguments.target.toString()#]"
		);

		// string
		if ( isSimpleValue( arguments.target ) AND find( arguments.needle, arguments.target ) ) {
			return this;
		}
		// array
		if ( isArray( arguments.target ) AND arrayContains( arguments.target, arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given "needle" argument does not exist in the incoming string or array with case-sensitivity
	 *
	 * @target  The target object to check if the incoming needle exists in. This can be a string or array
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function notIncludesWithCase(
		required any target,
		required any needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The needle [#arguments.needle#] was found in [#arguments.target.toString()#]"
		);

		// string
		if ( isSimpleValue( arguments.target ) AND !find( arguments.needle, arguments.target ) ) {
			return this;
		}
		// array
		if ( isArray( arguments.target ) AND !arrayContains( arguments.target, arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with no case-sensitivity
	 *
	 * @target  The target object to check if the incoming needle exists in. This can be a string or array
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function notIncludes(
		required any target,
		required any needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The needle [#arguments.needle#] was found in [#arguments.target.toString()#]"
		);

		// string
		if ( isSimpleValue( arguments.target ) AND !findNoCase( arguments.needle, arguments.target ) ) {
			return this;
		}
		// array
		if ( isArray( arguments.target ) AND !arrayFindNoCase( arguments.target, arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given target string starts with the given needle string with no case-sensitivity
	 *
	 * $assert.startsWith( "hello world", "hello" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function startsWith(
		required string target,
		required string needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "[#arguments.target#] doesn't start with [#arguments.needle#]]"
		);

		if ( toString( lCase( arguments.target ) ).startsWith( lCase( arguments.needle ) ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given target string doesn't start with the given needle string with no case-sensitivity
	 *
	 * $assert.notStartsWith( "hello world", "hello" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function notStartsWith(
		required string target,
		required string needle,
		message = ""
	){
		try {
			startsWith( argumentCollection = arguments );
			arguments.message = (
				len( arguments.message ) ? arguments.message : "[#arguments.target#] actually starts with [#arguments.needle#]]"
			);
			fail( arguments.message );
		} catch ( "TestBox.AssertionFailed" e ) {
			return this;
		}
	}

	/**
	 * Assert that the given target string starts with the given needle string with case-sensitivity
	 *
	 * $assert.startsWith( "hello world", "hello" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function startsWithCase(
		required string target,
		required string needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "[#arguments.target#] doesn't start with [#arguments.needle#]]"
		);

		if ( toString( arguments.target ).startsWith( arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given target string doesn't start with the given needle string with case-sensitivity
	 *
	 * $assert.notStartsWith( "hello world", "hello" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function notStartsWithCase(
		required string target,
		required string needle,
		message = ""
	){
		try {
			startsWithCase( argumentCollection = arguments );
			arguments.message = (
				len( arguments.message ) ? arguments.message : "[#arguments.target#] actually starts with [#arguments.needle#]]"
			);
			fail( arguments.message );
		} catch ( "TestBox.AssertionFailed" e ) {
			return this;
		}
	}

	/**
	 * Assert that the given target string ends with the given needle string with no case-sensitivity
	 *
	 * $assert.endsWith( "hello world", "World" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function endsWith(
		required string target,
		required string needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "[#arguments.target#] doesn't end with [#arguments.needle#]]"
		);

		if ( toString( lCase( arguments.target ) ).endsWith( lCase( arguments.needle ) ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given target string doesn't end with the given needle string with no case-sensitivity
	 *
	 * $assert.notEndsWith( "hello world", "peace" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function notEndsWith(
		required string target,
		required string needle,
		message = ""
	){
		try {
			endsWith( argumentCollection = arguments );
			arguments.message = (
				len( arguments.message ) ? arguments.message : "[#arguments.target#] actually ends with [#arguments.needle#]]"
			);
			fail( arguments.message );
		} catch ( "TestBox.AssertionFailed" e ) {
			return this;
		}
	}

	/**
	 * Assert that the given target string ends with the given needle string with case-sensitivity
	 *
	 * $assert.endsWith( "hello world", "ld" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function endsWithCase(
		required string target,
		required string needle,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "[#arguments.target#] doesn't end with [#arguments.needle#]]"
		);

		if ( toString( arguments.target ).endsWith( arguments.needle ) ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the given target string doesn't end with the given needle string with case-sensitivity
	 *
	 * $assert.notEndsWith( "hello world", "ld" );
	 *
	 * @target  The target string to check
	 * @needle  The starts with string
	 * @message The message to send in the failure
	 */
	function notEndsWithCase(
		required string target,
		required string needle,
		message = ""
	){
		try {
			endsWithCase( argumentCollection = arguments );
			arguments.message = (
				len( arguments.message ) ? arguments.message : "[#arguments.target#] actually ends with [#arguments.needle#]]"
			);
			fail( arguments.message );
		} catch ( "TestBox.AssertionFailed" e ) {
			return this;
		}
	}

	/**
	 * Assert that the actual value is greater than the target value
	 *
	 * @actual  The actual value
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function isGT(
		required any actual,
		required any target,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not greater than [#arguments.target#]"
		);

		if ( arguments.actual gt arguments.target ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the actual value is greater than or equal the target value
	 *
	 * @actual  The actual value
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function isGTE(
		required any actual,
		required any target,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not greater than or equal to [#arguments.target#]"
		);

		if ( arguments.actual gte arguments.target ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the actual value is less than the target value
	 *
	 * @actual  The actual value
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function isLT(
		required any actual,
		required any target,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not less than [#arguments.target#]"
		);

		if ( arguments.actual lt arguments.target ) {
			return this;
		}

		fail( arguments.message );
	}

	/**
	 * Assert that the actual value is less than or equal the target value
	 *
	 * @actual  The actual value
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function isLTE(
		required any actual,
		required any target,
		message = ""
	){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#arguments.actual#] is not less than or equal to [#arguments.target#]"
		);

		if ( arguments.actual lte arguments.target ) {
			return this;
		}

		fail( arguments.message );
	}


	/**
	 * Get a string name representation of an incoming object.
	 */
	function getStringName( obj ){
		if ( isNull( arguments.obj ) ) {
			return "null";
		}
		if ( isSimpleValue( arguments.obj ) ) {
			return arguments.obj;
		}
		var type = "";
		try {
			type = "[#getMetadata( arguments.obj ).name#]: ";
		} catch ( any e ) {
			type = "[Unknown Object]: ";
		}

		var toStringValue = "";
		try {
			toStringValue = limitString( arguments.obj.toString(), 200 );
		} catch ( any e ) {
			// do nothing
		}
		return type & toStringValue;
	}

	/**
	 * Assert something is JSON
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function isJSON( required any actual, message = "" ){
		arguments.message = (
			len( arguments.message ) ? arguments.message : "Expected [#arguments.actual#] to be json"
		);
		if ( !isJSON( arguments.actual ) ) {
			fail( arguments.message );
		}
		return this;
	}

	/*********************************** PRIVATE Methods ***********************************/

	private boolean function equalize( any expected, any actual ){
		// Null values
		if ( isNull( arguments.expected ) && isNull( arguments.actual ) ) {
			return true;
		}

		if ( isNull( arguments.expected ) || isNull( arguments.actual ) ) {
			return false;
		}

		// Numerics
		if (
			isNumeric( arguments.actual ) && isNumeric( arguments.expected ) && toString( arguments.actual ) eq toString(
				arguments.expected
			)
		) {
			return true;
		}

		// Simple values
		if (
			isSimpleValue( arguments.actual ) && isSimpleValue( arguments.expected ) && arguments.actual eq arguments.expected
		) {
			return true;
		}

		// Queries
		if ( isQuery( arguments.actual ) && isQuery( arguments.expected ) ) {
			// Check number of records
			if ( arguments.actual.recordCount != arguments.expected.recordCount ) {
				return false;
			}

			// Get both column lists and sort them the same
			var actualColumnList   = listSort( arguments.actual.columnList, "textNoCase" );
			var expectedColumnList = listSort( arguments.expected.columnList, "textNoCase" );

			// Check column lists
			if ( actualColumnList != expectedColumnList ) {
				return false;
			}

			// Loop over each row
			var i = 0;
			while ( ++i <= arguments.actual.recordCount ) {
				// Loop over each column
				for ( var column in listToArray( actualColumnList ) ) {
					// Compare each value
					if ( arguments.actual[ column ][ i ] != arguments.expected[ column ][ i ] ) {
						// At the first sign of trouble, bail!
						return false;
					}
				}
			}

			// We made it here so nothing looked wrong
			return true;
		}

		// UDFs
		if (
			isCustomFunction( arguments.actual ) && isCustomFunction( arguments.expected ) &&
			arguments.actual.toString() eq arguments.expected.toString()
		) {
			return true;
		}

		// XML
		if (
			isXMLDoc( arguments.actual ) && isXMLDoc( arguments.expected ) &&
			toString( arguments.actual ) eq toString( arguments.expected )
		) {
			return true;
		}

		// Arrays
		if ( isArray( arguments.actual ) && isArray( arguments.expected ) ) {
			// Confirm both arrays are the same length
			if ( arrayLen( arguments.actual ) neq arrayLen( arguments.expected ) ) {
				return false;
			}

			for ( var i = 1; i lte arrayLen( arguments.actual ); i++ ) {
				// check for both being defined
				if ( arrayIsDefined( arguments.actual, i ) and arrayIsDefined( arguments.expected, i ) ) {
					// check for both nulls
					if ( isNull( arguments.actual[ i ] ) and isNull( arguments.expected[ i ] ) ) {
						continue;
					}
					// check if one is null mismatch
					if ( isNull( arguments.actual[ i ] ) OR isNull( arguments.expected[ i ] ) ) {
						return false;
					}
					// And make sure they match
					if ( !equalize( arguments.actual[ i ], arguments.expected[ i ] ) ) {
						return false;
					}
					continue;
				}
				// check if both not defined, then continue to next element
				if ( !arrayIsDefined( arguments.actual, i ) and !arrayIsDefined( arguments.expected, i ) ) {
					continue;
				} else {
					return false;
				}
			}

			// If we made it here, we couldn't find anything different
			return true;
		}

		// Structs / Object
		if ( isStruct( arguments.actual ) && isStruct( arguments.expected ) ) {
			var actualKeys   = listSort( structKeyList( arguments.actual ), "textNoCase" );
			var expectedKeys = listSort( structKeyList( arguments.expected ), "textNoCase" );
			var key          = "";

			// Confirm both structs have the same keys
			if ( actualKeys neq expectedKeys ) {
				return false;
			}

			// Loop over each key
			for ( key in arguments.actual ) {
				// check for both nulls
				if ( isNull( arguments.actual[ key ] ) and isNull( arguments.expected[ key ] ) ) {
					continue;
				}
				// check if one is null mismatch
				if ( isNull( arguments.actual[ key ] ) OR isNull( arguments.expected[ key ] ) ) {
					return false;
				}
				// And make sure they match when actual values exist
				if ( !equalize( arguments.actual[ key ], arguments.expected[ key ] ) ) {
					return false;
				}
			}

			// If we made it here, we couldn't find anything different
			return true;
		}

		return arguments.actual.equals( arguments.expected );
	}

	/**
	 * Returns the length of the target based on its type
	 *
	 * @target The target to get the length of
	 */
	private function getTargetLength( required any target ){
		var aLength = 0;

		if ( isSimpleValue( arguments.target ) ) {
			aLength = len( arguments.target );
		}
		if ( isArray( arguments.target ) ) {
			aLength = arrayLen( arguments.target );
		}
		if ( isStruct( arguments.target ) ) {
			aLength = structCount( arguments.target );
		}
		if ( isQuery( arguments.target ) ) {
			aLength = arguments.target.recordcount;
		}
		if ( isCustomFunction( arguments.target ) or isClosure( arguments.target ) ) {
			throw(
				type    = "InvalidType",
				message = "You sent an invalid type for length checking (closure/function)"
			);
		}

		return aLength;
	}

	/**
	 * Get the identity hash code for the target.
	 *
	 * @target The target to get the hash code for
	 */
	private function getIdentityHashCode( required any target ){
		var system = createObject( "java", "java.lang.System" );
		return system.identityHashCode( arguments.target );
	}

	/**
	 * Normalize the target to a struct if possible.
	 *
	 * @target The target to normalize
	 *
	 * @throws InvalidTargetType - If we can normalize it to a struct
	 */
	private function normalizeToStruct( any target ){
		if ( isQuery( arguments.target ) ) {
			return getMetadata( arguments.target ).reduce( ( results, item ) => {
				results[ item.name ] = {};
				return results;
			}, {} );
		}
		return arguments.target;
	}

	private string function limitString(
		required string str,
		required numeric limit,
		string end = "..."
	){
		if ( len( arguments.str ) <= arguments.limit ) {
			return arguments.str;
		}

		return left( arguments.str, arguments.limit ) & arguments.end;
	}

}
