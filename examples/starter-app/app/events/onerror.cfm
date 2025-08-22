<!--- Place HTML here that should be displayed when an error is encountered while running in "production" mode. --->
<cfswitch expression="#arguments.exception.cause.type#">
	<cfcase value="app.AccessDenied">
		<cfheader statuscode="403" statustext="Access Denied">
		<h1>Denied!</h1>
		<p>
			Sorry, but you're not allowed to access that.
		</p>
	</cfcase>
	<cfdefaultcase>
		<cfheader statuscode="500">
		<h1>Error!</h1>
		<p>
			Sorry, that caused an unexpected error.<br>
			Please try again later.
		</p>
	</cfdefaultcase>
</cfswitch>