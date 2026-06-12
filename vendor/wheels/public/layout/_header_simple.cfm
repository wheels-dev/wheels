<!---
Static simple version of the header/navigation for output on error screens
--->
<cfscript>
// Opt the request into the dev debug bar emitted at onrequestend.
// Public.cfc::index() <cfinclude>s congratulations.cfm directly (bypassing
// renderView, which is what normally flips this flag), so without this
// the bar wouldn't appear on the welcome page when served from the
// framework's Public dispatcher. Same opt-in pattern as _header.cfm.
if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
	request.wheels.showDebugInformation = true;
}

// Inline icon font (see _header.cfm and issue ##2421). Duplicated here
// because error pages can render before _header.cfm has been visited.
// Double-checked locking matches _header.cfm — see comment there for
// the TOCTOU rationale.
if (!StructKeyExists(application.wheels, "iconsFontDataUri")) {
	lock name="wheelsIconsFontInit" type="exclusive" timeout="10" {
		if (!StructKeyExists(application.wheels, "iconsFontDataUri")) {
			local.iconsFontPath = ExpandPath("/wheels/public/assets/css/woff_files/icons.woff2");
			local.dataUri = "";
			if (FileExists(local.iconsFontPath)) {
				try {
					local.dataUri = "data:font/woff2;base64," & ToBase64(FileReadBinary(local.iconsFontPath));
				} catch (any e) {
				}
			}
			application.wheels.iconsFontDataUri = local.dataUri;
		}
	}
}

// Page <title> for this shared chrome. Defaults to "Wheels" — the
// fresh-install welcome page (congratulations.cfm) leaves it at the
// default. The error handler (EventMethods.$runOnError) sets
// request.wheels.pageTitle = "Wheels - Error" before including this
// partial so error screens keep their error-specific title.
// Issue ##3175: the title was hardcoded to "Wheels - Error", so every
// successful first boot rendered a browser tab titled "Error".
local.simpleHeaderTitle = "Wheels";
if (
	StructKeyExists(request, "wheels")
	&& IsStruct(request.wheels)
	&& StructKeyExists(request.wheels, "pageTitle")
	&& Len(Trim(request.wheels.pageTitle))
) {
	local.simpleHeaderTitle = request.wheels.pageTitle;
}
</cfscript>
<cfoutput>
<!--- cfformat-ignore-start --->
<!DOCTYPE html>
<html>
<head>
	<title>#EncodeForHTML(local.simpleHeaderTitle)#</title>
	<meta charset="utf-8">
	<meta name="robots" content="noindex,nofollow">
	<style>
		<cfinclude template="/wheels/public/assets/css/semantic.min.css">
		<cfif Len(application.wheels.iconsFontDataUri)>
		@font-face {
			font-family: 'Icons';
			src: url("#application.wheels.iconsFontDataUri#") format('woff2');
			font-weight: normal;
			font-style: normal;
			font-display: block;
		}
		</cfif>
		/* ===== Wheels Dark Error Theme ===== */
		:root {
			--w-bg-base: ##1e1e2e;
			--w-bg-surface: ##181825;
			--w-bg-overlay: ##313244;
			--w-border: ##45475a;
			--w-text: ##cdd6f4;
			--w-text-muted: ##a6adc8;
			--w-text-subtle: ##6c7086;
			--w-accent: ##89b4fa;
			--w-red: ##f38ba8;
			--w-yellow: ##f9e2af;
			--w-green: ##a6e3a1;
			--w-teal: ##94e2d5;
			--w-violet: ##cba6f7;
		}
		html, body {
			background: var(--w-bg-base) !important;
			color: var(--w-text) !important;
		}
		.ui.menu {
			background: var(--w-bg-surface) !important;
			border-color: var(--w-border) !important;
			box-shadow: 0 2px 8px rgba(0,0,0,.3) !important;
		}
		.ui.menu .item {
			color: var(--w-text-muted) !important;
		}
		.ui.menu .item:hover {
			background: var(--w-bg-overlay) !important;
			color: var(--w-text) !important;
		}
		.ui.menu .item svg path { fill: currentColor; }
		.ui.segment {
			background: var(--w-bg-overlay) !important;
			border-color: var(--w-border) !important;
			color: var(--w-text) !important;
		}
		h1, h2, h3 { color: var(--w-text) !important; }
		a { color: var(--w-accent) !important; }
		a:hover { color: ##74c7ec !important; }
		pre, code {
			background: var(--w-bg-surface) !important;
			color: var(--w-teal) !important;
			border: 1px solid var(--w-border) !important;
			border-radius: 4px;
		}
		pre code { border: none !important; }
		tt { background: var(--w-bg-overlay); color: var(--w-teal); padding: 1px 5px; border-radius: 3px; }
		strong { color: var(--w-text); }
		em { color: var(--w-text-muted); }
		::-webkit-scrollbar { width: 8px; height: 8px; }
		::-webkit-scrollbar-track { background: var(--w-bg-surface); }
		::-webkit-scrollbar-thumb { background: var(--w-border); border-radius: 4px; }
		::-webkit-scrollbar-thumb:hover { background: var(--w-text-subtle); }
	</style>
	<script>
		<cfinclude template="/wheels/public/assets/js/jquery.min.js">
		<cfinclude template="/wheels/public/assets/js/semantic.min.js">
	</script>
</head>
<body>
<!--- Note: top nav bar removed in favor of the dev-mode debug bar emitted at
      onrequestend. The debug bar (vendor/wheels/events/onrequestend/debug.cfm)
      already exposes links to /wheels/info, /wheels/routes, /wheels/api,
      /wheels/guides, /wheels/migrator, /wheels/packages, /wheels/plugins.
      Keeping just one chrome surface (footer-only) makes the dev UX
      consistent across welcome, error, and app pages. --->
<div class="container ui" style="margin-top:2em;">
</cfoutput>
<!--- cfformat-ignore-end --->
