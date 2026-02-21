<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui container" style="padding-bottom:2em;">
		<!--- Error Type Badge --->
		<div style="margin-bottom:1.5em;">
			<span style="display:inline-block;background:rgba(243,139,168,.15);color:##f38ba8;padding:4px 12px;border-radius:4px;font-size:12px;font-weight:600;letter-spacing:.5px;text-transform:uppercase;">#EncodeForHTML(arguments.wheelsError.type)#</span>
		</div>

		<!--- Error Message --->
		<h1 style="font-size:1.8em;margin-bottom:.5em;line-height:1.3;">
			#ReReplace(arguments.wheelsError.message, "`([^`]*)`", "<code style='background:##313244;color:##94e2d5;padding:2px 6px;border-radius:3px;font-size:.85em;'>\1</code>", "all")#
		</h1>

		<!--- Suggested Action --->
		<cfif StructKeyExists(arguments.wheelsError, "extendedInfo") AND Len(arguments.wheelsError.extendedInfo)>
			<div style="background:rgba(137,180,250,.08);border:1px solid rgba(137,180,250,.2);border-radius:6px;padding:16px 20px;margin:1.5em 0;">
				<div style="font-size:11px;font-weight:700;color:##89b4fa;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">Suggested Action</div>
				<cfset local.info = ReReplace(arguments.wheelsError.extendedInfo, "`([^`]*)`", "<code style='background:##313244;color:##94e2d5;padding:2px 6px;border-radius:3px;font-size:.85em;'>\1</code>", "all")>
				<cftry>
					<cfset local.info = ReReplaceNoCase(
						local.info,
						"<code[^>]*>([a-z]*)\(\)</code>",
						'<a href="#$get('webPath')##ListLast(request.cgi.script_name, '/')#?controller=wheels&action=wheels&view=docs&type=core##\1" style="color:##89b4fa;">\1()</a>'
					)>
					<cfcatch></cfcatch>
				</cftry>
				<div style="color:##cdd6f4;line-height:1.6;">#local.info#</div>
			</div>
		</cfif>

		<!--- Source Code Context --->
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
					<cfset local.errorLine = arguments.wheelsError.tagContext[local.errorPos].line>
					<cfset local.errorFile = Replace(arguments.wheelsError.tagContext[local.errorPos].template, local.path, "")>
					<cfsavecontent variable="local.fileContents">
						<cfset local.pos = 0>
						<cfset local.startLine = Max(1, local.errorLine - 5)>
						<cfset local.endLine = local.errorLine + 5>
						<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;overflow:hidden;margin-top:12px;">
							<div style="display:flex;align-items:center;justify-content:space-between;padding:8px 16px;background:##11111b;border-bottom:1px solid ##45475a;">
								<span style="font-family:monospace;font-size:12px;color:##a6adc8;">#EncodeForHTML(local.errorFile)#</span>
								<span style="font-size:11px;color:##6c7086;">line #local.errorLine#</span>
							</div>
							<pre style="margin:0;padding:0;background:##181825 !important;border:none !important;"><code style="border:none !important;background:none !important;"><cfloop file="#arguments.wheelsError.tagContext[local.errorPos].template#" index="local.i"><cfset local.pos = local.pos + 1><cfif local.pos GTE local.startLine AND local.pos LTE local.endLine><cfif local.pos IS local.errorLine><span style="display:block;background:rgba(243,139,168,.12);border-left:3px solid ##f38ba8;padding:1px 12px 1px 9px;"><span style="display:inline-block;width:40px;color:##f38ba8;font-weight:700;text-align:right;margin-right:12px;user-select:none;">#local.pos#</span>#HtmlEditFormat(local.i)#</span><cfelse><span style="display:block;padding:1px 12px 1px 12px;"><span style="display:inline-block;width:40px;color:##6c7086;text-align:right;margin-right:12px;user-select:none;">#local.pos#</span>#HtmlEditFormat(local.i)#</span></cfif></cfif></cfloop></code></pre>
						</div>
					</cfsavecontent>
					<cfcatch>
						<cfset local.lookupWorked = false>
					</cfcatch>
				</cftry>
				<cfif local.lookupWorked>
					<div style="margin-top:1.5em;">
						<div style="font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Error Location</div>
						<div style="font-size:13px;color:##cdd6f4;">
							Line <strong style="color:##f38ba8;">#local.errorLine#</strong> in <code style="background:##313244;color:##94e2d5;padding:2px 6px;border-radius:3px;font-size:.85em;">#EncodeForHTML(local.errorFile)#</code>
						</div>
						#local.fileContents#
					</div>
				</cfif>
				<cfbreak>
			</cfif>
		</cfloop>

		<!--- Stack Trace (Collapsible) --->
		<cfif ArrayLen(arguments.wheelsError.tagContext) GTE 2>
			<div style="margin-top:1.5em;">
				<div onclick="var el=document.getElementById('wheels-stacktrace');el.style.display=el.style.display==='none'?'block':'none';this.querySelector('svg').style.transform=el.style.display==='none'?'':'rotate(90deg)';" style="cursor:pointer;display:flex;align-items:center;gap:6px;font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;user-select:none;">
					<svg style="width:10px;height:10px;fill:##a6adc8;transition:transform .15s;" viewBox="0 0 320 512"><path d="M310.6 233.4c12.5 12.5 12.5 32.8 0 45.3l-192 192c-12.5 12.5-32.8 12.5-45.3 0s-12.5-32.8 0-45.3L242.7 256 73.4 86.6c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0l192 192z"/></svg>
					Stack Trace (#ArrayLen(arguments.wheelsError.tagContext) - 1# frames)
				</div>
				<div id="wheels-stacktrace" style="display:none;">
					<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;overflow:hidden;">
						<cfset local.frameNum = 0>
						<!--- skip the first item in the array as this is always the Throw() method --->
						<cfloop from="2" to="#ArrayLen(arguments.wheelsError.tagContext)#" index="local.i">
							<cfset local.frameNum = local.frameNum + 1>
							<cfset local.frameFile = Replace(arguments.wheelsError.tagContext[local.i].template, local.path, "")>
							<div style="display:flex;align-items:center;padding:8px 16px;border-bottom:1px solid ##313244;font-size:12px;gap:10px;<cfif local.i EQ 2>background:rgba(137,180,250,.05);</cfif>">
								<span style="color:##6c7086;font-weight:600;min-width:24px;">###local.frameNum#</span>
								<span style="font-family:monospace;color:##cdd6f4;flex:1;">#EncodeForHTML(local.frameFile)#</span>
								<span style="color:##f9e2af;font-family:monospace;font-size:11px;">line #arguments.wheelsError.tagContext[local.i].line#</span>
							</div>
						</cfloop>
					</div>
				</div>
			</div>
		</cfif>
	</div>
	<!--- cfformat-ignore-end --->
</cfoutput>
