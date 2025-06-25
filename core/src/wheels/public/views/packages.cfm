<cfinclude template="../layout/_header.cfm">

<cfscript>
param name="request.wheels.params.type" default="app";
param name="request.wheels.params.sort" default="directory";

packages = $createObjectFromRoot(
	path = application.wheels.wheelsComponentPath,
	fileName = "Test",
	method = "$listTestPackages",
	options = request.wheels.params
);

// ignore packages before the "tests directory"
if (packages.recordCount) {
	allPackages = ListToArray(packages.package, ".");
	preTest = "";
	for (i in allPackages) {
		preTest = ListAppend(preTest, i, ".");
		if (i eq "tests") {
			break;
		}
	}
}
</cfscript>
<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui container">
		#pageHeader("Test Suites", "Core &amp; App test suites")#

		<cfinclude template="../tests/_navigation.cfm">

		<div class="ui segment">
			<p>Below is listing of all the #request.wheels.params.type# test packages. Click the part of the package to run it individually.</p>
				<cfif packages.recordcount>
				<table class="ui celled striped table searchable">
					<thead>
						<tr>
							<th>Test Packages</th>
						</tr>
					</thead>
					<cfloop query="packages">
						<tr><td>
							<cfset testablePackages = ListToArray(ReplaceNoCase(package, "#preTest#.", "", "one"), ".")>
							<cfset packagesLen = arrayLen(testablePackages)>
							<cfloop from="1" to="#packagesLen#" index="i">
								<a href="#urlFor(route="wheelsTests",
								type = request.wheels.params.type,
								params="package=#ArrayToList(testablePackages.subList(JavaCast('int', 0), JavaCast('int', i)), '.')#&format=html&#_baseParams#")#">#testablePackages[i]#<cfif i neq packagesLen> .</cfif></a>
							</cfloop>
						</td></tr>
					</cfloop>
				</table>
				<cfelse>
					<div class="ui placeholder segment">
						<div class="ui icon header">
							<i class="tasks icon"></i>
							No tests found!
						</div>
					</div>
				</cfif>
			</div>

	</div>
	<!--- cfformat-ignore-end --->
</cfoutput>

<cfinclude template="../layout/_footer.cfm">
