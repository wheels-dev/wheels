<!--- ${modelName} Edit Form --->
<cfparam name="${itemVar}">
<cfoutput>
<h1>Edit ${modelName}</h1>
#errorMessagesFor("${itemVar}")#
#startFormTag(id="${itemVarLower}EditForm", route="${modelName}", method="patch", key=params.key)#
	#includePartial("form")#
	#submitTag(value="Update ${modelName}")#
#endFormTag()#
</cfoutput>