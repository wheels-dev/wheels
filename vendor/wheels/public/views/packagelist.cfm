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
<cfscript>
// Load registry packages for the "Browse registry" section.
// Short-circuits in production via $loadRegistryPackages.
registryResult = application.wheels.public.$loadRegistryPackages();
registryPackages = registryResult.packages;
registryError = registryResult.error;

// Build a set of installed package keys (lowercased) for quick
// lookup when rendering the "✓ Installed" badge on registry rows.
installedKeys = {};
for (local.key in packageMeta) {
	installedKeys[LCase(local.key)] = true;
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
								<a class="ui button tiny" href="#urlFor(route='testbox', params='directory=vendor.#LCase(local.pkgKey)#.tests')#">View Tests</a>
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

<div class="ui container" style="margin-top: 3em;">
	<h2 class="ui header">
		Browse registry
		<div class="sub header">
			Packages available at
			<a href="https://wheels.dev/packages" target="_blank" rel="noopener">wheels.dev/packages</a>.
			Install with the CLI.
		</div>
	</h2>

	<cfif Len(registryError)>
		<div class="ui warning message">
			<div class="header">Registry unavailable</div>
			<p>#HTMLEditFormat(registryError)#</p>
		</div>
	<cfelseif ArrayLen(registryPackages) EQ 0>
		<div class="ui message">
			<p>No packages found in the registry.</p>
		</div>
	<cfelse>
		<table class="ui celled striped table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Description</th>
					<th>Latest</th>
					<th>Install</th>
				</tr>
			</thead>
			<tbody>
				<cfloop array="#registryPackages#" index="local.rp">
					<cfset local.rpKey = LCase(local.rp.name)>
					<cfset local.isInstalled = StructKeyExists(installedKeys, local.rpKey)>
					<tr>
						<td>
							<strong>#HTMLEditFormat(local.rp.name)#</strong>
							<cfif Len(local.rp.homepage) AND REFindNoCase("^https?://", local.rp.homepage)>
								<br><a href="#HTMLEditFormat(local.rp.homepage)#" target="_blank" rel="noopener" class="ui small grey text">homepage</a>
							</cfif>
						</td>
						<td>#HTMLEditFormat(local.rp.description)#</td>
						<td>#HTMLEditFormat(local.rp.latestVersion)#</td>
						<td>
							<cfif local.isInstalled>
								<span class="ui label"><svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 512 512" fill="currentColor" style="vertical-align: middle; margin-right: 4px;"><path d="M438.6 105.4c12.5 12.5 12.5 32.8 0 45.3l-256 256c-12.5 12.5-32.8 12.5-45.3 0l-128-128c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0L160 338.7 393.4 105.4c12.5-12.5 32.8-12.5 45.3 0z"/></svg>Installed</span>
							<cfelse>
								<!--- rp.name is registry-schema-constrained to ^[a-z0-9][a-z0-9-]*$, so both id and JS string are already safe.
								      JSStringFormat() is applied in the onclick defensively in case that invariant ever loosens.
								      `add` (not `install`) is the canonical verb — LuCLI's built-in extension
								      installer intercepts the literal subcommand `install`, so `wheels packages
								      install <name>` never reaches Module.cfc. See PR #2374 / cli/lucli/services/packages/PackagesMainCli.cfc. --->
								<code id="install-#HTMLEditFormat(local.rpKey)#">wheels packages add #HTMLEditFormat(local.rp.name)#</code>
								<button type="button"
									class="ui tiny button"
									aria-label="Copy install command for #HTMLEditFormat(local.rp.name)#"
									onclick="navigator.clipboard.writeText(document.getElementById('install-#JSStringFormat(local.rpKey)#').innerText)">
									Copy
								</button>
							</cfif>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfif>
</div>

</cfoutput>
<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->