<cfsilent>
<cfif testResults.numErrors || testResults.numFailures>
	<cfheader statuscode="417" statustext="Expectation Failed" />
<cfelse>
	<cfheader statuscode="200" statustext="OK" />
</cfif>
<!---cfscript>
  content(type="text/json");
  writeOutput(serializeJSON(testResults));
</cfscript--->
<!--- Moved back to tags - see https://github.com/cfwheels/cfwheels/issues/659 --->
<cfset request.wheels.showDebugInformation = false>
<cfsetting showdebugoutput="false">
<cfcontent type="text/json">
</cfsilent><cfoutput>#SerializeJSON(testResults)#</cfoutput>
