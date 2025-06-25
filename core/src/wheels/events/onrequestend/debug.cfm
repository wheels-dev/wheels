<cfset local.baseReloadURL = cgi.script_name>
<cfif IsDefined("request.cgi.path_info")>
	<cfif request.cgi.path_info IS NOT cgi.script_name>
		<cfset local.baseReloadURL &= request.cgi.path_info>
	</cfif>
<cfelse>
	<cfif cgi.path_info IS NOT cgi.script_name>
		<cfset local.baseReloadURL &= cgi.path_info>
	</cfif>
</cfif>
<cfif Len(cgi.query_string)>
	<cfset local.baseReloadURL &= "?" & cgi.query_string>
</cfif>
<cfset local.baseReloadURL = ReplaceNoCase(local.baseReloadURL, "/" & application.wheels.rewriteFile, "")>
<cfloop list="development,testing,maintenance,production,true" index="local.i">
	<cfset local.baseReloadURL = ReplaceNoCase(
		ReplaceNoCase(local.baseReloadURL, "?reload=" & local.i, ""),
		"&reload=" & local.i,
		""
	)>
</cfloop>
<cfif local.baseReloadURL Contains "?">
	<cfset local.baseReloadURL &= "&">
<cfelse>
	<cfset local.baseReloadURL &= "?">
</cfif>
<cfset local.baseReloadURL &= "reload=">
<cfset local.frameworkTestDir = GetDirectoryFromPath(GetBaseTemplatePath()) & "wheels/tests">
<cfset local.hasFrameworkTests = DirectoryExists(local.frameworkTestDir)>
<cfset local.hasFrameworkBuildFile = FileExists(GetDirectoryFromPath(GetBaseTemplatePath()) & "wheels/public/build.cfm")>
<cfset local.appTestDir = GetDirectoryFromPath(GetBaseTemplatePath()) & "tests">
<cfset local.hasAppTests = DirectoryExists(local.appTestDir)>
<cfset local.gitbranch = DirectoryExists(GetDirectoryFromPath(GetBaseTemplatePath()) & ".git") ? FileRead(GetDirectoryFromPath(GetBaseTemplatePath()) & ".git/HEAD") : "">

<cfif local.hasAppTests>
	<cfdirectory action="list" directory="#local.appTestDir#" name="local.tests">
	<cfif NOT local.tests.recordCount>
		<cfset local.hasAppTests = false>
	</cfif>
</cfif>
<!--- cfformat-ignore-start --->
<cfsavecontent variable="local.css">
	<style>#wheels-debug-area {
		background: #ececec;
		border-bottom: 3px solid #999;
		border-top: 3px solid #999;
		clear: both;
		margin: 50px 0;
		padding: 10px;
		text-align: left;
		}
		#wheels-debug-area table {
		border-collapse: collapse;
		border-spacing: 0;
		}
		#wheels-debug-area td {
		color: #333;
		font-family: Arial, Helvetica, sans-serif;
		font-size: 12px;
		line-height: 1.5em;
		padding: 0 10px 0 0;
		vertical-align: top;
		border-bottom: none;
		}
		#wheels-debug-area th {
		border-bottom: none;
		}
		#wheels-debug-area a {
		color: #333;
		padding: 0 1px;
		text-decoration: underline;
		}
		#wheels-debug-area a.btn {
		background-color: #f5f5f5;
		padding:5px 10px;
		margin-right:5px;
		}
		#wheels-debug-area a:hover {
		background: #333;
		color: #fff;
		text-decoration: none;
		}
		#wheels-debug-area a.btn:hover {
		background-color: #999;
		padding:5px 10px;
		margin-right:5px;
		}</style>
</cfsavecontent>
<cfset $htmlhead(text = local.css)>
<cfoutput>
	<div id="wheels-debug-area">
		<cfif $get("enablePublicComponent")>
			<table>
				<tr>
					<td>
						<a href="#urlFor(route = "wheelsInfo")#" class="btn" target="_blank">Info</a>
					</td>
					<td>
						<a href="#urlFor(route = "wheelsRoutes")#" class="btn" target="_blank">Routes</a>
					</td>
					<td>
						<a href="#urlFor(route = "wheelsDocs")#" class="btn" target="_blank">Docs</a>
					</td>
					<td>
						<a href="#urlFor(route = "wheelsPackages", type = "app")#" class="btn" target="_blank">Tests</a>
					</td>
					<cfif $get("enableMigratorComponent")>
						<td>
							<a href="#urlFor(route = "wheelsMigrator")#" class="btn" target="_blank">Migrator</a>
						</td>
					</cfif>
					<cfif $get("enablePluginsComponent")>
						<td>
							<a href="#urlFor(route = "wheelsPlugins")#" class="btn" target="_blank">Plugins</a>
						</td>
					</cfif>
				</tr>
			</table>
			<hr>
		</cfif>
		<table>
			<cfif $get("enablePluginsComponent")>
				<cfif ($get("showIncompatiblePlugins") AND Len(application.wheels.incompatiblePlugins))
				OR Len(application.wheels.dependantPlugins)>
					<tr>
						<td>
							<strong>
								<span style="color:red;">Warnings:</span>
							</strong>
						</td>
						<td>
							<span style="color:red;">
								<cfif $get("showIncompatiblePlugins") AND Len(application.wheels.incompatiblePlugins)>
									<cfloop list="#application.wheels.incompatiblePlugins#" index="local.i">
										The #local.i# plugin may be incompatible with this version of Wheels, please look for a compatible version of the plugin<br>
									</cfloop>
								</cfif>
								<cfif Len(application.wheels.dependantPlugins)>
									<cfloop list="#application.wheels.dependantPlugins#" index="local.i">
										<cfset needs = ListLast(local.i, "|")>The #ListFirst(local.i, "|")# plugin needs the following plugin<cfif ListLen(
											needs
										) GT 1>s</cfif>
										to work properly: #needs#<br>
									</cfloop>
								</cfif>
							</span>
						</td>
					</tr>
				</cfif>
			</cfif>
			<cfif Len(local.gitbranch)>
			<tr>
				<td>
					<strong>Git Branch:</strong>
				</td>
				<td>#local.gitbranch#</td>
			</tr>
			</cfif>
			<tr>
				<td>
					<strong>Application:</strong>
				</td>
				<td>
					#application.applicationName#
					<cfif NOT Len($get("reloadPassword"))>
						[<a href="#local.baseReloadURL#true">Reload</a>
						]
					</cfif>
				</td>
			</tr>
			<tr>
				<td>
					<strong>Framework:</strong>
				</td>
				<td>
					<a href="https://cfwheels.org/" target="_blank">CFWheels</a>
					#$get("version")#
				</td>
			</tr>
			<tr>
				<td>
					<strong>Environment:</strong>
				</td>
				<td>
					#capitalize($get("environment"))#<cfif NOT Len($get("reloadPassword"))>
						<cfset local.environments = "development,testing,maintenance,production">
						[
						<cfset local.pos = 0>
						<cfloop list="#local.environments#" index="local.i">
							<cfset local.pos = local.pos + 1>
							<cfif $get("environment") IS NOT local.i>
								<a href="#local.baseReloadURL##local.i#">#capitalize(local.i)#</a>
								<cfif ListLen(local.environments) GT local.pos>,</cfif>
							</cfif>
						</cfloop>
						]
					</cfif>
				</td>
			</tr>
			<cfif StructKeyExists(application.wheels, "hostName")>
				<tr>
					<td>
						<strong>Host Name:</strong>
					</td>
					<td>#$get("hostName")#</td>
				</tr>
			</cfif>
			<tr>
				<td>
					<strong>CFML Engine:</strong>
				</td>
				<td>#$get("serverName")##$get("serverVersion")#</td>
			</tr>
			<tr>
				<td>
					<strong>Data Source:</strong>
				</td>
				<td>#capitalize($get("dataSourceName"))#</td>
			</tr>
			<cfif StructKeyExists(application.wheels, "adapterName")>
				<tr>
					<td>
						<strong>Database Adapter:</strong>
					</td>
					<td>#$get("adapterName")#</td>
				</tr>
			</cfif>
			<tr>
				<td>
					<strong>URL Rewriting:</strong>
				</td>
				<td>#capitalize($get("URLRewriting"))#</td>
			</tr>
			<tr>
				<td>
					<strong>URL Obfuscation:</strong>
				</td>
				<td>
					<cfif $get("obfuscateUrls")>
						On<cfelse>Off
					</cfif>
				</td>
			</tr>
			<cfif $get("enablePluginsComponent")>
				<tr>
					<td>
						<strong>Plugins:</strong>
					</td>
					<td>
						<cfif StructCount($get("plugins")) IS NOT 0>
							<cfset local.count = 0>
							<cfloop collection="#$get('plugins')#" item="local.i">
								<cfset local.count = local.count + 1>
								<a
									href="#$get('webPath')##ListLast(request.cgi.script_name, '/')#?controller=wheels&action=wheels&view=plugins&name=#local.i#"
								>
									#local.i#
									<cfif StructCount($get("pluginMeta")) IS NOT 0 && StructKeyExists($get("pluginMeta"), local.i)>
										#$get("pluginMeta")[local.i]['version']#
									</cfif>
								</a>
								<cfif DirectoryExists("#GetDirectoryFromPath(GetBaseTemplatePath())#plugins/#LCase(local.i)#/tests")>
									[
									<a
										href="#$get('webPath')##ListLast(request.cgi.script_name, '/')#?controller=wheels&action=wheels&view=tests&type=#LCase(local.i)#"
									>Run Tests</a>
									,
									<a
										href="#$get('webPath')##ListLast(request.cgi.script_name, '/')#?controller=wheels&action=wheels&view=packages&type=#LCase(local.i)#"
									>View Tests</a>
									]
								</cfif>
								<cfif StructCount($get("plugins")) GT local.count>
									<br/>
								</cfif>
							</cfloop>
						<cfelse>
							None
						</cfif>
					</td>
				</tr>
			</cfif>
			<cfif StructKeyExists(request.wheels.params, "route")>
				<tr>
					<td>
						<strong>Route:</strong>
					</td>
					<td>#capitalize(request.wheels.params.route)#</td>
				</tr>
			</cfif>
			<tr>
				<td>
					<strong>Controller:</strong>
				</td>
				<td>#capitalize(request.wheels.params.controller)#</td>
			</tr>
			<tr>
				<td>
					<strong>Action:</strong>
				</td>
				<td>#capitalize(request.wheels.params.action)#</td>
			</tr>
			<cfif StructKeyExists(request.wheels.params, "key")>
				<tr>
					<td>
						<strong>Key(s):</strong>
					</td>
					<td>#request.wheels.params.key#</td>
				</tr>
			</cfif>
			<tr>
				<td>
					<strong>Parameters:</strong>
				</td>
				<td>
					<cfset local.additionalParamsExists = false>
					<cfloop collection="#request.wheels.params#" item="local.i">
						<cfif local.i IS NOT "fieldnames"
						AND local.i IS NOT "route"
						AND local.i IS NOT "controller"
						AND local.i IS NOT "action"
						AND local.i IS NOT "key">
							<cfset local.additionalParamsExists = true>
							<cfif IsStruct(request.wheels.params[local.i])>
								#LCase(local.i)# = #SerializeJSON(request.wheels.params[local.i])#<br>
							<cfelseif IsArray(request.wheels.params[local.i])>
								#LCase(local.i)# = #SerializeJSON(request.wheels.params[local.i])#<br>
							<cfelseif IsSimpleValue(request.wheels.params[local.i])>
								#LCase(local.i)# = #request.wheels.params[local.i]#<br>
							</cfif>
						</cfif>
					</cfloop>
					<cfif NOT local.additionalParamsExists>None</cfif>
				</td>
			</tr>
			<tr>
				<td>
					<strong>Execution Time:</strong>
				</td>
				<td>
					#request.wheels.execution.total#ms<cfif request.wheels.execution.total GT 0>
						(
						<cfset local.keys = StructSort(request.wheels.execution, "numeric", "desc")>
						<cfset local.firstDone = false>
						<cfloop from="1" to="#ArrayLen(local.keys)#" index="local.i">
							<cfset local.key = local.keys[local.i]>
							<cfif local.key IS NOT "total" AND request.wheels.execution[local.key] GT 0>
								<cfif local.firstDone>,</cfif>
								#LCase(local.key)# ~#request.wheels.execution[local.key]#ms
								<cfset local.firstDone = true>
							</cfif>
						</cfloop>
						)
					</cfif>
				</td>
			</tr>
		</table>
	</div>
</cfoutput>
<!--- cfformat-ignore-end --->
