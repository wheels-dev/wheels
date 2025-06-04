<!--- Product Form Contents --->
<cfoutput>
#textField(objectName="product", property="name", label="Name")#
#textArea(objectName="product", property="description", label="Description")#
#textField(objectName="product", property="price", label="Price")#
#textField(objectName="product", property="stock", label="Stock")#
#checkBox(objectName="product", property="active", label="Active")#
<!--- CLI-Appends-Here --->
</cfoutput>