<cfif IsDefined("request.partialTests.currentTotal")>
	<cfset request.partialTests.currentTotal = request.partialTests.currentTotal + arguments.current>
	<cfif StructKeyExists(arguments, "current") AND arguments.current IS 3>
		<cfset request.partialTests.thirdUserName = arguments.firstName>
	</cfif>
</cfif>

<cfif NOT StructKeyExists(arguments, "current") AND StructKeyExists(arguments, "user") AND IsObject(arguments.user) AND arguments.user.firstName IS "Chris" AND arguments.firstName IS "Chris">
	<cfset request.wheelsTests.objectTestsPassed = true>
	<cfoutput>#arguments.firstName#</cfoutput>
</cfif>