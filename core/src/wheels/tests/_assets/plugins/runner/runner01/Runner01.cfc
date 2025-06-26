<cfcomponent>
	<cffunction name="init">
		<cfset this.version = "99.9.9">
		<cfreturn this>
	</cffunction>

	<cffunction name="URLFor" returntype="string">
		<cfset local.result = core.URLFor(argumentCollection = arguments)/>
		<cfset local.result &= Find("?", local.result) ? "&urlfor01" : "?urlfor01"/>
		<cfreturn local.result/>
	</cffunction>

	<cffunction name="onMissingMethod" returntype="any">
		<cfreturn core.onMissingMethod(argumentCollection = arguments)/>
	</cffunction>

	<cffunction name="$$pluginOnlyMethod" returntype="string">
		<cfreturn "$$returnValue"/>
	</cffunction>

	<cffunction name="singularize" returntype="string">
		<cfreturn "$$completelyOverridden"/>
	</cffunction>

	<cffunction name="pluralize" returntype="string">
		<cfset corePluralize = core.pluralize/>
		<cfreturn corePluralize(argumentCollection = arguments)/>
	</cffunction>

	<cffunction name="$helper01">
		<cfreturn $helper011()/>
	</cffunction>

	<cffunction name="$helper01ConditionalCheck">
		<cfreturn false/>
	</cffunction>

	<cffunction name="$helper011">
		<cfreturn "$helper011Responding"/>
	</cffunction>

	<cffunction name="includePartial">
		<cfreturn core.includePartial(argumentCollection = arguments)/>
	</cffunction>
</cfcomponent>
