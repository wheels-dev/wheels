<cfparam name="params" default="#{}#">
<cfoutput>
	<p id="login-status">Logged in as #EncodeForHTML(params.identifier ?: "unknown")#</p>
</cfoutput>
