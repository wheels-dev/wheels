<!---
	Password Reset Form
--->
<cfparam name="user">
<cfoutput>
<div class="row">
  <div class="col-md-6 offset-md-3">
  	#errorMessagesFor("user")#
	#panel(title="Reset Password")#
		#startFormTag(route="updatePasswordreset", method="put", token=params.token)#
	      #passwordField(objectname="user", property="password", label="Password *", required="true")#
	      #passwordField(objectname="user", property="passwordConfirmation", label="Confirm Password *", required="true")#
			#submitTag(value="Update Password", class="btn btn-block btn-primary")#
		#endFormTag()#
	#panelEnd()#
	</div>
</div>
</cfoutput>
