<!--- User Index --->
<cfparam name="users">
<cfoutput>

#pageHeader(title="Users", btn=linkTo(route="newUser", text="<i class='fa fa-plus'></i> New", class="btn btn-primary btn-xs", encode="attributes"))#

#includePartial("filter")#

#panel(title="User Listings", class="mb-4")#

	<cfif users.recordcount>
		<div class="table-responsive">
			<table class="table table-sm">
				<thead>
					<tr>
						<th>Name</th>
						<th>Role</th>
						<th>Status</th>
						<th>Email</th>
						<th colspan=2>Created</th>
						<!--- CLI-Appends-thead-Here --->
					</tr>
				</thead>
				<tbody>
					<cfloop query="users">
					<cfscript>
					if (verified){
						badgeClass = "success";
						badgeText = "Active";
						rowClass = "";
					} else {
						badgeClass = "warning";
						badgeText = "Pending";
						rowClass = "";
					}
					if(len(deletedAt)){
						badgeClass = "danger";
						badgeText = "Disabled";
						rowClass = "";
					}
					</cfscript>
					<tr class="#rowClass#">
						<td>
							#e(firstname)# #e(lastname)#
						</td>
						<td>
							#e(name)#
						</td>
						<td>
							<span class="badge rounded-pill text-bg-#badgeClass#">#badgeText#</span>
						</td>
						<td>
							<a href="mailto:#e(email)#">#e(email)#</a>
						</td>
						<td class="text-nowrap">
							#formatDate(createdAt)#
						</td>
						<td class="float-end">
							<div class="btn-group gap-2 text-nowrap">
								<cfif len(deletedAt)>
									#buttonTo(route="recoverUser", method="patch", key=id, text="Recover",
				confirm="Are you sure you wish to recover this account?", inputClass="btn btn-sm btn-warning")#
									#buttonTo(route="destroyUser", method="delete", key=id, text="Delete",
				confirm="Are you sure you wish permanently delete this account?", inputClass="btn btn-sm btn-danger")#
								<cfelse>
									#linkTo(route="User", key=id, text="<i class='fa fa-eye'></i> View", class="btn btn-sm btn-info text-white", encode=false)#
									#linkTo(route="editUser", key = id, text="<i class='fa fa-edit'></i> Edit", class="btn btn-sm btn-primary", encode=false)#
								</cfif>
							</div>
						</td>
					</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
		#paginationLinks(route="users", params="status=#params.status#&roleid=#params.roleid#&q=#params.q#")#
	<cfelse>
		<div class="alert alert-info">
			<strong>Sorry</strong><br /> there are no Users to display
		</div>
	</cfif>

#panelEnd()#

</cfoutput>
