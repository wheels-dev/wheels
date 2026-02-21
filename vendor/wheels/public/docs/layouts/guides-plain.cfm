<cfparam name="docs">
<cfoutput>
<cfif request.wheels.params.format EQ "json">
	<cfcontent type="application/json">
	<cfset response = {
		"title" = docs.title,
		"path" = docs.path,
		"content" = docs.content,
		"navigation" = docs.navigation
	}>
	#serializeJSON(response)#
<cfelse>
	<cfcontent type="text/plain">
	#docs.title#
	#repeatString("=", len(docs.title))#
	
	#docs.content#
</cfif>
</cfoutput>