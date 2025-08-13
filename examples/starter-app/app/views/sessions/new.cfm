<!---
	Login Form:
	Only displays password reset link | rememberMe if authentication model allows it
	Runs through the validation on the tableless model in /models/Auth/Local.cfc
	You can change authentication methods via the app settings and build new Auth models to select
--->
<cfparam name="auth">
<cfparam name="usingRememberMeCookie">
<cfparam name="savedEmail">
<cfoutput>
<div class="row">
	<div class="col-md-6 offset-md-3">
	#panel(title="Login")#
		#startFormTag(route="authenticate")#
		#errorMessagesFor("auth")#

		<cfif auth.allowRememberMe && usingRememberMeCookie>
			
			<div class="my-3">#gravatar(savedEmail)#</div>

			<p>Welcome back <strong>#savedEmail#</strong>. (#linkTo(text="Not You?", route="forgetme")#)</p>
			#hiddenField(objectname="auth", property="email", value=savedEmail)#
		<cfelse>
			#textField(objectname="auth", property="email", label="Email Address")#
		</cfif>

		#passwordField(objectname="auth", property="password", label="Password")#

	  	<cfif auth.allowRememberMe && !usingRememberMeCookie>
	  	 	#checkbox(objectname="auth", property="rememberme", label="Remember Me")#
	  	</cfif>

		<div class="d-grid">
			#submitTag(value="Login", class="btn btn-primary mt-2")#
		</div>

		<cfif getSetting("authentication_allowRegistration") OR getSetting("authentication_allowPasswordResets")>
			<hr />
		</cfif>
		<cfif auth.allowUserRegistration && getSetting("authentication_allowRegistration")>
			<p class="float-start">#linkTo(route="register", text="Register")#</p>
		</cfif>
		<cfif auth.allowPasswordReset && getSetting("authentication_allowPasswordResets")>
			<p class="float-end">#linkTo(route="Passwordreset", text="I forgot my password")#</p>
		</cfif>

		#endFormTag()#
	#panelEnd()#
	</div>
</div>
</cfoutput>
