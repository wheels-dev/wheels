<cfscript>
			variables[ "$requireRunningServer" ] = variables[ "tmp_$requireRunningServer_F952D54F1096E25C030C8E3149ABD8C4" ];
			this[ "$requireRunningServer" ]           = variables[ "tmp_$requireRunningServer_F952D54F1096E25C030C8E3149ABD8C4" ];

			// Clean up
			structDelete( variables, "tmp_$requireRunningServer_F952D54F1096E25C030C8E3149ABD8C4" );
			structDelete( this, "tmp_$requireRunningServer_F952D54F1096E25C030C8E3149ABD8C4" );
			private numeric function tmp_$requireRunningServer_F952D54F1096E25C030C8E3149ABD8C4( 

			) output=true {
 
			var results                 = this._mockResults;
			var resultsKey           = "$requireRunningServer";
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
			arrayAppend( this._mockCallLoggers["$requireRunningServer"], arguments );

				throw(
					"spec capture — abort before HTTP",
					"TestAbort.ServerGuard",
					"",
					""
				);

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