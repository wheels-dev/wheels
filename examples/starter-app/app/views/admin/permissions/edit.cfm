<cfoutput>
#pageHeader(title="Edit Permission", btn=linkTo(route="permissions", text="<i class='fa fa-chevron-left'></i> Cancel and return", class="btn btn-info btn-xs text-white", encode="attributes"))#

	#startFormTag(route="permission", key=permission.key(), method="put")#
		#includePartial("form")#
		#submitTag()#
	#endFormTag()#
</cfoutput>
