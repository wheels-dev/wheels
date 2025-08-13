<cfoutput>
Account Verification

Hi #user.firstname#,
Thank you for taking the time to create an account.
In order to complete your registration, we need to verify your email address. Please use the link below to verify your account:
#linkto(route="verify", onlyPath=false, token=user.verificationToken)#
</cfoutput>
