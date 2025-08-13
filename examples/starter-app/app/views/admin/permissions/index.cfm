<cfparam name="allpermissions">
<cfparam name="allroles">

<cfoutput>
 	#pageHeader("Permissions")#
 	#panel(title="Controller Role Permissions", class="mb-4")#
	<div class="alert alert-info">
	 <strong>Note:</strong> any changes here require will require a user to relogin to take effect
	</div>
	<div class="table-responsive">
		<table id="permissionstable" class="table table-striped table-sm table-hover">
			<thead>
			<tr>
				<th>Name</th>
				<cfloop query="allroles">
					<th>#name#</th>
				</cfloop>
				<th>&nbsp;</th>
			</tr>
			</thead>
			<cfloop query="allpermissions" group="type">
				<tbody>
					<tr><th colspan=#(2 + allroles.recordcount)#>#e(titleize(type))# Permissions</th></tr>
				<cfloop>
				<cfset qNameArr=listToArray(name, '.')>
				<cfset pName=name>
				<tr title="#description#">
					<td>
						<cfloop from="1" to="#arrayLen(qNameArr)#" index="i">
							<cfif i EQ arrayLen(qNameArr)>
								<strong>#qNameArr[i]#</strong>
							<cfelse>
								<span class="text-muted">#qNameArr[i]# <i class="fa fa-angle-double-right"></i> </span>
							</cfif>
						</cfloop>
					</td>
					<cfset roleArr=[]>
					<cfloop><cfset arrayAppend(roleArr, name)></cfloop>
					<cfloop query="allroles">
						<cfif structKeyExists(application.rolepermissions, name)>

							<cfscript>
								permissionDebug=hasPermission(permission=pname, debug=1,
								userPermissions=application.rolepermissions[name]);
								isInherited = (arrayLen(permissionDebug.passes) && !structKeyExists(permissionDebug.passes[1], pname) ) ? true: false;
							</cfscript>

						<td>
							<cfif isInherited>
								<!--- Inherited permission --->
								<i class="fa fa-check text-info" title="Inherited"></i>
							<cfelse>
								#tickOrCross(permissionDebug.rv)#
							</cfif>
						</td>
						<cfelse>
							<td><i class='fa fa-question text-warning'></i></td>
						</cfif>
					</cfloop>
					<td>#linkTo(route="editPermission", encode="attributes", key=id, text="<i class='fa fa-edit'></i> " & "Edit", class="btn btn-sm btn-primary float-end text-nowrap")#</td>
				</tr>
			</cfloop>
			</cfloop>
			</tbody>
		</table>
	</div>
 	#panelEnd()#
</cfoutput>
