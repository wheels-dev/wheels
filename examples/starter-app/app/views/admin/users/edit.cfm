<!--- User Edit Form --->
<cfparam name="user">
<cfoutput>
#pageHeader(title="Edit User", btn=linkTo(route="users", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#


#errorMessagesFor("user")#
#startFormTag(id="userEditForm", route="User", method="patch", key=params.key)#
	#includePartial("form/details")#
	#includePartial("form/role")#
	#submitTag(value="Update User", class="mt-4 btn btn-success")#
#endFormTag()#
</cfoutput>
