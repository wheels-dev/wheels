<cfscript>
// NB ACF10/11 throw duplicate routines if already defined here
if (!IsDefined("pageHeader")) {
	include "../helpers.cfm";
}

// Css Path
request.wheelsInternalAssetPath = application.wheels.webpath & "wheels/public/assets";

// Primary Navigation
request.navigation = [
	{
		route = "wheelsInfo",
		title = "System Information",
		isFluid = false,
		text = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="14" viewBox="0 0 512 512"><path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM216 336h24V272H216c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24H216c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 1 1 0 64 32 32 0 1 1 0-64z"/></svg>&nbsp Info'
	},
	{
		route = "wheelsRoutes",
		title = "Routes",
		isFluid = false,
		text = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="14" viewBox="0 0 512 512"><path d="M403.8 34.4c12-5 25.7-2.2 34.9 6.9l64 64c6 6 9.4 14.1 9.4 22.6s-3.4 16.6-9.4 22.6l-64 64c-9.2 9.2-22.9 11.9-34.9 6.9s-19.8-16.6-19.8-29.6V160H352c-10.1 0-19.6 4.7-25.6 12.8L284 229.3 244 176l31.2-41.6C293.3 110.2 321.8 96 352 96h32V64c0-12.9 7.8-24.6 19.8-29.6zM164 282.7L204 336l-31.2 41.6C154.7 401.8 126.2 416 96 416H32c-17.7 0-32-14.3-32-32s14.3-32 32-32H96c10.1 0 19.6-4.7 25.6-12.8L164 282.7zm274.6 188c-9.2 9.2-22.9 11.9-34.9 6.9s-19.8-16.6-19.8-29.6V416H352c-30.2 0-58.7-14.2-76.8-38.4L121.6 172.8c-6-8.1-15.5-12.8-25.6-12.8H32c-17.7 0-32-14.3-32-32s14.3-32 32-32H96c30.2 0 58.7 14.2 76.8 38.4L326.4 339.2c6 8.1 15.5 12.8 25.6 12.8h32V320c0-12.9 7.8-24.6 19.8-29.6s25.7-2.2 34.9 6.9l64 64c6 6 9.4 14.1 9.4 22.6s-3.4 16.6-9.4 22.6l-64 64z"/></svg>&nbsp Routes'
	},
	{
		route = "wheelsApiDocs",
		title = "API",
		isFluid = true,
		text = '<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path d="M64 0C28.7 0 0 28.7 0 64V448c0 35.3 28.7 64 64 64H320c35.3 0 64-28.7 64-64V160H256c-17.7 0-32-14.3-32-32V0H64zM256 0V128H384L256 0zM112 256H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16zm0 64H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16zm0 64H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16z"/></svg>&nbsp API'
	},
	{
		route = "wheelsGuides",
		title = "Guides",
		isFluid = true,
		text = '<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path d="M64 0C28.7 0 0 28.7 0 64V448c0 35.3 28.7 64 64 64H320c35.3 0 64-28.7 64-64V160H256c-17.7 0-32-14.3-32-32V0H64zM256 0V128H384L256 0zM112 256H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16zm0 64H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16zm0 64H272c8.8 0 16 7.2 16 16s-7.2 16-16 16H112c-8.8 0-16-7.2-16-16s7.2-16 16-16z"/></svg>&nbsp Guides'
	},
	{
		route = "tests",
		type = "core",
		title = "Tests",
		isFluid = false,
		text = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="14" viewBox="0 0 512 512"><path d="M152.1 38.2c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 113C-2.3 103.6-2.3 88.4 7 79s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zm0 160c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 273c-9.4-9.4-9.4-24.6 0-33.9s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zM224 96c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zm0 160c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zM160 416c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H192c-17.7 0-32-14.3-32-32zM48 368a48 48 0 1 1 0 96 48 48 0 1 1 0-96z"/></svg>&nbsp Tests'
	}
];
if (application.wheels.enableMigratorComponent) {
	ArrayAppend(
		request.navigation,
		{
			route = "wheelsMigrator",
			title = "Migrator",
			isFluid = false,
			text = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="14" viewBox="0 0 448 512"><path d="M448 80v48c0 44.2-100.3 80-224 80S0 172.2 0 128V80C0 35.8 100.3 0 224 0S448 35.8 448 80zM393.2 214.7c20.8-7.4 39.9-16.9 54.8-28.6V288c0 44.2-100.3 80-224 80S0 332.2 0 288V186.1c14.9 11.8 34 21.2 54.8 28.6C99.7 230.7 159.5 240 224 240s124.3-9.3 169.2-25.3zM0 346.1c14.9 11.8 34 21.2 54.8 28.6C99.7 390.7 159.5 400 224 400s124.3-9.3 169.2-25.3c20.8-7.4 39.9-16.9 54.8-28.6V432c0 44.2-100.3 80-224 80S0 476.2 0 432V346.1z"/></svg>&nbsp Migrator'
		}
	);
}
if (application.wheels.enablePluginsComponent) {
	ArrayAppend(
		request.navigation,
		{
			route = "wheelsPlugins",
			title = "Plugins",
			isFluid = false,
			text = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="10" viewBox="0 0 384 512"><path d="M96 0C78.3 0 64 14.3 64 32v96h64V32c0-17.7-14.3-32-32-32zM288 0c-17.7 0-32 14.3-32 32v96h64V32c0-17.7-14.3-32-32-32zM32 160c-17.7 0-32 14.3-32 32s14.3 32 32 32v32c0 77.4 55 142 128 156.8V480c0 17.7 14.3 32 32 32s32-14.3 32-32V412.8C297 398 352 333.4 352 256V224c17.7 0 32-14.3 32-32s-14.3-32-32-32H32z"/></svg>&nbsp Plugins'
		}
	);
}

// Get Active Route Info
request.currentRoute = getActiveRoute(request.wheels.params.route, request.navigation);

// Page Title
request.internalPageTitle = StructKeyExists(request.currentRoute, 'title') ? request.currentRoute.title & ' | ' & "Wheels" : "Wheels";

request.wheels.internalHeaderLoaded = true;

if (StructKeyExists(url, "refresh")) {
	_refresh = 3;
	if (IsNumeric(url.refresh)) {
		_refresh = url.refresh;
	}
}
</cfscript>
<cfparam name="request.isFluid" default="false">
<cfoutput>
	<!--- cfformat-ignore-start --->
	<DOCTYPE html>
	<html>
	<head>
		<title>#request.internalPageTitle#</title>
		<meta charset="utf-8">
		<meta name="robots" content="noindex,nofollow">
		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="0">
		<cfif StructKeyExists(variables, "_refresh")>
			<meta http-equiv="refresh" content="#_refresh#">
		</cfif>
		<script>
			<cfinclude template="/wheels/public/assets/js/jquery.min.js">
			<cfinclude template="/wheels/public/assets/js/semantic.min.js">
			<cfinclude template="/wheels/public/assets/js/marked.min.js">
			<cfinclude template="/wheels/public/assets/js/highlight.min.js">
		</script>
		<style>
			<cfinclude template="/wheels/public/assets/css/semantic.min.css">
			<cfinclude template="/wheels/public/assets/css/highlight_default.min.css">
			.h-100 {height:100%;}
			.forcescroll { overflow-y: scroll; max-height: 40rem;   }
			.margin-top { margin-top: 5em; }
		</style>
	</head>
	<body>
	<cfif request.isFluid>
		<div id="main" class="ui grid stackable h-100">
		<cfinclude template="_navigation.cfm">
		<div id="top" class="sixteen wide stretched column ">
		<div class="ui grid stackable">
	<cfelse>
		<div id="main">
		<cfinclude template="_navigation.cfm">
		<div id="top" class="margin-top">
	</cfif>
	<!--- cfformat-ignore-end --->
</cfoutput>
