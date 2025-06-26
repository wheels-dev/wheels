<cfscript>
param name="request.wheels.params.name";

if (!application.wheels.enablePluginsComponent)
	Throw(type = "wheels.plugins", message = "The Wheels Plugin component is disabled...");

meta = $get("pluginMeta")[request.wheels.params.name];
</cfscript>
<cfinclude template="../layout/_header.cfm">
<cfoutput>
	<div class="ui container">
		#pageHeader("Plugins", "What you've got loaded..")#

		<div class="ui menu">
			<a href="#urlFor(route = "wheelsPlugins")#" class="item">
				<i class="arrow alternate circle left icon"></i>
				Back to Plugin List
			</a>
		</div>

		<cfif StructCount(meta.boxjson)>
			<cfif StructKeyExists(meta.boxjson, "homepage")>
				<a class="ui button small teal" href="#meta.boxjson.homepage#" target="_blank">
					<i class="icon home"></i>
					www
				</a>
			</cfif>
		</cfif>

		<div class="ui segment">
			<cfinclude template="/app/plugins/#LCase(request.wheels.params.name)#/index.cfm">
		</div>
	</div>
</cfoutput>
<cfinclude template="../layout/_footer.cfm">
