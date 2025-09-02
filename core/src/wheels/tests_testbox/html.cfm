<cfcontent type="text/html">
<cfparam name="result" default="">
<cfparam name="_baseParams" default="">
<cfparam name="type" type="string">
<cfif NOT listFindNoCase("Core,App", type)>
    <cfthrow message="Invalid 'type' value. Allowed values are 'Core' or 'App'." type="InvalidType">
</cfif>
<cfscript>
    DeJsonResult = DeserializeJSON(result);
    if(type eq "Core") {
        package = "wheels.tests_testbox.specs";
        route = "wheelstestbox";
    } else if(type eq "App") {
        package = "tests.specs";
        route = "testbox";
    }
    // Convert TestBox results to a format similar to RocketUnit
    testResults = {
        path = StructKeyExists(url, "directory") ? url.directory : package,
        begin = DeJsonResult.startTime,
        end = DeJsonResult.endTime,
        ok = true,
        numCases = DeJsonResult.totalBundles,
        numTests = DeJsonResult.totalSpecs,
        numFailures = DeJsonResult.totalFail,
        numErrors = DeJsonResult.totalError,
        results = []
    };
    durationMillis = DeJsonResult.endTime-DeJsonResult.startTime;
    totalSeconds = int(durationMillis / 1000);
    duration.hours = int(totalSeconds / 3600);
    duration.minutes = int((totalSeconds mod 3600) / 60);
    duration.seconds = totalSeconds mod 60;
    
    testResults.ok = (testResults.numFailures + testResults.numErrors) == 0;
    
    // Recursive function to process nested suites
    function processNestedSuites(suites, bundleName) {
        for (suite in suites) {
            // Process nested suites first (deeper level)
            if (structKeyExists(suite, "suiteStats") && arrayLen(suite.suiteStats) > 0) {
                processNestedSuites(suite.suiteStats, bundleName);
            }
            
            // Process individual specs in this suite
            for (spec in suite.specStats) {
                thisResult = {
                    packageName = bundleName,
                    testName = structKeyExists(spec, "name") ? spec.name : "Unknown Test",
                    time = structKeyExists(spec, "totalDuration") ? spec.totalDuration : 0,
                    status = "",
                    message = "",
                    cleanTestCase = replaceNoCase(bundleName, "#package#.", "", "all"),
                    cleanTestName = structKeyExists(spec, "name") ? spec.name : "Unknown Test"
                };
                
                // Check if spec has status field
                if (structKeyExists(spec, "status")) {
                    switch (spec.status) {
                        case "Failed":
                            thisResult.message = structKeyExists(spec, "failMessage") ? spec.failMessage : "";
                            thisResult.status = "Failed";
                            break;
                        case "Error":
                            thisResult.status = "Error";
                            if (isStruct(spec.error) && structKeyExists(spec.error, "message")) {
                                thisResult.message = spec.error.message;
                            }
                            break;
                        case "Skipped":
                            thisResult.status = "Skipped";
                            break;
                        default:
                            thisResult.status = "Success";
                    }
                } else if (structKeyExists(spec, "error")) {
                    // Spec has error but no status - treat as error
                    thisResult.status = "Error";
                    if (isStruct(spec.error) && structKeyExists(spec.error, "message")) {
                        thisResult.message = spec.error.message;
                    }
                }
                
                arrayAppend(testResults.results, thisResult);
            }
            
            // Handle suites with errors but no individual specs (setup errors)
            if (arrayLen(suite.specStats) == 0 && (suite.totalError > 0 || suite.totalFail > 0)) {
                thisResult = {
                    packageName = bundleName,
                    testName = suite.name & " (Suite Setup Error)",
                    time = structKeyExists(suite, "totalDuration") ? suite.totalDuration : 0,
                    status = "",
                    message = "",
                    cleanTestCase = replaceNoCase(bundleName, "#package#.", "", "all"),
                    cleanTestName = suite.name & " (Suite Setup Error)"
                };
                
                if (suite.totalError > 0) {
                    thisResult.status = "Error";
                    thisResult.message = "Suite setup failed with " & suite.totalError & " error(s)";
                } else if (suite.totalFail > 0) {
                    thisResult.status = "Failed";
                    thisResult.message = "Suite setup failed with " & suite.totalFail & " failure(s)";
                }
                
                arrayAppend(testResults.results, thisResult);
            }
        }
    }

    for (bundle in DeJsonResult.bundleStats) {
        processNestedSuites(bundle.suiteStats, bundle.name);
    }
    
    failures = [];
    errors = [];
    passes = [];
    skipped = [];
    
    // Count bundles with failures/errors as fallback when individual specs aren't available
    bundlesWithFailures = 0;
    bundlesWithErrors = 0;
    
    for (result in testResults.results) {
        switch (result.status) {
            case "Success": arrayAppend(passes, result); break;
            case "Skipped": arrayAppend(skipped, result); break;
            case "Failed": arrayAppend(failures, result); break;
            case "Error": arrayAppend(errors, result); break;
        }
    }
    
    // If we have no individual error/failure results but the totals show errors/failures,
    // count the bundles that have them
    if (arraylen(errors) eq 0 and testResults.numErrors gt 0) {
        for (bundle in DeJsonResult.bundleStats) {
            if (bundle.totalError gt 0) {
                bundlesWithErrors++;
            }
        }
    }
    
    if (arraylen(failures) eq 0 and testResults.numFailures gt 0) {
        for (bundle in DeJsonResult.bundleStats) {
            if (bundle.totalFail gt 0) {
                bundlesWithFailures++;
            }
        }
    }
</cfscript>

<cfoutput>
<cfinclude template="/wheels/public/layout/_header.cfm">
<div class="ui container">

    #pageHeader(title="TestBox #type# Test Results")#
    <cfinclude template="/wheels/tests_testbox/_navigation.cfm">

    <cfif NOT isStruct(testResults)>
        <p style="margin-bottom: 50px;">Sorry, no tests were found.</p>
    <cfelse>
        <h4>Package: #testResults.path#</h4>

        #startTable(title="Test Results", colspan=6)#
        <tr class="<cfif testResults.ok>positive<cfelse>error</cfif>">
            <td><strong>Status</strong><br /><cfif testResults.ok> Passed<cfelse> Failed</cfif></td>
            <td><strong>Duration</strong><br />#numberFormat(duration.hours, "00")#:#numberFormat(duration.minutes, "00")#:#numberFormat(duration.seconds, "00")#</td>
            <td><strong>Bundles</strong><br />#testResults.numCases#</td>
            <td><strong>Specs</strong><br />#testResults.numTests#</td>
            <td><strong>Failures</strong><br />#testResults.numFailures#</td>
            <td><strong>Errors</strong><br />#testResults.numErrors#</td>
        </tr>
        #endTable()#

        <div class="ui top attached tabular menu stackable">
            <a class="item <cfif !testResults.ok and (arraylen(failures) gt 0 or bundlesWithFailures gt 0)>active</cfif>" data-tab="failures">Failures (<cfif arraylen(failures) gt 0>#arraylen(failures)#<cfelse>#bundlesWithFailures#</cfif>)</a>
            <a class="item <cfif !testResults.ok and arraylen(failures) eq 0 and bundlesWithFailures eq 0 and (arraylen(errors) gt 0 or bundlesWithErrors gt 0)>active</cfif>" data-tab="errors">Errors (<cfif arraylen(errors) gt 0>#arraylen(errors)#<cfelse>#bundlesWithErrors#</cfif>)</a>
            <a class="item <cfif testResults.ok>active</cfif>" data-tab="passed">Passed (#arraylen(passes)#)</a>
        </div>

        #startTab(tab="failures", active=(!testResults.ok and (arraylen(failures) gt 0 or bundlesWithFailures gt 0)))#
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
                <cfloop array="#failures#" index="result">
                    <tr class="error">
                        <td><a href="?method=runRemote&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                        <td><a href="?method=runRemote&testSpecs=#ReplaceNoCase(result.testName," ","%20","all")#&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestName#</a></td>
                        <td class="n">#result.time#</td>
                        <td class="failed">#result.status#</td>
                    </tr>
                    <tr class="error">
                        <td colspan="4" class="failed">#replace(result.message, chr(10), "<br/>", "ALL")#</td>
                    </tr>
                </cfloop>

                <cfloop array="#skipped#" index="result">
                    <tr>
                        <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                        <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                        <td class="n">#result.time#</td>
                        <td>#result.status#</td>
                    </tr>
                    <tr>
                        <td colspan="4">#replace(result.message, chr(10), "<br/>", "ALL")#</td>
                    </tr>
                </cfloop>
            </tbody>
        </table>
        #endTab()#

        #startTab(tab="errors", active=(!testResults.ok and arraylen(failures) eq 0 and bundlesWithFailures eq 0 and (arraylen(errors) gt 0 or bundlesWithErrors gt 0)))#
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
                <cfif arraylen(errors) gt 0>
                    <cfloop array="#errors#" index="result">
                        <tr class="error">
                            <td><a href="?method=runRemote&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                            <td><a href="?method=runRemote&testSpecs=#ReplaceNoCase(result.testName," ","%20","all")#&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestName#</a></td>
                            <td class="n">#result.time#</td>
                            <td class="failed">#result.status#</td>
                        </tr>
                        <tr class="error">
                            <td colspan="4" class="failed">#replace(result.message, chr(10), "<br/>", "ALL")#</td>
                        </tr>
                    </cfloop>
                <cfelseif testResults.numErrors gt 0>
                    <!--- Show error summary when individual specs aren't available --->
                    <cfloop array="#DeJsonResult.bundleStats#" index="bundle">
                        <cfif bundle.totalError gt 0>
                            <tr class="error">
                                <td colspan="4" class="failed">
                                    <strong>#bundle.name#</strong><br/>
                                    <em>Bundle has #bundle.totalError# error(s), but individual test details are not available in the TestBox results.</em><br/>
                                    <a href="?method=runRemote&testBundles=#bundle.name#&#_baseParams#">Re-run this bundle</a> to see detailed error information.
                                </td>
                            </tr>
                        </cfif>
                    </cfloop>
                </cfif>
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
                <cfloop array="#passes#" index="result">
                    <tr class="positive">
                        <td><a href="?method=runRemote&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                        <td><a href="?method=runRemote&testSpecs=#ReplaceNoCase(result.testName," ","%20","all")#&testBundles=#result.packageName#&#_baseParams#">#result.cleanTestName#</a></td>
                        <td class="n">#result.time#</td>
                        <td class="success">#result.status#</td>
                    </tr>
                </cfloop>

                <cfloop array="#skipped#" index="result">
                    <tr>
                        <td><a href="?directory=#result.packageName#&#_baseParams#">#result.cleanTestCase#</a></td>
                        <td><a href="?directory=#result.packageName#&testSpecs=#result.testName#&#_baseParams#">#result.cleanTestName#</a></td>
                        <td class="n">#result.time#</td>
                        <td>#result.status#</td>
                    </tr>
                    <tr>
                        <td colspan="4">#replace(result.message, chr(10), "<br/>", "ALL")#</td>
                    </tr>
                </cfloop>
            </tbody>
        </table>
        #endTab()#

    </cfif>
</div>
<cfinclude template="/wheels/public/layout/_footer.cfm">
</cfoutput>