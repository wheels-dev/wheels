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
			.forcescroll { overflow-y: scroll; max-height: 40rem; }
			.margin-top { margin-top: 5em; }
			.flex-wrap { flex-wrap: wrap; }
		</style>
		</cfoutput>
		<style>
			/* ===== Wheels Dark Theme ===== */
			:root {
				--w-bg-base: #1e1e2e;
				--w-bg-surface: #181825;
				--w-bg-overlay: #313244;
				--w-border: #45475a;
				--w-text: #cdd6f4;
				--w-text-muted: #a6adc8;
				--w-text-subtle: #6c7086;
				--w-accent: #89b4fa;
				--w-accent-hover: #74c7ec;
				--w-green: #a6e3a1;
				--w-red: #f38ba8;
				--w-yellow: #f9e2af;
				--w-orange: #fab387;
				--w-violet: #cba6f7;
				--w-teal: #94e2d5;
			}
			html, body {
				background: var(--w-bg-base) !important;
				color: var(--w-text) !important;
			}
			/* Navigation */
			.ui.menu {
				background: var(--w-bg-surface) !important;
				border-color: var(--w-border) !important;
				box-shadow: 0 2px 8px rgba(0,0,0,.3) !important;
			}
			.ui.menu .item {
				color: var(--w-text-muted) !important;
				transition: color .15s, background .15s;
			}
			.ui.menu .item:hover {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
			}
			.ui.menu .item.active, .ui.menu .active.item {
				background: var(--w-bg-overlay) !important;
				color: var(--w-accent) !important;
				border-color: var(--w-accent) !important;
			}
			.ui.menu .item svg path {
				fill: currentColor;
			}
			.ui.pointing.menu .active.item::after {
				background: var(--w-bg-overlay) !important;
				border-color: var(--w-border) !important;
			}
			.ui.tabular.menu .active.item {
				background: var(--w-bg-base) !important;
				border-bottom-color: var(--w-bg-base) !important;
			}
			.ui.tabular.menu .item {
				border-color: transparent !important;
			}
			.ui.tabular.menu .active.item {
				border-color: var(--w-border) !important;
				border-bottom-color: var(--w-bg-base) !important;
				color: var(--w-accent) !important;
			}
			.ui.dropdown .menu {
				background: var(--w-bg-surface) !important;
				border-color: var(--w-border) !important;
			}
			.ui.dropdown .menu .item {
				color: var(--w-text-muted) !important;
				border-color: var(--w-border) !important;
			}
			.ui.dropdown .menu .item:hover {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
			}
			/* Segments & Cards */
			.ui.segment, .ui.segments {
				background: var(--w-bg-overlay) !important;
				border-color: var(--w-border) !important;
				color: var(--w-text) !important;
				box-shadow: 0 1px 4px rgba(0,0,0,.2) !important;
			}
			.ui.bottom.attached.tab.segment {
				background: var(--w-bg-base) !important;
				border-color: var(--w-border) !important;
			}
			.ui.card, .ui.cards > .card {
				background: var(--w-bg-overlay) !important;
				border-color: var(--w-border) !important;
				box-shadow: 0 1px 4px rgba(0,0,0,.2) !important;
				color: var(--w-text) !important;
			}
			.ui.card .content, .ui.cards > .card .content {
				border-color: var(--w-border) !important;
			}
			.ui.card .header, .ui.cards > .card .header {
				color: var(--w-text) !important;
			}
			.ui.card .description, .ui.cards > .card .description {
				color: var(--w-text-muted) !important;
			}
			.ui.placeholder.segment {
				background: var(--w-bg-overlay) !important;
			}
			/* Tables */
			.ui.table {
				background: var(--w-bg-base) !important;
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			.ui.table thead th {
				background: var(--w-bg-surface) !important;
				color: var(--w-text-muted) !important;
				border-color: var(--w-border) !important;
			}
			.ui.table td {
				border-color: var(--w-border) !important;
				color: var(--w-text) !important;
			}
			.ui.table tr:hover td {
				background: rgba(49,50,68,.5) !important;
			}
			.ui.celled.table tr td, .ui.celled.table tr th {
				border-color: var(--w-border) !important;
			}
			.ui.striped.table tbody tr:nth-child(2n) {
				background: rgba(24,24,37,.5) !important;
			}
			.ui.table tr.positive, .ui.table td.positive {
				background: rgba(166,227,161,.1) !important;
				color: var(--w-green) !important;
			}
			.ui.table tr.active, .ui.table td.active {
				background: rgba(137,180,250,.15) !important;
				color: var(--w-accent) !important;
			}
			/* Headers */
			h1, h2, h3, h4, h5, h6,
			.ui.header, .ui.dividing.header {
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			.ui.header .sub.header {
				color: var(--w-text-muted) !important;
			}
			/* Dividers */
			.ui.divider, .ui.horizontal.divider {
				color: var(--w-text-subtle) !important;
				border-color: var(--w-border) !important;
			}
			.ui.horizontal.divider::before, .ui.horizontal.divider::after {
				background-image: none !important;
				border-bottom: 1px solid var(--w-border) !important;
			}
			/* Links */
			a { color: var(--w-accent) !important; }
			a:hover { color: var(--w-accent-hover) !important; }
			/* Buttons */
			.ui.button {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
				border: 1px solid var(--w-border) !important;
			}
			.ui.button:hover {
				background: var(--w-border) !important;
				color: var(--w-text) !important;
			}
			.ui.primary.button, .ui.blue.button {
				background: var(--w-accent) !important;
				color: var(--w-bg-base) !important;
				border-color: var(--w-accent) !important;
			}
			.ui.violet.button {
				background: var(--w-violet) !important;
				color: var(--w-bg-base) !important;
				border-color: var(--w-violet) !important;
			}
			.ui.red.button {
				background: var(--w-red) !important;
				color: var(--w-bg-base) !important;
				border-color: var(--w-red) !important;
			}
			.ui.teal.button {
				background: var(--w-teal) !important;
				color: var(--w-bg-base) !important;
				border-color: var(--w-teal) !important;
			}
			.ui.green.button {
				background: var(--w-green) !important;
				color: var(--w-bg-base) !important;
				border-color: var(--w-green) !important;
			}
			/* Labels */
			.ui.label {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			.ui.green.label, .ui.green.horizontal.label {
				background: rgba(166,227,161,.15) !important;
				color: var(--w-green) !important;
			}
			.ui.blue.label, .ui.blue.horizontal.label {
				background: rgba(137,180,250,.15) !important;
				color: var(--w-accent) !important;
			}
			.ui.violet.label, .ui.violet.horizontal.label {
				background: rgba(203,166,247,.15) !important;
				color: var(--w-violet) !important;
			}
			.ui.purple.label, .ui.purple.horizontal.label {
				background: rgba(203,166,247,.15) !important;
				color: var(--w-violet) !important;
			}
			.ui.red.label, .ui.red.horizontal.label {
				background: rgba(243,139,168,.15) !important;
				color: var(--w-red) !important;
			}
			/* Forms & Inputs */
			.ui.input input, .ui.form input, .ui.form textarea, select {
				background: var(--w-bg-surface) !important;
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			.ui.input input:focus, .ui.form input:focus, .ui.form textarea:focus, select:focus {
				border-color: var(--w-accent) !important;
			}
			::placeholder {
				color: var(--w-text-subtle) !important;
			}
			/* Messages */
			.ui.info.message {
				background: rgba(137,180,250,.1) !important;
				color: var(--w-accent) !important;
				border: 1px solid rgba(137,180,250,.3) !important;
				box-shadow: none !important;
			}
			.ui.info.message .header { color: var(--w-accent) !important; }
			.ui.error.message, .ui.negative.message {
				background: rgba(243,139,168,.1) !important;
				color: var(--w-red) !important;
				border: 1px solid rgba(243,139,168,.3) !important;
				box-shadow: none !important;
			}
			.ui.error.message .header, .ui.negative.message .header { color: var(--w-red) !important; }
			.ui.success.message, .ui.positive.message {
				background: rgba(166,227,161,.1) !important;
				color: var(--w-green) !important;
				border: 1px solid rgba(166,227,161,.3) !important;
				box-shadow: none !important;
			}
			.ui.success.message .header, .ui.positive.message .header { color: var(--w-green) !important; }
			.ui.warning.message {
				background: rgba(249,226,175,.1) !important;
				color: var(--w-yellow) !important;
				border: 1px solid rgba(249,226,175,.3) !important;
				box-shadow: none !important;
			}
			.ui.warning.message .header { color: var(--w-yellow) !important; }
			/* Modals */
			.ui.modal {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
			}
			.ui.modal > .header {
				background: var(--w-bg-surface) !important;
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			.ui.modal > .content {
				background: var(--w-bg-overlay) !important;
				color: var(--w-text) !important;
			}
			.ui.modal > .actions {
				background: var(--w-bg-surface) !important;
				border-color: var(--w-border) !important;
			}
			.ui.dimmer {
				background: rgba(0,0,0,.7) !important;
			}
			/* Popups */
			.ui.popup {
				background: var(--w-bg-surface) !important;
				color: var(--w-text) !important;
				border-color: var(--w-border) !important;
			}
			/* Code & Pre */
			pre, code {
				background: var(--w-bg-surface) !important;
				color: var(--w-teal) !important;
				border: 1px solid var(--w-border) !important;
				border-radius: 4px;
			}
			pre code {
				border: none !important;
			}
			/* Highlight.js dark overrides */
			.hljs {
				background: var(--w-bg-surface) !important;
				color: var(--w-text) !important;
			}
			/* Misc */
			.ui.grid > .column:not(.row) { color: var(--w-text); }
			em { color: var(--w-text-muted); }
			strong { color: var(--w-text); }
			tt, kbd { background: var(--w-bg-overlay); color: var(--w-teal); padding: 1px 5px; border-radius: 3px; }
			.route-count { color: var(--w-text-subtle); font-size: .9em; }
			/* Loader */
			.ui.text.loader { color: var(--w-text-muted) !important; }
			/* Scrollbar */
			::-webkit-scrollbar { width: 8px; height: 8px; }
			::-webkit-scrollbar-track { background: var(--w-bg-surface); }
			::-webkit-scrollbar-thumb { background: var(--w-border); border-radius: 4px; }
			::-webkit-scrollbar-thumb:hover { background: var(--w-text-subtle); }
			/* Checkbox */
			.ui.checkbox label, .ui.radio.checkbox label { color: var(--w-text) !important; }
		</style>
<cfoutput>
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
