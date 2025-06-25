<cfcomponent>
	<cffunction name="init">
		<cfset this.version = "99.9.9">
		<cfreturn this>
	</cffunction>

	<cffunction name="URLFor" returntype="string">
		<cfset local.result = core.URLFor(argumentCollection = arguments)/>
		<cfset local.result &= Find("?", local.result) ? "&urlfor02" : "?urlfor02"/>
		<cfreturn local.result/>
	</cffunction>

	<cffunction name="onMissingMethod" returntype="any">
		<cfreturn core.onMissingMethod(argumentCollection = arguments)/>
	</cffunction>
</cfcomponent>
