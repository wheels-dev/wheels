<cfscript>
			variables[ "sendSSEEvent" ] = variables[ "tmp_sendSSEEvent_754BEF48E30B63BC11E518FA73C07785" ];
			this[ "sendSSEEvent" ]           = variables[ "tmp_sendSSEEvent_754BEF48E30B63BC11E518FA73C07785" ];

			// Clean up
			structDelete( variables, "tmp_sendSSEEvent_754BEF48E30B63BC11E518FA73C07785" );
			structDelete( this, "tmp_sendSSEEvent_754BEF48E30B63BC11E518FA73C07785" );
			public void function tmp_sendSSEEvent_754BEF48E30B63BC11E518FA73C07785( 

			) output=true {
 
			var results                 = this._mockResults;
			var resultsKey           = "sendSSEEvent";
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
			arrayAppend( this._mockCallLoggers["sendSSEEvent"], arguments );
}
</cfscript>