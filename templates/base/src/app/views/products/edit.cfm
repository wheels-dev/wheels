<!--- Product Edit Form --->
<cfparam name="product">
<cfoutput>
<h1>Edit Product</h1>
#errorMessagesFor("product")#
#startFormTag(id="productEditForm", route="Product", method="patch", key=params.key)#
	#includePartial("form")#
	#submitTag(value="Update Product")#
#endFormTag()#
</cfoutput>
