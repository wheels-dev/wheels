<!---
	New User Registration Form
--->
<cfoutput>
#pageHeader(title="Create Account", btn=linkTo(route="login", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#


#errorMessagesFor("user")#

#startFormTag(id="registrationForm", route="register")#

	<div class="row">
		<div class="col-md-6 offset-md-3">

			#panel(title="Your Details", class="mb-4")#
				<div class="row">
					<div class="col-12 col-sm">
						#textField(objectName="user", property="firstname", label="First Name")#
					</div>
					<div class="col-12 col-sm">
						#textField(objectName="user", property="lastname", label="Last Name")#
					</div>
				</div>

				#textField(objectName="user", property="email", label="Email Address")#
				#passwordField(objectName="user", property="password", label="Password")#
				#passwordField(objectName="user", property="passwordConfirmation", label="Confirm Password")#

				#checkBox(objectName="user", property="terms", label="I agree to the terms and conditions")#

				#submitTag(value="Create Account", class="mt-4 btn btn-success")#

				#panelEnd()#
		</div>
	</div>

#endFormTag()#

</cfoutput>
