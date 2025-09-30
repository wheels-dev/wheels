<!--- ${modelName} Creation Form --->
<cfparam name="${itemVar}">
<cfoutput>
<h1>Create New ${modelName}</h1>
#errorMessagesFor("${itemVar}")#
#startFormTag(id="${itemVarLower}NewForm", action="create")#
	#includePartial("form")#
	#submitTag(value="Create ${modelName}")#
#endFormTag()#
</cfoutput>