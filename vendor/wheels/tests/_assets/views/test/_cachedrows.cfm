<cfparam name="rows" default=""><cfparam name="request.cachedRowsRenders" default="0"><cfset request.cachedRowsRenders++><cfoutput><cfloop query="rows">#rows.id#:#rows.name#|</cfloop></cfoutput>
