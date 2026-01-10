<cfoutput>
#panel(title="Update Value for #e(permission.name)#", class="my-5 my-sm-4")#
	<div class="row">
		<div class="col-md-4">
			<p class="text-muted">#e(permission.description)#</p>
		</div>
		<div class="col-md-4">
			<cfloop query="roles">
				#hasManyCheckBox(objectName="permission", association="rolepermissions", keys="#id#,#permission.key()#", label=name)#
			</cfloop>
		</div>
	</div>
#panelEnd()#
</cfoutput>
