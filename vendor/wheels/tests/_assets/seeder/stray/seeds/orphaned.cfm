<!--- S3: stray seeds/*.cfm that hasSeedFiles() sees but runSeeds() never includes. --->
<cfscript>
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName",
	properties = {firstName: "SeederStrayOrphan99", lastName: "StrayOrphan"}
);
</cfscript>
