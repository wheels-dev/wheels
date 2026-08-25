<!--- S2: environment-specific include — only when environment=testing. --->
<cfscript>
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName",
	properties = {firstName: "SeederEnvTest99", lastName: "EnvTest"}
);
</cfscript>
