<!--- Product Creation Form --->
<cfparam name="product">
<cfoutput>
<h1>Create New Product</h1>
#errorMessagesFor("product")#
#startFormTag(id="productNewForm", action="create")#
	#includePartial("form")#
	#submitTag(value="Create Product")#
#endFormTag()#
</cfoutput>
