<cfcontent type="text/html">
<cfparam name="result" default="">
<cfparam name="type" default="core">
<cfparam name="_baseParams" default="">
<cfparam name="_params" default="">

<cfset DeJsonResult = DeserializeJSON(result)>

<cfscript>
    // Convert TestBox results to a format similar to RocketUnit
    testResults = {
        path = StructKeyExists(url, "directory") ? url.directory : "wheels.tests_testbox.specs",
        begin = now(),
        end = dateAdd("n", 1, now()),
        ok = true,
        numCases = 0,
        numTests = 0,
        numFailures = 0,
        numErrors = 0,
        results = []
    };
    
    testResults.numCases = DeJsonResult.totalBundles;
    testResults.numTests = DeJsonResult.totalSpecs;
    testResults.numFailures = DeJsonResult.totalFail;
    testResults.numErrors = DeJsonResult.totalError;
    testResults.ok = (DeJsonResult.totalFail + DeJsonResult.totalError) == 0;
    
    for (bundle in DeJsonResult.bundleStats) {
        for (suite in bundle.suiteStats) {
            for (spec in suite.specStats) {
                thisResult = {
                    packageName = bundle.name,
                    testName = spec.name,
                    time = spec.totalDuration,
                    status = spec.status,
                    message = "",
                    cleanTestCase = replaceNoCase(bundle.name, "wheels.tests_testbox.specs.","","all"),
                    cleanTestName = spec.name
                };
                
                if (spec.status eq "Failed") {
                    thisResult.message = spec.failMessage;
                    thisResult.status = "Failed";
                } else if (spec.status eq "Error") {
                    thisResult.message = "";
                    if (isStruct(spec.error) && structKeyExists(spec.error, "message")) {
                        thisResult.message = spec.error.message;
                    }
                    thisResult.status = "Error";
                } else if (spec.status eq "Skipped") {
                    thisResult.status = "Skipped";
                } else {
                    thisResult.status = "Success";
                }
                
                arrayAppend(testResults.results, thisResult);
            }
        }
    }
    
    // Process the results into failures and passes
    failures = [];
    passes = [];
    skipped = [];
    for (result in testResults.results) {
        if (result.status EQ "Success") {
            arrayAppend(passes, result);
        } else if (result.status EQ "Skipped") {
            arrayAppend(skipped, result);
        } else {
            arrayAppend(failures, result);
        }
    }
</cfscript>

<cfoutput>
<!--- cfformat-ignore-start --->
<cfinclude template="/wheels/public/layout/_header.cfm">
<div class="ui container">

    #pageHeader(title="TestBox Test Results")#
    <cfinclude template="_navigation.cfm">
    <cfif NOT isStruct(testResults)>

        <p style="margin-bottom: 50px;">Sorry, no tests were found.</p>

    <cfelse>

        <h4>Package: #testResults.path#</h4>

        #startTable(title="Test Results", colspan=6)#
        <tr class="<cfif testResults.ok>positive<cfelse>error</cfif>">
            <td><strong>Status</strong><br /><cfif testResults.ok><i class='icon check'></i> Passed<cfelse><i class='icon close'></i> Failed</cfif></td>
            <td><strong>Duration</strong><br />#TimeFormat(testResults.end - testResults.begin, "HH:mm:ss")#</td>
            <td><strong>Bundles</strong><br />#testResults.numCases#</td>
            <td><strong>Specs</strong><br />#testResults.numTests#</td>
            <td><strong>Failures</strong><br />#testResults.numFailures#</td>
            <td><strong>Errors</strong><br />#testResults.numErrors#</td>
        </tr>
        #endTable()#

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
                    <th>Bundle</th>
                    <th>Spec Name</th>
                    <th>Time</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <cfloop from="1" to="#arrayLen(failures)#" index="testIndex">
                    <cfset result = failures[testIndex]>
                    <cfif result.status neq 'Success'>
                        <tr class="error">
                            <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                            <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                            <td class="n">#result.time#</td>
                            <td class="<cfif result.status eq 'Success'>success<cfelse>failed</cfif>">#result.status#</td>
                        </tr>
                        <tr class="error"><td colspan="4" class="failed">#replace(result.message, chr(10), "<br/>", "ALL")#</td></tr>
                    </cfif>
                </cfloop>
                <cfloop from="1" to="#arrayLen(skipped)#" index="testIndex">
                    <cfset result = skipped[testIndex]>
                    <cfif arrayLen(failures)>
                        <tr>
                            <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                            <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                            <td class="n">#result.time#</td>
                            <td>#result.status#</td>
                        </tr>
                        <tr><td colspan="4">#replace(result.message, chr(10), "<br/>", "ALL")#</td></tr>
                    </cfif>
                </cfloop>
                </tbody>
            </table>
        #endTab()#

        #startTab(tab="passed", active=testResults.ok)#
            <table class="ui celled table searchable">
                <thead>
                <tr>
                    <th>Bundle</th>
                    <th>Spec Name</th>
                    <th>Time</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <cfloop from="1" to="#arrayLen(passes)#" index="testIndex">
                    <cfset result = passes[testIndex]>
                    <cfif result.status eq 'Success'>
                        <tr class="positive">
                            <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                            <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                            <td class="n">#result.time#</td>
                            <td class="success">#result.status#</td>
                        </tr>
                    </cfif>
                </cfloop>
                <cfloop from="1" to="#arrayLen(skipped)#" index="testIndex">
                    <cfset result = skipped[testIndex]>
                    <cfif !arrayLen(failures)>
                        <tr>
                            <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                            <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                            <td class="n">#result.time#</td>
                            <td>#result.status#</td>
                        </tr>
                        <tr><td colspan="4">#replace(result.message, chr(10), "<br/>", "ALL")#</td></tr>
                    </cfif>
                </cfloop>
                </tbody>
            </table>
        #endTab()#

    </cfif>
</div>

<cfinclude template="/wheels/public/layout/_footer.cfm">
<!--- cfformat-ignore-end --->
</cfoutput>

<script>
$(document).ready(function(){
    $('.ui.menu .item').tab();
});
</script>