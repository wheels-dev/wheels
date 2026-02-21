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
				<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 640 640" style="vertical-align: middle;">
					<circle cx="320" cy="320" r="256" fill="black"/>
					<path d="M188.7 308.7L292.7 204.7C297.3 200.1 304.2 198.8 310.1 201.2C316 203.6 320 209.5 320 216V272H416C433.7 272 448 286.3 448 304V336C448 353.7 433.7 368 416 368H320V424C320 430.5 316.1 436.3 310.1 438.8C304.1 441.3 297.2 439.9 292.7 435.3L188.7 331.3C182.5 325.1 182.5 314.9 188.7 308.7Z" fill="white"/>
				</svg>
				&nbsp; Back to Plugin List
			</a>
		</div>

		<cfif StructCount(meta.boxjson)>
			<cfif StructKeyExists(meta.boxjson, "homepage")>
				<a class="ui button small teal" href="#meta.boxjson.homepage#" target="_blank">
					<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="white" viewBox="0 0 24 24" style="vertical-align: middle;">
						<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
					</svg>
					<span style="position: relative; top: 2px;">www</span>
				</a>
			</cfif>
		</cfif>

		<div class="ui segment">
			<cfinclude template="/plugins/#LCase(request.wheels.params.name)#/index.cfm">
		</div>
	</div>
</cfoutput>
<cfinclude template="../layout/_footer.cfm">
