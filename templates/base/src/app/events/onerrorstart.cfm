<cfif structKeyExists(request.wheels, "exception")>
	<cflog
		file="wheels-errors"
		type="error"
		text="#request.wheels.exception.message#
#request.wheels.exception.detail#"
	>
</cfif>
