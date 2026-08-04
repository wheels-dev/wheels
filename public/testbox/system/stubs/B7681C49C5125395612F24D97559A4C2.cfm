<cfscript>
			variables[ "initSSEStream" ] = variables[ "tmp_initSSEStream_B7681C49C5125395612F24D97559A4C2" ];
			this[ "initSSEStream" ]           = variables[ "tmp_initSSEStream_B7681C49C5125395612F24D97559A4C2" ];

			// Clean up
			structDelete( variables, "tmp_initSSEStream_B7681C49C5125395612F24D97559A4C2" );
			structDelete( this, "tmp_initSSEStream_B7681C49C5125395612F24D97559A4C2" );
			public any function tmp_initSSEStream_B7681C49C5125395612F24D97559A4C2( 

			) output=true {
 
			var results                 = this._mockResults;
			var resultsKey           = "initSSEStream";
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
			arrayAppend( this._mockCallLoggers["initSSEStream"], arguments );

					if (resultsLen neq 0) {
						if (internalCounter gt resultsLen) {
							resultsCounter = internalCounter - ( resultsLen * fix( ( internalCounter - 1 ) / resultsLen ) );
							return results[ resultsKey ][ resultsCounter ];
						} else {
							return results[ resultsKey ][ internalCounter ];
						}
					}
					
					if ( callbackLen neq 0 ) {
						fCallBack = this._mockCallbacks[ resultsKey ].first();
						return fCallBack( argumentCollection : arguments );
					}
					
					if ( not isSimpleValue( fCallBack ) ){
						return fCallBack( argumentCollection : arguments );
					}
				}
</cfscript>