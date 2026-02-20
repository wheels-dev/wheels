<cfsilent>
<cfif testResults.numErrors || testResults.numFailures>
	<cfheader statuscode="417" />
<cfelse>
	<cfheader statuscode="200" />
</cfif>
<!---cfscript>
  content(type="text/json");
  writeOutput(serializeJSON(testResults));
</cfscript--->
<!--- Moved back to tags - see https://github.com/wheels-dev/wheels/issues/659 --->
<cfset request.wheels.showDebugInformation = false>
<cfsetting showdebugoutput="false">
<cfcontent type="text/json">
</cfsilent><cfoutput>#SerializeJSON(testResults)#</cfoutput>
