<!---
	"My Account" Password Reset Form
	Also used for when a user has a password block and needs to reset their password
--->
<cfparam name="user">
<cfoutput>
<cfif hasPasswordResetBlock()>
	#pageHeader(title="Password Update Required")#
<cfelse>
	#pageHeader(title="Update Password", btn=linkTo(route="account", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#
</cfif>

#panel(title="Update Your Password", class="mb-4")#

#errorMessagesFor("user")#
#startFormTag(id="accountUpdateForm", route="accountPassword", method="put")#

	<div class="row mb-3">
		<div class="col-12 col-sm">
			#passwordField(objectName="user", property="oldpassword", label="Old Password")#
			<small id="passwordHelpBlock" class="form-text text-muted">Please enter your old password</small>
		</div>
	</div>
	<div class="row">
		<div class="col-12 col-sm">
			#passwordField(objectName="user", property="password", label="New Password")#<small id="passwordHelpBlock" class="form-text text-muted">Your new password</small>
		</div>

		<div class="col-12 col-sm">
			#passwordField(objectName="user", property="passwordConfirmation", label="Confirm New Password")#<small id="passwordHelpBlock" class="form-text text-muted">Retype your new password</small>
		</div>
	</div>

	#submitTag(value="Update Your Password", class="mt-4 btn btn-success")#
#endFormTag()#


#panelEnd()#
</cfoutput>
