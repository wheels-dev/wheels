<!---
	Request a Password Reset Form
--->
<cfoutput>
<div class="row">
  <div class="col-md-6 offset-md-3">
    #panel(title="Reset Password")#
    #startFormTag(route="Passwordreset")#
    #textFieldTag(name="email", label="Email")#
    <div class="d-grid">
      #submitTag(value="Send Password Reset Email", class="btn btn-block btn-primary")#
    </div>
    #endFormTag()#
    <p class="mt-2">#linkTo(route="root", text="Cancel")#</p>
  </div>
</div>
</cfoutput>
