/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * The CollectionExpectation holds a collection and behaves like an expectation
 * that automatically unrolls the collection to verify every element
 */
component accessors="true" {

	// The (actual) collection
	property name="actual";
	// The reference to the spec that created this
	property name="spec";
	// The assertions reference
	property name="assert";

	/**
	 * Constructor
	 *
	 * @spec       The target spec
	 * @assertions The assertions library
	 * @collection The collection target
	 */
	function init(
		required spec,
		required any assertions,
		required collection
	){
		variables.actual = arguments.collection;
		variables.spec   = arguments.spec;
		variables.assert = arguments.assertions;

		return this;
	}

	function onMissingMethod( string missingMethodName, any missingMethodArguments ){
		if ( isArray( variables.actual ) ) {
			for ( var e in variables.actual ) {
				invoke(
					variables.spec.expect( e ),
					arguments.missingMethodName,
					arguments.missingMethodArguments
				);
			}
		} else if ( isStruct( variables.actual ) ) {
			for ( var k in variables.actual ) {
				var e = variables.actual[ k ];
				invoke(
					variables.spec.expect( e ),
					arguments.missingMethodName,
					arguments.missingMethodArguments
				);
			}
		} else {
			variables.assert.fail( "expectAll() actual is neither array nor struct" );
		}
		return this; // so we can chain matchers
	}

}
