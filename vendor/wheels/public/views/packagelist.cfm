<cfscript>
param name="request.wheels.params.format" default="html";

if (!StructKeyExists(application.wheels, "enablePackagesComponent") || !application.wheels.enablePackagesComponent)
	throw(type="wheels.packages", message="The Wheels Package component is disabled.");

packageMeta = StructKeyExists(application.wheels, "packageMeta") ? application.wheels.packageMeta : {};
failedPackages = StructKeyExists(application.wheels, "failedPackages") ? application.wheels.failedPackages : [];

// JSON format
if (request.wheels.params.format == "json") {
	local.data = {
		"version": application.wheels.version,
		"timestamp": now(),
		"packages": {
			"enabled": true,
			"loaded": {},
			"failed": [],
			"count": StructCount(packageMeta)
		}
	};

	for (local.pkgName in packageMeta) {
		local.data.packages.loaded[local.pkgName] = {
			"name": packageMeta[local.pkgName].name,
			"version": packageMeta[local.pkgName].version,
			"author": packageMeta[local.pkgName].author,
			"description": packageMeta[local.pkgName].description
		};
	}

	if (ArrayLen(failedPackages)) {
		local.data.packages.failed = failedPackages;
	}

	cfcontent(type="application/json", reset=true);
	writeOutput(serializeJSON(local.data));
	abort;
}
</cfscript>
<cfinclude template="../layout/_header.cfm">
<cfoutput>
<!--- cfformat-ignore-start --->
<div class="ui container">
	#pageHeader("Packages", "Installed vendor packages")#

	<cfif ArrayLen(failedPackages)>
		<div class="ui error message">
			<div class="header">Package Loading Errors</div>
			<cfloop array="#failedPackages#" index="local.fp">
				<p><strong>#local.fp.name#</strong>: #local.fp.error#<cfif Len(local.fp.detail)> &mdash; #local.fp.detail#</cfif></p>
			</cfloop>
		</div>
	</cfif>

	<cfif StructCount(packageMeta) GT 0>
		<table class="ui celled striped table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Version</th>
					<th>Author</th>
					<th>Description</th>
					<th>Info</th>
				</tr>
			</thead>
			<tbody>
				<cfloop collection="#packageMeta#" item="local.pkgKey">
					<cfset local.pkg = packageMeta[local.pkgKey]>
					<tr>
						<td>
							<a href="#urlFor(route="wheelsPackageEntry", name=local.pkgKey)#">#local.pkg.name#</a>
						</td>
						<td>#local.pkg.version#</td>
						<td>#local.pkg.author#</td>
						<td>#local.pkg.description#</td>
						<td>
							<a class="ui button tiny teal" href="#urlFor(route='wheelsPackageEntry', name=local.pkgKey)#">
								<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="8 6 8 12" fill="white" style="vertical-align: middle; margin-right: 4px;">
									<path d="M11 7h2v2h-2V7zm0 4h2v6h-2v-6z"/>
								</svg>
								Details
							</a>
							<cfif DirectoryExists("#expandPath("/vendor/#LCase(local.pkgKey)#/tests")#")>
								<a class="ui button tiny" href="#urlFor(route='testbox')#&directory=vendor.#LCase(local.pkgKey)#.tests">View Tests</a>
							</cfif>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	<cfelse>
		<div class="ui placeholder segment">
			<div class="ui icon header">
				<svg xmlns="http://www.w3.org/2000/svg" height="60" width="60" viewBox="0 0 512 512"><path fill="##6c7086" d="M234.5 5.7c13.9-5.3 29.7-5.3 43.6 0l192 73.7C493.6 89.5 512 112.3 512 138.4V373.6c0 26.1-18.4 48.9-42 59l-192 73.7c-13.9 5.3-29.7 5.3-43.6 0l-192-73.7C18.4 422.5 0 399.7 0 373.6V138.4c0-26.1 18.4-48.9 42-59l192-73.7zM256 66L82 133l174 67 174-67L256 66zM32 373.6c0 8.7 6.1 16.3 14 19.7l192 73.7V274L46 200v173.6zM274 467l192-73.7c7.9-3 14-11 14-19.7V200L274 274V467z"/></svg>
				<br>No packages installed
			</div>
			<p>Activate packages by copying them from <code>packages/</code> to <code>vendor/</code>.</p>
		</div>
	</cfif>
</div>

</cfoutput>
<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->