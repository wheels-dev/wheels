<cfparam name="roles">
<cfoutput>
 	#pageHeader(title="Roles",  btn=linkTo(route="newRole", text="<i class='fa fa-plus'></i> New", class="btn btn-primary btn-xs", encode="attributes"))#
 	#panel(title="Available Application Roles", class="mb-4")#
 	<div class="alert alert-info">
	 <strong>Note:</strong> any changes here require a restart of the application to take effect
	</div>
	<cfif roles.recordcount>
		<div class="table-responsive">
			<table class="table table-sm">
				<thead>
					<tr>
						<th>Name</th>
						<th colspan=2>Description</th>
						<!--- CLI-Appends-thead-Here --->
					</tr>
				</thead>
				<tbody>
					<cfloop query="roles">
					<tr>
						<td>
							#e(name)#
						</td>
						<td>
							<span class="text-muted">#e(description)#</span>
						</td>
						<!--- CLI-Appends-tbody-Here --->
						<td class="float-end">
							#linkTo(route="editrole", key=id, text="<i class='fa fa-edit'></i> Edit", class="btn btn-sm btn-primary text-nowrap", encode=false)#
						</td>
					</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	<cfelse>
		<div class="alert alert-info">
			<strong>Sorry</strong><br /> there are no Roles to display
		</div>
	</cfif>
 	#panelEnd()#
</cfoutput>
