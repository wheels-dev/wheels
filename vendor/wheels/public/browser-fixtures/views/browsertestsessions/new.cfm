<cfparam name="flashError" default="">
<cfoutput>
	<h1>Log in</h1>
	<cfif Len(flashError)>
		<div class="error" id="error-message">#flashError#</div>
	</cfif>
	<form method="post" action="#urlFor(route = 'browserTestAuthenticate')#">
		<label for="email">Email</label>
		<input type="email" name="email" id="email">
		<label for="password">Password</label>
		<input type="password" name="password" id="password">
		<button type="submit">Sign in</button>
	</form>
</cfoutput>
