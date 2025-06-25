<cfcomponent>
	<cffunction name="init">
		<cfset this.version = "99.9.9">
		<cfreturn this>
	</cffunction>

	<cffunction name="$MixinForControllers" mixin="controller" returntype="void"></cffunction>

	<cffunction name="$MixinForModels" mixin="model" returntype="void"></cffunction>

	<cffunction name="$MixinForModelsAndContollers" mixin="model,controller" returntype="void"></cffunction>

	<cffunction name="$MixinForDispatch" mixin="dispatch" returntype="void"></cffunction>
</cfcomponent>
