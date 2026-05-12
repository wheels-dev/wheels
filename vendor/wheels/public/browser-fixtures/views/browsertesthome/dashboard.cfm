<cfparam name="user" default="#{}#">
<cfoutput>
	<h1>Dashboard</h1>
	<p>
		Welcome, <span id="user-email">#EncodeForHTML(user.email)#</span>
	</p>
	<form method="post" action="#urlFor(route = 'browserTestLogout')#">
		<button type="submit">Log out</button>
	</form>
</cfoutput>
