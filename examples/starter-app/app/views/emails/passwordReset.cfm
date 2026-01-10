<cfparam name="user">
<cfoutput>
#includePartial("/emails/header")#

<h1 style="Margin-top: 0;color: ##565656;font-weight: 700;font-size: 36px;Margin-bottom: 18px;font-family: sans-serif;line-height: 42px">Password Reset</h1>

<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Hi #user.firstname#,
<br><br>We've received a request to reset your password. Click the link below to reset your password:
<br><br>#linkto(route="editPasswordreset", onlyPath=false, token=user.passwordResetToken)#
<br><br><br>If you did not request a password reset, please ignore this message. Your password will remain the same.</p>

#includePartial("/emails/footer")#

</cfoutput>
