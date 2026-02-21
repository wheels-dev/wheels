/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Mail Utility library for TestBox
 */
component {

	/**
	 * Get the mixer utility object instance. It lazy loads into variables scope for faster execution next time.
	 *
	 * @return MixerUtil
	 */
	function getMixerUtil(){
		if ( structKeyExists( variables, "mixerUtil" ) ) {
			return variables.mixerUtil;
		}
		variables.mixerUtil = new MixerUtil();
		return variables.mixerUtil;
	}

	/**
	 * Convert an array to struct argument notation
	 *
	 * @input The array to convert
	 */
	struct function arrayToStruct( required array input ){
		var results = structNew();
		var x       = 1;
		var inLen   = arrayLen( arguments.input );

		for ( x = 1; x lte inLen; x = x + 1 ) {
			results[ x ] = arguments.input[ x ];
		}

		return results;
	}

	/**
	 * Get the last modified date of a file
	 *
	 * @filename The target
	 *
	 * @return date
	 */
	function fileLastModified( required filename ){
		var objFile = createObject( "java", "java.io.File" ).init(
			javacast( "string", getAbsolutePath( arguments.filename ) )
		);
		// Calculate adjustments fot timezone and daylightsavindtime
		var offset = ( ( getTimezoneInfo().utcHourOffset ) + 1 ) * -3600;
		// Date is returned as number of seconds since 1-1-1970
		return dateAdd(
			"s",
			( round( objFile.lastModified() / 1000 ) ) + offset,
			createDateTime( 1970, 1, 1, 0, 0, 0 )
		);
	}

	/**
	 * Rip an extension of a filename
	 *
	 * @filename The target
	 */
	string function ripExtension( required filename ){
		return reReplace( arguments.filename, "\.[^.]*$", "" );
	}

	/**
	 * Turn any system path, either relative or absolute, into a fully qualified one
	 *
	 * @path The target
	 */
	string function getAbsolutePath( required path ){
		var fileObj = createObject( "java", "java.io.File" ).init( javacast( "String", arguments.path ) );
		if ( fileObj.isAbsolute() ) {
			return arguments.path;
		}
		return expandPath( arguments.path );
	}

	/**
	 * Add a CFML Mapping to the running engine
	 *
	 * @name     The name of the mapping
	 * @path     The path of the mapping
	 * @mappings A struct of mappings to incorporate instead of one-offs
	 */
	Util function addMapping( string name, string path, struct mappings ){
		var engineMappingHelper = getEngineMappingHelper();

		if ( !isNull( arguments.mappings ) ) {
			engineMappingHelper.addMappings( arguments.mappings );
		} else {
			// Add / registration
			if ( left( arguments.name, 1 ) != "/" ) {
				arguments.name = "/#arguments.name#";
			}

			// Add mapping
			engineMappingHelper.addMapping( arguments.name, arguments.path );
		}

		return this;
	}

	/**
	 * Check if you are in cfthread or not for any CFML Engine
	 */
	boolean function inThread(){
		// ACF
		if ( server.keyExists( "coldfusion" ) && server.coldfusion.productname.findNoCase( "ColdFusion" ) ) {
			if (
				findNoCase(
					"cfthread",
					createObject( "java", "java.lang.Thread" )
						.currentThread()
						.getThreadGroup()
						.getName()
				)
			) {
				return true;
			}
			return false;
		}

		// Lucee + BoxLang
		return isInThread();
	}

	/**
	 * Create a URL safe slug from a string
	 *
	 * @str       The target
	 * @maxLength The maximum number of characters for the slug
	 * @allow     A regex safe list of additional characters to allow
	 */
	string function slugify(
		required string str,
		numeric maxLength = 0,
		string allow      = ""
	){
		// Cleanup and slugify the string
		var slug = lCase( trim( arguments.str ) );

		slug = reReplace(
			slug,
			"[^a-z0-9-\s#arguments.allow#]",
			"",
			"all"
		);
		slug = trim( reReplace( slug, "[\s-]+", " ", "all" ) );
		slug = reReplace( slug, "\s", "-", "all" );

		// is there a max length restriction
		if ( arguments.maxlength ) {
			slug = left( slug, arguments.maxlength );
		}

		return slug;
	}


	/**
	 * Find all methods on a given metadata and it's parents with a given annotation
	 *
	 * @annotation The annotation name to look for on methods
	 * @metadata   The metadata to search (recursively) for the provided annotation
	 */
	array function getAnnotatedMethods( required string annotation, required struct metadata ){
		var lifecycleMethods = [];

		if ( structKeyExists( arguments.metadata, "functions" ) ) {
			for ( var thisFunction in arguments.metadata.functions ) {
				if ( structKeyExists( thisFunction, arguments.annotation ) ) {
					arrayAppend( lifecycleMethods, thisFunction );
				}
				// BoxLang support
				if (
					thisFunction.keyExists( "annotations" ) && thisFunction.annotations.keyExists(
						arguments.annotation
					)
				) {
					arrayAppend( lifecycleMethods, thisFunction );
				}
			}
		}

		if ( structKeyExists( arguments.metadata, "extends" ) ) {
			arrayEach( getAnnotatedMethods( arguments.annotation, arguments.metadata.extends ), function( item ){
				arrayAppend( lifecycleMethods, arguments.item );
			} );
		}

		return lifecycleMethods;
	}

	/**
	 * Get the appropriate engine mapping helper for the current engine
	 */
	private function getEngineMappingHelper(){
		// Lazy load the helper
		if ( isNull( variables.engineMappingHelper ) ) {
			if ( server.keyExists( "boxlang" ) ) {
				variables.engineMappingHelper = new BoxLangMappingHelper();
			} else if ( listFindNoCase( "Lucee", server.coldfusion.productname ) ) {
				variables.engineMappingHelper = new LuceeMappingHelper();
			} else {
				variables.engineMappingHelper = new CFMappingHelper();
			}
		}
		return variables.engineMappingHelper;
	}

}
