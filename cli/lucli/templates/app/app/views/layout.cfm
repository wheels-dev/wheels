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
			<!--- Default styling: simple.css (https://simplecss.org/) — a classless
			      stylesheet that gives plain semantic HTML a clean, modern look without
			      any markup changes. Form helpers like #textField()# already emit the
			      right tags, so scaffolded views render polished out of the box.
			      Remove this line if you're bringing your own CSS, or swap for a richer
			      component kit — e.g. `wheels packages install wheels-basecoat`. --->
			<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
		</head>

		<body>
			<cfoutput>
				#flashMessages()#
				#includeContent()#
			</cfoutput>
		</body>
	</html>
</cfif>
