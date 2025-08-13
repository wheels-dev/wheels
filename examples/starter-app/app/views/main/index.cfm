<cfoutput>
<div class="row justify-content-center mt-5">
  <div class="col-md-8 col-lg-6">
    #card(
      header="Welcome",
      class="shadow-sm mb-4",
      text="This is an example App using Wheels 3.x and some Bootstrap",
      close=false
    )#
    <div class="text-center my-4">
      <cfif !isAuthenticated()>
        #linkTo(route="login", text="Login", class="btn btn-primary btn-lg px-4")#
      <cfelse>
        <div class="mb-3">
          #gravatar(getSession().user.properties.email, 80, "pg", "rounded-circle mb-2 shadow-sm")#
        </div>
        <p class="lead mb-2">Cool beans bro.</p>
        <cfif hasPermission("accounts.show")>
          <p>#linkTo(route="account", text="Go to your Account", class="btn btn-outline-success btn-lg px-4")#</p>
        </cfif>
	</cfif>
    </div>
    #cardEnd()#
  </div>
</div>
</cfoutput>