<cfif StructKeyExists(arguments, "customQuery")>
	<cfoutput>#arguments.customQuery['firstName'][3]#</cfoutput>
<cfelse>
	<cfinclude template="_user.cfm">
	<cfif StructKeyExists(arguments, "query")>
		<cfset request.partialTests.noQueryArg = false>
	</cfif>
	<cfif StructKeyExists(arguments, "objects")>
		<cfset request.partialTests.noObjectsArg = false>
	</cfif>
	<cfif arguments.current IS 3 AND StructKeyExists(arguments, "user") AND IsObject(arguments.user) AND arguments.user.firstName IS "Per">
		<cfset request.partialTests.thirdObjectExists = true>
	</cfif>
</cfif>