<cfscript>
			variables[ "closeSSEStream" ] = variables[ "tmp_closeSSEStream_139184C0543CCDB338AEFB643110CB89" ];
			this[ "closeSSEStream" ]           = variables[ "tmp_closeSSEStream_139184C0543CCDB338AEFB643110CB89" ];

			// Clean up
			structDelete( variables, "tmp_closeSSEStream_139184C0543CCDB338AEFB643110CB89" );
			structDelete( this, "tmp_closeSSEStream_139184C0543CCDB338AEFB643110CB89" );
			public void function tmp_closeSSEStream_139184C0543CCDB338AEFB643110CB89( 

			) output=true {
 
			var results                 = this._mockResults;
			var resultsKey           = "closeSSEStream";
			var resultsCounter   = 0;
			var internalCounter = 0;
			var resultsLen           = 0;
			var callbackLen         = 0;
			var argsHashKey         = resultsKey & "|" & this.mockBox.normalizeArguments( arguments );
			var fCallBack             = "";

			// If Method & argument Hash Results, switch the results struct
if (structKeyExists( this._mockArgResults, argsHashKey) ) {
										// Check if it is a callback
if (isStruct( this._mockArgResults[ argsHashKey ]) &&
												structKeyExists( this._mockArgResults[ argsHashKey ], "type" ) &&
												structKeyExists( this._mockArgResults[ argsHashKey ], "target" ) ) {
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
			this._mockMethodCallCounters[ listFirst( resultsKey, "|" ) ] = this._mockMethodCallCounters[ listFirst( resultsKey, "|" ) ] + 1;

			// Get the CallCounter Reference
			internalCounter = this._mockMethodCallCounters[listFirst(resultsKey,"|")];
			arrayAppend( this._mockCallLoggers["closeSSEStream"], arguments );
}
</cfscript>