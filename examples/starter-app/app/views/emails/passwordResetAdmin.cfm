<cfparam name="user">
<cfparam name="tempPassword">
<cfoutput>
#includePartial("/emails/header")#

<h1 style="Margin-top: 0;color: ##565656;font-weight: 700;font-size: 36px;Margin-bottom: 18px;font-family: sans-serif;line-height: 42px">Your New Temporary Password</h1>

<p style="Margin-top: 0;color: ##565656;font-family: sans-serif;font-size: 16px;line-height: 25px;Margin-bottom: 24px">Hi #user.firstname#,
<br><br>An administrator has reset your password to:
<br><br>#tempPassword#
<br><br><br>You will be required to change this password on your next login.</p>

#includePartial("/emails/footer")#

</cfoutput>
