<cfoutput>
#pageHeader(title="Edit Setting", btn=linkTo(route="settings", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#

	#startFormTag(route="setting", key=setting.key(), method="put")#
		#includePartial("form")#
		#submitTag()#
	#endFormTag()#
</cfoutput>
