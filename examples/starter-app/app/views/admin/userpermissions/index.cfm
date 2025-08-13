<cfparam name="permissions">
<cfoutput>
#pageHeader(title="User Permissions", btn=linkTo(route="user", key=params.userkey, text="<i class='fa fa-chevron-left'></i> Return", class="btn btn-info text-white", encode="attributes"))#

#panel(title="Controller Permissions for #e(user.firstname)# #e(user.lastname)# (#user.role.name#)", class="mb-4")#
<div class="table-responsive">
	<table id="permissionstable" class="table  table-striped table-sm table-hover">
		<thead>
		<tr>
			<th>Name</th>
			<th>Set By</th>
			<th>Access</th>
			<th>&nbsp;</th>
		</tr>
		</thead>
		<tbody>
		<cfloop query="allpermissions" group="type">
				<tr><th colspan=4>#e(titleize(type))# Permissions</th></tr>
			<cfloop>
			<cfscript>
				qNameArr=listToArray(name, '.');
				pName=name;

				permissionDebug=hasPermission(permission=pname, debug=1, userPermissions=permissions);

				// Some helper vars
				userHasPermission 	= permissionDebug.rv;
				isInherited 		= (arrayLen(permissionDebug.passes) && !structKeyExists(permissionDebug.passes[1], pname) ) ? true: false;
				setby 				= userHasPermission && structKeyExists(permissions, pName) ? permissions[pName]["setby"] : "";
				if(isInherited){
					setby = "Inherited";
				}
			</cfscript>
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
				<td>#setby#</td>
				<td>
					<cfif isInherited>
						<i class="fa fa-check text-info" title="Inherited"></i>
					<cfelse>
						#tickOrCross(userHasPermission)#
					</cfif>
				</td>
				<td>
					<cfif !userHasPermission>
						#startFormTag(route="userpermissions", userKey=params.userkey)#
							#hiddenFieldTag(name= "permissionid", value = id)#
							#submitTag(value="Grant", class="btn btn-sm btn-warning")#
						#endFormTag()#
					</cfif>
					<cfif setby EQ 'User'>
						#buttonTo(route="userPermission", text="Revoke", inputClass="btn btn-sm btn-danger", userKey=params.userkey, key=id, method="delete")#
					</cfif>
				</td>

			</tr>
		</cfloop>
		</cfloop>
		</tbody>
	</table>
</div>
#panelEnd()#

</cfoutput>
