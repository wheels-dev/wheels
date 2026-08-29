<cfscript>
	function $cfmlErrorTagContext(required struct exception) {
		if (
			StructKeyExists(arguments.exception, "cause")
			&& StructKeyExists(arguments.exception.cause, "tagContext")
			&& ArrayLen(arguments.exception.cause.tagContext)
		) {
			return Duplicate(arguments.exception.cause.tagContext);
		} else if (
			StructKeyExists(arguments.exception, "rootCause")
			&& StructKeyExists(arguments.exception.rootCause, "tagContext")
			&& ArrayLen(arguments.exception.rootCause.tagContext)
		) {
			return Duplicate(arguments.exception.rootCause.tagContext);
		} else if (
			StructKeyExists(arguments.exception, "tagContext")
			&& ArrayLen(arguments.exception.tagContext)
		) {
			return Duplicate(arguments.exception.tagContext);
		}
		return [];
	}

	function $cfmlErrorNormalizePath(required string path) {
		local.norm = arguments.path;
		local.norm = ReReplace(local.norm, "[" & Chr(92) & "(.*?)" & Chr(92) & "]", "." & Chr(92) & "1", "all");
		local.norm = ReReplace(local.norm, "^" & Chr(92) & ".", "", "one");
		return local.norm;
	}

	function $cfmlErrorSanitizeScope(required struct scope, required string skip, required string scopeName) {
		local.hide = "wheels";
		local.sanitizedScope = Duplicate(arguments.scope);
		for (local.j in ListToArray(arguments.skip)) {
			local.normalizedPath = $cfmlErrorNormalizePath(local.j);
			if (local.normalizedPath CONTAINS "." AND ListFirst(local.normalizedPath, ".") EQ arguments.scopeName) {
				local.relativePath = ListRest(local.normalizedPath, ".");
				local.keyList = ListToArray(local.relativePath, ".");
				local.ref = local.sanitizedScope;
				local.depth = ArrayLen(local.keyList);
				for (local.k = 1; local.k LTE local.depth; local.k++) {
					local.key = local.keyList[local.k];
					if (local.k EQ local.depth) {
						if (StructKeyExists(local.ref, local.key)) {
							StructDelete(local.ref, local.key);
						}
					} else {
						if (StructKeyExists(local.ref, local.key) AND IsStruct(local.ref[local.key])) {
							local.ref = local.ref[local.key];
						} else {
							break;
						}
					}
				}
			} else if (ListFindNoCase(arguments.skip, arguments.scopeName)) {
				local.hide = ListAppend(local.hide, local.j);
			}
		}
		return {hide = local.hide, sanitizedScope = local.sanitizedScope};
	}
</cfscript>
<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui container" style="padding-bottom:2em;">

		<!--- Error Badge --->
		<div style="margin-bottom:1.5em;">
			<span style="display:inline-block;background:rgba(243,139,168,.15);color:##f38ba8;padding:4px 12px;border-radius:4px;font-size:12px;font-weight:600;letter-spacing:.5px;text-transform:uppercase;">CFML Error</span>
		</div>

		<!--- Error Summary --->
		<h1 style="font-size:1.8em;margin-bottom:.5em;line-height:1.3;">
			<cfif
				StructKeyExists(arguments.exception, "rootcause")
				&& StructKeyExists(arguments.exception.rootcause, "message")
			>
				#EncodeForHTML(arguments.exception.rootcause.message)#
				<cfif arguments.exception.rootcause.detail IS NOT "">
					<div style="font-size:.6em;color:##a6adc8;margin-top:8px;font-weight:400;">#EncodeForHTML(arguments.exception.rootcause.detail)#</div>
				</cfif>
			<cfelse>
				A root cause was not provided.
			</cfif>
		</h1>

		<!--- Tag Context / Location --->
		<cfset local.tagContext = $cfmlErrorTagContext(arguments.exception)>

		<cfif StructKeyExists(local, "tagContext") AND ArrayLen(local.tagContext)>
			<div style="margin:1.5em 0;">
				<div style="font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">Location</div>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;overflow:hidden;">
					<cfset local.path = GetDirectoryFromPath(GetBaseTemplatePath())>
					<cfset local.pos = 0>
					<cfloop array="#local.tagContext#" index="local.i">
						<cfset local.pos = local.pos + 1>
						<cfset local.template = Replace(local.tagContext[local.pos].template, local.path, "")>
						<cfset local.template = Replace(local.template, "/wheels../", "")>
						<div style="display:flex;align-items:center;padding:8px 16px;border-bottom:1px solid ##313244;font-size:12px;gap:10px;<cfif local.pos EQ 1>background:rgba(243,139,168,.05);</cfif>">
							<span style="color:##6c7086;font-weight:600;min-width:24px;">###local.pos#</span>
							<span style="font-family:monospace;color:##cdd6f4;flex:1;">#EncodeForHTML(local.template)#</span>
							<span style="color:##f9e2af;font-family:monospace;font-size:11px;">line #local.tagContext[local.pos].line#</span>
						</div>
					</cfloop>
				</div>
			</div>
		</cfif>

		<!--- Request Info Grid --->
		<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:12px;margin:1.5em 0;">
			<cfif IsDefined("application.wheels.rewriteFile")>
				<!---
					Base composed from webPath (subpath-aware, issue #3344) so subfolder
					installs display /myapp/... instead of /myapp/public/... — same idiom
					as urlFor() and $buildDebugReloadUrl().
				--->
				<cfif IsDefined("application.wheels.webPath") AND Len(application.wheels.webPath)>
					<cfset local.errorUrlBase = Replace(application.wheels.webPath & ListLast(cgi.script_name, "/"), "/#application.wheels.rewriteFile#", "")>
				<cfelse>
					<cfset local.errorUrlBase = Replace(cgi.script_name, "/#application.wheels.rewriteFile#", "")>
				</cfif>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">URL</div>
					<div style="font-family:monospace;font-size:12px;color:##cdd6f4;word-break:break-all;">http<cfif cgi.http_x_forwarded_proto EQ "https" OR cgi.server_port_secure EQ "true">s</cfif>://#EncodeForHTML(cgi.server_name)##EncodeForHTML(local.errorUrlBase)#<cfif IsDefined("request.cgi.path_info")>#EncodeForHTML(request.cgi.path_info)#<cfelse>#EncodeForHTML(cgi.path_info)#</cfif><cfif cgi.query_string IS NOT "">?#EncodeForHTML(cgi.query_string)#</cfif></div>
				</div>
			</cfif>
			<cfif Len(cgi.http_referer)>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Referrer</div>
					<div style="font-family:monospace;font-size:12px;color:##cdd6f4;word-break:break-all;">#EncodeForHTML(cgi.http_referer)#</div>
				</div>
			</cfif>
			<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
				<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Method</div>
				<div style="font-family:monospace;font-size:12px;color:##cdd6f4;">#EncodeForHTML(cgi.request_method)#</div>
			</div>
			<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
				<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">IP Address</div>
				<div style="font-family:monospace;font-size:12px;color:##cdd6f4;">#EncodeForHTML(cgi.remote_addr)#</div>
			</div>
			<cfif IsDefined("application.wheels.hostName")>
				<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
					<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Host Name</div>
					<div style="font-family:monospace;font-size:12px;color:##cdd6f4;">#EncodeForHTML(application.wheels.hostName)#</div>
				</div>
			</cfif>
			<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
				<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">User Agent</div>
				<div style="font-family:monospace;font-size:12px;color:##cdd6f4;word-break:break-all;">#EncodeForHTML(cgi.http_user_agent)#</div>
			</div>
			<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;padding:12px 16px;">
				<div style="font-size:10px;font-weight:700;color:##6c7086;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;">Date &amp; Time</div>
				<div style="font-family:monospace;font-size:12px;color:##cdd6f4;">#DateFormat(Now(), "MMMM D, YYYY")# at #TimeFormat(Now(), "h:MM TT")#</div>
			</div>
		</div>

		<!--- Scope Dumps (Collapsible) --->
		<cfset local.scopes = "CGI,Form,URL,Application,Session,Request,Cookie,Arguments.Exception">
		<cfset local.skip = "">
		<cfif IsDefined("application.wheels.excludeFromErrorEmail")>
			<cfset local.skip = application.wheels.excludeFromErrorEmail>
		</cfif>
		<!--- always skip cause since it's just a copy of rootCause anyway --->
		<cfset local.skip = ListAppend(local.skip, "exception.cause")>
		<cfset local.scopeMap = {
			"CGI": CGI,
			"Form": Form,
			"URL": URL,
			"Application": Application,
			"Session": Session,
			"Request": Request,
			"Cookie": Cookie,
			"Arguments.Exception": Arguments.Exception
		}>

		<div style="margin-top:1.5em;">
			<div style="font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:12px;">Scope Details</div>

			<cfset local.scopeIdx = 0>
			<cfloop list="#local.scopes#" index="local.i">
				<cfset local.scopeName = ListLast(local.i, ".")>
				<cfif NOT ListFindNoCase(local.skip, local.scopeName) AND IsDefined(local.scopeName)>
					<cftry>
						<cfset local.scope = local.scopeMap[local.i]>
						<cfif IsStruct(local.scope)>
							<cfset local.scopeIdx = local.scopeIdx + 1>
							<cfset local.scopeMask = $cfmlErrorSanitizeScope(local.scope, local.skip, local.scopeName)>
							<cfset local.hide = local.scopeMask.hide>
							<cfset local.sanitizedScope = local.scopeMask.sanitizedScope>

							<div style="margin-bottom:8px;">
								<div onclick="var el=document.getElementById('scope-#LCase(local.scopeName)#');el.style.display=el.style.display==='none'?'block':'none';this.querySelector('svg').style.transform=el.style.display==='none'?'':'rotate(90deg)';" style="cursor:pointer;display:flex;align-items:center;gap:8px;padding:10px 16px;background:##181825;border:1px solid ##45475a;border-radius:6px;user-select:none;">
									<svg style="width:10px;height:10px;fill:##a6adc8;transition:transform .15s;" viewBox="0 0 320 512"><path d="M310.6 233.4c12.5 12.5 12.5 32.8 0 45.3l-192 192c-12.5 12.5-32.8 12.5-45.3 0s-12.5-32.8 0-45.3L242.7 256 73.4 86.6c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0l192 192z"/></svg>
									<span style="font-weight:600;color:##cdd6f4;font-size:13px;">#EncodeForHTML(local.scopeName)#</span>
									<span style="font-size:11px;color:##6c7086;">scope</span>
								</div>
								<div id="scope-#LCase(local.scopeName)#" style="display:none;margin-top:-1px;">
									<div style="background:##181825;border:1px solid ##45475a;border-top:none;border-radius:0 0 6px 6px;padding:12px;overflow-x:auto;">
										<cfdump var="#local.sanitizedScope#" format="text" showUDFs="false" hide="#local.hide#">
									</div>
								</div>
							</div>
						</cfif>
						<cfcatch type="any"><!--- just keep going, we need to send out error emails ---></cfcatch>
					</cftry>
				</cfif>
			</cfloop>
		</div>
	</div>
	<!--- cfformat-ignore-end --->
</cfoutput>
