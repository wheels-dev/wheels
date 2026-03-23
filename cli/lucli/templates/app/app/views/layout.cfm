<!--- Place HTML here that should be used as the default layout of your application. --->
<cfif application.contentOnly>
	<cfoutput>
		#flashMessages()#
		#includeContent()#
	</cfoutput>
<cfelse>
	<!DOCTYPE html>
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<title>{{appName}}</title>
			<cfoutput>#csrfMetaTags()#</cfoutput>
		</head>

		<body>
			<cfoutput>
				#flashMessages()#
				#includeContent()#
			</cfoutput>
		</body>
	</html>
</cfif>
