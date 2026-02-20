<cfsilent>
	<!--- Place JSON error response here that should be displayed when an error is encountered while running in "production" mode. --->
	
	<cfset local.errorResponse = {
		"error": true,
		"message": "Internal Server Error",
		"statusCode": 500,
		"timestamp": DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm:ss") & "Z"
	} />
</cfsilent><cfoutput>#SerializeJSON(local.errorResponse)#</cfoutput>