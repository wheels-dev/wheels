<!---
	"My Account" Edit Form
--->
<cfparam name="user">
<cfoutput>
#pageHeader(title="Edit Account", btn=linkTo(route="account", text="<i class='fa fa-chevron-left'></i> Cancel", class="btn btn-info btn-xs text-white", encode="attributes"))#

#panel(title="Your Account Details", class="mb-4")#

#errorMessagesFor("user")#
#startFormTag(id="accountUpdateForm", route="account", method="patch")#

	<div class="row">
		<div class="col-12 col-sm">
			#textField(objectName="user", property="firstname", label="First Name")#
		</div>
		<div class="col-12 col-sm">
			#textField(objectName="user", property="lastname", label="Last Name")#
		</div>
	</div>
	<div class="row">
		<div class="col-12 col-sm">
			#textField(objectName="user", property="email", label="Email Address")#
			<small id="passwordHelpBlock" class="form-text text-muted">Your email address: used both as your login and also the source of your #linkTo(href="https://en.gravatar.com/", target="_blank", text="profile picture", title="Go to Gravatar")#.</small>
		</div>
	</div>

	#submitTag(value="Update Your Details", class="mt-4 btn btn-success")#
#endFormTag()#



#panelEnd()#
</cfoutput>
