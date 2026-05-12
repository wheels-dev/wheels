<cfscript>
param name="request.wheels.params.name";

if (!StructKeyExists(application.wheels, "enablePackagesComponent") || !application.wheels.enablePackagesComponent)
	Throw(type = "wheels.packages", message = "The Wheels Package component is disabled.");

local.pkgName = request.wheels.params.name;
local.packageMeta = StructKeyExists(application.wheels, "packageMeta") ? application.wheels.packageMeta : {};

if (!StructKeyExists(local.packageMeta, local.pkgName))
	Throw(type = "wheels.packages.notFound", message = "Package '#local.pkgName#' is not installed.");

local.meta = local.packageMeta[local.pkgName];
local.manifest = local.meta.manifest;
</cfscript>
<cfinclude template="../layout/_header.cfm">
<cfoutput>
	<div class="ui container">
		#pageHeader("Packages", "Installed vendor packages")#

		<div class="ui menu">
			<a href="#urlFor(route = "wheelsPackageList")#" class="item">
				<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 640 640" style="vertical-align: middle;">
					<circle cx="320" cy="320" r="256" fill="black"/>
					<path d="M188.7 308.7L292.7 204.7C297.3 200.1 304.2 198.8 310.1 201.2C316 203.6 320 209.5 320 216V272H416C433.7 272 448 286.3 448 304V336C448 353.7 433.7 368 416 368H320V424C320 430.5 316.1 436.3 310.1 438.8C304.1 441.3 297.2 439.9 292.7 435.3L188.7 331.3C182.5 325.1 182.5 314.9 188.7 308.7Z" fill="white"/>
				</svg>
				&nbsp; Back to Package List
			</a>
		</div>

		<cfif StructKeyExists(local.manifest, "homepage") AND Len(local.manifest.homepage)>
			<a class="ui button small teal" href="#local.manifest.homepage#" target="_blank">
				<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="white" viewBox="0 0 24 24" style="vertical-align: middle;">
					<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
				</svg>
				<span style="position: relative; top: 2px;">Homepage</span>
			</a>
		</cfif>

		<div class="ui segment">
			<h3 class="ui header">#local.meta.name#</h3>
			<cfif Len(local.meta.description)>
				<p>#local.meta.description#</p>
			</cfif>

			<table class="ui definition table">
				<tbody>
					<tr>
						<td class="two wide">Version</td>
						<td>#local.meta.version#</td>
					</tr>
					<cfif Len(local.meta.author)>
					<tr>
						<td>Author</td>
						<td>#local.meta.author#</td>
					</tr>
					</cfif>
					<tr>
						<td>Directory</td>
						<td><code>#local.meta.directory#</code></td>
					</tr>
					<cfif StructKeyExists(local.manifest, "wheelsVersion") AND Len(local.manifest.wheelsVersion)>
					<tr>
						<td>Wheels Version</td>
						<td>#local.manifest.wheelsVersion#</td>
					</tr>
					</cfif>
					<cfif StructKeyExists(local.manifest, "provides")>
					<tr>
						<td>Provides</td>
						<td>
							<cfset local.provides = local.manifest.provides>
							<cfif StructKeyExists(local.provides, "mixins") AND Len(local.provides.mixins)>
								<span class="ui blue label">Mixins: #local.provides.mixins#</span>
							</cfif>
							<cfif StructKeyExists(local.provides, "services") AND IsArray(local.provides.services) AND ArrayLen(local.provides.services)>
								<span class="ui green label">Services: #ArrayToList(local.provides.services, ", ")#</span>
							</cfif>
							<cfif StructKeyExists(local.provides, "middleware") AND IsArray(local.provides.middleware) AND ArrayLen(local.provides.middleware)>
								<span class="ui violet label">Middleware: #ArrayLen(local.provides.middleware)#</span>
							</cfif>
						</td>
					</tr>
					</cfif>
					<cfif StructKeyExists(local.manifest, "dependencies") AND IsStruct(local.manifest.dependencies) AND StructCount(local.manifest.dependencies) GT 0>
					<tr>
						<td>Dependencies</td>
						<td>
							<cfloop collection="#local.manifest.dependencies#" item="local.depName">
								<span class="ui label">#local.depName#: #local.manifest.dependencies[local.depName]#</span>
							</cfloop>
						</td>
					</tr>
					</cfif>
				</tbody>
			</table>
		</div>

		<!--- Include package-provided index if it exists --->
		<cfset local.pkgIndexPath = "/vendor/#LCase(local.pkgName)#/index.cfm">
		<cfif FileExists(expandPath(local.pkgIndexPath))>
			<div class="ui segment">
				<cfinclude template="#local.pkgIndexPath#">
			</div>
		</cfif>

		<!--- Show test link if package has tests --->
		<cfif DirectoryExists(expandPath("/vendor/#LCase(local.pkgName)#/tests"))>
			<a class="ui button" href="#urlFor(route='testbox', params='directory=vendor.#LCase(local.pkgName)#.tests')#">
				Run Package Tests
			</a>
		</cfif>
	</div>
</cfoutput>
<cfinclude template="../layout/_footer.cfm">