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
			<!--- Default styling: simple.css (https://simplecss.org/), bundled in
			      public/stylesheets/simple.css so the app renders polished offline.
			      It is a classless stylesheet — it styles plain semantic HTML without
			      any markup changes, so scaffolded views look good out of the box and
			      removing it needs no markup cleanup. Delete this line (and the file)
			      to bring your own CSS, or swap for a richer kit — e.g.
			      `wheels packages add wheels-basecoat`. --->
			<cfoutput>#styleSheetLinkTag(sources="simple")#</cfoutput>
		</head>

		<body>
			<cfoutput>
				#flashMessages()#
				#includeContent()#
			</cfoutput>
		</body>
	</html>
</cfif>
