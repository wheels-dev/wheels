<cfparam name="params" default="#{}#">
<cfoutput>
<p id="login-status">Logged in as #encodeForHTML(params.identifier ?: "unknown")#</p>
</cfoutput>
