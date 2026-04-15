<cfparam name="flashError" default="">
<cfoutput>
<h1>Log in</h1>
<cfif len(flashError)>
    <div class="error">#flashError#</div>
</cfif>
<form method="post" action="#urlFor(route='authenticate')#">
    <input type="email" name="email" id="email">
    <input type="password" name="password" id="password">
    <button type="submit">Sign in</button>
</form>
</cfoutput>
