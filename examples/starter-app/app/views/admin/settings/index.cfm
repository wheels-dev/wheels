

<cfparam name="settings">
<cfparam name="settingCategories">
<cfoutput>
#pageHeader("Settings")#

#panel(title="Your Setup:", class="mb-4")#

<div class="alert alert-info">
	 <strong>Note:</strong> any changes here require a restart of the application to take effect
	</div>

	<div class="row">
		<div class="col">
			CFML engine: <code>#application.wheels.servername# #application.wheels.serverversion#</code>
		</div>
		<div class="col">
			DB Version: <code>#application.wheels.migrator.getCurrentMigrationVersion()#</code>
		</div>
	</div>

<cfloop from="1" to="#arraylen(settingCategories)#" index="i">

<h4 class="my-4 fw-light">#titleize(settingCategories[i])#</h4>
<div class="table-responsive">
	<table id="settingstable#i#" class="table table-bordered table-striped table-sm">
		<thead>
		<tr>
			<th width=15%>Setting</th>
			<th width=35%>Description</th>
			<th width=25% class="text-nowrap">Current Value</th>
			<th width=5%>Actions</th>
		</tr>
		</thead>
		<tbody>
		<cfloop query="settings">
		<cfif listFirst(name, "_") EQ settingCategories[i]>
			<tr>
				<td>#titleize(listLast(name, "_"))#</td>
				<td><cfif len(docs)>#linkTo(href=docs, text=description, target="_blank")#<cfelse>#description#</cfif></td>
				<td><cfif editable><cfif type EQ 'boolean'>#tickorcross(deserializeJSON(value))#<cfelse><code>#deserializeJSON(value)#</code></cfif><cfelse><code>[hidden]</code></cfif></td>
				<td><cfif editable>#linkTo(route="editSetting", encode="attributes", key=id, text="<i class='fa fa-edit'></i> " & "Edit", class="btn btn-sm btn-primary text-nowrap")#</cfif></td>
			</tr>
		</cfif>

		</cfloop>
		</tbody>
	</table>
</div>
</cfloop>
#panelEnd()#

</cfoutput>
