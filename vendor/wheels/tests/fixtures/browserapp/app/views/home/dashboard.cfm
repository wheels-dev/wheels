<cfparam name="user" default="#{}#">
<cfoutput>
<h1>Dashboard</h1>
<p>Welcome, #encodeForHTML(user.email)#</p>
<form method="post" action="#urlFor(route='logout')#">
    <button type="submit">Log out</button>
</form>
</cfoutput>
