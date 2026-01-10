<cfparam name="user">
<cfoutput>
Password Reset

Hi #user.firstname#,

We've received a request to reset your password. Visit the link below to reset your password:

#urlFor(route="editPasswordreset", onlyPath=false, token=user.passwordResetToken)#

If you did not request a password reset, please ignore this message. Your password will remain the same.
</cfoutput>
