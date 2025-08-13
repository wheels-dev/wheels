<!--- User Show --->
<cfparam name="user">
<cfoutput>
#pageHeader(title=e(user.firstname) & ' ' & e(user.lastname),  btn=linkTo(route="users", text="<i class='fa fa-chevron-left'></i> Return", class="btn btn-info btn-xs text-white", encode="attributes"))#


#panel(title="User Details", class="my-5 my-sm-4")#
<div class="table-responsive">
	<table class="table table-sm">
	<tbody>
		<tr>
			<th>Gravatar</th>
			<td>#gravatar(user.email)#</td>
		</tr>
		<tr>
			<th>First Name</th>
			<td>#e(user.firstname)#</td>
		</tr>
		<tr>
			<th>Last Name</th>
			<td>#e(user.lastname)#</td>
		</tr>
		<tr>
			<th>Email</th>
			<td><a href="mailto:#e(user.email)#">#e(user.email)#</a></td>
		</tr>
		<tr>
			<th>Verified</th>
			<td>#yesNoFormat(user.verified)#</td>
		</tr>
		<tr>
			<th>Role</th>
			<td>#user.role.name#</td>
		</tr>
		<tr>
			<th>Last Logged In</th>
			<td>#formatDate(user.loggedInAt)#</td>
		</tr>
		<tr>
			<th>Requires Password Change on Login?</th>
			<td>#yesNoFormat(user.passwordchangerequired)#</td>
		</tr>
		<tr>
			<th>Password Last Updated</th>
			<td>#formatDate(user.passwordResetAt)#</td>
		</tr>
		<tr>
			<th>Created At</th>
			<td>#formatDate(user.createdAt)#</td>
		</tr>
		<tr>
			<th>Last Updated</th>
			<td>#formatDate(user.updatedAt)#</td>
		</tr>
 	</tbody>
 </table>
</div>
 <!--- This is an example of a named permission in action --->
 <cfif len(user.adminNotes) && hasPermission("canViewAdminNotes")>
 	<h6 class="mt-5">Administrative Notes</h6>
 	<hr />
	#e(user.adminNotes)#
 </cfif>
#panelEnd()#

<div class="card-group">
	<cfif hasPermission("admin.users.edit")>
	#card(header="Edit User",
			text="Update this user's main details, including their administative notes",
			class="bg-light mb-3",
			style="max-width: 18rem;",
			footer=linkTo(route="editUser", key=user.id, text="Edit Details", class="btn btn-info btn-xs text-white"),
			close=true)#
	</cfif>
	<cfif hasPermission("admin.userpermissions.show")>
	#card(header="Permissions",
			text="View this user's permissions and add account specific overrides.",
			class="bg-light mb-3",
			style="max-width: 18rem;",
			footer=linkTo(route='userPermissions', userkey=user.id, text='Edit Permissions', class="btn btn-info text-white"),
			close=true)#
	</cfif>

	<cfif hasPermission("admin.user.reset") && user.verified>
	#card(header="Reset Password",
			text="Send a new password to this user via Email; they will be forced to change it when they login",
			class="bg-light mb-3",
			style="max-width: 18rem;",
			footer=buttonTo(route="resetUser", method="put", key=user.id, text="Reset Password", confirm="Are you sure you wish to reset this user's password?", inputClass="btn btn-warning btn-xs"),
			close=true)#
	</cfif>
</div>
<div class="card-group">
	<cfif hasPermission("admin.users.assume") && user.verified>
	#card(header="Assume User",
			text="Assume this user account so you can test this user's permissions and access. Note, you will need to logout/in again to resume your old session",
			class="bg-light mb-3",
			style="max-width: 18rem;",
			footer=buttonTo(route="assumeUser", method="post", key=user.id, text="Assume", inputClass="btn btn-warning btn-xs"),
			close=true)#
	</cfif>
	<cfif hasPermission("admin.users.delete")>
	#card(header="Disable User",
			text="Disable this user via the Soft Delete system. The account is recoverable.",
			class="bg-light mb-3",
			style="max-width: 18rem;",
			footer=buttonTo(route="User", method="delete", key=user.id, text="Disable", confirm="Are you sure you wish to disable this account?", inputClass="btn btn-danger btn-xs"),
			close=true)#
	</cfif>
</div>



<!--- CLI-Appends-Here --->
</cfoutput>
