<!--- Email template for Send Email --->
<cfoutput>

<h2>Send Email</h2>

<p>Hello,</p>

<p>
	This is the email template for the sendEmail action.
	Customize this template with your email content.
</p>

<!--- Access passed data --->
<cfif structKeyExists(variables, "data")>
	<!--- Use data passed from the mailer method --->
</cfif>

<p>Best regards,<br>Your Team</p>

</cfoutput>