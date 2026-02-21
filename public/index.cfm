<cfsilent>
<!---
	Uses the Dispatch object, which has been created on app start, to render content.
--->
</cfsilent><cfoutput>#application.wheels.dispatch.$request()#</cfoutput>
