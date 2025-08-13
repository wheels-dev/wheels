<!--- User Edit Form --->
<cfparam name="role">
<cfoutput>
#pageHeader(title="Edit Role", btn=linkTo(route="roles", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#


#errorMessagesFor("role")#
#startFormTag(id="roleEditForm", route="role", method="patch", key=params.key)#
	#includePartial("form")#
	#submitTag(value="Update Role", class="mt-4 btn btn-success")#
#endFormTag()#
</cfoutput>
