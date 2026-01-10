<!--- Place HTML here that should be used as the default layout of your application. --->
<!--- This condition prevents the content to be wrapped in HTML for the Junit, TXT and JSON formats when they are passed in the URL as "format=json","format=txt" and "format=junit" as these formats shouldn't have html wrapped around them --->
<cfif application.contentOnly>
	<cfoutput>
		#flashMessages()#
		#includeContent()#
	</cfoutput>
<cfelse>
	<html>
		<head>
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
