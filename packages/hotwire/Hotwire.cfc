<cfcomponent output="false" mixin="controller,view">

	<!---
	==============================================
	wheels-hotwire Plugin
	Hotwire infrastructure: Turbo Drive, Turbo Frames,
	Turbo Streams, Stimulus, and Hotwire Native.
	No CSS opinions — pair with wheels-basecoat or any design system.
	==============================================
	--->

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "3.0">
		<cfreturn this>
	</cffunction>

	<!--- ============================================== --->
	<!--- INCLUDES                                       --->
	<!--- ============================================== --->

	<cffunction name="hotwireIncludes" access="public" output="false" returntype="string"
		hint="Outputs Turbo and Stimulus script tags for the layout <head>. Does not include any CSS.">
		<cfargument name="turbo" type="boolean" required="false" default="true">
		<cfargument name="stimulus" type="boolean" required="false" default="true">
		<cfargument name="turboVersion" type="string" required="false" default="8">
		<cfargument name="stimulusVersion" type="string" required="false" default="3">
		<cfargument name="turboCacheControl" type="string" required="false" default="no-preview"
			hint="Turbo cache control: no-preview, no-cache, or empty string to omit">

		<cfset var local = {}>
		<cfsavecontent variable="local.html">
			<cfoutput>
<cfif Len(arguments.turboCacheControl)><meta name="turbo-cache-control" content="#arguments.turboCacheControl#">
</cfif><cfif arguments.turbo><script type="module">import * as Turbo from "https://cdn.jsdelivr.net/npm/@hotwired/turbo@#arguments.turboVersion#/+esm";</script>
</cfif><cfif arguments.stimulus><script type="module">import { Application } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@#arguments.stimulusVersion#/+esm"; window.Stimulus = Application.start();</script>
</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(local.html)>
	</cffunction>

	<!--- ============================================== --->
	<!--- REQUEST DETECTION                              --->
	<!--- ============================================== --->

	<cffunction name="isHotwireRequest" access="public" output="false" returntype="boolean"
		hint="Returns true if the current request accepts Turbo Stream responses (checks Accept header).">
		<cfset var local = {}>
		<cftry>
			<cfset local.accept = getHTTPRequestData().headers["Accept"]>
			<cfreturn FindNoCase("text/vnd.turbo-stream.html", local.accept) GT 0>
			<cfcatch><cfreturn false></cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="isTurboFrameRequest" access="public" output="false" returntype="boolean"
		hint="Returns true if the current request was initiated by a Turbo Frame (checks Turbo-Frame header).">
		<cftry>
			<cfreturn StructKeyExists(getHTTPRequestData().headers, "Turbo-Frame")>
			<cfcatch><cfreturn false></cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="turboFrameRequestId" access="public" output="false" returntype="string"
		hint="Returns the requesting Turbo Frame ID, or empty string if not a frame request.">
		<cfset var local = {}>
		<cftry>
			<cfset local.headers = getHTTPRequestData().headers>
			<cfif StructKeyExists(local.headers, "Turbo-Frame")>
				<cfreturn local.headers["Turbo-Frame"]>
			</cfif>
			<cfcatch></cfcatch>
		</cftry>
		<cfreturn "">
	</cffunction>

	<cffunction name="hotwireNativeApp" access="public" output="false" returntype="boolean"
		hint="Returns true if the request comes from a Hotwire Native iOS/Android app (checks User-Agent for 'Turbo Native').">
		<cftry>
			<cfreturn FindNoCase("Turbo Native", getHTTPRequestData().headers["User-Agent"]) GT 0>
			<cfcatch><cfreturn false></cfcatch>
		</cftry>
	</cffunction>

	<!--- ============================================== --->
	<!--- TURBO FRAMES                                   --->
	<!--- ============================================== --->

	<cffunction name="turboFrame" access="public" output="false" returntype="string"
		hint="Opens a <turbo-frame> tag. Close with turboFrameEnd().">
		<cfargument name="id" type="string" required="true" hint="Unique frame identifier">
		<cfargument name="src" type="string" required="false" default="" hint="URL to lazy-load content from">
		<cfargument name="loading" type="string" required="false" default="" hint="'lazy' for deferred loading, '' for eager (default)">
		<cfargument name="target" type="string" required="false" default="" hint="'_top' to break out of frame, or another frame ID">
		<cfargument name="autoscroll" type="boolean" required="false" default="false" hint="Auto-scroll to frame after update">
		<cfargument name="class" type="string" required="false" default="">
		<cfargument name="disabled" type="boolean" required="false" default="false" hint="Disable frame navigation">

		<cfset var local = {}>
		<cfset local.attrs = 'id="#arguments.id#"'>

		<cfif Len(arguments.src)><cfset local.attrs = local.attrs & ' src="#arguments.src#"'></cfif>
		<cfif Len(arguments.loading)><cfset local.attrs = local.attrs & ' loading="#arguments.loading#"'></cfif>
		<cfif Len(arguments.target)><cfset local.attrs = local.attrs & ' target="#arguments.target#"'></cfif>
		<cfif arguments.autoscroll><cfset local.attrs = local.attrs & ' autoscroll'></cfif>
		<cfif arguments.disabled><cfset local.attrs = local.attrs & ' disabled'></cfif>
		<cfif Len(arguments.class)><cfset local.attrs = local.attrs & ' class="#arguments.class#"'></cfif>

		<cfreturn '<turbo-frame #local.attrs#>'>
	</cffunction>

	<cffunction name="turboFrameEnd" access="public" output="false" returntype="string"
		hint="Closes a </turbo-frame> tag.">
		<cfreturn '</turbo-frame>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- TURBO STREAMS                                  --->
	<!--- ============================================== --->

	<cffunction name="turboStreamAppend" access="public" output="false" returntype="string"
		hint="Turbo Stream: append content as the last child of the target element.">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("append", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamPrepend" access="public" output="false" returntype="string"
		hint="Turbo Stream: prepend content as the first child of the target element.">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("prepend", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamReplace" access="public" output="false" returntype="string"
		hint="Turbo Stream: replace the entire target element with new content.">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("replace", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamUpdate" access="public" output="false" returntype="string"
		hint="Turbo Stream: update the inner HTML of the target element (keeps the element itself).">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("update", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamRemove" access="public" output="false" returntype="string"
		hint="Turbo Stream: remove the target element from the DOM.">
		<cfargument name="target" type="string" required="true">
		<cfreturn '<turbo-stream action="remove" target="#arguments.target#"></turbo-stream>'>
	</cffunction>

	<cffunction name="turboStreamBefore" access="public" output="false" returntype="string"
		hint="Turbo Stream: insert content before the target element.">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("before", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamAfter" access="public" output="false" returntype="string"
		hint="Turbo Stream: insert content after the target element.">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn $turboStreamAction("after", arguments.target, arguments.content)>
	</cffunction>

	<cffunction name="turboStreamRefresh" access="public" output="false" returntype="string"
		hint="Turbo Stream: trigger a full page refresh via morph.">
		<cfreturn '<turbo-stream action="refresh"></turbo-stream>'>
	</cffunction>

	<cffunction name="renderTurboStream" access="public" output="false" returntype="void"
		hint="Controller helper: sends a Turbo Stream response. Pass a single stream string or an array of stream strings.">
		<cfargument name="streams" type="any" required="true"
			hint="A single turboStream*() string, or an array of them">

		<cfset var local = {}>

		<!--- Normalize to array --->
		<cfif IsSimpleValue(arguments.streams)>
			<cfset local.streamArray = [arguments.streams]>
		<cfelse>
			<cfset local.streamArray = arguments.streams>
		</cfif>

		<cfset local.body = ArrayToList(local.streamArray, Chr(10))>

		<cfcontent type="text/vnd.turbo-stream.html" reset="true">
		<cfoutput>#local.body#</cfoutput>
		<cfabort>
	</cffunction>

	<!--- Private: builds a turbo-stream element with template wrapper --->
	<cffunction name="$turboStreamAction" access="private" output="false" returntype="string">
		<cfargument name="action" type="string" required="true">
		<cfargument name="target" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cfreturn '<turbo-stream action="#arguments.action#" target="#arguments.target#"><template>#arguments.content#</template></turbo-stream>'>
	</cffunction>

	<!--- ============================================== --->
	<!--- HOTWIRE NATIVE NAVIGATION                     --->
	<!--- ============================================== --->

	<cffunction name="recedeOrRedirectTo" access="public" output="false" returntype="void"
		hint="Hotwire Native: pops/dismisses current screen. Web: normal redirect. Pass standard Wheels redirectTo() arguments.">
		<cfargument name="route" type="string" required="false" default="">
		<cfargument name="controller" type="string" required="false" default="">
		<cfargument name="action" type="string" required="false" default="">
		<cfargument name="key" type="string" required="false" default="">
		<cfif hotwireNativeApp()>
			<cfheader statuscode="303">
			<cfheader name="Location" value="/hotwire/native/recede">
			<cfabort>
		<cfelse>
			<cfset redirectTo(argumentCollection=arguments)>
		</cfif>
	</cffunction>

	<cffunction name="refreshOrRedirectTo" access="public" output="false" returntype="void"
		hint="Hotwire Native: refreshes current screen. Web: normal redirect.">
		<cfargument name="route" type="string" required="false" default="">
		<cfargument name="controller" type="string" required="false" default="">
		<cfargument name="action" type="string" required="false" default="">
		<cfargument name="key" type="string" required="false" default="">
		<cfif hotwireNativeApp()>
			<cfheader statuscode="303">
			<cfheader name="Location" value="/hotwire/native/refresh">
			<cfabort>
		<cfelse>
			<cfset redirectTo(argumentCollection=arguments)>
		</cfif>
	</cffunction>

	<cffunction name="resumeOrRedirectTo" access="public" output="false" returntype="void"
		hint="Hotwire Native: resumes with no action. Web: normal redirect.">
		<cfargument name="route" type="string" required="false" default="">
		<cfargument name="controller" type="string" required="false" default="">
		<cfargument name="action" type="string" required="false" default="">
		<cfargument name="key" type="string" required="false" default="">
		<cfif hotwireNativeApp()>
			<cfheader statuscode="303">
			<cfheader name="Location" value="/hotwire/native/resume">
			<cfabort>
		<cfelse>
			<cfset redirectTo(argumentCollection=arguments)>
		</cfif>
	</cffunction>

	<!--- Serves Hotwire Native path configuration as JSON response --->
	<cffunction name="hotwireNativePathConfiguration" access="public" returntype="void" output="true"
		hint="Renders JSON path configuration for Hotwire Native apps">
		<cfargument name="settings" type="struct" required="false" default="#StructNew()#"
			hint="Settings object (tabs, etc.)">
		<cfargument name="rules" type="array" required="false" default="#ArrayNew(1)#"
			hint="Array of rule structs with patterns and properties">

		<cfset var local = {}>
		<cfset local.config = {}>

		<cfif NOT StructIsEmpty(arguments.settings)>
			<cfset local.config["settings"] = arguments.settings>
		</cfif>

		<cfif ArrayLen(arguments.rules) GT 0>
			<cfset local.config["rules"] = arguments.rules>
		<cfelse>
			<!--- Default rules: all pages default context, /new and /edit open as modals --->
			<cfset local.config["rules"] = [
				{
					"patterns": [".*"],
					"properties": {"context": "default", "pull_to_refresh_enabled": true}
				},
				{
					"patterns": ["/new$", "/edit$"],
					"properties": {"context": "modal", "pull_to_refresh_enabled": false}
				}
			]>
		</cfif>

		<cfcontent type="application/json" reset="true">
		<cfoutput>#SerializeJSON(local.config)#</cfoutput>
		<cfabort>
	</cffunction>

	<!--- ============================================== --->
	<!--- STIMULUS CONVENIENCE HELPERS                   --->
	<!--- ============================================== --->

	<cffunction name="stimulusController" access="public" output="false" returntype="string"
		hint="Generates a data-controller attribute value. Pass one or more controller names.">
		<cfargument name="controllers" type="string" required="true"
			hint="Space-separated controller names, e.g. 'toggle clipboard'">
		<cfreturn 'data-controller="#Trim(arguments.controllers)#"'>
	</cffunction>

	<cffunction name="stimulusAction" access="public" output="false" returntype="string"
		hint="Generates a data-action attribute value. Pass one or more action descriptors.">
		<cfargument name="actions" type="string" required="true"
			hint="Space-separated action descriptors, e.g. 'click->toggle##switch keydown.esc->modal##close'">
		<cfreturn 'data-action="#Trim(arguments.actions)#"'>
	</cffunction>

	<cffunction name="stimulusTarget" access="public" output="false" returntype="string"
		hint="Generates a data-{controller}-target attribute.">
		<cfargument name="controller" type="string" required="true" hint="Controller name, e.g. 'toggle'">
		<cfargument name="name" type="string" required="true" hint="Target name, e.g. 'content'">
		<cfreturn 'data-#arguments.controller#-target="#arguments.name#"'>
	</cffunction>

	<cffunction name="stimulusValue" access="public" output="false" returntype="string"
		hint="Generates a data-{controller}-{name}-value attribute.">
		<cfargument name="controller" type="string" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="value" type="string" required="true">
		<cfreturn 'data-#arguments.controller#-#arguments.name#-value="#arguments.value#"'>
	</cffunction>

</cfcomponent>
