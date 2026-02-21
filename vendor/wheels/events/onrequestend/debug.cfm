<!--- Skip debug bar for AJAX, HTMX, Turbo, and fetch requests to avoid breaking partial responses --->
<cfset local.reqHeaders = GetHttpRequestData().headers>
<cfif
	(StructKeyExists(local.reqHeaders, "X-Requested-With") AND local.reqHeaders["X-Requested-With"] IS "XMLHttpRequest")
	OR (StructKeyExists(local.reqHeaders, "HX-Request"))
	OR (StructKeyExists(local.reqHeaders, "Turbo-Frame"))
	OR (StructKeyExists(local.reqHeaders, "X-Fetch") AND local.reqHeaders["X-Fetch"] IS "true")
	OR (StructKeyExists(url, "format") AND ListFindNoCase("json,xml,csv,pdf", url.format))
><cfexit></cfif>
<cfset local.baseReloadURL = cgi.script_name>
<cfif IsDefined("request.cgi.path_info")>
	<cfif request.cgi.path_info IS NOT cgi.script_name>
		<cfset local.baseReloadURL &= request.cgi.path_info>
	</cfif>
<cfelse>
	<cfif cgi.path_info IS NOT cgi.script_name>
		<cfset local.baseReloadURL &= cgi.path_info>
	</cfif>
</cfif>
<cfif Len(cgi.query_string)>
	<cfset local.baseReloadURL &= "?" & cgi.query_string>
</cfif>
<cfset local.baseReloadURL = ReplaceNoCase(local.baseReloadURL, "/" & application.wheels.rewriteFile, "")>
<cfloop list="development,testing,maintenance,production,true" index="local.i">
	<cfset local.baseReloadURL = ReplaceNoCase(
		ReplaceNoCase(local.baseReloadURL, "?reload=" & local.i, ""),
		"&reload=" & local.i,
		""
	)>
</cfloop>
<cfif local.baseReloadURL Contains "?">
	<cfset local.baseReloadURL &= "&">
<cfelse>
	<cfset local.baseReloadURL &= "?">
</cfif>
<cfset local.baseReloadURL &= "reload=">
<cfset local.gitbranch = DirectoryExists(GetDirectoryFromPath(GetBaseTemplatePath()) & ".git") ? FileRead(GetDirectoryFromPath(GetBaseTemplatePath()) & ".git/HEAD") : "">
<cfset local.envClass = LCase($get("environment"))>
<cfif local.envClass IS "production">
	<cfset local.envColor = "##dc3545">
<cfelseif local.envClass IS "testing">
	<cfset local.envColor = "##fd7e14">
<cfelseif local.envClass IS "maintenance">
	<cfset local.envColor = "##ffc107">
<cfelse>
	<cfset local.envColor = "##28a745">
</cfif>
<!--- Collect execution timing breakdown --->
<cfset local.timingBreakdown = []>
<cfif request.wheels.execution.total GT 0>
	<cfset local.keys = StructSort(request.wheels.execution, "numeric", "desc")>
	<cfloop from="1" to="#ArrayLen(local.keys)#" index="local.ti">
		<cfset local.tkey = local.keys[local.ti]>
		<cfif local.tkey IS NOT "total" AND request.wheels.execution[local.tkey] GT 0>
			<cfset ArrayAppend(local.timingBreakdown, {name = LCase(local.tkey), ms = request.wheels.execution[local.tkey], pct = Round((request.wheels.execution[local.tkey] / request.wheels.execution.total) * 100)})>
		</cfif>
	</cfloop>
</cfif>
<!--- Collect parameters --->
<cfset local.paramsList = []>
<cfloop collection="#request.wheels.params#" item="local.pi">
	<cfif local.pi IS NOT "fieldnames" AND local.pi IS NOT "route" AND local.pi IS NOT "controller" AND local.pi IS NOT "action" AND local.pi IS NOT "key">
		<cfif IsSimpleValue(request.wheels.params[local.pi])>
			<cfset ArrayAppend(local.paramsList, {name = LCase(local.pi), value = request.wheels.params[local.pi], type = "string"})>
		<cfelseif IsStruct(request.wheels.params[local.pi]) OR IsArray(request.wheels.params[local.pi])>
			<cfset ArrayAppend(local.paramsList, {name = LCase(local.pi), value = SerializeJSON(request.wheels.params[local.pi]), type = "json"})>
		</cfif>
	</cfif>
</cfloop>
<!--- cfformat-ignore-start --->
<cfoutput>
<div id="wheels-debugbar" style="all:initial;position:fixed;bottom:0;left:0;right:0;z-index:99999;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,sans-serif;">
<style>
##wheels-debugbar *{box-sizing:border-box;margin:0;padding:0;}
##wheels-debugbar{position:fixed;bottom:0;left:0;right:0;z-index:99999;font-size:13px;line-height:1.4;}
##wheels-debugbar .wdb-bar{display:flex;align-items:center;background:##1e1e2e;color:##cdd6f4;height:36px;padding:0 8px;gap:2px;border-top:1px solid ##45475a;user-select:none;}
##wheels-debugbar .wdb-bar a,##wheels-debugbar .wdb-bar span{color:##cdd6f4;text-decoration:none;}
##wheels-debugbar .wdb-tab{display:flex;align-items:center;gap:5px;padding:0 10px;height:36px;cursor:pointer;border:none;background:none;color:##cdd6f4;font-size:12px;font-family:inherit;white-space:nowrap;transition:background .15s;}
##wheels-debugbar .wdb-tab:hover{background:##313244;}
##wheels-debugbar .wdb-tab.active{background:##313244;color:##89b4fa;border-top:2px solid ##89b4fa;padding-top:2px;}
##wheels-debugbar .wdb-tab svg{width:14px;height:14px;fill:currentColor;flex-shrink:0;}
##wheels-debugbar .wdb-badge{display:inline-flex;align-items:center;justify-content:center;min-width:18px;height:18px;padding:0 5px;border-radius:9px;font-size:10px;font-weight:700;line-height:1;}
##wheels-debugbar .wdb-badge-green{background:##28a74533;color:##a6e3a1;}
##wheels-debugbar .wdb-badge-yellow{background:##ffc10733;color:##f9e2af;}
##wheels-debugbar .wdb-badge-red{background:##dc354533;color:##f38ba8;}
##wheels-debugbar .wdb-badge-blue{background:##89b4fa33;color:##89b4fa;}
##wheels-debugbar .wdb-sep{width:1px;height:20px;background:##45475a;margin:0 4px;}
##wheels-debugbar .wdb-spacer{flex:1;}
##wheels-debugbar .wdb-panel{display:none;position:fixed;bottom:36px;left:0;right:0;max-height:50vh;background:##1e1e2e;border-top:1px solid ##45475a;overflow-y:auto;color:##cdd6f4;padding:0;}
##wheels-debugbar .wdb-panel.open{display:block;}
##wheels-debugbar .wdb-panel-header{display:flex;align-items:center;justify-content:space-between;padding:10px 16px;border-bottom:1px solid ##313244;position:sticky;top:0;background:##1e1e2e;z-index:1;}
##wheels-debugbar .wdb-panel-header h3{font-size:14px;font-weight:600;color:##cdd6f4;}
##wheels-debugbar .wdb-panel-body{padding:12px 16px;}
##wheels-debugbar .wdb-table{width:100%;border-collapse:collapse;}
##wheels-debugbar .wdb-table th{text-align:left;padding:6px 12px;font-size:11px;font-weight:600;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;background:##181825;border-bottom:1px solid ##313244;}
##wheels-debugbar .wdb-table td{padding:6px 12px;border-bottom:1px solid ##313244;font-size:12px;vertical-align:top;}
##wheels-debugbar .wdb-table tr:hover td{background:##31324433;}
##wheels-debugbar .wdb-kv{display:grid;grid-template-columns:180px 1fr;gap:0;}
##wheels-debugbar .wdb-kv dt{padding:6px 12px;font-weight:600;color:##a6adc8;font-size:12px;border-bottom:1px solid ##313244;}
##wheels-debugbar .wdb-kv dd{padding:6px 12px;font-size:12px;border-bottom:1px solid ##313244;word-break:break-word;}
##wheels-debugbar .wdb-kv dd code{font-family:'SF Mono',SFMono-Regular,Menlo,Consolas,monospace;background:##313244;padding:1px 5px;border-radius:3px;font-size:11px;}
##wheels-debugbar .wdb-timing-row{display:flex;align-items:center;gap:8px;margin-bottom:6px;}
##wheels-debugbar .wdb-timing-label{width:100px;font-size:12px;color:##a6adc8;text-align:right;}
##wheels-debugbar .wdb-timing-bar-bg{flex:1;height:20px;background:##313244;border-radius:3px;overflow:hidden;position:relative;}
##wheels-debugbar .wdb-timing-bar{height:100%;border-radius:3px;display:flex;align-items:center;padding-left:6px;font-size:10px;font-weight:600;color:##1e1e2e;min-width:30px;}
##wheels-debugbar .wdb-close-btn{background:none;border:none;color:##a6adc8;cursor:pointer;font-size:18px;padding:4px 8px;border-radius:4px;line-height:1;}
##wheels-debugbar .wdb-close-btn:hover{background:##45475a;color:##cdd6f4;}
##wheels-debugbar .wdb-link-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px;padding:4px 0;}
##wheels-debugbar .wdb-link-card{display:flex;align-items:center;gap:8px;padding:10px 12px;background:##313244;border-radius:6px;color:##cdd6f4;text-decoration:none;font-size:12px;font-weight:500;transition:background .15s;}
##wheels-debugbar .wdb-link-card:hover{background:##45475a;}
##wheels-debugbar .wdb-link-card svg{width:16px;height:16px;fill:##89b4fa;flex-shrink:0;}
##wheels-debugbar .wdb-env-dot{width:8px;height:8px;border-radius:50%;display:inline-block;}
##wheels-debugbar .wdb-section{margin-bottom:16px;}
##wheels-debugbar .wdb-section-title{font-size:11px;font-weight:700;color:##89b4fa;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;padding-bottom:4px;border-bottom:1px solid ##313244;}
</style>

<!--- ============ COLLAPSED BAR ============ --->
<div class="wdb-bar" id="wdb-bar">
	<!--- Wheels logo / toggle --->
	<button class="wdb-tab" onclick="wdbToggle('request')" title="Request Details">
		<svg viewBox="0 0 31 18" xmlns="http://www.w3.org/2000/svg" style="width:28px;height:16px;"><path d="M15.71 12c1.65 0 2.99 1.34 2.99 3s-1.34 3-2.99 3-2.99-1.34-2.99-3v-1.27c0-.42-.15-.79-.45-1.09L6.1 6.45c-.3-.3-.66-.45-1.09-.45H3.75c-1.65 0-2.99-1.34-2.99-3S2.09 0 3.74 0s2.99 1.34 2.99 3v1.27c0 .42.15.79.45 1.09l6.17 6.19c.3.3.66.45 1.09.45h1.27zM27.68 0c1.65 0 2.99 1.34 2.99 3s-1.34 3-2.99 3-2.99-1.34-2.99-3 1.34-3 2.99-3zm0 12h-1.27c-.42 0-.79-.15-1.09-.45l-6.17-6.19c-.3-.3-.45-.66-.45-1.09V3c0-1.65-1.34-3-2.99-3S12.73 1.35 12.73 3s1.34 3 2.99 3h1.27c.42 0 .79.16 1.09.45l6.17 6.19c.3.3.45.66.45 1.09V15c0 1.65 1.34 3 2.99 3s2.99-1.34 2.99-3-1.34-3-2.99-3z" fill="##f38ba8"/></svg>
	</button>
	<span class="wdb-sep"></span>

	<!--- Request tab --->
	<button class="wdb-tab" onclick="wdbToggle('request')" id="wdb-tab-request" title="Request">
		<svg viewBox="0 0 512 512"><path d="M256 512A256 256 0 10256 0a256 256 0 000 512zm-24-176h24V272h-24c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24h-80c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 110 64 32 32 0 010-64z"/></svg>
		#request.wheels.params.controller#.#request.wheels.params.action#
	</button>

	<!--- Timing tab --->
	<button class="wdb-tab" onclick="wdbToggle('timing')" id="wdb-tab-timing" title="Execution Time">
		<svg viewBox="0 0 512 512"><path d="M256 0a256 256 0 110 512A256 256 0 01256 0zm24 120a24 24 0 10-48 0v136c0 8.4 4.4 16.2 11.6 20.5l80 48a24 24 0 1024.8-41l-68.4-41V120z"/></svg>
		<span class="wdb-badge <cfif request.wheels.execution.total LT 100>wdb-badge-green<cfelseif request.wheels.execution.total LT 500>wdb-badge-yellow<cfelse>wdb-badge-red</cfif>">#request.wheels.execution.total#ms</span>
	</button>

	<!--- Params tab --->
	<button class="wdb-tab" onclick="wdbToggle('params')" id="wdb-tab-params" title="Parameters">
		<svg viewBox="0 0 576 512"><path d="M0 64C0 28.7 28.7 0 64 0h160v128c0 17.7 14.3 32 32 32h128v128H216c-13.3 0-24 10.7-24 24s10.7 24 24 24h168v128H64c-35.3 0-64-28.7-64-64V64z"/></svg>
		Params
		<cfif ArrayLen(local.paramsList)>
			<span class="wdb-badge wdb-badge-blue">#ArrayLen(local.paramsList)#</span>
		</cfif>
	</button>

	<!--- Environment tab --->
	<button class="wdb-tab" onclick="wdbToggle('environment')" id="wdb-tab-environment" title="Environment">
		<span class="wdb-env-dot" style="background:#local.envColor#;"></span>
		#capitalize($get("environment"))#
	</button>

	<!--- Tools tab --->
	<cfif $get("enablePublicComponent")>
	<button class="wdb-tab" onclick="wdbToggle('tools')" id="wdb-tab-tools" title="Developer Tools">
		<svg viewBox="0 0 512 512"><path d="M78.6 5C69.1-2.4 55.6-1.5 47 7L7 47c-8.5 8.5-9.4 22-2.1 31.6l80 104c4.5 5.9 11.6 9.4 19 9.4h54.1l109 109c-14.7 29-10 65.4 14.3 89.6l112 112c12.5 12.5 32.8 12.5 45.3 0l64-64c12.5-12.5 12.5-32.8 0-45.3l-112-112c-24.2-24.2-60.6-29-89.6-14.3l-109-109V124c0-7.5-3.5-14.5-9.4-19L78.6 5z"/></svg>
		Tools
	</button>
	</cfif>

	<span class="wdb-spacer"></span>

	<!--- Version --->
	<span style="font-size:11px;color:##6c7086;padding:0 8px;">
		<cfif Len(local.gitbranch)>
			<svg viewBox="0 0 448 512" style="width:11px;height:11px;fill:##6c7086;vertical-align:middle;"><path d="M80 104a24 24 0 100-48 24 24 0 000 48zm80-24c0 32.8-19.7 61-48 73.3v87.8c18.8-10.9 40.7-17.1 64-17.1h96c35.3 0 64-28.7 64-64v-6.7C307.7 141 288 112.8 288 80c0-44.2 35.8-80 80-80s80 35.8 80 80c0 32.8-19.7 61-48 73.3V224c0 70.7-57.3 128-128 128h-96c-35.3 0-64 28.7-64 64v6.7c28.3 12.3 48 40.5 48 73.3 0 44.2-35.8 80-80 80S0 540.2 0 496c0-32.8 19.7-61 48-73.3V153.3C19.7 141 0 112.8 0 80 0 35.8 35.8 0 80 0s80 35.8 80 80z"/></svg>
			#Trim(Replace(local.gitbranch, "ref: refs/heads/", ""))#
			&middot;
		</cfif>
		Wheels #$get("version")#
	</span>

	<!--- Reload button --->
	<cfif NOT Len($get("reloadPassword"))>
		<a href="#local.baseReloadURL#true" class="wdb-tab" title="Reload Application" style="color:##f9e2af;">
			<svg viewBox="0 0 512 512" style="width:13px;height:13px;fill:##f9e2af;"><path d="M105.1 202.6c7.7-21.8 20.2-42.3 37.8-59.8c62.5-62.5 163.8-62.5 226.3 0L386.3 160H352c-17.7 0-32 14.3-32 32s14.3 32 32 32h127.9c17.7 0 32-14.3 32-32V64c0-17.7-14.3-32-32-32s-32 14.3-32 32v35.2L430.6 81.9c-87.5-87.5-229.3-87.5-316.8 0C85.7 109.9 61 143.5 44.5 180.2l60.6 22.4z"/></svg>
		</a>
	</cfif>

	<!--- Close/minimize --->
	<button class="wdb-tab" onclick="wdbMinimize()" title="Hide Debug Bar" style="color:##a6adc8;">
		<svg viewBox="0 0 320 512" style="width:10px;height:10px;fill:currentColor;"><path d="M310.6 150.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L160 210.7 54.6 105.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L114.7 256 9.4 361.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L160 301.3 265.4 406.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L205.3 256 310.6 150.6z"/></svg>
	</button>
</div>

<!--- ============ REQUEST PANEL ============ --->
<div class="wdb-panel" id="wdb-panel-request">
	<div class="wdb-panel-header">
		<h3>Request Details</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<dl class="wdb-kv">
			<cfif StructKeyExists(request.wheels.params, "route")>
				<dt>Route</dt>
				<dd><code>#request.wheels.params.route#</code></dd>
			</cfif>
			<dt>Controller</dt>
			<dd><code>#request.wheels.params.controller#</code></dd>
			<dt>Action</dt>
			<dd><code>#request.wheels.params.action#</code></dd>
			<cfif StructKeyExists(request.wheels.params, "key")>
				<dt>Key</dt>
				<dd><code>#request.wheels.params.key#</code></dd>
			</cfif>
			<dt>HTTP Method</dt>
			<dd><code>#UCase(cgi.request_method)#</code></dd>
			<dt>URL</dt>
			<dd><code>#cgi.server_name##cgi.path_info#<cfif Len(cgi.query_string)>?#cgi.query_string#</cfif></code></dd>
			<dt>Application</dt>
			<dd>#application.applicationName#</dd>
			<dt>Data Source</dt>
			<dd><code>#$get("dataSourceName")#</code></dd>
			<cfif StructKeyExists(application.wheels, "adapterName")>
				<dt>DB Adapter</dt>
				<dd>#$get("adapterName")#</dd>
			</cfif>
			<dt>URL Rewriting</dt>
			<dd>#$get("URLRewriting")#</dd>
		</dl>
	</div>
</div>

<!--- ============ TIMING PANEL ============ --->
<div class="wdb-panel" id="wdb-panel-timing">
	<div class="wdb-panel-header">
		<h3>Execution Timing &mdash; #request.wheels.execution.total#ms total</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<cfif ArrayLen(local.timingBreakdown)>
			<cfset local.barColors = ["##89b4fa","##a6e3a1","##f9e2af","##fab387","##f38ba8","##cba6f7","##94e2d5","##74c7ec"]>
			<cfloop from="1" to="#ArrayLen(local.timingBreakdown)#" index="local.bi">
				<cfset local.bcolor = local.barColors[((local.bi - 1) MOD ArrayLen(local.barColors)) + 1]>
				<div class="wdb-timing-row">
					<span class="wdb-timing-label">#local.timingBreakdown[local.bi].name#</span>
					<div class="wdb-timing-bar-bg">
						<div class="wdb-timing-bar" style="width:#Max(local.timingBreakdown[local.bi].pct, 5)#%;background:#local.bcolor#;">
							#local.timingBreakdown[local.bi].ms#ms
						</div>
					</div>
				</div>
			</cfloop>
		<cfelse>
			<p style="color:##6c7086;">No timing breakdown available.</p>
		</cfif>
	</div>
</div>

<!--- ============ PARAMS PANEL ============ --->
<div class="wdb-panel" id="wdb-panel-params">
	<div class="wdb-panel-header">
		<h3>Request Parameters</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<cfif ArrayLen(local.paramsList)>
			<table class="wdb-table">
				<thead><tr><th>Name</th><th>Value</th><th>Type</th></tr></thead>
				<tbody>
				<cfloop from="1" to="#ArrayLen(local.paramsList)#" index="local.pIdx">
					<tr>
						<td><code>#local.paramsList[local.pIdx].name#</code></td>
						<td style="font-family:monospace;max-width:500px;overflow:hidden;text-overflow:ellipsis;">#EncodeForHTML(local.paramsList[local.pIdx].value)#</td>
						<td><span class="wdb-badge wdb-badge-blue">#local.paramsList[local.pIdx].type#</span></td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		<cfelse>
			<p style="color:##6c7086;">No additional parameters.</p>
		</cfif>
	</div>
</div>

<!--- ============ ENVIRONMENT PANEL ============ --->
<div class="wdb-panel" id="wdb-panel-environment">
	<div class="wdb-panel-header">
		<h3>Environment &amp; Configuration</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<div class="wdb-section">
			<div class="wdb-section-title">Application</div>
			<dl class="wdb-kv">
				<dt>Environment</dt>
				<dd>
					<span class="wdb-env-dot" style="background:#local.envColor#;"></span>
					#capitalize($get("environment"))#
					<cfif NOT Len($get("reloadPassword"))>
						<cfset local.environments = "development,testing,maintenance,production">
						&mdash;
						<cfloop list="#local.environments#" index="local.ei">
							<cfif $get("environment") IS NOT local.ei>
								<a href="#local.baseReloadURL##local.ei#" style="color:##89b4fa;font-size:11px;margin-left:4px;">#capitalize(local.ei)#</a>
							</cfif>
						</cfloop>
					</cfif>
				</dd>
				<cfif Len(local.gitbranch)>
					<dt>Git Branch</dt>
					<dd><code>#Trim(Replace(local.gitbranch, "ref: refs/heads/", ""))#</code></dd>
				</cfif>
				<dt>Wheels Version</dt>
				<dd>#$get("version")#</dd>
				<dt>CFML Engine</dt>
				<dd>#$get("serverName")# #$get("serverVersion")#</dd>
				<cfif StructKeyExists(application.wheels, "hostName")>
					<dt>Host Name</dt>
					<dd>#$get("hostName")#</dd>
				</cfif>
			</dl>
		</div>
		<cfif $get("enablePluginsComponent")>
			<div class="wdb-section">
				<div class="wdb-section-title">Plugins</div>
				<cfif StructCount($get("plugins")) IS NOT 0>
					<table class="wdb-table">
						<thead><tr><th>Plugin</th><th>Version</th></tr></thead>
						<tbody>
						<cfloop collection="#$get('plugins')#" item="local.pn">
							<tr>
								<td><code>#local.pn#</code></td>
								<td>
									<cfif StructCount($get("pluginMeta")) IS NOT 0 AND StructKeyExists($get("pluginMeta"), local.pn)>
										#$get("pluginMeta")[local.pn]['version']#
									<cfelse>
										-
									</cfif>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				<cfelse>
					<p style="color:##6c7086;">No plugins installed.</p>
				</cfif>
			</div>
			<!--- Warnings --->
			<cfif ($get("showIncompatiblePlugins") AND Len(application.wheels.incompatiblePlugins)) OR Len(application.wheels.dependantPlugins)>
				<div class="wdb-section">
					<div class="wdb-section-title" style="color:##f38ba8;">Warnings</div>
					<div style="color:##f38ba8;font-size:12px;">
						<cfif $get("showIncompatiblePlugins") AND Len(application.wheels.incompatiblePlugins)>
							<cfloop list="#application.wheels.incompatiblePlugins#" index="local.wi">
								<p>The <strong>#local.wi#</strong> plugin may be incompatible with this version of Wheels.</p>
							</cfloop>
						</cfif>
						<cfif Len(application.wheels.dependantPlugins)>
							<cfloop list="#application.wheels.dependantPlugins#" index="local.di">
								<cfset local.needs = ListLast(local.di, "|")>
								<p><strong>#ListFirst(local.di, "|")#</strong> needs: #local.needs#</p>
							</cfloop>
						</cfif>
					</div>
				</div>
			</cfif>
		</cfif>
	</div>
</div>

<!--- ============ TOOLS PANEL ============ --->
<cfif $get("enablePublicComponent")>
<div class="wdb-panel" id="wdb-panel-tools">
	<div class="wdb-panel-header">
		<h3>Developer Tools</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<div class="wdb-link-grid">
			<a href="#urlFor(route = 'wheelsInfo')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 512 512"><path d="M256 512A256 256 0 10256 0a256 256 0 000 512zm-24-176h24V272h-24c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24h-80c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 110 64 32 32 0 010-64z"/></svg>
				System Info
			</a>
			<a href="#urlFor(route = 'wheelsRoutes')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 512 512"><path d="M403.8 34.4c12-5 25.7-2.2 34.9 6.9l64 64c6 6 9.4 14.1 9.4 22.6s-3.4 16.6-9.4 22.6l-64 64c-9.2 9.2-22.9 11.9-34.9 6.9s-19.8-16.6-19.8-29.6V160H352c-10.1 0-19.6 4.7-25.6 12.8L284 229.3 244 176l31.2-41.6C293.3 110.2 321.8 96 352 96h32V64c0-12.9 7.8-24.6 19.8-29.6z"/></svg>
				Routes
			</a>
			<a href="#urlFor(route = 'wheelsApiDocs')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 384 512"><path d="M64 0C28.7 0 0 28.7 0 64v384c0 35.3 28.7 64 64 64h256c35.3 0 64-28.7 64-64V160H256c-17.7 0-32-14.3-32-32V0H64zm192 0v128h128L256 0zM112 256h160c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16z"/></svg>
				API Docs
			</a>
			<a href="#urlFor(route = 'wheelsGuides')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 448 512"><path d="M96 0C43 0 0 43 0 96v320c0 53 43 96 96 96h320c17.7 0 32-14.3 32-32s-14.3-32-32-32H96c-17.7 0-32-14.3-32-32h352c17.7 0 32-14.3 32-32V32c0-17.7-14.3-32-32-32H96z"/></svg>
				Guides
			</a>
			<a href="#urlFor(route = 'testbox')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 512 512"><path d="M152.1 38.2c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 113c-9.3-9.4-9.3-24.6 0-34s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8z"/></svg>
				Tests
			</a>
			<cfif $get("enableMigratorComponent")>
			<a href="#urlFor(route = 'wheelsMigrator')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 448 512"><path d="M448 80v48c0 44.2-100.3 80-224 80S0 172.2 0 128V80C0 35.8 100.3 0 224 0s224 35.8 224 80z"/></svg>
				Migrator
			</a>
			</cfif>
			<cfif $get("enablePluginsComponent")>
			<a href="#urlFor(route = 'wheelsPlugins')#" class="wdb-link-card" target="_blank">
				<svg viewBox="0 0 384 512"><path d="M96 0C78.3 0 64 14.3 64 32v96h64V32c0-17.7-14.3-32-32-32zm192 0c-17.7 0-32 14.3-32 32v96h64V32c0-17.7-14.3-32-32-32zM32 160c-17.7 0-32 14.3-32 32s14.3 32 32 32v32c0 77.4 55 142 128 156.8V480c0 17.7 14.3 32 32 32s32-14.3 32-32v-67.2C297 398 352 333.4 352 256v-32c17.7 0 32-14.3 32-32s-14.3-32-32-32H32z"/></svg>
				Plugins
			</a>
			</cfif>
		</div>
	</div>
</div>
</cfif>

<!--- ============ MINIMIZED BUTTON ============ --->
<div id="wdb-minimized" style="display:none;position:fixed;bottom:8px;right:8px;z-index:99999;">
	<button onclick="wdbRestore()" style="background:##1e1e2e;border:1px solid ##45475a;border-radius:8px;padding:6px 10px;cursor:pointer;color:##89b4fa;font-size:12px;font-family:inherit;display:flex;align-items:center;gap:4px;box-shadow:0 2px 8px rgba(0,0,0,.3);">
		<svg viewBox="0 0 153 18" xmlns="http://www.w3.org/2000/svg" style="width:20px;height:5px;"><path d="M15.71 12c1.65 0 2.99 1.34 2.99 3s-1.34 3-2.99 3-2.99-1.34-2.99-3v-1.27c0-.42-.15-.79-.45-1.09L6.1 6.45c-.3-.3-.66-.45-1.09-.45H3.75c-1.65 0-2.99-1.34-2.99-3S2.09 0 3.74 0s2.99 1.34 2.99 3v1.27c0 .42.15.79.45 1.09l6.17 6.19c.3.3.66.45 1.09.45z" fill="##f38ba8"/></svg>
		Debug
	</button>
</div>

<script>
(function(){
	var activePanel=null;
	window.wdbToggle=function(name){
		var panels=document.querySelectorAll('##wheels-debugbar .wdb-panel');
		var tabs=document.querySelectorAll('##wheels-debugbar .wdb-tab');
		if(activePanel===name){
			wdbClosePanel();
			return;
		}
		for(var i=0;i<panels.length;i++)panels[i].classList.remove('open');
		var p=document.getElementById('wdb-panel-'+name);
		if(p)p.classList.add('open');
		for(var j=0;j<tabs.length;j++)tabs[j].classList.remove('active');
		var t=document.getElementById('wdb-tab-'+name);
		if(t)t.classList.add('active');
		activePanel=name;
	};
	window.wdbClosePanel=function(){
		var panels=document.querySelectorAll('##wheels-debugbar .wdb-panel');
		var tabs=document.querySelectorAll('##wheels-debugbar .wdb-tab');
		for(var i=0;i<panels.length;i++)panels[i].classList.remove('open');
		for(var j=0;j<tabs.length;j++)tabs[j].classList.remove('active');
		activePanel=null;
	};
	window.wdbMinimize=function(){
		wdbClosePanel();
		document.getElementById('wheels-debugbar').style.display='none';
		document.getElementById('wdb-minimized').style.display='block';
		try{sessionStorage.setItem('wdb-hidden','1');}catch(e){}
	};
	window.wdbRestore=function(){
		document.getElementById('wheels-debugbar').style.display='';
		document.getElementById('wdb-minimized').style.display='none';
		try{sessionStorage.removeItem('wdb-hidden');}catch(e){}
	};
	try{if(sessionStorage.getItem('wdb-hidden')==='1')wdbMinimize();}catch(e){}
})();
</script>
</div>
</cfoutput>
<!--- cfformat-ignore-end --->
