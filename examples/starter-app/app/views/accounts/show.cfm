<!---
	"My Account" Display
--->
<cfparam name="user">
<cfoutput>
#pageHeader(title="My Account", btn=linkTo(route='logout', class='btn btn-outline-danger', text='logout'))#

#panel(title="Your Account Details", class="mb-4",
	btn="<div class='btn-group gap-2'>"
	& linkTo(route="accountPassword", text="Change Password", class="btn btn-warning btn-sm text-white")
	& linkTo(route="editAccount", text="Edit Details", class="btn btn-info btn-sm text-white")
	& "</div>")#

<div class="row">
	<div class="col-sm-4">
		<div class="my-4">#gravatar(email=user.email, size=160)#</div>
	</div>
	<div class="col-sm-8">
		  
	<h5>First Name</h5>
	<p>#e(user.firstname)#</p>

	<h5>Last Name</h5>
	<p>#e(user.lastname)#</p>

	<h5>Email</h5>
	<p><a href="mailto:#e(user.email)#">#e(user.email)#</a></p>

	<h5>Last Logged In</h5>
	<p>#formatdate(user.loggedInAt)#</p>

	<h5>Password Last Updated</h5>
	<p><cfif isDate(user.passwordResetAt)>#timeAgoInWords(user.passwordResetAt)# ago<cfelse>Never</cfif></p> 

	</div>
</div>

#panelEnd()#
</cfoutput>
