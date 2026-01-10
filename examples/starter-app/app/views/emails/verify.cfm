<cfoutput>
#includePartial("/emails/header")#

<h1 style="Margin-top: 0;color: ##565656;font-weight: 700;font-size: 36px;Margin-bottom: 18px;font-family: sans-serif;line-height: 42px">Account Verification</h1>

<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Hi #user.firstname#,
<br><br>Thank you for taking the time to create an account.
<br><br>In order to complete your registration, we need to verify your email address. Please use the link below to verify your account:
<br><br>#linkto(route="verify", onlyPath=false, token=user.verificationToken)#</p>

#includePartial("/emails/footer")#
</cfoutput>
