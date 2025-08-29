<cfscript>
formats = DirectoryList(ExpandPath("/wheels/public/tests"), false, "name", "", "name")
	.filter(function(name) {
		return !Find("_", arguments.name);
	}).map(function(name) {
		return ListFirst(arguments.name, ".");
	});

type = request.wheels.params.type;
_baseParams = "";
for (key in "reload,db,format,refresh") {
	if (StructKeyExists(url, key)) {
		_baseParams = ListAppend(_baseParams, "#key#=#url[key]#", "&");
	}
}
_params = _baseParams;
for (key in "package,test") {
	if (StructKeyExists(url, key)) {
		_params = ListAppend(_params, "#key#=#url[key]#", "&");
	}
}

subnavigation = [{route = "wheelsPackages", type = "app", text = '<svg xmlns="http://www.w3.org/2000/svg" height="13" width="13" viewBox="0 0 512 512"><path d="M152.1 38.2c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 113C-2.3 103.6-2.3 88.4 7 79s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zm0 160c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 273c-9.4-9.4-9.4-24.6 0-33.9s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zM224 96c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zm0 160c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zM160 416c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H192c-17.7 0-32-14.3-32-32zM48 368a48 48 0 1 1 0 96 48 48 0 1 1 0-96z"/></svg>&nbsp App'}];
if (DirectoryExists(ExpandPath("/wheels/tests"))) {
	ArrayAppend(subnavigation, {route = "wheelsPackages", type = "core", text = '<svg xmlns="http://www.w3.org/2000/svg" height="13" width="13" viewBox="0 0 512 512"><path d="M152.1 38.2c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 113C-2.3 103.6-2.3 88.4 7 79s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zm0 160c9.9 8.9 10.7 24 1.8 33.9l-72 80c-4.4 4.9-10.6 7.8-17.2 7.9s-12.9-2.4-17.6-7L7 273c-9.4-9.4-9.4-24.6 0-33.9s24.6-9.4 33.9 0l22.1 22.1 55.1-61.2c8.9-9.9 24-10.7 33.9-1.8zM224 96c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zm0 160c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H256c-17.7 0-32-14.3-32-32zM160 416c0-17.7 14.3-32 32-32H480c17.7 0 32 14.3 32 32s-14.3 32-32 32H192c-17.7 0-32-14.3-32-32zM48 368a48 48 0 1 1 0 96 48 48 0 1 1 0-96z"/></svg>&nbsp Core'});
}

pluginList = "";
if (application.wheels.enablePluginsComponent) {
	pluginList = StructKeyList(application.wheels.plugins);
}

// Get Plugins
for (p in pluginList) {
	ArrayAppend(subnavigation, {"route" = "wheelsPackages", "type" = p, "text" = '<svg xmlns="http://www.w3.org/2000/svg" height="14" width="10" viewBox="0 0 384 512"><path d="M96 0C78.3 0 64 14.3 64 32v96h64V32c0-17.7-14.3-32-32-32zM288 0c-17.7 0-32 14.3-32 32v96h64V32c0-17.7-14.3-32-32-32zM32 160c-17.7 0-32 14.3-32 32s14.3 32 32 32v32c0 77.4 55 142 128 156.8V480c0 17.7 14.3 32 32 32s32-14.3 32-32V412.8C297 398 352 333.4 352 256V224c17.7 0 32-14.3 32-32s-14.3-32-32-32H32z"/></svg>&nbsp; #p#'});
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfoutput>
	<div class="ui pointing stackable menu">
		<cfloop from="1" to="#ArrayLen(subnavigation)#" index="i">
			<cfscript>
			navArgs = {"route" = subnavigation[i]['route'], "text" = subnavigation[i]['text'], params = _baseParams};
			if (StructKeyExists(subnavigation[i], "type")) navArgs['type'] = subnavigation[i]['type'];
			</cfscript>
			<a href="#urlFor(argumentCollection = navArgs)#" class="item">#navArgs['text']#</a>
		</cfloop>
		<!--- Plugins --->
	</div>

	<div class="ui segment">
		<div class="ui grid">
			<div class="two column row">
				<div class="four wide column">
					<!--- Route Filter --->
					<div class="ui action input">
						<input
							type="text"
							class="table-searcher"
							name="package-search" id="package-search"
							placeholder="Quick find..."
						>
						<button class="ui icon button matched-count">
							<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path  fill="##7e7e7f" d="M505 442.7L405.3 343c-4.5-4.5-10.6-7-17-7H372c27.6-35.3 44-79.7 44-128C416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c48.3 0 92.7-16.4 128-44v16.3c0 6.4 2.5 12.5 7 17l99.7 99.7c9.4 9.4 24.6 9.4 33.9 0l28.3-28.3c9.4-9.4 9.4-24.6 .1-34zM208 336c-70.7 0-128-57.2-128-128 0-70.7 57.2-128 128-128 70.7 0 128 57.2 128 128 0 70.7-57.2 128-128 128z"/></svg>
							<span class="matched-count-value"></span>
						</button>
					</div>
				</div>
				<div class="twelve wide column right aligned">
					<cfif StructKeyExists(url, "refresh")>
						<a href="#urlFor(route = "wheelsTests", type = type, params = ReplaceNoCase(_params, "refresh=#url.refresh#", ""))#" class="ui button blue active">
							Stop &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path fill="##4d9dd9" d="M0 128C0 92.7 28.7 64 64 64H320c35.3 0 64 28.7 64 64V384c0 35.3-28.7 64-64 64H64c-35.3 0-64-28.7-64-64V128z"/></svg>
						</a>
					<cfelse>
						<a href="#urlFor(route = "wheelsTests", type = type, params = "#_params#&refresh=true")#" class="ui button basic blue">
							Refresh &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="12" viewBox="0 0 384 512"><path fill="##4d9dd9" d="M73 39c-14.8-9.1-33.4-9.4-48.5-.9S0 62.6 0 80V432c0 17.4 9.4 33.4 24.5 41.9s33.7 8.1 48.5-.9L361 297c14.3-8.7 23-24.2 23-41s-8.7-32.2-23-41L73 39z"/></svg>
						</a>
					</cfif>
					<cfif StructKeyExists(url, "reload")>
						<a href="#urlFor(route = "wheelsTests", params = ReplaceNoCase(_params, "reload=#url.reload#", ""), type = type)#" class="ui button blue">
							Without Reload &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path fill="##4d9dd9" d="M142.9 142.9c62.2-62.2 162.7-62.5 225.3-1L327 183c-6.9 6.9-8.9 17.2-5.2 26.2s12.5 14.8 22.2 14.8H463.5c0 0 0 0 0 0H472c13.3 0 24-10.7 24-24V72c0-9.7-5.8-18.5-14.8-22.2s-19.3-1.7-26.2 5.2L413.4 96.6c-87.6-86.5-228.7-86.2-315.8 1C73.2 122 55.6 150.7 44.8 181.4c-5.9 16.7 2.9 34.9 19.5 40.8s34.9-2.9 40.8-19.5c7.7-21.8 20.2-42.3 37.8-59.8zM16 312v7.6 .7V440c0 9.7 5.8 18.5 14.8 22.2s19.3 1.7 26.2-5.2l41.6-41.6c87.6 86.5 228.7 86.2 315.8-1c24.4-24.4 42.1-53.1 52.9-83.7c5.9-16.7-2.9-34.9-19.5-40.8s-34.9 2.9-40.8 19.5c-7.7 21.8-20.2 42.3-37.8 59.8c-62.2 62.2-162.7 62.5-225.3 1L185 329c6.9-6.9 8.9-17.2 5.2-26.2s-12.5-14.8-22.2-14.8H48.4h-.7H40c-13.3 0-24 10.7-24 24z"/></svg>
						</a>
					<cfelse>
						<a href="#urlFor(route = "wheelsTests", params = "#_params#&reload=true", type = type)#" class="ui button basic blue">
							Reload &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path fill="##4d9dd9" d="M142.9 142.9c62.2-62.2 162.7-62.5 225.3-1L327 183c-6.9 6.9-8.9 17.2-5.2 26.2s12.5 14.8 22.2 14.8H463.5c0 0 0 0 0 0H472c13.3 0 24-10.7 24-24V72c0-9.7-5.8-18.5-14.8-22.2s-19.3-1.7-26.2 5.2L413.4 96.6c-87.6-86.5-228.7-86.2-315.8 1C73.2 122 55.6 150.7 44.8 181.4c-5.9 16.7 2.9 34.9 19.5 40.8s34.9-2.9 40.8-19.5c7.7-21.8 20.2-42.3 37.8-59.8zM16 312v7.6 .7V440c0 9.7 5.8 18.5 14.8 22.2s19.3 1.7 26.2-5.2l41.6-41.6c87.6 86.5 228.7 86.2 315.8-1c24.4-24.4 42.1-53.1 52.9-83.7c5.9-16.7-2.9-34.9-19.5-40.8s-34.9 2.9-40.8 19.5c-7.7 21.8-20.2 42.3-37.8 59.8c-62.2 62.2-162.7 62.5-225.3 1L185 329c6.9-6.9 8.9-17.2 5.2-26.2s-12.5-14.8-22.2-14.8H48.4h-.7H40c-13.3 0-24 10.7-24 24z"/></svg>
						</a>
					</cfif>
					<a href="#urlFor(route = "wheelsTests", type = type, params = _params)#" class="ui button basic blue">
						Run All Tests &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="14" viewBox="0 0 448 512"><path  fill="##4d9dd9" d="M438.6 278.6c12.5-12.5 12.5-32.8 0-45.3l-160-160c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L338.8 224 32 224c-17.7 0-32 14.3-32 32s14.3 32 32 32l306.7 0L233.4 393.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l160-160z"/></svg>
					</a>
					<cfloop array="#formats#" index="_format">
						<cfif StructKeyExists(url, "format")>
							<cfset __params = ReplaceNoCase(_params, "format=#url.format#", "format=#_format#")>
						<cfelse>
							<cfset __params = ListAppend(_params, "format=#_format#", "&")>
						</cfif>
						<a href="#urlFor(route = "wheelsTests", type = type, params = __params)#" class="ui button basic<cfif _format eq "html"> active</cfif>">
							#_format#
						</a>
					</cfloop>
				</div>
			</div>
		</div>
	</div>
</cfoutput>
<!--- cfformat-ignore-end --->
