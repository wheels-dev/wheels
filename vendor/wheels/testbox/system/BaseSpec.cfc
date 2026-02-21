/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is a base spec object that is used to test XUnit and BDD style specification methods
 */
component {

	// Param default URL method runner when it runs remotely
	param name="url.method" default="runRemote";

	// Assertions object
	variables.$assert          = this.$assert = new wheels.testbox.system.Assertion();
	// Custom Matchers
	this.$customMatchers       = {};
	// BDD Test Suites are stored here as an array so they are executed in order of definition
	this.$suites               = [];
	// A reverse lookup for the suite definitions
	this.$suiteReverseLookup   = {};
	// The suite context, denotes the current suite being defined
	this.$suiteContext         = "";
	// ExpectedException Annotation
	this.$exceptionAnnotation  = "expectedException";
	// Expected Exception holder, only use on synchronous testing.
	this.$expectedException    = {};
	// Internal testing ID
	this.$testID               = hash( getTickCount() + randRange( 1, 10000000 ) );
	// Debug buffer
	this.$debugBuffer          = [];
	// Current Executing Spec
	this.$currentExecutingSpec = "";
	// Focused Structures
	this.$focusedTargets       = { "suites" : [], "specs" : [] };
	// Setup Request Utilities struct
	if ( !request.keyExists( "testbox" ) ) {
		request.testbox = {};
	}
	// Setup request lookbacks for debugging purposes.
	request.$testID = this.$testID;

	/************************************** BDD & EXPECTATIONS METHODS *********************************************/

	/**
	 * Constructor
	 */
	remote function init(){
		return this;
	}

	/**
	 * Expect an exception from the testing spec
	 *
	 * @type  The type to expect
	 * @regex Optional exception message regular expression to match, by default it matches .*
	 */
	function expectedException( type = "", regex = ".*" ){
		this.$expectedException = arguments;
		return this;
	}

	/**
	 * Assert that the passed expression is true
	 *
	 * @facade
	 */
	function assert( required expression, message = "" ){
		return this.$assert.assert( argumentCollection = arguments );
	}

	/**
	 * Fail an assertion
	 *
	 * @facade
	 */
	function fail( message = "", detail = "" ){
		this.$assert.fail( argumentCollection = arguments );
	}

	/**
	 * Skip a test
	 *
	 * @message The message to send in the skip information dialog
	 * @detail  The detail to add in the exception
	 */
	function skip( message = "", detail = "" ){
		this.$assert.skip( argumentCollection = arguments );
	}


	/**
	 * This function is used for BDD test suites to store the beforeEach() function to execute for a test suite group
	 *
	 * @body The closure function
	 * @data Data bindings
	 */
	function beforeEach( required any body, struct data = {} ){
		this.$suitesReverseLookup[ this.$suiteContext ].beforeEach = arguments.body;
		this.$suitesReverseLookup[ this.$suiteContext ].beforeEachData = arguments.data;
		return this;
	}

	/**
	 * This function is used for BDD test suites to store the afterEach() function to execute for a test suite group
	 *
	 * @body The closure function
	 * @data Data bindings
	 */
	function afterEach( required any body, struct data = {} ){
		this.$suitesReverseLookup[ this.$suiteContext ].afterEach = arguments.body;
		this.$suitesReverseLookup[ this.$suiteContext ].afterEachData = arguments.data;
		return this;
	}

	/**
	 * This is used to surround a spec with your own closure code to provide a nice around decoration advice
	 *
	 * @body The closure function
	 * @data Data bindings
	 */
	function aroundEach( required any body, struct data = {} ){
		this.$suitesReverseLookup[ this.$suiteContext ].aroundEach = arguments.body;
		this.$suitesReverseLookup[ this.$suiteContext ].aroundEachData = arguments.data;
		return this;
	}

	/**
	 * Focused Describe, only this should run
	 *
	 * @title    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function fdescribe(
		required string title,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		arguments.focused = true;
		return this.describe( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The title is usually what you are testing or grouping of tests.
	 * The body is the function that implements the suite.
	 *
	 * @title    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 * @focused  A flag that tells TestBox to only run this suite and no other
	 */
	any function describe(
		required string title,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false,
		boolean focused  = false
	){
		// closure checks
		if ( !isClosure( arguments.body ) && !isCustomFunction( arguments.body ) ) {
			throw(
				type    = "TestBox.InvalidBody",
				message = "The body of this test suite must be a closure and you did not give me one, what's up with that!"
			);
		}

		var suite = {
			// The unique id of the spec that can be reproducible
			"id"             : hash( this.$suiteContext & arguments.title ),
			// suite name
			"name"           : arguments.title,
			// async flag
			"asyncAll"       : arguments.asyncAll,
			// skip suite testing
			"skip"           : arguments.skip,
			// labels attached to the suite for execution
			"labels"         : ( isSimpleValue( arguments.labels ) ? listToArray( arguments.labels ) : arguments.labels ),
			// the test specs for this suite
			"specs"          : [],
			// the recursive suites
			"suites"         : [],
			// the beforeEach closure
			"beforeEach"     : variables.closureStub,
			"beforeEachData" : {},
			// the afterEach closure
			"afterEach"      : variables.closureStub,
			"afterEachData"  : {},
			// the aroundEach closure, init to empty to distinguish
			"aroundEach"     : variables.aroundStub,
			"aroundEachData" : {},
			// the parent suite
			"parent"         : "",
			// the parent ref
			"parentRef"      : "",
			// hierarchy slug
			"slug"           : "",
			// Focused
			"focused"        : arguments.focused
		};

		// skip constraint for suite as a closure
		// Todo: move this to the runner, so it can be delayed.
		if ( isClosure( arguments.skip ) || isCustomFunction( arguments.skip ) ) {
			suite.skip = arguments.skip(
				title    = arguments.title,
				body     = arguments.body,
				labels   = arguments.labels,
				asyncAll = arguments.asyncAll,
				suite    = suite
			);
		}

		// Are we in a nested describe() block
		if ( len( this.$suiteContext ) and this.$suiteContext neq arguments.title ) {
			// Append this suite to the nested suite.
			arrayAppend( this.$suitesReverseLookup[ this.$suiteContext ].suites, suite );
			this.$suitesReverseLookup[ arguments.title ] = suite;

			// Setup parent reference
			suite.parent    = this.$suiteContext;
			suite.parentRef = this.$suitesReverseLookup[ this.$suiteContext ];

			// Build hierarchy slug separated by /
			suite.slug = this.$suitesReverseLookup[ this.$suiteContext ].slug & "/" & this.$suiteContext;
			if ( left( suite.slug, 1 ) != "/" ) {
				suite.slug = "/" & suite.slug;
			}

			// Store parent context
			var parentContext    = this.$suiteContext;
			var parentSpecIndex  = this.$specOrderIndex;
			// Switch contexts and go deep
			this.$suiteContext   = arguments.title;
			this.$specOrderIndex = 1;
			// execute the test suite definition with this context now.
			arguments.body();
			// switch back the context to parent
			this.$suiteContext   = parentContext;
			this.$specOrderIndex = parentSpecIndex;
		} else {
			// Append this spec definition to the master root to track it
			arrayAppend( this.$suites, suite );
			// setup pivot context now and reverse lookups
			this.$suiteContext                           = arguments.title;
			this.$specOrderIndex                         = 1;
			this.$suitesReverseLookup[ arguments.title ] = suite;
			// execute the test suite definition with this context now.
			arguments.body();
			// reset context, finalized it already.
			this.$suiteContext = "";
		}

		// Are we focused?
		if ( arguments.focused ) {
			arrayAppend( this.$focusedTargets.suites, suite.slug & "/" & suite.name );
		}

		// Restart spec index
		this.$specOrderIndex = 1;

		return this;
	}

	/**
	 * The way to describe BDD test suites in TestBox. The story is an alias for describe usually use when you are writing using Gherkin-esque language
	 * The body is the function that implements the suite.
	 *
	 * @story    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function story(
		required string story,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return describe( argumentCollection = arguments, title = "Story: " & arguments.story );
	}

	/**
	 * A focused Story
	 *
	 * @story    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function fstory(
		required string story,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return fdescribe( argumentCollection = arguments, title = "Story: " & arguments.story );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The feature is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function feature(
		required string feature,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return describe( argumentCollection = arguments, title = "Feature: " & arguments.feature );
	}

	/**
	 * A Focused Feature
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function ffeature(
		required string feature,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return fdescribe( argumentCollection = arguments, title = "Feature: " & arguments.feature );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The given is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function given(
		required string given,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return describe( argumentCollection = arguments, title = "Given " & arguments.given );
	}

	/**
	 * A focused given
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function fgiven(
		required string given,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return fdescribe( argumentCollection = arguments, title = "Given " & arguments.given );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The scenario is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function scenario(
		required string scenario,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return describe( argumentCollection = arguments, title = "Scenario: " & arguments.scenario );
	}

	/**
	 * A focused scenario
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function fscenario(
		required string scenario,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return fdescribe( argumentCollection = arguments, title = "Scenario: " & arguments.scenario );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The when is an alias for scenario usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function when(
		required string when,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return describe( argumentCollection = arguments, title = "When " & arguments.when );
	}

	/**
	 * A focused when
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function fwhen(
		required string when,
		required any body,
		any labels       = [],
		boolean asyncAll = false,
		any skip         = false
	){
		return fdescribe( argumentCollection = arguments, title = "When " & arguments.when );
	}

	/**
	 * A focused `it` where only focused it's are executed
	 *
	 * @title  The title of this spec
	 * @body   The closure that represents the test
	 * @labels The list or array of labels this spec belongs to
	 * @skip   A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data   A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 */
	any function fit(
		required string title,
		required any body,
		any labels  = [],
		any skip    = false,
		struct data = {}
	){
		arguments.focused = true;
		return this.it( argumentCollection = arguments );
	}

	/**
	 * The it() function describes a spec or a test in TestBox.  The body argument is the closure that implements
	 * the test which usually contains one or more expectations that test the state of the code under test.
	 *
	 * @title   The title of this spec
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @skip    A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 *
	 * @throws TestBox.InvalidBody    If the body is not a closure
	 * @throws TestBox.InvalidContext If the spec is not defined within a suite
	 */
	any function it(
		required string title,
		required any body,
		any labels      = [],
		any skip        = false,
		struct data     = {},
		boolean focused = false
	){
		// closure checks
		if ( !isClosure( arguments.body ) && !isCustomFunction( arguments.body ) ) {
			throw(
				type    = "TestBox.InvalidBody",
				message = "The body of this test suite must be a closure and you did not give me one, what's up with that!"
			);
		}

		// context checks
		if ( !len( this.$suiteContext ) ) {
			throw(
				type    = "TestBox.InvalidContext",
				message = "You cannot define a spec without a test suite! This it() must exist within a describe() body! Go fix it :)"
			);
		}

		// define the spec
		var spec = {
			// The unique id of the spec that can be reproducible
			"id"          : hash( this.$suiteContext & arguments.title ),
			// the spec body
			"body"        : arguments.body,
			// the data binding
			"data"        : arguments.data,
			// Focus flag
			"focused"     : arguments.focused,
			// labels attached to the spec for execution
			"labels"      : ( isSimpleValue( arguments.labels ) ? listToArray( arguments.labels ) : arguments.labels ),
			// spec title
			"name"        : arguments.title,
			// Display name
			"displayName" : arguments.title,
			// the order of execution
			"order"       : this.$specOrderIndex++,
			// skip spec testing
			"skip"        : arguments.skip
		};

		// Executes the skip constraint for the spec and stores it's value
		// TODO: move this to the runner, so it can be delayed.
		if ( isClosure( arguments.skip ) || isCustomFunction( arguments.skip ) ) {
			spec.skip = arguments.skip(
				title  = arguments.title,
				body   = arguments.body,
				labels = arguments.labels,
				spec   = spec
			);
		}

		// Attach this spec to the incoming context array of specs
		arrayAppend( this.$suitesReverseLookup[ this.$suiteContext ].specs, spec );

		// Are we focused?
		if ( arguments.focused ) {
			var thisSuite = this.$suitesReverseLookup[ this.$suiteContext ];
			arrayAppend( this.$focusedTargets.specs, thisSuite.slug & "/" & thisSuite.name & "/" & spec.name );
		}
		return this;
	}

	/**
	 * An alias to the it() function to provide a more natural language for BDD.
	 *
	 * @title   The title of this test
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @skip    A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 */
	any function test(
		required string title,
		required any body,
		any labels      = [],
		any skip        = false,
		struct data     = {},
		boolean focused = false
	){
		return this.it( argumentCollection = arguments );
	}

	/**
	 * A focused alias to the fit() function to provide a more natural language for BDD.
	 *
	 * @then    The title of this spec
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @skip    A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 */
	any function ftest(
		required string title,
		required any body,
		any labels      = [],
		any skip        = false,
		struct data     = {},
		boolean focused = false
	){
		return this.fit( argumentCollection = arguments );
	}

	/**
	 * The then() function describes a spec or a test in TestBox and is an alias for it.  The body argument is the closure that implements
	 * the test which usually contains one or more expectations that test the state of the code under test.
	 *
	 * @then    The title of this spec
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @skip    A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 */
	any function then(
		required string then,
		required any body,
		any labels      = [],
		any skip        = false,
		struct data     = {},
		boolean focused = false
	){
		return it( argumentCollection = arguments, title = "Then " & arguments.then );
	}

	/**
	 * A focused then
	 *
	 * @then    The title of this spec
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @skip    A flag or a closure that tells TestBox to skip this spec test from testing if true. If this is a closure it must return boolean.
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 */
	any function fthen(
		required string then,
		required any body,
		any labels      = [],
		any skip        = false,
		struct data     = {},
		boolean focused = false
	){
		return fit( argumentCollection = arguments, title = "Then " & arguments.then );
	}

	/**
	 * This is a convenience method that makes sure the test suite is skipped from execution
	 *
	 * @title    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 */
	any function xdescribe(
		required string title,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.describe( argumentCollection = arguments );
	}

	/**
	 * This is a convenience method that makes sure the test spec is skipped from execution
	 *
	 * @title  The title of this spec
	 * @body   The closure that represents the test
	 * @labels The list or array of labels this spec belongs to
	 * @data   A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 */
	any function xit(
		required string title,
		required any body,
		any labels  = [],
		struct data = {}
	){
		arguments.skip = true;
		return this.it( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The story is an alias for describe usually use when you are writing using Gherkin-esque language
	 * The body is the function that implements the suite.
	 *
	 * @story    The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function xstory(
		required string story,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.story( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The feature is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function xfeature(
		required string feature,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.feature( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The given is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function xgiven(
		required string given,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.given( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The scenario is an alias for describe usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function xscenario(
		required string scenario,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.scenario( argumentCollection = arguments );
	}

	/**
	 * The way to describe BDD test suites in TestBox. The when is an alias for scenario usually use when you are writing in a Given-When-Then style
	 * The body is the function that implements the suite.
	 *
	 * @feature  The name of this test suite
	 * @body     The closure that represents the test suite
	 * @labels   The list or array of labels this suite group belongs to
	 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
	 * @skip     A flag or a closure that tells TestBox to skip this suite group from testing if true. If this is a closure it must return boolean.
	 */
	any function xwhen(
		required string when,
		required any body,
		any labels       = [],
		boolean asyncAll = false
	){
		arguments.skip = true;
		return this.when( argumentCollection = arguments );
	}

	/**
	 * This is a convenience method that makes sure the test spec is skipped from execution
	 *
	 * @title  The title of this spec
	 * @body   The closure that represents the test
	 * @labels The list or array of labels this spec belongs to
	 * @data   A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 */
	any function xthen(
		required string then,
		required any body,
		any labels  = [],
		struct data = {}
	){
		arguments.skip = true;
		return this.then( argumentCollection = arguments );
	}

	/**
	 * This is a convenience method that makes sure the test spec is skipped from execution
	 *
	 * @title   The title of this spec
	 * @body    The closure that represents the test
	 * @labels  The list or array of labels this spec belongs to
	 * @data    A struct of data you would like to bind into the spec so it can be later passed into the executing body function
	 * @focused A flag that tells TestBox to only run this spec and no other
	 */
	any function xtest(
		required string title,
		required any body,
		any labels      = [],
		struct data     = {},
		boolean focused = false
	){
		arguments.skip = true;
		return this.test( argumentCollection = arguments );
	}

	/**
	 * Start an expectation expression. This returns an instance of Expectation so you can work with its matchers.
	 *
	 * @actual The actual value, it is not required as it can be null.
	 */
	Expectation function expect( any actual ){
		// build an expectation
		var oExpectation = new Expectation( spec = this, assertions = this.$assert );

		// Store the actual data
		if ( !isNull( arguments.actual ) ) {
			oExpectation.actual = arguments.actual;
		} else {
			oExpectation.actual = javacast( "null", "" );
		}

		// Do we have any custom matchers to add to this expectation?
		if ( !structIsEmpty( this.$customMatchers ) ) {
			for ( var thisMatcher in this.$customMatchers ) {
				oExpectation.registerMatcher( thisMatcher, this.$customMatchers[ thisMatcher ] );
			}
		}

		return oExpectation;
	}

	/**
	 * Start a collection expectation expression. This returns an instance of CollectionExpectation
	 * so you can work with its collection-unrolling matches (delegating to Expectation).
	 *
	 * @actual The actual value, it should be an array or a struct.
	 */
	CollectionExpectation function expectAll( required any actual ){
		return new CollectionExpectation(
			spec       = this,
			assertions = this.$assert,
			collection = arguments.actual
		);
	}

	/**
	 * Add custom matchers to your expectations
	 *
	 * @matchers The structure of custom matcher functions to register or a path or instance of a class containing all the matcher functions to register
	 */
	function addMatchers( required any matchers ){
		// register structure
		if ( isStruct( arguments.matchers ) ) {
			// register the custom matchers with override
			structAppend( this.$customMatchers, arguments.matchers, true );
			return this;
		}

		// Build the Matcher
		var oMatchers = "";
		if ( isSimpleValue( arguments.matchers ) ) {
			oMatchers = new "#arguments.matchers#"( );
		} else if ( isObject( arguments.matchers ) ) {
			oMatchers = arguments.matchers;
		} else {
			throw(
				type    = "TestBox.InvalidCustomMatchers",
				message = "The matchers argument you sent is not valid, it must be a struct, string or object"
			);
		}

		// Register the methods into our custom matchers struct
		var matcherArray = structKeyArray( oMatchers );
		for ( var thisMatcher in matcherArray ) {
			this.$customMatchers[ thisMatcher ] = oMatchers[ thisMatcher ];
		}

		return this;
	}

	/**
	 * Add custom assertions to the $assert object
	 *
	 * @assertions The structure of custom assertion functions to register or a path or instance of a class containing all the assertion functions to register
	 */
	function addAssertions( required any assertions ){
		// register structure
		if ( isStruct( arguments.assertions ) ) {
			// register the custom matchers with override
			structAppend( this.$assert, arguments.assertions, true );
			return this;
		}

		// Build the Custom Assertion
		var oAssertions = "";
		if ( isSimpleValue( arguments.assertions ) ) {
			oAssertions = new "#arguments.assertions#"( );
		} else if ( isObject( arguments.assertions ) ) {
			oAssertions = arguments.assertions;
		} else {
			throw(
				type    = "TestBox.InvalidCustomAssertions",
				message = "The assertions argument you sent is not valid, it must be a struct, string or object"
			);
		}

		// Register the methods into our custom assertions struct
		var methodArray = structKeyArray( oAssertions );
		for ( var thisMethod in methodArray ) {
			this.$assert[ thisMethod ] = oAssertions[ thisMethod ];
		}

		return this;
	}

	/************************************** RUN BDD METHODS *********************************************/

	/**
	 * Run a test remotely, only useful if the spec inherits from this class. Useful for remote executions.
	 *
	 * @testSuites A list or array of suite names that are the ones that will be executed ONLY!
	 * @testSpecs  A list or array of test names that are the ones that will be executed ONLY!
	 * @reporter   The type of reporter to run the test with
	 * @labels     A list or array of labels to apply to the testing.
	 */
	remote function runRemote(
		string testSpecs  = "",
		string testSuites = "",
		string reporter   = "simple",
		string labels     = ""
	) output=true{
		setting requesttimeout=99999999;

		// content type defaulted, to avoid dreaded wddx default
		getPageContext().getResponse().setContentType( "text/html" );

		// run tests
		var runner = new wheels.testbox.system.TestBox(
			bundles : "#getMetadata( this ).name#",
			labels  : arguments.labels,
			reporter: arguments.reporter,
			options : { coverage : { enabled : false } }
		);
		// Produce report
		writeOutput( runner.run( testSuites = arguments.testSuites, testSpecs = arguments.testSpecs ) );
	}

	/**
	 * Run a BDD test in this target
	 *
	 * @spec        The spec definition to test
	 * @suite       The suite definition this spec belongs to
	 * @testResults The testing results object
	 * @suiteStats  The suite stats that the incoming spec definition belongs to
	 * @runner      The runner calling this BDD test
	 */
	function runSpec(
		required spec,
		required suite,
		required testResults,
		required suiteStats,
		required runner
	){
		try {
			// init spec tests
			var specStats          = arguments.testResults.startSpecStats( arguments.spec, arguments.suiteStats );
			// init consolidated spec labels
			var consolidatedLabels = arguments.spec.labels;
			var md                 = getMetadata( this );
			var mdLabels           = structKeyExists( md, "labels" ) ? md.labels : "";
			consolidatedLabels.append( listToArray( mdLabels ), true );
			// Build labels from nested suites, so suites inherit from parent suite labels
			var parentSuite = arguments.suite;
			while ( !isSimpleValue( parentSuite ) ) {
				consolidatedLabels.append( parentSuite.labels, true );
				parentSuite = parentSuite.parentref;
			}

			// Is the spec focused
			var isSpecFocused = function( name ){
				return (
					// We have no focused suites or specs
					( arrayLen( this.$focusedTargets.specs ) == 0 && arrayLen( this.$focusedTargets.suites ) == 0 )
					||
					(
						// Are we in the focused Spec?
						arrayLen( this.$focusedTargets.specs ) && arrayFindNoCase(
							this.$focusedTargets.specs,
							name
						)
						||
						// Are we in the focused Suite?
						arrayLen( this.$focusedTargets.suites ) && runner.isSuiteFocused(
							suite         = suite,
							target        = this,
							checkChildren = false
						)
					)
				);
			};

			// Verify we can execute
			if (
				!arguments.spec.skip && // Not skipping
				isSpecFocused( arguments.suite.slug & "/" & arguments.suite.name & "/" & arguments.spec.name ) && // Is the spec focused
				arguments.runner.canRunLabel( consolidatedLabels, arguments.testResults ) && // In label or no labels
				arguments.runner.canRunSpec( arguments.spec, arguments.testResults ) // In test results
			) {
				// setup the current executing spec for debug purposes
				this.$currentExecutingSpec = arguments.suite.slug & "/" & arguments.suite.name & "/" & arguments.spec.name;
				// Run beforeEach closures
				runBeforeEachClosures( arguments.suite, arguments.spec );

				try {
					runAroundEachClosures( arguments.suite, arguments.spec );
				} catch ( any e ) {
					rethrow;
				} finally {
					runAfterEachClosures( arguments.suite, arguments.spec );
				}

				// store spec status
				specStats.status = "Passed";
				// Increment recursive pass stats
				arguments.testResults.incrementSpecStat( type = "pass", stats = specStats );
			} else {
				// store spec status
				specStats.status = "Skipped";
				// Increment recursive pass stats
				arguments.testResults.incrementSpecStat( type = "skipped", stats = specStats );
			}
		}
		// Catch Skip() calls
		catch ( "TestBox.SkipSpec" e ) {
			// store spec status
			specStats.status      = "Skipped";
			specStats.failMessage = e.message;
			specStats.failDetail  = e.detail;
			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "skipped", stats = specStats );
			// Module call backs
			arguments.runner
				.getTestBox()
				.announceToModules(
					"onSpecSkipped",
					[
						arguments.spec,
						specStats,
						arguments.suite,
						arguments.suiteStats,
						arguments.testResults
					]
				);
		}
		// Catch Fail() calls
		catch ( "TestBox.AssertionFailed" e ) {
			// store spec status and debug data
			specStats.status           = "Failed";
			specStats.failMessage      = e.message;
			specStats.error            = e;
			specStats.failDetail       = e.detail;
			specStats.failExtendedInfo = e.extendedInfo;
			specStats.failStacktrace   = e.stackTrace;
			specStats.failOrigin       = e.tagContext;
			specStats.debugBuffer      = duplicate( this.$debugBuffer );

			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "fail", stats = specStats );
			// Module call backs
			arguments.runner
				.getTestBox()
				.announceToModules(
					"onSpecFailure",
					[
						e,
						arguments.spec,
						specStats,
						arguments.suite,
						arguments.suiteStats,
						arguments.testResults
					]
				);
		}
		// Catch errors
		catch ( any e ) {
			// store spec status and debug data
			specStats.status           = "Error";
			specStats.error            = e;
			specStats.failOrigin       = e.tagContext;
			specStats.failMessage      = e.message;
			specStats.failDetail       = e.detail;
			specStats.failExtendedInfo = e.extendedInfo;
			specStats.failStacktrace   = e.stackTrace;
			specStats.debugBuffer      = duplicate( this.$debugBuffer );

			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "error", stats = specStats );

			// Module call backs
			arguments.runner
				.getTestBox()
				.announceToModules(
					"onSpecError",
					[
						e,
						arguments.spec,
						specStats,
						arguments.suite,
						arguments.suiteStats,
						arguments.testResults
					]
				);
		} finally {
			// Complete spec testing
			arguments.testResults.endStats( specStats );
		}

		return this;
	}

	/**
	 * Execute the before each closures in order for a suite and spec
	 *
	 * @suite The suite definition
	 * @spec  The spec definition
	 */
	BaseSpec function runBeforeEachClosures( required suite, required spec ){
		// re-bind request utilities to the currently executing test before they may be invoked
		request.testbox.console          = () => variables.console( argumentCollection = arguments );
		request.testbox.debug            = () => variables.debug( argumentCollection = arguments );
		request.testbox.clearDebugBuffer = () => variables.clearDebugBuffer( argumentCollection = arguments );
		request.testbox.print            = () => variables.print( argumentCollection = arguments );
		request.testbox.println          = () => variables.println( argumentCollection = arguments );

		var reverseTree = [];

		// do we have nested suites? If so, traverse the tree to build reverse execution map
		var parentSuite = arguments.suite.parentRef;
		while ( !isSimpleValue( parentSuite ) ) {
			arrayAppend(
				reverseTree,
				{
					beforeEach     : parentSuite.beforeEach,
					beforeEachData : parentSuite.beforeEachData
				}
			);
			parentSuite = parentSuite.parentRef;
		}

		// Incorporate annotated methods
		arrayEach( getUtility().getAnnotatedMethods( annotation = "beforeEach", metadata = getMetadata( this ) ), function( item ){
			arrayAppend(
				reverseTree,
				{
					beforeEach     : this[ arguments.item.name ],
					beforeEachData : {}
				}
			);
		} );

		// sort tree backwards
		arraySort( reverseTree, function( a, b ){
			return -1;
		} );

		// Execute it
		arrayEach( reverseTree, function( item ){
			item.beforeEach( currentSpec = spec.name, data = item.beforeEachData );
		} );

		// execute beforeEach()
		arguments.suite.beforeEach( currentSpec = arguments.spec.name, data = arguments.suite.beforeEachData );

		return this;
	}

	/**
	 * Execute the around each closures in order for a suite and spec
	 *
	 * @suite The suite definition
	 * @spec  The spec definition
	 */
	BaseSpec function runAroundEachClosures( required suite, required spec ){
		var reverseTree = [
			{
				name   : arguments.suite.name,
				body   : arguments.suite.aroundEach,
				data   : arguments.suite.aroundEachData,
				labels : arguments.suite.labels,
				order  : 0,
				skip   : arguments.suite.skip
			}
		];

		// do we have nested suites? If so, traverse the tree to build reverse execution map
		var parentSuite = arguments.suite.parentRef;
		while ( !isSimpleValue( parentSuite ) ) {
			arrayAppend(
				reverseTree,
				{
					name   : parentSuite.name,
					body   : parentSuite.aroundEach,
					data   : parentSuite.aroundEachData,
					labels : parentSuite.labels,
					order  : 0,
					skip   : parentSuite.skip
				}
			);
			// go deep
			parentSuite = parentSuite.parentRef;
		}

		// Discover annotated methods and add to reverseTree
		arrayEach( getUtility().getAnnotatedMethods( annotation = "aroundEach", metadata = getMetadata( this ) ), function( item ){
			arrayAppend(
				reverseTree,
				{
					name   : arguments.item.name,
					body   : this[ arguments.item.name ],
					data   : {},
					labels : {},
					order  : 0,
					skip   : false
				}
			);
		} );

		// Sort the closures from the oldest parent down to the current spec
		arraySort( reverseTree, function( a, b ){
			return -1;
		} );

		// Build a function that will execute down the tree
		var specStack = generateAroundEachClosuresStack(
			closures = reverseTree,
			suite    = arguments.suite,
			spec     = arguments.spec
		);
		// Run the specs
		specStack();

		return this;
	}

	/**
	 * Generates a specs stack for executions
	 *
	 * @closures The array of closures data to build
	 * @suite    The target suite
	 * @spec     The target spec
	 */
	function generateAroundEachClosuresStack(
		array closures,
		required suite,
		required spec,
		closureIndex = 1
	){
		thread.closures = arguments.closures;
		thread.suite    = arguments.suite;
		thread.spec     = arguments.spec;

		// Get closure data from stack and pop it
		var nextClosure = thread.closures[ arguments.closureIndex ];

		// Check if we have more in the stack or empty
		if ( arrayLen( thread.closures ) == arguments.closureIndex ) {
			// Return the closure of execution for a single spec ONLY
			return function(){
				// Execute the body of the spec
				nextClosure.body(
					spec  = thread.spec,
					suite = thread.suite,
					data  = nextClosure.data
				);
			};
		}

		// Get next Spec in stack
		var nextSpecInfo = thread.closures[ ++arguments.closureIndex ];
		// Return generated closure
		return function(){
			nextClosure.body(
				spec = {
					name : nextSpecInfo.name,
					body : generateAroundEachClosuresStack(
						thread.closures,
						thread.suite,
						thread.spec,
						closureIndex
					),
					data   : nextSpecInfo.data,
					labels : nextSpecInfo.labels,
					order  : nextSpecInfo.order,
					skip   : nextSpecInfo.skip
				},
				suite = thread.suite,
				data  = nextClosure.data
			);
		};
	}

	/**
	 * Execute the after each closures in order for a suite and spec
	 *
	 * @suite The suite definition
	 * @spec  The spec definition
	 */
	BaseSpec function runAfterEachClosures( required suite, required spec ){
		// execute nearest afterEach()
		arguments.suite.afterEach( currentSpec = arguments.spec.name, data = arguments.suite.afterEachData );

		// do we have nested suites? If so, traverse and execute life-cycle methods up the tree backwards
		var parentSuite = arguments.suite.parentRef;
		while ( !isSimpleValue( parentSuite ) ) {
			parentSuite.afterEach( currentSpec = arguments.spec.name, data = parentSuite.afterEachData );
			parentSuite = parentSuite.parentRef;
		}

		arrayEach( getUtility().getAnnotatedMethods( annotation = "afterEach", metadata = getMetadata( this ) ), function( item ){
			invoke(
				this,
				item.name,
				{ currentSpec : spec.name, data : {} }
			);
		} );

		return this;
	}

	/**
	 * Runs a xUnit style test method in this target
	 *
	 * @spec        The spec definition to test
	 * @testResults The testing results object
	 * @suiteStats  The suite stats that the incoming spec definition belongs to
	 * @runner      The runner calling this BDD test
	 */
	function runTestMethod(
		required spec,
		required testResults,
		required suiteStats,
		required runner
	){
		try {
			// init spec tests
			var specStats = arguments.testResults.startSpecStats( arguments.spec, arguments.suiteStats );

			// Verify we can execute
			if (
				!arguments.spec.skip &&
				arguments.runner.canRunLabel( arguments.spec.labels, arguments.testResults ) &&
				arguments.runner.canRunSpec( arguments.spec, arguments.testResults )
			) {
				// Reset expected exceptions: Only works on synchronous testing.
				this.$expectedException    = {};
				// setup the current executing spec for debug purposes
				this.$currentExecutingSpec = arguments.spec.name;

				// execute setup()
				if ( structKeyExists( this, "setup" ) ) {
					this.setup( currentMethod = arguments.spec.name );
				}

				// Execute Spec
				try {
					invoke( this, arguments.spec.name );
					// Where we expecting an exception and it did not throw?
					if ( hasExpectedException( arguments.spec.name, arguments.runner ) ) {
						$assert.fail(
							"Method did not throw expected exception: [#this.$expectedException.toString()#]"
						);
					}
					// else all good.
				} catch ( Any e ) {
					// do we have expected exception? else rethrow it
					if ( !hasExpectedException( arguments.spec.name, arguments.runner ) ) {
						rethrow;
					}
					// if not the expected exception, then fail it
					if ( !isExpectedException( e, arguments.spec.name, arguments.runner ) ) {
						$assert.fail(
							"Method did not throw expected exception: [#this.$expectedException.toString()#], actual exception [type:#e.type#][message:#e.message#]"
						);
					}
				} finally {
					// execute teardown()
					if ( structKeyExists( this, "teardown" ) ) {
						this.teardown( currentMethod = arguments.spec.name );
					}
				}

				// store spec status
				specStats.status = "Passed";
				// Increment recursive pass stats
				arguments.testResults.incrementSpecStat( type = "pass", stats = specStats );
			} else {
				// store spec status
				specStats.status = "Skipped";
				// Increment recursive pass stats
				arguments.testResults.incrementSpecStat( type = "skipped", stats = specStats );
			}
		}
		// Catch skip() calls
		catch ( "TestBox.SkipSpec" e ) {
			// store spec status
			specStats.status      = "Skipped";
			specStats.failMessage = e.message;
			specStats.failDetail  = e.detail;
			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "skipped", stats = specStats );
		}
		// Catch Fail() calls
		catch ( "TestBox.AssertionFailed" e ) {
			// store spec status and debug data
			specStats.status           = "Failed";
			specStats.failMessage      = e.message;
			specStats.error            = e;
			specStats.failExtendedInfo = e.extendedInfo;
			specStats.failStacktrace   = e.stackTrace;
			specStats.failOrigin       = e.tagContext;
			specStats.debugBuffer      = duplicate( this.$debugBuffer );

			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "fail", stats = specStats );
		}
		// Catch errors
		catch ( any e ) {
			// store spec status and debug data
			specStats.status     = "Error";
			specStats.error      = e;
			specStats.failOrigin = e.tagContext;
			// Increment recursive pass stats
			arguments.testResults.incrementSpecStat( type = "error", stats = specStats );
		} finally {
			// Complete spec testing
			arguments.testResults.endStats( specStats );
		}

		return this;
	}

	/************************************** UTILITY METHODS *********************************************/

	/**
	 * Send some information to the console via writedump( output="console" )
	 *
	 * @var      The data to send
	 * @top      Apply a top to the dump, by default it does 9999 levels
	 * @showUDFs Show UDFs in the dump, by default it does not
	 * @label    A label to add to the console output
	 */
	any function console(
		required var,
		numeric top      = 9999,
		boolean showUDFs = false,
		string label     = ""
	){
		writeDump(
			output   = "console",
			var      = arguments.var,
			label    = "TestBox Console: #arguments.label#",
			top      = arguments.top,
			showUDFs = arguments.showUDFs
		);
		return this;
	}

	/**
	 * Debug some information into the TestBox debugger array buffer
	 *
	 * @var      The data to debug
	 * @label    The label to add to the debug entry
	 * @deepCopy By default we do not duplicate the incoming information, but you can :)
	 * @top      The top numeric number to dump on the screen in the report, defaults to 999
	 */
	any function debug(
		any var,
		string label     = "",
		boolean deepCopy = false,
		numeric top      = "999",
		boolean showUDFs = false
	){
		// null check
		if ( isNull( arguments.var ) ) {
			arrayAppend( this.$debugBuffer, "null" );
			return;
		}

		// duplication control
		var newVar = ( arguments.deepCopy ? duplicate( arguments.var ) : arguments.var );
		// compute label?
		if ( !len( trim( arguments.label ) ) ) {
			// Check if executing spec is set, else most likely this is called from a request scoped debug method
			arguments.label = !isNull( this.$currentExecutingSpec ) ? this.$currentExecutingSpec : "request";
		}

		// add to debug output
		arrayAppend(
			this.$debugBuffer,
			{
				"data"      : newVar,
				"label"     : arguments.label,
				"timestamp" : now(),
				"top"       : arguments.top,
				"showUDFs"  : arguments.showUDFs
			}
		);
		return this;
	}

	/**
	 * Clear the debug array buffer
	 */
	any function clearDebugBuffer(){
		arrayClear( this.$debugBuffer );
		return this;
	}

	/**
	 * Get the debug array buffer from scope
	 */
	array function getDebugBuffer(){
		return this.$debugBuffer;
	}

	/**
	 * Write some output to the ColdFusion output buffer
	 */
	any function print( required message ) output=true{
		writeOutput( arguments.message );
		return this;
	}

	/**
	 * Write some output to the ColdFusion output buffer using a <br> attached
	 */
	any function println( required message ) output=true{
		return print( arguments.message & "<br>" );
	}

	/************************************** MOCKING METHODS *********************************************/

	/**
	 * Make a private method on a class public with or without a new name and returns the target object
	 *
	 * @target  The target object to expose the method
	 * @method  The private method to expose
	 * @newName If passed, it will expose the method with this name, else just uses the same name
	 */
	any function makePublic(
		required any target,
		required string method,
		string newName = ""
	){
		// decorate it
		getUtility().getMixerUtil().start( arguments.target );
		// expose it
		arguments.target.exposeMixin( arguments.method, arguments.newName );

		return arguments.target;
	}

	/**
	 * Get a private property
	 *
	 * @target       The target to get a property from
	 * @name         The name of the property to retrieve
	 * @scope        The scope to get it from, defaults to 'variables' scope
	 * @defaultValue A default value if the property does not exist
	 */
	any function getProperty(
		required target,
		required name,
		scope = "variables",
		defaultValue
	){
		// stupid cf10 parser
		if ( structKeyExists( arguments, "defaultValue" ) ) {
			arguments.default = arguments.defaultValue;
		}
		return prepareMock( arguments.target ).$getProperty( argumentCollection = arguments );
	}

	/**
	 * First line are the query columns separated by commas. Then do a consequent rows separated by line breaks separated by | to denote columns.
	 */
	function querySim( required queryData ){
		return getMockBox().querySim( arguments.queryData );
	}

	/**
	 * Use cbMockData to mock whatever data you want by executing the `mock()` function in cbMockData
	 *
	 * @return The mock data you desire sir!
	 */
	function mockData(){
		return getCBMockData().mock( argumentCollection = arguments );
	}

	/**
	 * Get the MockData Class object
	 *
	 * @return wheels.testbox.system.modules.cbMockData.models.MockData
	 */
	function getCBMockData(){
		// Lazy Load it
		if ( isNull( variables.$cbMockData ) ) {
			variables.$cbMockData = new wheels.testbox.system.modules.cbMockData.models.MockData();
		}
		return variables.$cbMockData;
	}

	/**
	 * Get the TestBox utility object
	 *
	 * @return wheels.testbox.system.util.Util
	 */
	function getUtility(){
		// Lazy Load it
		if ( isNull( variables.$utility ) ) {
			variables.$utility = new wheels.testbox.system.util.Util();
		}
		return variables.$utility;
	}

	/**
	 * Get the TestBox Env  object
	 *
	 * @return wheels.testbox.system.util.Env
	 */
	function getEnv(){
		// Lazy Load it
		if ( isNull( variables.$env ) ) {
			variables.$env = new wheels.testbox.system.util.Env();
		}
		return variables.$env;
	}

	/**
	 * Get a reference to the MockBox Engine
	 *
	 * @generationPath The path to generate the mocks if passed, else uses default location.
	 *
	 * @return wheels.testbox.system.MockBox
	 */
	function getMockBox( string generationPath = "" ){
		// Lazy Load it
		if ( isNull( this.$mockbox ) ) {
			variables.$mockbox = this.$mockbox = new wheels.testbox.system.MockBox( arguments.generationPath );
		} else {
			// Generation path updates
			if ( len( arguments.generationPath ) ) {
				this.$mockBox.setGenerationPath( arguments.generationPath );
			}
		}

		return this.$mockBox;
	}

	/**
	 * Create an empty mock
	 *
	 * @className   The class name of the object to mock. The mock factory will instantiate it for you
	 * @object      The object to mock, already instantiated
	 * @callLogging Add method call logging for all mocked methods. Defaults to true
	 */
	function createEmptyMock(
		string className,
		any object,
		boolean callLogging = true
	){
		return getMockBox().createEmptyMock( argumentCollection = arguments );
	}

	/**
	 * Create a mock with or without clearing implementations, usually not clearing means you want to build object spies
	 *
	 * @className    The class name of the object to mock. The mock factory will instantiate it for you
	 * @object       The object to mock, already instantiated
	 * @clearMethods If true, all methods in the target mock object will be removed. You can then mock only the methods that you want to mock. Defaults to false
	 * @callLogging  Add method call logging for all mocked methods. Defaults to true
	 */
	function createMock(
		string className,
		any object,
		boolean clearMethods = false
		boolean callLogging  =true
	){
		return getMockBox().createMock( argumentCollection = arguments );
	}

	/**
	 * Prepares an already instantiated object to act as a mock for spying and much more
	 *
	 * @object      The object to mock, already instantiated
	 * @callLogging Add method call logging for all mocked methods. Defaults to true
	 */
	function prepareMock( any object, boolean callLogging = true ){
		return getMockBox().prepareMock( argumentCollection = arguments );
	}

	/**
	 * Create an empty stub object that you can use for mocking
	 *
	 * @callLogging Add method call logging for all mocked methods. Defaults to true
	 * @extends     Make the stub extend from certain class
	 * @implements  Make the stub adhere to an interface
	 */
	function createStub(
		boolean callLogging = true,
		string extends      = "",
		string implements   = ""
	){
		return getMockBox().createStub( argumentCollection = arguments );
	}

	// Closure Stub
	function closureStub(){
	}

	// Around Stub
	function aroundStub( spec ){
		arguments.spec.body( arguments.spec.data );
	}

	/**
	 * Check if an expected exception is defined
	 */
	boolean function hasExpectedException( required specName, required runner ){
		// do we have an expected annotation?
		var eAnnotation = arguments.runner.getMethodAnnotation(
			this[ arguments.specName ],
			this.$exceptionAnnotation,
			"false"
		);

		if ( eAnnotation != false ) {
			// incorporate it.
			this.$expectedException = {
				type  : ( eAnnotation == "true" ? "" : listFirst( eAnnotation, ":" ) ),
				regex : ( find( ":", eAnnotation ) ? listLast( eAnnotation, ":" ) : ".*" )
			};
		}

		return ( structIsEmpty( this.$expectedException ) ? false : true );
	}

	/**
	 * Check if the incoming exception is expected or not.
	 */
	boolean function isExpectedException(
		required exception,
		required specName,
		required runner
	){
		var results = false;

		// normalize expected exception
		if ( hasExpectedException( arguments.specName, arguments.runner ) ) {
			// If no type, message expectations
			if ( !len( this.$expectedException.type ) && this.$expectedException.regex eq ".*" ) {
				results = true;
			}
			// Type expectation then
			else if (
				len( this.$expectedException.type ) &&
				arguments.exception.type eq this.$expectedException.type &&
				(
					this.$expectedException.regex == ".*"
					|| arrayLen( reMatchNoCase( this.$expectedException.regex, arguments.exception.message ) )
				)
			) {
				results = true;
			}
			// Message regex then only
			else if (
				this.$expectedException.regex neq ".*" &&
				arrayLen( reMatchNoCase( this.$expectedException.regex, arguments.exception.message ) )
			) {
				results = true;
			}
		}

		return results;
	}

	/**
	 * ------------------------------------------------------------------
	 * Environment Skipping Helpers
	 * ------------------------------------------------------------------
	 */

	function isAdobe(){
		return server.keyExists( "coldfusion" ) && server.coldfusion.productName.findNoCase( "ColdFusion Server" );
	}

	function isLucee(){
		return server.keyExists( "lucee" );
	}

	function isBoxLang(){
		return server.keyExists( "boxlang" );
	}

	function isWindows(){
		return server.keyExists( "os" ) && server.os.name.findNoCase( "windows" );
	}

	function isLinux(){
		return server.keyExists( "os" ) && server.os.name.findNoCase( "unix" );
	}

	function isMac(){
		return server.keyExists( "os" ) && server.os.name.findNoCase( "mac" );
	}

	/**
	 * ------------------------------------------------------------------
	 * Pass-through assertions
	 * ------------------------------------------------------------------
	 */

	/**
	 * On missing method handler for dynamic assertions
	 *
	 * @missingMethodName      The name of the missing method
	 * @missingMethodArguments The arguments passed to the missing method
	 */
	function onMissingMethod( missingMethodName, missingMethodArguments ){
		// If the method follows the pattern "assert{target}" then get the target into a variable
		if ( left( arguments.missingMethodName, 6 ) == "assert" && len( arguments.missingMethodName ) > 6 ) {
			var target = right( arguments.missingMethodName, len( arguments.missingMethodName ) - 6 );
			return invoke(
				this.$assert,
				target,
				arguments.missingMethodArguments
			);
		}

		// Throw an exception
		throw( type = "InvalidMethod", message = "The method #arguments.missingMethodName# does not exist." );
	}

}
