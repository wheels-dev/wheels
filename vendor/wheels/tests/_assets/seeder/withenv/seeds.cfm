<!--- S2: main seeds run before the environment-specific include. --->
<cfscript>
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName",
	properties = {firstName: "SeederEnvMain99", lastName: "EnvMain"}
);
</cfscript>
