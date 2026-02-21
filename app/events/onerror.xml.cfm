<cfsilent>
	<!--- Place XML error response here that should be displayed when an error is encountered while running in "production" mode. --->
	
	<cfset local.timestamp = DateFormat(Now(), "yyyy-mm-dd") & "T" & TimeFormat(Now(), "HH:mm:ss") & "Z" />
</cfsilent><cfoutput><?xml version="1.0" encoding="UTF-8"?>
<error>
	<message>Internal Server Error</message>
	<statusCode>500</statusCode>
	<timestamp>#local.timestamp#</timestamp>
</error></cfoutput>