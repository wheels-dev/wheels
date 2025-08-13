<!--- role Creation Form --->
<cfparam name="role">
<cfoutput>
#pageHeader(title="Create New Role",  btn=linkTo(route="roles", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#
#errorMessagesFor("role")#
#startFormTag(id="roleNewForm", route="roles")#
	#includePartial("form")#
	#submitTag(value="Create role", class="mt-4 btn btn-success")#
#endFormTag()#
</cfoutput>
