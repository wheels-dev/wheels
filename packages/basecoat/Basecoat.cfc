<cfcomponent output="false" mixin="controller,view">

	<!---
	==============================================
	wheels-basecoat Plugin
	Basecoat UI component helpers for Wheels.
	Generates shadcn/ui-quality HTML using Basecoat CSS classes.
	Works with or without wheels-hotwire.
	==============================================
	--->

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "3.0">
		<cfreturn this>
	</cffunction>

	<!--- ============================================== --->
	<!--- INCLUDES                                       --->
	<!--- ============================================== --->

	<cffunction name="basecoatIncludes" access="public" output="false" returntype="string"
		hint="Outputs Basecoat CSS and Alpine.js (for interactive components) tags for the layout <head>.">
		<cfargument name="alpine" type="boolean" required="false" default="true"
			hint="Include Alpine.js for interactive components (dropdowns, tabs, etc.)">
		<cfargument name="alpineVersion" type="string" required="false" default="3">
		<cfargument name="basecoatCSSPath" type="string" required="false" default="/plugins/basecoat/assets/basecoat/basecoat.min.css"
			hint="Path to Basecoat CSS file. Override if using CDN or custom build.">
		<cfargument name="turboAware" type="boolean" required="false" default="true"
			hint="Include turbo-cache-control meta tag (harmless without Turbo, helpful with it)">

		<cfset var local = {}>
		<cfsavecontent variable="local.html">
			<cfoutput>
<cfif arguments.turboAware><meta name="turbo-cache-control" content="no-preview">
</cfif><link rel="stylesheet" href="#arguments.basecoatCSSPath#">
<cfif arguments.alpine><script defer src="https://cdn.jsdelivr.net/npm/alpinejs@#arguments.alpineVersion#/dist/cdn.min.js"></script>
</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<!--- ============================================== --->
	<!--- BUTTONS                                        --->
	<!--- ============================================== --->

	<cffunction name="uiButton" access="public" output="false" returntype="string"
		hint="Basecoat button. Variants: primary, secondary, destructive, outline, ghost, link. Sizes: sm, md, lg.">
		<cfargument name="text" type="string" required="false" default="">
		<cfargument name="variant" type="string" required="false" default="primary"
			hint="primary, secondary, destructive, outline, ghost, link">
		<cfargument name="size" type="string" required="false" default="md"
			hint="sm, md (default), lg">
		<cfargument name="icon" type="string" required="false" default=""
			hint="Lucide icon name. If text is empty, renders icon-only button.">
		<cfargument name="href" type="string" required="false" default=""
			hint="Renders as <a> instead of <button>">
		<cfargument name="type" type="string" required="false" default="button"
			hint="button, submit, reset">
		<cfargument name="disabled" type="boolean" required="false" default="false">
		<cfargument name="loading" type="boolean" required="false" default="false">
		<cfargument name="close" type="boolean" required="false" default="false"
			hint="Adds onclick to close nearest <dialog>">
		<cfargument name="class" type="string" required="false" default="">
		<cfargument name="id" type="string" required="false" default="">
		<cfargument name="ariaLabel" type="string" required="false" default="">
		<cfargument name="turboConfirm" type="string" required="false" default=""
			hint="data-turbo-confirm (works when wheels-hotwire is installed)">
		<cfargument name="turboMethod" type="string" required="false" default=""
			hint="data-turbo-method (works when wheels-hotwire is installed)">

		<cfset var local = {}>

		<!--- Build Basecoat compound class: btn[-size][-icon][-variant] --->
		<cfset local.isIconOnly = Len(arguments.icon) AND NOT Len(arguments.text)>
		<cfset local.parts = []>
		<cfif arguments.size NEQ "md">
			<cfset ArrayAppend(local.parts, arguments.size)>
		</cfif>
		<cfif local.isIconOnly>
			<cfset ArrayAppend(local.parts, "icon")>
		</cfif>
		<cfif arguments.variant NEQ "primary">
			<cfset ArrayAppend(local.parts, arguments.variant)>
		</cfif>

		<cfif ArrayLen(local.parts)>
			<cfset local.cls = "btn-" & ArrayToList(local.parts, "-")>
		<cfelse>
			<cfset local.cls = "btn">
		</cfif>
		<cfif Len(arguments.class)>
			<cfset local.cls = local.cls & " " & arguments.class>
		</cfif>

		<!--- Inner content: icon + text --->
		<cfset local.inner = "">
		<cfif arguments.loading>
			<cfset local.inner = $uiLucideIcon("loader", 24, 2, "animate-spin")>
		<cfelseif Len(arguments.icon)>
			<cfset local.inner = $uiLucideIcon(arguments.icon, 24)>
		</cfif>
		<cfif Len(arguments.text)>
			<cfif Len(local.inner)><cfset local.inner = local.inner & " "></cfif>
			<cfset local.inner = local.inner & arguments.text>
		</cfif>

		<!--- Attributes --->
		<cfset local.attrs = 'class="#local.cls#"'>
		<cfif Len(arguments.id)><cfset local.attrs = local.attrs & ' id="#arguments.id#"'></cfif>
		<cfif arguments.disabled OR arguments.loading><cfset local.attrs = local.attrs & " disabled"></cfif>
		<cfif Len(arguments.ariaLabel)><cfset local.attrs = local.attrs & ' aria-label="#arguments.ariaLabel#"'></cfif>
		<cfif arguments.close><cfset local.attrs = local.attrs & " onclick=""this.closest('dialog').close()"""></cfif>
		<cfif Len(arguments.turboConfirm)><cfset local.attrs = local.attrs & ' data-turbo-confirm="#arguments.turboConfirm#"'></cfif>
		<cfif Len(arguments.turboMethod)><cfset local.attrs = local.attrs & ' data-turbo-method="#arguments.turboMethod#"'></cfif>

		<cfif Len(arguments.href)>
			<cfreturn '<a href="#arguments.href#" #local.attrs#>#local.inner#</a>'>
		<cfelse>
			<cfreturn '<button type="#arguments.type#" #local.attrs#>#local.inner#</button>'>
		</cfif>
	</cffunction>

	<!--- ============================================== --->
	<!--- BADGES                                         --->
	<!--- ============================================== --->

	<cffunction name="uiBadge" access="public" output="false" returntype="string"
		hint="Basecoat badge. Variants: default, secondary, destructive, outline.">
		<cfargument name="text" type="string" required="true">
		<cfargument name="variant" type="string" required="false" default="default">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = (arguments.variant EQ "default") ? "badge" : "badge-#arguments.variant#">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<span class="#local.cls#">#arguments.text#</span>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- ICONS                                          --->
	<!--- ============================================== --->

	<cffunction name="uiIcon" access="public" output="false" returntype="string"
		hint="Renders a Lucide SVG icon by name.">
		<cfargument name="name" type="string" required="true" hint="Lucide icon name, e.g. 'trash', 'plus', 'check'">
		<cfargument name="size" type="numeric" required="false" default="24">
		<cfargument name="strokeWidth" type="numeric" required="false" default="2">
		<cfargument name="class" type="string" required="false" default="">
		<cfreturn $uiLucideIcon(arguments.name, arguments.size, arguments.strokeWidth, arguments.class)>
	</cffunction>

	<!--- ============================================== --->
	<!--- SIMPLE COMPONENTS                              --->
	<!--- ============================================== --->

	<cffunction name="uiSpinner" access="public" output="false" returntype="string"
		hint="Basecoat loading spinner.">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "spinner">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#"></div>'>
	</cffunction>

	<cffunction name="uiSkeleton" access="public" output="false" returntype="string"
		hint="Basecoat skeleton loading placeholder. Specify lines for multiple, or use height/width for custom.">
		<cfargument name="lines" type="numeric" required="false" default="1">
		<cfargument name="height" type="string" required="false" default="h-4">
		<cfargument name="width" type="string" required="false" default="w-full">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = "skeleton #arguments.height# #arguments.width#">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>

		<cfif arguments.lines EQ 1>
			<cfreturn '<div class="#local.cls#"></div>'>
		</cfif>

		<cfset local.html = "">
		<cfloop from="1" to="#arguments.lines#" index="local.i">
			<cfset local.html = local.html & '<div class="#local.cls#"></div>'>
			<cfif local.i LT arguments.lines><cfset local.html = local.html & Chr(10)></cfif>
		</cfloop>
		<cfreturn local.html>
	</cffunction>

	<cffunction name="uiProgress" access="public" output="false" returntype="string"
		hint="Basecoat progress bar.">
		<cfargument name="value" type="numeric" required="true" hint="0-100">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = "progress">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#"><div class="progress-indicator" style="width: #arguments.value#%"></div></div>'>
	</cffunction>

	<cffunction name="uiSeparator" access="public" output="false" returntype="string"
		hint="Basecoat horizontal separator.">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "separator">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<hr class="#local.cls#" />'>
	</cffunction>

	<cffunction name="uiTooltip" access="public" output="false" returntype="string"
		hint="Opens a Basecoat tooltip wrapper. Place trigger element inside, close with uiTooltipEnd().">
		<cfargument name="tip" type="string" required="true" hint="Tooltip text">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "tooltip">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<span class="#local.cls#" data-tip="#arguments.tip#">'>
	</cffunction>

	<cffunction name="uiTooltipEnd" access="public" output="false" returntype="string">
		<cfreturn '</span>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- ALERTS                                         --->
	<!--- ============================================== --->

	<cffunction name="uiAlert" access="public" output="false" returntype="string"
		hint="Basecoat alert. Self-closing (returns complete element). Variants: default, destructive.">
		<cfargument name="title" type="string" required="false" default="">
		<cfargument name="description" type="string" required="false" default="">
		<cfargument name="variant" type="string" required="false" default="default"
			hint="default, destructive">
		<cfargument name="icon" type="string" required="false" default=""
			hint="Lucide icon name. Defaults: info for default, alert-triangle for destructive.">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = "alert">
		<cfif arguments.variant EQ "destructive">
			<cfset local.cls = local.cls & " alert-destructive">
		</cfif>
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>

		<!--- Default icons by variant --->
		<cfset local.iconName = arguments.icon>
		<cfif NOT Len(local.iconName)>
			<cfset local.iconName = (arguments.variant EQ "destructive") ? "alert-triangle" : "info">
		</cfif>

		<cfsavecontent variable="local.html">
			<cfoutput>
<div class="#local.cls#" role="alert">
#$uiLucideIcon(local.iconName, 16)#
<div>
<cfif Len(arguments.title)><h5>#arguments.title#</h5>
</cfif><cfif Len(arguments.description)><div>#arguments.description#</div>
</cfif></div>
</div>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<!--- ============================================== --->
	<!--- CARDS                                          --->
	<!--- ============================================== --->

	<cffunction name="uiCard" access="public" output="false" returntype="string"
		hint="Opens a Basecoat card. Close with uiCardEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "card">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#">'>
	</cffunction>

	<cffunction name="uiCardHeader" access="public" output="false" returntype="string"
		hint="Card header with optional title and description. Self-closing.">
		<cfargument name="title" type="string" required="false" default="">
		<cfargument name="description" type="string" required="false" default="">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = "card-header">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>

		<cfsavecontent variable="local.html">
			<cfoutput>
<div class="#local.cls#">
<cfif Len(arguments.title)><h3>#arguments.title#</h3>
</cfif><cfif Len(arguments.description)><p>#arguments.description#</p>
</cfif></div>
			</cfoutput>
		</cfsavecontent>
		<cfreturn Trim(local.html)>
	</cffunction>

	<cffunction name="uiCardContent" access="public" output="false" returntype="string"
		hint="Opens card content section. Close with uiCardContentEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "card-content">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#">'>
	</cffunction>

	<cffunction name="uiCardContentEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<cffunction name="uiCardFooter" access="public" output="false" returntype="string"
		hint="Opens card footer section. Close with uiCardFooterEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "card-footer">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#">'>
	</cffunction>

	<cffunction name="uiCardFooterEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<cffunction name="uiCardEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- PRIVATE: LUCIDE ICON SVG HELPER                --->
	<!--- ============================================== --->

	<cffunction name="$uiLucideIcon" access="private" output="false" returntype="string"
		hint="Returns SVG markup for a Lucide icon. Extend the icon map as needed.">
		<cfargument name="name" type="string" required="true">
		<cfargument name="size" type="numeric" required="false" default="24">
		<cfargument name="strokeWidth" type="numeric" required="false" default="2">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.icons = {
			"plus": '<line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/>',
			"trash": '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
			"pencil": '<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/><path d="m15 5 4 4"/>',
			"x": '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
			"check": '<path d="M20 6 9 17l-5-5"/>',
			"chevron-right": '<path d="m9 18 6-6-6-6"/>',
			"chevron-left": '<path d="m15 18-6-6 6-6"/>',
			"search": '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
			"loader": '<path d="M12 2v4"/><path d="m16.2 7.8 2.9-2.9"/><path d="M18 12h4"/><path d="m16.2 16.2 2.9 2.9"/><path d="M12 18v4"/><path d="m4.9 19.1 2.9-2.9"/><path d="M2 12h4"/><path d="m4.9 4.9 2.9 2.9"/>',
			"alert-triangle": '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
			"info": '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
			"check-circle": '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
			"send": '<path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z"/><path d="m21.854 2.147-10.94 10.939"/>',
			"ellipsis": '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
			"external-link": '<path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>'
		}>

		<cfset local.paths = StructKeyExists(local.icons, arguments.name) ? local.icons[arguments.name] : '<circle cx="12" cy="12" r="10"/>'>
		<cfset local.classAttr = Len(arguments.class) ? ' class="#arguments.class#"' : "">
		<cfreturn '<svg xmlns="http://www.w3.org/2000/svg" width="#arguments.size#" height="#arguments.size#" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="#arguments.strokeWidth#" stroke-linecap="round" stroke-linejoin="round"#local.classAttr#>#local.paths#</svg>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- PRIVATE: ID GENERATION                         --->
	<!--- ============================================== --->

	<cffunction name="$uiBuildId" access="private" output="false" returntype="string"
		hint="Generates a short unique ID if none provided.">
		<cfargument name="providedId" type="string" required="false" default="">
		<cfargument name="prefix" type="string" required="false" default="ui">
		<cfif Len(arguments.providedId)>
			<cfreturn arguments.providedId>
		</cfif>
		<cfreturn arguments.prefix & "-" & Replace(Left(CreateUUID(), 8), "-", "", "all")>
	</cffunction>

	<!--- ============================================== --->
	<!--- DIALOGS                                        --->
	<!--- ============================================== --->

	<cffunction name="uiDialog" access="public" output="false" returntype="string"
		hint="Opens a Basecoat dialog (native <dialog> element). Close with uiDialogEnd(). Optionally renders a trigger button.">
		<cfargument name="title" type="string" required="true" hint="Dialog heading text">
		<cfargument name="description" type="string" required="false" default="" hint="Optional subtitle/description text">
		<cfargument name="triggerText" type="string" required="false" default="" hint="If provided, renders a button that opens this dialog">
		<cfargument name="triggerClass" type="string" required="false" default="btn-outline" hint="CSS class for the trigger button">
		<cfargument name="id" type="string" required="false" default="" hint="Dialog ID. Auto-generated if empty.">
		<cfargument name="maxWidth" type="string" required="false" default="sm:max-w-[425px]" hint="Tailwind max-width class">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.id = $uiBuildId(arguments.id, "dlg")>
		<cfset local.cls = "dialog w-full #arguments.maxWidth# max-h-[612px]">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>

		<cfsavecontent variable="local.html">
			<cfoutput>
<cfif Len(arguments.triggerText)><button type="button" onclick="document.getElementById('#local.id#').showModal()" class="#arguments.triggerClass#">#arguments.triggerText#</button>
</cfif><dialog id="#local.id#" class="#local.cls#" aria-labelledby="#local.id#-title"<cfif Len(arguments.description)> aria-describedby="#local.id#-desc"</cfif> onclick="if (event.target === this) this.close()">
<div>
<header>
<h2 id="#local.id#-title">#arguments.title#</h2>
<cfif Len(arguments.description)><p id="#local.id#-desc">#arguments.description#</p>
</cfif></header>
<section>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<cffunction name="uiDialogFooter" access="public" output="false" returntype="string"
		hint="Closes the dialog content section and opens the footer section.">
		<cfreturn '</section><footer>'>
	</cffunction>

	<cffunction name="uiDialogEnd" access="public" output="false" returntype="string"
		hint="Closes the dialog footer, adds the close (X) button, and closes the dialog element.">
		<cfset var local = {}>
		<cfset local.xIcon = $uiLucideIcon("x", 24, 2)>
		<cfreturn '</footer><button type="button" aria-label="Close dialog" onclick="this.closest(''dialog'').close()">#local.xIcon#</button></div></dialog>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- FORM FIELDS                                    --->
	<!--- ============================================== --->

	<cffunction name="uiField" access="public" output="false" returntype="string"
		hint="Basecoat form field. Handles text, email, password, number, tel, url, textarea, select, checkbox, switch.">
		<cfargument name="label" type="string" required="true" hint="Label text">
		<cfargument name="name" type="string" required="true" hint="Input name attribute">
		<cfargument name="type" type="string" required="false" default="text" hint="text, email, password, number, tel, url, textarea, select, checkbox, switch">
		<cfargument name="value" type="string" required="false" default="">
		<cfargument name="id" type="string" required="false" default="" hint="Auto-generated if empty">
		<cfargument name="placeholder" type="string" required="false" default="">
		<cfargument name="description" type="string" required="false" default="">
		<cfargument name="errorMessage" type="string" required="false" default="">
		<cfargument name="required" type="boolean" required="false" default="false">
		<cfargument name="disabled" type="boolean" required="false" default="false">
		<cfargument name="checked" type="boolean" required="false" default="false" hint="For checkbox and switch types">
		<cfargument name="options" type="string" required="false" default="" hint="Comma-delimited value:label pairs for select, e.g. 'a:Option A,b:Option B'">
		<cfargument name="rows" type="numeric" required="false" default="4" hint="Rows for textarea">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.id = $uiBuildId(arguments.id, "fld")>
		<cfset local.hasError = Len(arguments.errorMessage)>
		<cfset local.isToggle = (arguments.type EQ "checkbox" OR arguments.type EQ "switch")>

		<!--- Build input attrs common to all types --->
		<cfset local.commonAttrs = 'id="#local.id#" name="#arguments.name#"'>
		<cfif arguments.required><cfset local.commonAttrs = local.commonAttrs & " required"></cfif>
		<cfif arguments.disabled><cfset local.commonAttrs = local.commonAttrs & " disabled"></cfif>

		<cfsavecontent variable="local.html">
			<cfoutput>
<cfif local.isToggle><div class="flex items-center gap-2">
<cfelse><div class="grid gap-2">
</cfif><cfif NOT local.isToggle><label for="#local.id#">#arguments.label#</label>
</cfif><cfif arguments.type EQ "textarea"><textarea #local.commonAttrs# class="textarea<cfif local.hasError> border-destructive</cfif>"<cfif Len(arguments.placeholder)> placeholder="#arguments.placeholder#"</cfif> rows="#arguments.rows#"<cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif>>#arguments.value#</textarea>
<cfelseif arguments.type EQ "select"><select #local.commonAttrs# class="select<cfif local.hasError> border-destructive</cfif>"<cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif>>
<cfif Len(arguments.options)><cfloop list="#arguments.options#" index="local.opt"><cfset local.optParts = ListToArray(local.opt, ":")><cfset local.optVal = local.optParts[1]><cfset local.optLabel = (ArrayLen(local.optParts) GT 1) ? local.optParts[2] : local.optParts[1]><option value="#local.optVal#"<cfif arguments.value EQ local.optVal> selected</cfif>>#local.optLabel#</option>
</cfloop></cfif></select>
<cfelseif arguments.type EQ "checkbox"><input type="checkbox" #local.commonAttrs# class="checkbox<cfif Len(arguments.class)> #arguments.class#</cfif>"<cfif arguments.checked> checked</cfif><cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif> />
<cfelseif arguments.type EQ "switch"><input type="checkbox" #local.commonAttrs# class="switch<cfif Len(arguments.class)> #arguments.class#</cfif>" role="switch"<cfif arguments.checked> checked</cfif><cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif> />
<cfelse><input type="#arguments.type#" #local.commonAttrs# class="input<cfif local.hasError> border-destructive</cfif>"<cfif Len(arguments.value)> value="#arguments.value#"</cfif><cfif Len(arguments.placeholder)> placeholder="#arguments.placeholder#"</cfif><cfif local.hasError> aria-invalid="true" aria-describedby="#local.id#-error"</cfif><cfif Len(arguments.class)> </cfif><cfif Len(arguments.class)>#arguments.class#</cfif> />
</cfif><cfif local.isToggle><label for="#local.id#">#arguments.label#</label>
</cfif><cfif Len(arguments.description) AND NOT local.hasError><p class="text-sm text-muted-foreground">#arguments.description#</p>
</cfif><cfif local.hasError><p id="#local.id#-error" class="text-sm text-destructive">#arguments.errorMessage#</p>
</cfif></div>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<!--- ============================================== --->
	<!--- TABLES                                         --->
	<!--- ============================================== --->

	<cffunction name="uiTable" access="public" output="false" returntype="string"
		hint="Opens a Basecoat table (table-container + table). Close with uiTableEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "table">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="table-container"><table class="#local.cls#">'>
	</cffunction>

	<cffunction name="uiTableHeader" access="public" output="false" returntype="string"
		hint="Opens the table thead and a tr. Close with uiTableHeaderEnd().">
		<cfreturn '<thead><tr>'>
	</cffunction>

	<cffunction name="uiTableHeaderEnd" access="public" output="false" returntype="string">
		<cfreturn '</tr></thead>'>
	</cffunction>

	<cffunction name="uiTableBody" access="public" output="false" returntype="string"
		hint="Opens the table tbody. Close with uiTableBodyEnd().">
		<cfreturn '<tbody>'>
	</cffunction>

	<cffunction name="uiTableBodyEnd" access="public" output="false" returntype="string">
		<cfreturn '</tbody>'>
	</cffunction>

	<cffunction name="uiTableRow" access="public" output="false" returntype="string"
		hint="Opens a table tr. Close with uiTableRowEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfif Len(arguments.class)>
			<cfreturn '<tr class="#arguments.class#">'>
		</cfif>
		<cfreturn '<tr>'>
	</cffunction>

	<cffunction name="uiTableRowEnd" access="public" output="false" returntype="string">
		<cfreturn '</tr>'>
	</cffunction>

	<cffunction name="uiTableHead" access="public" output="false" returntype="string"
		hint="Renders a th cell.">
		<cfargument name="text" type="string" required="false" default="">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfif Len(arguments.class)>
			<cfreturn '<th class="#arguments.class#">#arguments.text#</th>'>
		</cfif>
		<cfreturn '<th>#arguments.text#</th>'>
	</cffunction>

	<cffunction name="uiTableCell" access="public" output="false" returntype="string"
		hint="Renders a td cell.">
		<cfargument name="text" type="string" required="false" default="">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfif Len(arguments.class)>
			<cfreturn '<td class="#arguments.class#">#arguments.text#</td>'>
		</cfif>
		<cfreturn '<td>#arguments.text#</td>'>
	</cffunction>

	<cffunction name="uiTableEnd" access="public" output="false" returntype="string">
		<cfreturn '</table></div>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- TABS                                           --->
	<!--- ============================================== --->

	<cffunction name="uiTabs" access="public" output="false" returntype="string"
		hint="Opens a Basecoat tabs container. Close with uiTabsEnd().">
		<cfargument name="defaultTab" type="string" required="false" default="" hint="data-default value (ID of initial tab)">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "tabs">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfset local.dataDefault = Len(arguments.defaultTab) ? ' data-default="#arguments.defaultTab#"' : "">
		<cfreturn '<div class="#local.cls#"#local.dataDefault#>'>
	</cffunction>

	<cffunction name="uiTabList" access="public" output="false" returntype="string"
		hint="Opens the tabs-list container. Close with uiTabListEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "tabs-list">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#">'>
	</cffunction>

	<cffunction name="uiTabListEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<cffunction name="uiTabTrigger" access="public" output="false" returntype="string"
		hint="Renders a tab trigger button.">
		<cfargument name="value" type="string" required="true" hint="Matches the data-value of the corresponding uiTabContent">
		<cfargument name="text" type="string" required="true" hint="Button label">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "tabs-trigger">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<button class="#local.cls#" data-value="#arguments.value#">#arguments.text#</button>'>
	</cffunction>

	<cffunction name="uiTabContent" access="public" output="false" returntype="string"
		hint="Opens a tab content panel. Close with uiTabContentEnd().">
		<cfargument name="value" type="string" required="true" hint="Matches the data-value of the trigger button">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "tabs-content">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<div class="#local.cls#" data-value="#arguments.value#">'>
	</cffunction>

	<cffunction name="uiTabContentEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<cffunction name="uiTabsEnd" access="public" output="false" returntype="string">
		<cfreturn '</div>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- DROPDOWNS                                      --->
	<!--- ============================================== --->

	<cffunction name="uiDropdown" access="public" output="false" returntype="string"
		hint="Opens a CSS-only dropdown (details/summary). Close with uiDropdownEnd().">
		<cfargument name="text" type="string" required="true" hint="Trigger label text">
		<cfargument name="triggerClass" type="string" required="false" default="btn-outline" hint="CSS class for the summary element">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "dropdown">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<details class="#local.cls#"><summary class="#arguments.triggerClass#">#arguments.text#</summary><ul>'>
	</cffunction>

	<cffunction name="uiDropdownItem" access="public" output="false" returntype="string"
		hint="Renders a dropdown menu item.">
		<cfargument name="text" type="string" required="true">
		<cfargument name="href" type="string" required="false" default="#">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = Len(arguments.class) ? ' class="#arguments.class#"' : "">
		<cfreturn '<li><a href="#arguments.href#"#local.cls#>#arguments.text#</a></li>'>
	</cffunction>

	<cffunction name="uiDropdownSeparator" access="public" output="false" returntype="string"
		hint="Renders a separator line inside a dropdown.">
		<cfreturn '<li><hr class="separator" /></li>'>
	</cffunction>

	<cffunction name="uiDropdownEnd" access="public" output="false" returntype="string">
		<cfreturn '</ul></details>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- PAGINATION                                     --->
	<!--- ============================================== --->

	<cffunction name="uiPagination" access="public" output="false" returntype="string"
		hint="Renders a pagination nav with prev/next, page window, and ellipsis.">
		<cfargument name="currentPage" type="numeric" required="true">
		<cfargument name="totalPages" type="numeric" required="true">
		<cfargument name="baseUrl" type="string" required="true" hint="URL without page param, e.g. /posts">
		<cfargument name="pageParam" type="string" required="false" default="page">
		<cfargument name="windowSize" type="numeric" required="false" default="2" hint="Pages shown on each side of current page">
		<cfargument name="class" type="string" required="false" default="">

		<cfset var local = {}>
		<cfset local.cls = "pagination">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>

		<!--- URL builder helper --->
		<cfset local.sep = (Find("?", arguments.baseUrl) GT 0) ? "&" : "?">

		<cfset local.prevIcon = $uiLucideIcon("chevron-left", 16, 2)>
		<cfset local.nextIcon = $uiLucideIcon("chevron-right", 16, 2)>

		<cfsavecontent variable="local.html">
			<cfoutput>
<nav class="#local.cls#" aria-label="Pagination">
<cfif arguments.currentPage LTE 1><span class="pagination-item opacity-50" aria-disabled="true">#local.prevIcon#</span>
<cfelse><a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.currentPage - 1#" class="pagination-item" aria-label="Previous page">#local.prevIcon#</a>
</cfif><cfset local.windowStart = Max(1, arguments.currentPage - arguments.windowSize)><cfset local.windowEnd = Min(arguments.totalPages, arguments.currentPage + arguments.windowSize)><cfif local.windowStart GT 1><a href="#arguments.baseUrl##local.sep##arguments.pageParam#=1" class="pagination-item">1</a><cfif local.windowStart GT 2><span class="pagination-item" aria-hidden="true">&hellip;</span>
</cfif></cfif><cfloop from="#local.windowStart#" to="#local.windowEnd#" index="local.p"><cfif local.p EQ arguments.currentPage><span class="pagination-item pagination-item-active" aria-current="page">#local.p#</span>
<cfelse><a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#local.p#" class="pagination-item">#local.p#</a>
</cfif></cfloop><cfif local.windowEnd LT arguments.totalPages><cfif local.windowEnd LT arguments.totalPages - 1><span class="pagination-item" aria-hidden="true">&hellip;</span>
</cfif><a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.totalPages#" class="pagination-item">#arguments.totalPages#</a>
</cfif><cfif arguments.currentPage GTE arguments.totalPages><span class="pagination-item opacity-50" aria-disabled="true">#local.nextIcon#</span>
<cfelse><a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.currentPage + 1#" class="pagination-item" aria-label="Next page">#local.nextIcon#</a>
</cfif></nav>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<!--- ============================================== --->
	<!--- BREADCRUMB                                     --->
	<!--- ============================================== --->

	<cffunction name="uiBreadcrumb" access="public" output="false" returntype="string"
		hint="Opens a Basecoat breadcrumb nav. Close with uiBreadcrumbEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "breadcrumb">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<nav aria-label="Breadcrumb" class="#local.cls#"><ol>'>
	</cffunction>

	<cffunction name="uiBreadcrumbItem" access="public" output="false" returntype="string"
		hint="Renders a breadcrumb item. Omit href for the current (last) page.">
		<cfargument name="text" type="string" required="true">
		<cfargument name="href" type="string" required="false" default="" hint="If empty, renders as current-page span">
		<cfif Len(arguments.href)>
			<cfreturn '<li><a href="#arguments.href#">#arguments.text#</a></li>'>
		</cfif>
		<cfreturn '<li><span aria-current="page">#arguments.text#</span></li>'>
	</cffunction>

	<cffunction name="uiBreadcrumbSeparator" access="public" output="false" returntype="string"
		hint="Renders a breadcrumb separator (chevron-right icon).">
		<cfset var local = {}>
		<cfset local.icon = $uiLucideIcon("chevron-right", 14, 2)>
		<cfreturn '<li aria-hidden="true">#local.icon#</li>'>
	</cffunction>

	<cffunction name="uiBreadcrumbEnd" access="public" output="false" returntype="string">
		<cfreturn '</ol></nav>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- SIDEBAR                                        --->
	<!--- ============================================== --->

	<cffunction name="uiSidebar" access="public" output="false" returntype="string"
		hint="Opens a Basecoat sidebar (aside + nav). Close with uiSidebarEnd().">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "sidebar">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfreturn '<aside class="#local.cls#"><nav>'>
	</cffunction>

	<cffunction name="uiSidebarSection" access="public" output="false" returntype="string"
		hint="Opens a sidebar section with optional heading. Close with uiSidebarSectionEnd().">
		<cfargument name="title" type="string" required="false" default="" hint="Optional section heading">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "sidebar-section">
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfset local.heading = Len(arguments.title) ? '<h4>#arguments.title#</h4>' : "">
		<cfreturn '<div class="#local.cls#">#local.heading#<ul>'>
	</cffunction>

	<cffunction name="uiSidebarSectionEnd" access="public" output="false" returntype="string">
		<cfreturn '</ul></div>'>
	</cffunction>

	<cffunction name="uiSidebarItem" access="public" output="false" returntype="string"
		hint="Renders a sidebar navigation item.">
		<cfargument name="text" type="string" required="true">
		<cfargument name="href" type="string" required="false" default="#">
		<cfargument name="icon" type="string" required="false" default="" hint="Lucide icon name">
		<cfargument name="active" type="boolean" required="false" default="false">
		<cfargument name="class" type="string" required="false" default="">
		<cfset var local = {}>
		<cfset local.cls = "sidebar-item">
		<cfif arguments.active><cfset local.cls = local.cls & " sidebar-item-active"></cfif>
		<cfif Len(arguments.class)><cfset local.cls = local.cls & " " & arguments.class></cfif>
		<cfset local.iconHtml = Len(arguments.icon) ? $uiLucideIcon(arguments.icon, 16, 2) & " " : "">
		<cfreturn '<li><a href="#arguments.href#" class="#local.cls#">#local.iconHtml##arguments.text#</a></li>'>
	</cffunction>

	<cffunction name="uiSidebarEnd" access="public" output="false" returntype="string">
		<cfreturn '</nav></aside>'>
	</cffunction>

</cfcomponent>
