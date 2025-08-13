<!--- User Creation Form --->
<cfparam name="user">
<cfoutput>
#pageHeader(title="Create New User",  btn=linkTo(route="users", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#
#errorMessagesFor("user")#
#startFormTag(id="userNewForm", route="Users")#
	#includePartial("form/details")#
	#includePartial("form/role")#
	#includePartial("form/auth")#
	#submitTag(value="Create User", class="mt-4 btn btn-success")#
#endFormTag()#
</cfoutput>
