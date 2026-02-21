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

		<!--- Classify all stack frames --->
		<cfset local.path = GetDirectoryFromPath(GetBaseTemplatePath())>
		<!--- Derive the app root (parent of public/) for reliable path display --->
		<cfset local.appRoot = local.path>
		<cfif local.path Contains "/public/" OR local.path Contains "\public\">
			<cfset local.appRoot = REReplaceNoCase(local.path, "[/\\]public[/\\]?$", "/")>
		</cfif>
		<cfset local.frames = []>
		<cfloop from="2" to="#ArrayLen(arguments.wheelsError.tagContext)#" index="local.i">
			<cfset local.tpl = arguments.wheelsError.tagContext[local.i].template>
			<cfset local.frameFile = Replace(local.tpl, local.appRoot, "")>
			<!---
				Classification uses path segments (not base path math) for reliability.
				Framework: vendor/wheels/, index.cfm & Application.cfc in public/
				Plugin: plugins/
				Library: any other vendor/ path (testbox, coldbox, etc.)
				App: app/, config/, public/, tests/, and anything else
			--->
			<cfset local.frameType = "app">
			<cfif local.tpl Contains "vendor/wheels/" OR local.tpl Contains "vendor\wheels\">
				<cfset local.frameType = "framework">
			<cfelseif local.tpl Contains "/vendor/" OR local.tpl Contains "\vendor\">
				<cfset local.frameType = "library">
			<cfelseif local.tpl Contains "/plugins/" OR local.tpl Contains "\plugins\">
				<cfset local.frameType = "plugin">
			<cfelseif GetFileFromPath(local.tpl) IS "index.cfm" AND local.tpl Contains "public">
				<cfset local.frameType = "framework">
			<cfelseif GetFileFromPath(local.tpl) IS "Application.cfc" AND local.tpl Contains "public">
				<cfset local.frameType = "framework">
			</cfif>
			<cfset ArrayAppend(local.frames, {
				template = local.tpl,
				file = local.frameFile,
				line = arguments.wheelsError.tagContext[local.i].line,
				type = local.frameType
			})>
		</cfloop>

		<!--- Count frames by type --->
		<cfset local.appCount = 0>
		<cfset local.frameworkCount = 0>
		<cfloop array="#local.frames#" index="local.f">
			<cfif local.f.type IS "app">
				<cfset local.appCount++>
			<cfelse>
				<cfset local.frameworkCount++>
			</cfif>
		</cfloop>

		<!--- Source Code Context: show first app frame, or first framework frame if no app code --->
		<cfset local.contextFrame = "">
		<cfloop array="#local.frames#" index="local.f">
			<cfif local.f.type IS "app">
				<cfset local.contextFrame = local.f>
				<cfbreak>
			</cfif>
		</cfloop>
		<cfif IsSimpleValue(local.contextFrame) AND ArrayLen(local.frames)>
			<cfset local.contextFrame = local.frames[1]>
		</cfif>
		<cfif NOT IsSimpleValue(local.contextFrame)>
			<cfset local.lookupWorked = true>
			<cftry>
				<cfset local.errorLine = local.contextFrame.line>
				<cfset local.errorFile = local.contextFrame.file>
				<cfset local.errorType = local.contextFrame.type>
				<cfsavecontent variable="local.fileContents">
					<cfset local.pos = 0>
					<cfset local.startLine = Max(1, local.errorLine - 5)>
					<cfset local.endLine = local.errorLine + 5>
					<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;overflow:hidden;margin-top:12px;">
						<div style="display:flex;align-items:center;justify-content:space-between;padding:8px 16px;background:##11111b;border-bottom:1px solid ##45475a;">
							<span style="font-family:monospace;font-size:12px;color:##a6adc8;">#EncodeForHTML(local.errorFile)#</span>
							<span style="font-size:11px;color:##6c7086;">line #local.errorLine#</span>
						</div>
						<pre style="margin:0;padding:0;background:##181825 !important;border:none !important;"><code style="border:none !important;background:none !important;"><cfloop file="#local.contextFrame.template#" index="local.ln"><cfset local.pos = local.pos + 1><cfif local.pos GTE local.startLine AND local.pos LTE local.endLine><cfif local.pos IS local.errorLine><span style="display:block;background:rgba(243,139,168,.12);border-left:3px solid ##f38ba8;padding:1px 12px 1px 9px;"><span style="display:inline-block;width:40px;color:##f38ba8;font-weight:700;text-align:right;margin-right:12px;user-select:none;">#local.pos#</span>#HtmlEditFormat(local.ln)#</span><cfelse><span style="display:block;padding:1px 12px 1px 12px;"><span style="display:inline-block;width:40px;color:##6c7086;text-align:right;margin-right:12px;user-select:none;">#local.pos#</span>#HtmlEditFormat(local.ln)#</span></cfif></cfif></cfloop></code></pre>
					</div>
				</cfsavecontent>
				<cfcatch>
					<cfset local.lookupWorked = false>
				</cfcatch>
			</cftry>
			<cfif local.lookupWorked>
				<div style="margin-top:1.5em;">
					<div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;">
						<span style="font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;">Error Location</span>
						<cfif local.errorType IS NOT "app">
							<span style="font-size:10px;padding:2px 8px;border-radius:3px;background:rgba(249,226,175,.12);color:##f9e2af;font-weight:600;">Framework Code</span>
						</cfif>
					</div>
					<cfif local.errorType IS NOT "app">
						<div style="font-size:12px;color:##f9e2af;margin-bottom:8px;line-height:1.5;">
							No application code found in the stack trace. The error originated in the framework, likely triggered by a missing file, route, or configuration in your app.
						</div>
					</cfif>
					<div style="font-size:13px;color:##cdd6f4;">
						Line <strong style="color:##f38ba8;">#local.errorLine#</strong> in <code style="background:##313244;color:##94e2d5;padding:2px 6px;border-radius:3px;font-size:.85em;">#EncodeForHTML(local.errorFile)#</code>
					</div>
					#local.fileContents#
				</div>
			</cfif>
		</cfif>

		<!--- Stack Trace with App/Framework Toggle --->
		<cfif ArrayLen(local.frames)>
			<div style="margin-top:1.5em;">
				<!--- Header with toggle buttons --->
				<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
					<div onclick="var el=document.getElementById('wheels-stacktrace');el.style.display=el.style.display==='none'?'block':'none';this.querySelector('svg').style.transform=el.style.display==='none'?'':'rotate(90deg)';" style="cursor:pointer;display:flex;align-items:center;gap:6px;font-size:11px;font-weight:700;color:##a6adc8;text-transform:uppercase;letter-spacing:.5px;user-select:none;">
						<svg style="width:10px;height:10px;fill:##a6adc8;transition:transform .15s;" viewBox="0 0 320 512"><path d="M310.6 233.4c12.5 12.5 12.5 32.8 0 45.3l-192 192c-12.5 12.5-32.8 12.5-45.3 0s-12.5-32.8 0-45.3L242.7 256 73.4 86.6c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0l192 192z"/></svg>
						Stack Trace (#ArrayLen(local.frames)# frames)
					</div>
					<div id="wheels-trace-filters" style="display:none;gap:4px;">
						<cfif local.appCount GT 0>
							<button onclick="wheelsFilterTrace('app')" id="wheels-filter-app" style="font-size:11px;padding:3px 10px;border-radius:4px;border:1px solid ##89b4fa;background:rgba(137,180,250,.15);color:##89b4fa;cursor:pointer;font-weight:600;">App #local.appCount#</button>
						</cfif>
						<button onclick="wheelsFilterTrace('framework')" id="wheels-filter-framework" style="font-size:11px;padding:3px 10px;border-radius:4px;border:1px solid ##45475a;background:transparent;color:##6c7086;cursor:pointer;font-weight:600;">Framework #local.frameworkCount#</button>
						<button onclick="wheelsFilterTrace('all')" id="wheels-filter-all" style="font-size:11px;padding:3px 10px;border-radius:4px;border:1px solid ##45475a;background:transparent;color:##6c7086;cursor:pointer;font-weight:600;">All #ArrayLen(local.frames)#</button>
					</div>
				</div>
				<div id="wheels-stacktrace" style="display:none;">
					<div style="background:##181825;border:1px solid ##45475a;border-radius:6px;overflow:hidden;">
						<cfset local.frameNum = 0>
						<cfloop array="#local.frames#" index="local.f">
							<cfset local.frameNum++>
							<cfset local.isApp = local.f.type IS "app">
							<div data-frame-type="#local.f.type#" style="display:flex;align-items:center;padding:8px 16px;border-bottom:1px solid ##313244;font-size:12px;gap:10px;<cfif NOT local.isApp>opacity:.45;</cfif>">
								<span style="color:##6c7086;font-weight:600;min-width:24px;">###local.frameNum#</span>
								<cfif local.isApp>
									<span style="font-size:9px;padding:1px 6px;border-radius:3px;background:rgba(166,227,161,.12);color:##a6e3a1;font-weight:700;min-width:32px;text-align:center;">APP</span>
								<cfelse>
									<span style="font-size:9px;padding:1px 6px;border-radius:3px;background:rgba(108,112,134,.15);color:##6c7086;font-weight:700;min-width:32px;text-align:center;">#UCase(local.f.type)#</span>
								</cfif>
								<span style="font-family:monospace;color:<cfif local.isApp>##cdd6f4<cfelse>##6c7086</cfif>;flex:1;">#EncodeForHTML(local.f.file)#</span>
								<span style="color:<cfif local.isApp>##f9e2af<cfelse>##45475a</cfif>;font-family:monospace;font-size:11px;">line #local.f.line#</span>
							</div>
						</cfloop>
					</div>
				</div>
			</div>
		</cfif>
	</div>
	</cfoutput>
	<script>
	(function(){
		// Show filter buttons when trace is expanded
		var traceEl = document.getElementById('wheels-stacktrace');
		var filtersEl = document.getElementById('wheels-trace-filters');
		var observer = new MutationObserver(function(){
			filtersEl.style.display = traceEl.style.display === 'none' ? 'none' : 'flex';
		});
		observer.observe(traceEl, {attributes: true, attributeFilter: ['style']});

		// Default to app filter if app frames exist
		var hasApp = document.querySelector('[data-frame-type="app"]');
		if (hasApp) {
			wheelsFilterTrace('app');
		}
	})();

	function wheelsFilterTrace(filter) {
		var frames = document.querySelectorAll('[data-frame-type]');
		var buttons = {
			app: document.getElementById('wheels-filter-app'),
			framework: document.getElementById('wheels-filter-framework'),
			all: document.getElementById('wheels-filter-all')
		};
		// Reset button styles
		for (var key in buttons) {
			if (buttons[key]) {
				buttons[key].style.background = 'transparent';
				buttons[key].style.borderColor = '#45475a';
				buttons[key].style.color = '#6c7086';
			}
		}
		// Highlight active button
		var active = buttons[filter];
		if (active) {
			active.style.borderColor = '#89b4fa';
			active.style.background = 'rgba(137,180,250,.15)';
			active.style.color = '#89b4fa';
		}
		// Filter frames
		for (var i = 0; i < frames.length; i++) {
			var type = frames[i].getAttribute('data-frame-type');
			if (filter === 'all') {
				frames[i].style.display = 'flex';
				frames[i].style.opacity = type === 'app' ? '1' : '.45';
			} else if (filter === 'app') {
				frames[i].style.display = type === 'app' ? 'flex' : 'none';
				frames[i].style.opacity = '1';
			} else {
				frames[i].style.display = type !== 'app' ? 'flex' : 'none';
				frames[i].style.opacity = '1';
			}
		}
	}
	</script>
	<cfoutput>
	<!--- cfformat-ignore-end --->
</cfoutput>
