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
    
    for (bundle in DeJsonResult.bundleStats) {
        for (suite in bundle.suiteStats) {
            for (spec in suite.specStats) {
                thisResult = {
                    packageName = bundle.name,
                    testName = spec.name,
                    time = spec.totalDuration,
                    status = "",
                    message = "",
                    cleanTestCase = replaceNoCase(bundle.name, "#package#.", "", "all"),
                    cleanTestName = spec.name
                };
                
                switch (spec.status) {
                    case "Failed":
                        thisResult.message = spec.failMessage;
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
                
                arrayAppend(testResults.results, thisResult);
            }
        }
    }
    
    failures = [];
    passes = [];
    skipped = [];
    
    for (result in testResults.results) {
        switch (result.status) {
            case "Success": arrayAppend(passes, result); break;
            case "Skipped": arrayAppend(skipped, result); break;
            default: arrayAppend(failures, result);
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
            <td><strong>Status</strong><br /><cfif testResults.ok><i class='icon check'></i> Passed<cfelse><i class='icon close'></i> Failed</cfif></td>
            <td><strong>Duration</strong><br />#numberFormat(duration.hours, "00")#:#numberFormat(duration.minutes, "00")#:#numberFormat(duration.seconds, "00")#</td>
            <td><strong>Bundles</strong><br />#testResults.numCases#</td>
            <td><strong>Specs</strong><br />#testResults.numTests#</td>
            <td><strong>Failures</strong><br />#testResults.numFailures#</td>
            <td><strong>Errors</strong><br />#testResults.numErrors#</td>
        </tr>
        #endTable()#

        <div class="ui top attached tabular menu stackable">
            <a class="item <cfif !testResults.ok>active</cfif>" data-tab="failures">Failures (#arraylen(failures)#)</a>
            <a class="item <cfif testResults.ok>active</cfif>" data-tab="passed">Passed (#arraylen(passes)#)</a>
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