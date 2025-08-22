<cfoutput>
	<!DOCTYPE html>
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta http-equiv="X-UA-Compatible" content="IE=edge">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
			<cfoutput>#csrfMetaTags()#</cfoutput>
			<title>#e(getSetting('general_sitename'))#</title>
			<meta name="keywords" content="cfwheels,cfml,ruby,framework">
			<meta name="description" content="This is an example wheels Application">
			<!---
				CSS
				Include Bootstrap 5 and Font Awesome
				Yes, I could technically put these all in a stylesheetLinkTag, but I think this is slightly more readable
				Also include custom.css from /stylesheets/
			--->
			#stylesheetLinkTag("custom")#
			#stylesheetLinkTag("bootstrap.min")#
			#stylesheetLinkTag("fontawesome.min")#
			#stylesheetLinkTag("daterangepicker")#

			<!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
			<!--[if lt IE 9]>
			<script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
			<script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
			<![endif]-->
			<link rel="shortcut icon" href="/images/favicon.ico">
		</head>
		<body>
			<!--[if lt IE 8]>
				<p class="browserupgrade">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
			<![endif]-->
			
			<!---
			Include Header and Navigation
			--->
			#includePartial("/layout/navigation")#
			
			<!---
			Primary Content
			Flashmessages are automatically output and styled to suit bootstrap 4
			--->
			<div id="content" class="container">
				<div class="pt-5">
					#flashMessages()#
					<section class="pt-2">
						#includeContent()#
					</section>
				</div>
			</div>
		
			<!---
			Include Footer
			--->
			#includePartial("/layout/footer")#
			
			<!---
			Javascript
			Include jQuery and Bootstrap JS, moment js & daterangepicker from CDN
			Yes, I could technically put these all in a javascriptIncludeTag, but I think this is slightly more readable
			Also include custom.js from /javascripts/
			--->
			#javascriptIncludeTag("jquery.min")#
			#javascriptIncludeTag("bootstrap.min")#
			#javascriptIncludeTag("moment.min")#
			#javascriptIncludeTag("daterangepicker")#
			#javascriptIncludeTag("custom")#
			
			<!---
			Additional JS Set in view files
			Sometimes for development it's a load easier to just have a cfsavecontent block of javascript in the same file as
			the form/page you're dealing with. As JS is loaded *after* the template, we're delaying it's execution to after
			jQuery etc is loaded. See /views/admin/auditlogs/_filter.cfm as an example of using this.
			--->
			<cfif structKeyExists(request, "js")>
				<cfloop collection="#request.js#" item="i">
					<cfoutput>
						#request.js[i]#
					</cfoutput>
				</cfloop>
			</cfif>
		
		</body>
	</html>
</cfoutput>
	