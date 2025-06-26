<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui container">
		<h1>#arguments.wheelsError.type#</h1>
		<p>
			<strong>#ReReplace(arguments.wheelsError.message, "`([^`]*)`", "<tt>\1</tt>", "all")#</strong>
		</p>
		<cfif StructKeyExists(arguments.wheelsError, "extendedInfo") AND Len(arguments.wheelsError.extendedInfo)>
			<h2>Suggested action</h2>
			<cfset local.info = ReReplace(arguments.wheelsError.extendedInfo, "`([^`]*)`", "<tt>\1</tt>", "all")>
			<cftry>
				<cfset local.info = ReReplaceNoCase(
					local.info,
					"<tt>([a-z]*)\(\)</tt>",
					'<a href="#$get('webPath')##ListLast(request.cgi.script_name, '/')#?controller=wheels&action=wheels&view=docs&type=core##\1">\1()</a>'
				)>
				<cfcatch></cfcatch>
			</cftry>
			<p>#local.info#</p>
		</cfif>
		<cfset local.path = GetDirectoryFromPath(GetBaseTemplatePath())>
		<cfset local.errorPos = 0>
		<cfloop array="#arguments.wheelsError.tagContext#" index="local.i">
			<cfset local.errorPos = local.errorPos + 1>
			<cfif
				local.i.template Does Not Contain local.path & "wheels"
				AND local.i.template IS NOT local.path & "index.cfm"
				AND IsDefined("application.wheels.rewriteFile")
				AND local.i.template IS NOT local.path & application.wheels.rewriteFile
				AND local.i.template IS NOT local.path & "Application.cfc"
				AND local.i.template Does Not Contain local.path & "plugins"
			>
				<cfset local.lookupWorked = true>
				<cftry>
					<cfsavecontent variable="local.fileContents">
						<cfset local.pos = 0>
						<p style="overflow-x: scroll; padding-bottom:10px;">
							<code>
								<cfloop file="#arguments.wheelsError.tagContext[local.errorPos].template#" index="local.i">
									<cfset local.pos = local.pos + 1>
									<cfif local.pos GTE (arguments.wheelsError.tagContext[local.errorPos].line - 2)
									AND local.pos LTE (arguments.wheelsError.tagContext[local.errorPos].line + 2)>
										<cfif local.pos IS arguments.wheelsError.tagContext[local.errorPos].line>
											<span style="color: red;">#local.pos#: #HtmlEditFormat(local.i)#</span>
										<cfelse>
											#local.pos#: #HtmlEditFormat(local.i)#
										</cfif>
										#Chr(13)##Chr(10)#<br>
									</cfif>
								</cfloop>
							</code>
						</p>
					</cfsavecontent>
					<cfcatch>
						<cfset local.lookupWorked = false>
					</cfcatch>
				</cftry>
				<cfif local.lookupWorked>
					<h2>Error location</h2>
					<p>Line #arguments.wheelsError.tagContext[local.errorPos].line# in #Replace(arguments.wheelsError.tagContext[local.errorPos].template, local.path, "")#</p>
					#local.fileContents#
				</cfif>
				<cfbreak>
			</cfif>
		</cfloop>
		<cfif ArrayLen(arguments.wheelsError.tagContext) gte 2>
			<h2>Tag context</h2>
			<p>
				Error thrown on line #arguments.wheelsError.tagContext[2].line# in #Replace(arguments.wheelsError.tagContext[2].template, local.path, "")#<br>
				<!--- skip the first item in the array as this is always the Throw() method --->
				<cfloop from="3" to="#ArrayLen(arguments.wheelsError.tagContext)#" index="local.i">
					- called from line #arguments.wheelsError.tagContext[local.i].line# in #Replace(arguments.wheelsError.tagContext[local.i].template, local.path, "")#<br>
				</cfloop>
			</p>
		</cfif>
	</div>
	<!--- cfformat-ignore-end --->
</cfoutput>
