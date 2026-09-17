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
			<!--- Default styling: simple.css (https://simplecss.org/) plus
			      wheels.css (stacked form fields + red validation errors).
			      Both live in public/stylesheets/ so the app renders polished
			      offline. simple.css is classless; wheels.css only adds form
			      layout and error styles. Delete these lines (and the files)
			      to bring your own CSS, or swap for a richer kit — e.g.
			      `wheels packages add wheels-basecoat`. --->
			<cfoutput>#styleSheetLinkTag(sources="simple,wheels")#</cfoutput>
		</head>

		<body>
			<cfoutput>
				#flashMessages()#
				#includeContent()#
			</cfoutput>
		</body>
	</html>
</cfif>
