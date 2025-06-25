<cfoutput>
<!--- cfformat-ignore-start --->
<cfinclude template="../layout/_header.cfm">
<div class="ui container">

	#pageHeader(title="Test Results")#

	<cfinclude template="_navigation.cfm">

	<cfif NOT isStruct(testResults)>

		<p style="margin-bottom: 50px;">Sorry, no tests were found.</p>

	<cfelse>

		<h4>Package: #testResults.path#</h4>

		<div class="ui breadcrumb">
			<cfif type EQ "app" OR type EQ "core">
				<a class="section" href="#urlFor(route="wheelsPackages", type=type, params=_baseParams)#">#type#</a>
			<cfelse>
			<div class="section">Plugins</div>
			</cfif>

			<cfset prevPath ="">
			<cfloop list="#testResults.path#" delimiters="." index="i">
			<cfif !listFind("wheels,tests,plugins", i)>
				<cfset prevPath= listAppend(prevPath, i, '.')>
				<i class="right angle icon divider"></i>
					<cfif !listLast(testResults.path, '.') EQ i>
						<a class="section" href="#urlFor(route="wheelsPackages", params="package=#prevPath#", type=type, params=_baseParams)#">#listLast(prevPath, '.')#</a>
					<cfelse>
						<a class="section active" href="#urlFor(route="wheelsPackages", params="package=#prevPath#&#_baseParams#", type=type, params=_baseParams)#">#listLast(prevPath, '.')#</a>
					</cfif>
			</cfif>
			</cfloop>
		</div>

		#startTable(title="Test Results", colspan=6)#
		<tr class="<cfif testResults.ok>positive<cfelse>error</cfif>">
			<td><strong>Status</strong><br /><cfif testResults.ok><i class='icon check'></i> Passed<cfelse><i class='icon close'></i> Failed</cfif></td>
			<td><strong>Duration</strong><br />#TimeFormat(testResults.end - testResults.begin, "HH:mm:ss")#</td>
			<td><strong>Packages</strong><br />#testResults.numCases#</td>
			<td><strong>Tests</strong><br />#testResults.numTests#</td>
			<td><strong>Failures</strong><br />#testResults.numFailures#</td>
			<td><strong>Errors</strong><br />#testResults.numErrors#</td>
		</tr>
		#endTable()#


			<cfscript>
				failures = [];
				passes = [];
				for(result in testResults.results){
					if(result.status NEQ "Success"){
						arrayAppend(failures, result);
					} else {
						arrayAppend(passes, result);
					}
				}
			</cfscript>

			<div class="ui top attached tabular menu stackable">
				<cfif testResults.ok>
					<a class="item active" data-tab="passed">Passed (#arraylen(passes)#)</a>
					<a class="item" data-tab="failures">Failures (#arraylen(failures)#)</a>
				<cfelse>
					<a class="item active" data-tab="failures">Failures (#arraylen(failures)#)</a>
					<a class="item" data-tab="passed">Passed (#arraylen(passes)#)</a>
				</cfif>
			</div>

			#startTab(tab="failures", active=!testResults.ok)#
				<table class="ui celled table searchable">
					<thead>
					<tr>
						<th>Package</th>
						<th>Test Name</th>
						<th>Time</th>
						<th>Status</th>
					</tr>
				</thead>
				<tbody>
					<cfloop from="1" to="#arrayLen(failures)#" index="testIndex">
						<cfset result = failures[testIndex]>
						<cfif result.status neq 'Success'>
							<tr class="error">
								<td><a href="?package=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
								<td><a href="?package=#result.packageName#&test=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
								<td class="n">#result.time#</td>
								<td class="<cfif result.status eq 'Success'>success<cfelse>failed</cfif>">#result.status#</td>
							</tr>
							<tr class="error"><td colspan="4" class="failed">#replace(result.message, chr(10), "<br/>", "ALL")#</td></tr>
							<!-- plugins use a slightly different debug key? -->
							<cfif type EQ "app" OR type EQ "core">
								<cfset distinctKey= replace(replace(replace(result.packageName, ".", "_", "all"), "tests_", "", "one"),  "wheels_", "", "one") & '_' & result.testName>
							<cfelse>
								<cfset distinctKey= result.DISTINCTKEY>
							</cfif>
							<cfif StructKeyExists(request, "TESTING_FRAMEWORK_DEBUGGING") && StructKeyExists(request["TESTING_FRAMEWORK_DEBUGGING"], distinctKey)>
								<cfloop array="#request['TESTING_FRAMEWORK_DEBUGGING'][distinctKey]#" index="i">
								<tr class="error"><td colspan="4">#i#</tr>
								</cfloop>
							</cfif>
						</cfif>
					</cfloop>
					</tbody>
				</table>
			#endTab()#

			#startTab(tab="passed", active=testResults.ok)#
				<table class="ui celled table searchable">
					<thead>
					<tr>
						<th>Package</th>
						<th>Test Name</th>
						<th>Time</th>
						<th>Status</th>
					</tr>
				</thead>
				<tbody>
					<cfloop from="1" to="#arrayLen(passes)#" index="testIndex">
						<cfset result = passes[testIndex]>
						<cfif result.status eq 'Success'>
							<tr class="positive">
								<td><a href="?package=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
								<td><a href="?package=#result.packageName#&test=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
								<td class="n">#result.time#</td>
								<td class="success">#result.status#</td>
							</tr>
							<!-- plugins use a slightly different debug key? -->
							<cfif type EQ "app" OR type EQ "core">
								<cfset distinctKey= replace(replace(replace(result.packageName, ".", "_", "all"), "tests_", "", "one"),  "wheels_", "", "one") & '_' & result.testName>
							<cfelse>
								<cfset distinctKey= result.DISTINCTKEY>
							</cfif>
							<cfif StructKeyExists(request, "TESTING_FRAMEWORK_DEBUGGING") && StructKeyExists(request["TESTING_FRAMEWORK_DEBUGGING"], distinctKey)>
								<cfloop array="#request['TESTING_FRAMEWORK_DEBUGGING'][distinctKey]#" index="i">
								<tr class="positive"><td colspan="4">#i#</tr>
								</cfloop>
							</cfif>
						</cfif>
					</cfloop>
					</tbody>
				</table>
			#endTab()#

	</cfif>
</div>

<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
</cfoutput>
